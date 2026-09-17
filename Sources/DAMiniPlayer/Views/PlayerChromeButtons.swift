import SwiftUI

/// The expand/collapse chevron and close button shared by the compact and
/// expanded player layouts. The chevron always points in the direction
/// tapping it will move the layout: down to expand, up to collapse.
///
/// Color defaults to the current theme's ink/inkDim, which is right when
/// these sit on the app's own surface (the compact bar). In the expanded
/// layout they instead sit on a fixed dark capsule over arbitrary album
/// art, so that call site overrides `dimColor`/`brightColor` to a fixed
/// light color — theme ink/inkDim go dark in the light theme and would
/// otherwise vanish against that dark backdrop.
struct PlayerChromeButtons: View {
    let mode: PlayerLayoutMode
    let onToggleLayout: () -> Void
    let onClose: () -> Void
    var dimColor: Color?
    var brightColor: Color?
    @Environment(\.playerTheme) private var theme

    @State private var isHoveringLayout = false
    @State private var isHoveringClose = false

    private var dim: Color { dimColor ?? theme.inkDim }
    private var bright: Color { brightColor ?? theme.ink }

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onToggleLayout) {
                Image(systemName: mode == .compact ? "chevron.down" : "chevron.up")
            }
            .buttonStyle(.plain)
            .foregroundColor(isHoveringLayout ? bright : dim)
            .onHover { isHoveringLayout = $0 }

            Button(action: onClose) {
                Image(systemName: "xmark")
            }
            .buttonStyle(.plain)
            .foregroundColor(isHoveringClose ? bright : dim)
            .onHover { isHoveringClose = $0 }
        }
        .font(.system(size: 10, weight: .semibold))
        .animation(.easeOut(duration: 0.12), value: isHoveringLayout)
        .animation(.easeOut(duration: 0.12), value: isHoveringClose)
    }
}
