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
}

final class PlayerLayoutState: ObservableObject {
    @Published var mode: PlayerLayoutMode = .compact
}
