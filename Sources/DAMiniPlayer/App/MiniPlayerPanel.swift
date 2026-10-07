import AppKit
import SwiftUI

final class MiniPlayerPanel: NSPanel {
    /// Shown on right-click anywhere on the panel — the same NSMenu the
    /// status bar icon uses, so every menu option is reachable without
    /// leaving the floating panel.
    var contextMenu: NSMenu?

    init<Content: View>(@ViewBuilder content: () -> Content) {
        super.init(
            contentRect: NSRect(origin: NSPoint(x: 100, y: 100), size: PlayerLayoutMode.canvasSize),
            styleMask: [.nonactivatingPanel, .borderless],
            backing: .buffered,
            defer: false
        )
        isFloatingPanel = true
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isMovableByWindowBackground = true
        backgroundColor = .clear
        isOpaque = false
        // The SwiftUI panel draws its own shadow: a window shadow is traced
        // from the content's shape once, so it'd go stale mid-morph.
        hasShadow = false
        contentView = NSHostingView(rootView: content())
    }

    override func rightMouseDown(with event: NSEvent) {
        guard let contextMenu, let contentView else {
            super.rightMouseDown(with: event)
            return
        }
        NSMenu.popUpContextMenu(contextMenu, with: event, for: contentView)
    }
}
