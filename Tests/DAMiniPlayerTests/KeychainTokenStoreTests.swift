import XCTest
@testable import DAMiniPlayer

final class KeychainTokenStoreTests: XCTestCase {
    func testSaveLoadClearRoundTrip() {
        let store = KeychainTokenStore()
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
