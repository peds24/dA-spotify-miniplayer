import Foundation

@MainActor
final class PlaybackMonitor: ObservableObject {
    @Published private(set) var nowPlaying: NowPlaying = .empty
    @Published private(set) var isSpotifyRunning: Bool = false

    private var timer: Timer?

    func start() {
        poll()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.poll() }
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

    private func poll() {
        isSpotifyRunning = SpotifyScript.isRunning()
        guard isSpotifyRunning,
              let raw = SpotifyScript.currentTrackInfo(),
              let parsed = SpotifyTrackParser.parse(raw) else {
            nowPlaying = .empty
            return
        }
        nowPlaying = parsed
    }
}
