import SwiftUI
import CoreText

enum PlayerTheme {
    static let ground = Color(hex: 0x030C06)
    static let surface = Color(hex: 0x0A1F11)
    static let ink = Color(hex: 0xE1F4E8)
    static let inkDim = Color(hex: 0x72C08E)
    static let hairline = Color(hex: 0x194328)
    static let accent = Color(hex: 0x1DB954)

    static func registerFonts(bundle: Bundle = .main) {
        for name in ["SpaceMono-Regular", "SpaceMono-Bold"] {
            guard let url = bundle.url(forResource: name, withExtension: "ttf") else { continue }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
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
