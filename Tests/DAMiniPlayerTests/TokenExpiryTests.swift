import XCTest
@testable import DAMiniPlayer

final class TokenExpiryTests: XCTestCase {
    func testNotYetExpired() {
        let future = Date().addingTimeInterval(60)
        XCTAssertFalse(TokenExpiry.isExpired(expiresAt: future, now: Date()))
    }

    func testAlreadyExpired() {
        let past = Date().addingTimeInterval(-60)
        XCTAssertTrue(TokenExpiry.isExpired(expiresAt: past, now: Date()))
    }

    func testExactlyAtExpiry() {
        let now = Date()
        XCTAssertTrue(TokenExpiry.isExpired(expiresAt: now, now: now))
    }
}
