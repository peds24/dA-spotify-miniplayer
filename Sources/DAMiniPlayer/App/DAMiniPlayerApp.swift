import SwiftUI

@main
struct DAMiniPlayerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            SettingsView(appDelegate: appDelegate)
        }
    }
}
