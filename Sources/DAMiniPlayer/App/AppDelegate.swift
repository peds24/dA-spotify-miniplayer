import AppKit
import SwiftUI
import Combine

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var panel: MiniPlayerPanel?
    private let monitor = PlaybackMonitor()
    private lazy var auth = SpotifyAuth(clientID: Config.spotifyClientID, tokenStore: KeychainTokenStore())
    private lazy var likedSongs = LikedSongsService(client: SpotifyWebAPIClient(auth: auth))
    private let layoutState = PlayerLayoutState()
    private var loginMenuItem: NSMenuItem?
    private var compactMenuItem: NSMenuItem?
    private var expandedMenuItem: NSMenuItem?
    private var authCancellable: AnyCancellable?
    private var layoutCancellable: AnyCancellable?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // The DAMiniPlayerTests bundle is hosted inside this app (XcodeGen
        // wires a unit-test target's dependency on an application target as
        // TEST_HOST), so `xcodebuild test` launches this app for real. None
        // of the actual tests touch app state, so skip setup entirely rather
        // than eagerly evaluate `auth` (which requires Config.plist) just to
        // host the test bundle.
        guard ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil else { return }

        PlayerTheme.registerFonts()
        NSApp.setActivationPolicy(.accessory)

        let panel = MiniPlayerPanel {
            MiniPlayerContainerView(monitor: self.monitor, likedSongs: self.likedSongs, auth: self.auth, layoutState: self.layoutState)
        }
        panel.orderFrontRegardless()
        self.panel = panel

        monitor.start()

        let statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusBarItem.button?.title = "♪"

        let menu = NSMenu()
        let loginItem = NSMenuItem(title: loginTitle, action: #selector(toggleLogin), keyEquivalent: "")
        menu.addItem(loginItem)
        menu.addItem(NSMenuItem.separator())
        let compactItem = NSMenuItem(title: "Compact", action: #selector(selectCompact), keyEquivalent: "")
        let expandedItem = NSMenuItem(title: "Expanded", action: #selector(selectExpanded), keyEquivalent: "")
        menu.addItem(compactItem)
        menu.addItem(expandedItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit DA Mini Player", action: #selector(quit), keyEquivalent: "q"))
        statusBarItem.menu = menu
        self.loginMenuItem = loginItem
        self.compactMenuItem = compactItem
        self.expandedMenuItem = expandedItem
        updateLayoutMenuState()

        authCancellable = auth.$isLoggedIn.sink { [weak self] _ in
            self?.loginMenuItem?.title = self?.loginTitle ?? ""
        }

        layoutCancellable = layoutState.$mode.sink { [weak self] mode in
            self?.panel?.resize(to: mode.size)
            self?.updateLayoutMenuState()
        }

        self.statusItem = statusBarItem
    }

    func applicationWillTerminate(_ notification: Notification) {
        monitor.stop()
    }

    private var loginTitle: String {
        auth.isLoggedIn ? "Log Out of Spotify" : "Log In to Spotify"
    }

    private func updateLayoutMenuState() {
        compactMenuItem?.state = layoutState.mode == .compact ? .on : .off
        expandedMenuItem?.state = layoutState.mode == .expanded ? .on : .off
    }

    @objc private func toggleLogin() {
        if auth.isLoggedIn {
            auth.logout()
        } else {
            auth.login()
        }
    }

    @objc private func selectCompact() {
        layoutState.mode = .compact
    }

    @objc private func selectExpanded() {
        layoutState.mode = .expanded
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
