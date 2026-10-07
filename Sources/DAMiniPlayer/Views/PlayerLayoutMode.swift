import CoreGraphics
import Combine

enum PlayerLayoutMode: Hashable {
    case compact
    case expanded

    var size: CGSize {
        switch self {
        case .compact: CGSize(width: 320, height: 56)
        case .expanded: CGSize(width: 222, height: 300)
        }
    }

    /// Room left around the panel inside the window for its drop shadow.
    static let shadowMargin: CGFloat = 24

    /// The window never resizes: it's always big enough for either layout
    /// (plus shadow), and SwiftUI morphs the visible panel inside it. Its
    /// unused area is fully transparent, so clicks fall through to whatever
    /// is behind it.
    static var canvasSize: CGSize {
        let all = [PlayerLayoutMode.compact, .expanded].map(\.size)
        return CGSize(
            width: all.map(\.width).max()! + shadowMargin * 2,
            height: all.map(\.height).max()! + shadowMargin * 2
        )
    }
}

final class PlayerLayoutState: ObservableObject {
    @Published var mode: PlayerLayoutMode = .compact
}
