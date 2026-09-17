import Foundation
import Security

protocol TokenStore {
    func saveRefreshToken(_ token: String)
    func loadRefreshToken() -> String?
    func clear()
}

final class KeychainTokenStore: TokenStore {
    private let service: String
    private let account = "refresh-token"

    /// `service` defaults to the real app's identifier. Tests must pass a
    /// distinct value — the default is also what the running app uses to
    /// store the user's real Spotify refresh token, and a test that shares
    /// it will silently delete that real credential every time it runs.
    init(service: String = "com.pedro.da-miniplayer.spotify") {
        self.service = service
    }

    func saveRefreshToken(_ token: String) {
        clear()
        let data = Data(token.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]
        SecItemAdd(query as CFDictionary, nil)
    }

    func loadRefreshToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func clear() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}

final class InMemoryTokenStore: TokenStore {
    private var token: String?

    func saveRefreshToken(_ token: String) {
        self.token = token
    }

    func loadRefreshToken() -> String? {
        token
    }

    func clear() {
        token = nil
    }
}
