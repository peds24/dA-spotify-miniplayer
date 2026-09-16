import Foundation

@MainActor
final class LikedSongsService: ObservableObject {
    @Published private(set) var likedState: [String: Bool] = [:]

    private let client: SpotifyLibraryClient

    init(client: SpotifyLibraryClient) {
        self.client = client
    }

    func refreshLikedState(for trackID: String) async {
        guard likedState[trackID] == nil else { return }
        if let liked = try? await client.containsTrack(id: trackID) {
            likedState[trackID] = liked
        }
    }

    func toggleLike(for trackID: String) async {
        let previous = likedState[trackID] ?? false
        likedState[trackID] = !previous
        do {
            if previous {
                try await client.removeTrack(id: trackID)
            } else {
                try await client.saveTrack(id: trackID)
            }
        } catch {
            likedState[trackID] = previous
        }
    }
}
