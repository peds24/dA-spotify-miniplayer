import AppKit
import SwiftUI

final class MiniPlayerPanel: NSPanel {
    /// Shown on right-click anywhere on the panel — the same NSMenu the
    /// status bar icon uses, so every menu option is reachable without
    /// leaving the floating panel.
    var contextMenu: NSMenu?

    init<Content: View>(@ViewBuilder content: () -> Content) {
        super.init(
            contentRect: NSRect(x: 100, y: 100, width: 320, height: 56),
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
        hasShadow = true
        contentView = NSHostingView(rootView: content())
    }

    override func rightMouseDown(with event: NSEvent) {
        guard let contextMenu, let contentView else {
            super.rightMouseDown(with: event)
            return
        }
        NSMenu.popUpContextMenu(contextMenu, with: event, for: contentView)
    }

    /// Resizes the panel, keeping its top-left corner fixed so it grows/shrinks
    /// in place rather than jumping when the user has dragged it elsewhere.
    func resize(to size: CGSize) {
        var newFrame = frame
        newFrame.origin.y += newFrame.height - size.height
        newFrame.size = size
        setFrame(newFrame, display: true, animate: true)
    }
}
