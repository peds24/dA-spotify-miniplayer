import AppKit
import SwiftUI

final class MiniPlayerPanel: NSPanel {
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

    /// Resizes the panel, keeping its top-left corner fixed so it grows/shrinks
    /// in place rather than jumping when the user has dragged it elsewhere.
    func resize(to size: CGSize) {
        var newFrame = frame
        newFrame.origin.y += newFrame.height - size.height
        newFrame.size = size
        setFrame(newFrame, display: true, animate: true)
    }
}
