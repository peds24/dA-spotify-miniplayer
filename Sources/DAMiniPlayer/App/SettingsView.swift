import SwiftUI

/// Defers touching `appDelegate.auth`/`.layoutState` (both `lazy`) until this
/// view is actually rendered — i.e. until the Settings window is opened,
/// which is always well after launch. Referencing them any earlier (e.g.
/// directly in `DAMiniPlayerApp.body`) would force their initialization
/// during app startup, the exact class of bug that once froze launch.
struct SettingsView: View {
    let appDelegate: AppDelegate

    var body: some View {
        SettingsContentView(auth: appDelegate.auth, layoutState: appDelegate.layoutState)
    }
}

private struct SettingsContentView: View {
    @ObservedObject var auth: SpotifyAuth
    @ObservedObject var layoutState: PlayerLayoutState

    var body: some View {
        Form {
            Section("Spotify Account") {
                HStack {
                    Text(auth.isLoggedIn ? "Logged in" : "Not logged in")
                    Spacer()
                    Button(auth.isLoggedIn ? "Log Out" : "Log In") {
                        if auth.isLoggedIn {
                            auth.logout()
                        } else {
                            auth.login()
                        }
                    }
                }
            }

            Section("Appearance") {
                Picker("Layout", selection: $layoutState.mode) {
                    Text("Compact").tag(PlayerLayoutMode.compact)
                    Text("Expanded").tag(PlayerLayoutMode.expanded)
                }
                .pickerStyle(.radioGroup)
            }
        }
        .padding(20)
        .frame(width: 320)
    }
}
