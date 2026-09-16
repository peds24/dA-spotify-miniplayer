import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var panel: MiniPlayerPanel?

    func applicationDidFinishLaunching(_ notification: Notification) {
        PlayerTheme.registerFonts()
        NSApp.setActivationPolicy(.accessory)

        let mockNowPlaying = NowPlaying(
            trackID: "mock",
            title: "My Rival",
            artist: "Steely Dan",
            artworkURL: nil,
            position: 42,
            duration: 273,
            isPlaying: true
        )

        let panel = MiniPlayerPanel {
            MiniPlayerView(
                nowPlaying: mockNowPlaying,
                isLiked: false,
                onTogglePlay: {},
                onNext: {},
                onPrevious: {},
                onToggleLike: {}
            )
        }
        panel.orderFrontRegardless()
        self.panel = panel

        let statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusBarItem.button?.title = "♪"

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Quit DA Mini Player", action: #selector(quit), keyEquivalent: "q"))
        statusBarItem.menu = menu

        self.statusItem = statusBarItem
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
