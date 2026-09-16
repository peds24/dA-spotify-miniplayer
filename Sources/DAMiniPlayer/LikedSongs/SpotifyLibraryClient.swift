import Foundation

@MainActor
protocol SpotifyLibraryClient {
    func containsTrack(id: String) async throws -> Bool
    func saveTrack(id: String) async throws
    func removeTrack(id: String) async throws
}

enum SpotifyLibraryClientError: Error {
    case notAuthenticated
    case requestFailed
}

@MainActor
final class SpotifyWebAPIClient: SpotifyLibraryClient {
    private let auth: SpotifyAuth

    init(auth: SpotifyAuth) {
        self.auth = auth
    }

    func containsTrack(id: String) async throws -> Bool {
        guard let token = await auth.validAccessToken() else { throw SpotifyLibraryClientError.notAuthenticated }
        var request = URLRequest(url: URL(string: "https://api.spotify.com/v1/me/tracks/contains?ids=\(id)")!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw SpotifyLibraryClientError.requestFailed
        }
        let result = try JSONDecoder().decode([Bool].self, from: data)
        return result.first ?? false
    }

    func saveTrack(id: String) async throws {
        try await mutate(id: id, method: "PUT")
    }

    func removeTrack(id: String) async throws {
        try await mutate(id: id, method: "DELETE")
    }

    private func mutate(id: String, method: String) async throws {
        guard let token = await auth.validAccessToken() else { throw SpotifyLibraryClientError.notAuthenticated }
        var request = URLRequest(url: URL(string: "https://api.spotify.com/v1/me/tracks?ids=\(id)")!)
        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw SpotifyLibraryClientError.requestFailed
        }
    }
}
