import AppKit
import SwiftUI
import Combine

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var panel: MiniPlayerPanel?
    private let monitor = PlaybackMonitor()
    private var cancellable: AnyCancellable?

    func applicationDidFinishLaunching(_ notification: Notification) {
        PlayerTheme.registerFonts()
        NSApp.setActivationPolicy(.accessory)

        let panel = MiniPlayerPanel {
            MiniPlayerContainerView(monitor: self.monitor)
        }
        panel.orderFrontRegardless()
        self.panel = panel

        monitor.start()

        let statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusBarItem.button?.title = "♪"

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Quit DA Mini Player", action: #selector(quit), keyEquivalent: "q"))
        statusBarItem.menu = menu

        self.statusItem = statusBarItem
    }

    func applicationWillTerminate(_ notification: Notification) {
        monitor.stop()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
