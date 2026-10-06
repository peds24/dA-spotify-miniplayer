import SwiftUI
import CoreText

struct PlayerTheme {
    let ground: Color
    let surface: Color
    let ink: Color
    let inkDim: Color
    let hairline: Color
    let accent: Color
    let typeface: Typeface
    /// Draws the panel as Liquid Glass (see `playerSurface`) instead of the
    /// opaque `surface` color with a `hairline` border.
    let usesGlass: Bool

    enum Typeface {
        case spaceMono
        case system
    }

    static func resolve(style: PlayerStyle, colorScheme: ColorScheme) -> PlayerTheme {
        switch style {
        case .liquidGlass: .glass
        case .digitalArchives: colorScheme == .dark ? .dark : .light
        }
    }

    // Liquid Glass: semantic system colors, so one definition adapts to
    // light and dark and to whatever the glass is refracting behind it.
    // `surface`/`hairline` go unused — the glass material replaces both.
    static let glass = PlayerTheme(
        ground: Color.primary.opacity(0.08),
        surface: .clear,
        ink: .primary,
        inkDim: .secondary,
        hairline: .clear,
        accent: .pink,
        typeface: .system,
        usesGlass: true
    )

    // Digital Archives' own dark palette (peds24.github.io/digital-archives) —
    // the mini player has always matched it.
    static let dark = PlayerTheme(
        ground: Color(hex: 0x030C06),
        surface: Color(hex: 0x0A1F11),
        ink: Color(hex: 0xE1F4E8),
        inkDim: Color(hex: 0x72C08E),
        hairline: Color(hex: 0x194328),
        accent: Color(hex: 0x1DB954),
        typeface: .spaceMono,
        usesGlass: false
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
        accent: Color(hex: 0x0B6B34),
        typeface: .spaceMono,
        usesGlass: false
    )

    func titleFont(size: CGFloat) -> Font {
        switch typeface {
        case .spaceMono: .custom("SpaceMono-Bold", size: size)
        case .system: .system(size: size, weight: .semibold)
        }
    }

    func bodyFont(size: CGFloat) -> Font {
        switch typeface {
        case .spaceMono: .custom("SpaceMono-Regular", size: size)
        case .system: .system(size: size)
        }
    }

    /// For the elapsed/total time readout — tabular digits so it doesn't
    /// jitter as the seconds tick.
    func numericFont(size: CGFloat) -> Font {
        switch typeface {
        case .spaceMono: .custom("SpaceMono-Regular", size: size)
        case .system: .system(size: size, weight: .medium).monospacedDigit()
        }
    }

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

/// The panel's background and outline: Liquid Glass for the glass theme
/// (real `glassEffect` on macOS 26+, a translucent material before that),
/// otherwise the theme's opaque surface with a hairline border.
struct PlayerSurface<S: InsettableShape>: ViewModifier {
    let shape: S
    @Environment(\.playerTheme) private var theme

    func body(content: Content) -> some View {
        if theme.usesGlass {
            if #available(macOS 26.0, *) {
                content.glassEffect(.regular, in: shape)
            } else {
                content
                    .background(.regularMaterial, in: shape)
                    .overlay(shape.strokeBorder(Color.white.opacity(0.18), lineWidth: 1))
                    .clipShape(shape)
            }
        } else {
            content
                .background(theme.surface)
                .overlay(shape.stroke(theme.hairline, lineWidth: 1))
                .clipShape(shape)
        }
    }
}

extension View {
    func playerSurface<S: InsettableShape>(_ shape: S) -> some View {
        modifier(PlayerSurface(shape: shape))
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
