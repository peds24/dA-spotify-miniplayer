import SwiftUI
import CoreText

struct PlayerTheme {
    let ground: Color
    let surface: Color
    let ink: Color
    let inkDim: Color
    let hairline: Color
    let accent: Color

    // Digital Archives' own dark palette (peds24.github.io/digital-archives) —
    // the mini player has always matched it.
    static let dark = PlayerTheme(
        ground: Color(hex: 0x030C06),
        surface: Color(hex: 0x0A1F11),
        ink: Color(hex: 0xE1F4E8),
        inkDim: Color(hex: 0x72C08E),
        hairline: Color(hex: 0x194328),
        accent: Color(hex: 0x1DB954)
    )

    // Digital Archives' light palette: tan ground/surface shared with the
    // personal site, green ink/accent tuned a shade darker for AA contrast
    // against the tan ground.
    static let light = PlayerTheme(
        ground: Color(hex: 0xDCD6C8),
        surface: Color(hex: 0xE8E2D4),
        ink: Color(hex: 0x23261C),
        inkDim: Color(hex: 0x545D48),
        hairline: Color(hex: 0xB8AF98),
        accent: Color(hex: 0x0B6B34)
    )

    static func registerFonts(bundle: Bundle = .main) {
        for name in ["SpaceMono-Regular", "SpaceMono-Bold"] {
            guard let url = bundle.url(forResource: name, withExtension: "ttf") else { continue }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}

private struct PlayerThemeKey: EnvironmentKey {
    static let defaultValue = PlayerTheme.dark
}

extension EnvironmentValues {
    var playerTheme: PlayerTheme {
        get { self[PlayerThemeKey.self] }
        set { self[PlayerThemeKey.self] = newValue }
    }
}

extension Color {
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
