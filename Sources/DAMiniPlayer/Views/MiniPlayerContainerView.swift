import SwiftUI

struct MiniPlayerContainerView: View {
    @ObservedObject var monitor: PlaybackMonitor
    @ObservedObject var likedSongs: LikedSongsService
    @ObservedObject var auth: SpotifyAuth

    var body: some View {
        MiniPlayerView(
            nowPlaying: monitor.nowPlaying,
            isLiked: auth.isLoggedIn ? (monitor.nowPlaying.trackID.flatMap { likedSongs.likedState[$0] }) : nil,
            onTogglePlay: monitor.togglePlayPause,
            onNext: monitor.next,
            onPrevious: monitor.previous,
            onToggleLike: {
                guard auth.isLoggedIn, let trackID = monitor.nowPlaying.trackID else {
                    auth.login()
                    return
                }
                Task { await likedSongs.toggleLike(for: trackID) }
            }
        )
        // Single-value onChange (not the two-value macOS 14+ overload) —
        // deployment target here is macOS 13.
        .onChange(of: monitor.nowPlaying.trackID) { newID in
            guard auth.isLoggedIn, let newID else { return }
            Task { await likedSongs.refreshLikedState(for: newID) }
        }
    }
}
