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
    private var loginMenuItem: NSMenuItem?
    private var authCancellable: AnyCancellable?

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
            MiniPlayerContainerView(monitor: self.monitor, likedSongs: self.likedSongs, auth: self.auth)
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
        menu.addItem(NSMenuItem(title: "Quit DA Mini Player", action: #selector(quit), keyEquivalent: "q"))
        statusBarItem.menu = menu
        self.loginMenuItem = loginItem

        authCancellable = auth.$isLoggedIn.sink { [weak self] _ in
            self?.loginMenuItem?.title = self?.loginTitle ?? ""
        }

        self.statusItem = statusBarItem
    }

    func applicationWillTerminate(_ notification: Notification) {
        monitor.stop()
    }

    private var loginTitle: String {
        auth.isLoggedIn ? "Log Out of Spotify" : "Log In to Spotify"
    }

    @objc private func toggleLogin() {
        if auth.isLoggedIn {
            auth.logout()
        } else {
            auth.login()
        }
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
