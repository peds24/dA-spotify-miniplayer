import SwiftUI

@main
struct DAMiniPlayerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // AppDelegate opens the Settings window itself via a plain NSWindow
    // (see AppDelegate.showSettings) rather than through this scene — the
    // SwiftUI `App` protocol still requires at least one Scene in `body`,
    // so this stays as an inert placeholder.
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
