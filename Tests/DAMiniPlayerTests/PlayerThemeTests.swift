import XCTest
import AppKit
import SwiftUI
@testable import DAMiniPlayer

final class PlayerThemeTests: XCTestCase {
    func testFontsRegisterSuccessfully() {
        // XcodeGen doesn't generate a Resources copy phase for the unit-test
        // target when it shares an identical resource path with the app
        // target, so the fonts never land inside DAMiniPlayerTests.xctest.
        // Load them straight from source instead of via bundle resources.
        let fontsDirectory = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Sources/DAMiniPlayer/Resources/Fonts")
        let testBundle = Bundle(url: fontsDirectory)!
        PlayerTheme.registerFonts(bundle: testBundle)
        XCTAssertNotNil(NSFont(name: "SpaceMono-Regular", size: 12))
        XCTAssertNotNil(NSFont(name: "SpaceMono-Bold", size: 12))
    }

    func testHexColorInit() {
        let color = Color(hex: 0x1DB954)
        XCTAssertEqual(color, Color(red: 0x1D.hexDouble, green: 0xB9.hexDouble, blue: 0x54.hexDouble))
    }
}

private extension Int {
    var hexDouble: Double { Double(self) / 255.0 }
}
