import XCTest
@testable import DAMiniPlayer

final class AppVersionTests: XCTestCase {
    func testVersionAndBuild() {
        XCTAssertEqual(
            AppVersion.display(info: ["CFBundleShortVersionString": "1.1.0", "CFBundleVersion": "2"]),
            "Version 1.1.0 (2)"
        )
    }

    func testMissingBuildOmitsParentheses() {
        XCTAssertEqual(AppVersion.display(info: ["CFBundleShortVersionString": "1.1.0"]), "Version 1.1.0")
    }

    func testMissingInfo() {
        XCTAssertEqual(AppVersion.display(info: nil), "Version ?")
    }
}
