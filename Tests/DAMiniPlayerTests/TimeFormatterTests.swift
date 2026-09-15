import XCTest
@testable import DAMiniPlayer

final class TimeFormatterTests: XCTestCase {
    func testZero() {
        XCTAssertEqual(TimeFormatter.format(0), "0:00")
    }

    func testUnderAMinute() {
        XCTAssertEqual(TimeFormatter.format(5), "0:05")
    }

    func testOverAMinute() {
        XCTAssertEqual(TimeFormatter.format(65), "1:05")
    }

    func testExactMinute() {
        XCTAssertEqual(TimeFormatter.format(120), "2:00")
    }

    func testNegativeClampsToZero() {
        XCTAssertEqual(TimeFormatter.format(-5), "0:00")
    }

    func testNaNClampsToZero() {
        XCTAssertEqual(TimeFormatter.format(.nan), "0:00")
    }

    func testFractionalSecondsTruncate() {
        XCTAssertEqual(TimeFormatter.format(59.9), "0:59")
    }
}
