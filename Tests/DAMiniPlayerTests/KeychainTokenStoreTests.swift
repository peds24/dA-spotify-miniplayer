import XCTest
@testable import DAMiniPlayer

final class KeychainTokenStoreTests: XCTestCase {
    func testSaveLoadClearRoundTrip() {
        // A distinct service identifier — the default matches the real app's
        // own storage, and sharing it here would delete a real logged-in
        // user's Spotify refresh token every time this test runs.
        let store = KeychainTokenStore(service: "com.pedro.da-miniplayer.spotify.test")
        store.clear()
        XCTAssertNil(store.loadRefreshToken())

        store.saveRefreshToken("test-refresh-token-123")
        XCTAssertEqual(store.loadRefreshToken(), "test-refresh-token-123")

        store.saveRefreshToken("replacement-token")
        XCTAssertEqual(store.loadRefreshToken(), "replacement-token")

        store.clear()
        XCTAssertNil(store.loadRefreshToken())
    }

    func testInMemoryStoreRoundTrip() {
        let store = InMemoryTokenStore()
        XCTAssertNil(store.loadRefreshToken())
        store.saveRefreshToken("abc")
        XCTAssertEqual(store.loadRefreshToken(), "abc")
        store.clear()
        XCTAssertNil(store.loadRefreshToken())
    }
}
