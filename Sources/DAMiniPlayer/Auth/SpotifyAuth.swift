import Foundation
import AuthenticationServices
import AppKit

struct SpotifyTokenResponse: Decodable {
    let access_token: String
    let expires_in: Int
    let refresh_token: String?
}

@MainActor
final class SpotifyAuth: NSObject, ObservableObject, ASWebAuthenticationPresentationContextProviding {
    @Published private(set) var isLoggedIn: Bool

    private let clientID: String
    private let redirectURI = "da-miniplayer://callback"
    private let scopes = "user-library-read user-library-modify"
    private let tokenStore: TokenStore
    private var accessToken: String?
    private var expiresAt: Date = .distantPast
    private var session: ASWebAuthenticationSession?

    init(clientID: String, tokenStore: TokenStore) {
        self.clientID = clientID
        self.tokenStore = tokenStore
        self.isLoggedIn = tokenStore.loadRefreshToken() != nil
        super.init()
    }

    func login() {
        let verifier = PKCE.generateCodeVerifier()
        let challenge = PKCE.codeChallenge(for: verifier)
        var components = URLComponents(string: "https://accounts.spotify.com/authorize")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "code_challenge", value: challenge),
            URLQueryItem(name: "scope", value: scopes)
        ]

        // ASWebAuthenticationSession invokes this completion handler on a
        // background XPC queue, not the main actor. Since the closure
        // captures `self` (a @MainActor type), Swift infers it as
        // @MainActor-isolated, and calling it off-actor traps at runtime.
        // Hop to the main actor first — nothing here may touch `self`
        // synchronously outside the Task.
        let authSession = ASWebAuthenticationSession(
            url: components.url!,
            callbackURLScheme: "da-miniplayer"
        ) { [weak self] callbackURL, error in
            Task { @MainActor in
                guard let self, let callbackURL, error == nil,
                      let code = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?
                          .queryItems?.first(where: { $0.name == "code" })?.value else { return }
                await self.exchangeCode(code, verifier: verifier)
            }
        }
        authSession.presentationContextProvider = self
        authSession.start()
        self.session = authSession
    }

    func logout() {
        tokenStore.clear()
        accessToken = nil
        expiresAt = .distantPast
        isLoggedIn = false
    }

    func validAccessToken() async -> String? {
        if let token = accessToken, !TokenExpiry.isExpired(expiresAt: expiresAt) {
            return token
        }
        return await refreshAccessToken()
    }

    nonisolated func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        NSApplication.shared.windows.first ?? ASPresentationAnchor()
    }

    private func exchangeCode(_ code: String, verifier: String) async {
        let body = [
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": redirectURI,
            "client_id": clientID,
            "code_verifier": verifier
        ]
        guard let token = await requestToken(body: body) else { return }
        apply(token)
    }

    private func refreshAccessToken() async -> String? {
        guard let refreshToken = tokenStore.loadRefreshToken() else { return nil }
        let body = [
            "grant_type": "refresh_token",
            "refresh_token": refreshToken,
            "client_id": clientID
        ]
        guard let token = await requestToken(body: body) else {
            logout()
            return nil
        }
        apply(token)
        return token.access_token
    }

    private func requestToken(body: [String: String]) async -> SpotifyTokenResponse? {
        var request = URLRequest(url: URL(string: "https://accounts.spotify.com/api/token")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)

        guard let (data, _) = try? await URLSession.shared.data(for: request) else { return nil }
        return try? JSONDecoder().decode(SpotifyTokenResponse.self, from: data)
    }

    private func apply(_ token: SpotifyTokenResponse) {
        accessToken = token.access_token
        expiresAt = Date().addingTimeInterval(TimeInterval(token.expires_in - 60))
        if let refresh = token.refresh_token {
            tokenStore.saveRefreshToken(refresh)
        }
        isLoggedIn = true
    }
}
