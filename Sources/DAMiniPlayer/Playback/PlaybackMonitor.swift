import Foundation

@MainActor
final class PlaybackMonitor: ObservableObject {
    @Published private(set) var nowPlaying: NowPlaying = .empty
    @Published private(set) var isSpotifyRunning: Bool = false

    private var timer: Timer?

    func start() {
        // Kick off the first poll asynchronously rather than calling it
        // synchronously here. SpotifyScript's AppleScript calls block the
        // calling thread — if Spotify's Automation permission dialog is
        // pending (e.g. after the app's code signature changes on rebuild),
        // a synchronous call on the main actor freezes the entire launch
        // sequence before the menu bar item is even created.
        Task { await poll() }
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { await self?.poll() }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func togglePlayPause() {
        SpotifyScript.playPause()
    }

    func next() {
        SpotifyScript.next()
    }

    func previous() {
        SpotifyScript.previous()
    }

    private func poll() async {
        // Run the actual blocking AppleScript calls off the main actor so a
        // slow or permission-blocked Apple Event never freezes the UI.
        let (running, raw): (Bool, String?) = await Task.detached(priority: .utility) {
            let running = SpotifyScript.isRunning()
            guard running else { return (false, nil) }
            return (true, SpotifyScript.currentTrackInfo())
        }.value

        isSpotifyRunning = running
        guard running, let raw, let parsed = SpotifyTrackParser.parse(raw) else {
            nowPlaying = .empty
            return
        }
        nowPlaying = parsed
    }
}
