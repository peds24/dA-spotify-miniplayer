import XCTest
@testable import DAMiniPlayer

@MainActor
private final class FakeSpotifyLibraryClient: SpotifyLibraryClient {
    var containsResult: Result<Bool, Error> = .success(false)
    var saveResult: Result<Void, Error> = .success(())
    var removeResult: Result<Void, Error> = .success(())
    var saveCallCount = 0
    var removeCallCount = 0

    func containsTrack(id: String) async throws -> Bool {
        try containsResult.get()
    }

    func saveTrack(id: String) async throws {
        saveCallCount += 1
        try saveResult.get()
    }

    func removeTrack(id: String) async throws {
        removeCallCount += 1
        try removeResult.get()
    }
}

private struct TestError: Error {}

@MainActor
final class LikedSongsServiceTests: XCTestCase {
    func testRefreshLikedStateSetsTrueWhenAlreadyLiked() async {
        let client = FakeSpotifyLibraryClient()
        client.containsResult = .success(true)
        let service = LikedSongsService(client: client)

        await service.refreshLikedState(for: "track1")

        XCTAssertEqual(service.likedState["track1"], true)
    }

    func testRefreshLikedStateDoesNotReFetchOnceKnown() async {
        let client = FakeSpotifyLibraryClient()
        client.containsResult = .success(false)
        let service = LikedSongsService(client: client)

        await service.refreshLikedState(for: "track1")
        client.containsResult = .success(true) // would flip the result if fetched again
        await service.refreshLikedState(for: "track1")

        XCTAssertEqual(service.likedState["track1"], false)
    }

    func testToggleLikeOptimisticallySetsTrueAndCallsSave() async {
        let client = FakeSpotifyLibraryClient()
        let service = LikedSongsService(client: client)

        await service.toggleLike(for: "track1")

        XCTAssertEqual(service.likedState["track1"], true)
        XCTAssertEqual(client.saveCallCount, 1)
    }

    func testToggleLikeTwiceCallsRemove() async {
        let client = FakeSpotifyLibraryClient()
        let service = LikedSongsService(client: client)

        await service.toggleLike(for: "track1")
        await service.toggleLike(for: "track1")

        XCTAssertEqual(service.likedState["track1"], false)
        XCTAssertEqual(client.removeCallCount, 1)
    }

    func testToggleLikeRevertsOnFailure() async {
        let client = FakeSpotifyLibraryClient()
        client.saveResult = .failure(TestError())
        let service = LikedSongsService(client: client)

        await service.toggleLike(for: "track1")

        XCTAssertEqual(service.likedState["track1"], false)
    }
}
