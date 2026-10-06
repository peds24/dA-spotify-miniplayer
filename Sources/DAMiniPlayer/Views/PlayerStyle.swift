import Foundation
import Combine

/// The visual style of the floating panel, picked by the user and remembered
/// across launches. Independent of light/dark — each style adapts to the
/// system appearance on its own.
enum PlayerStyle: String, CaseIterable, Identifiable {
    /// macOS 26's Liquid Glass material with system typography. The default.
    case liquidGlass
    /// The original Digital Archives look: opaque green/tan palette, Space Mono.
    case digitalArchives

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .liquidGlass: "Liquid Glass"
        case .digitalArchives: "Digital Archives"
        }
    }
}

final class PlayerStyleState: ObservableObject {
    static let defaultsKey = "playerStyle"

    @Published var style: PlayerStyle {
        didSet { defaults.set(style.rawValue, forKey: Self.defaultsKey) }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.style = defaults.string(forKey: Self.defaultsKey).flatMap(PlayerStyle.init(rawValue:)) ?? .liquidGlass
    }
}
