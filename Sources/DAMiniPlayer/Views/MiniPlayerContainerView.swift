import SwiftUI

struct MiniPlayerContainerView: View {
    @ObservedObject var monitor: PlaybackMonitor
    @ObservedObject var likedSongs: LikedSongsService
    @ObservedObject var auth: SpotifyAuth
    @ObservedObject var layoutState: PlayerLayoutState

    var body: some View {
        content
            // Single-value onChange (not the two-value macOS 14+ overload) —
            // deployment target here is macOS 13.
            .onChange(of: monitor.nowPlaying.trackID) { newID in
                guard auth.isLoggedIn, let newID else { return }
                Task { await likedSongs.refreshLikedState(for: newID) }
            }
    }

    @ViewBuilder
    private var content: some View {
        switch layoutState.mode {
        case .compact:
            MiniPlayerView(
                nowPlaying: monitor.nowPlaying,
                isLiked: isLiked,
                onTogglePlay: monitor.togglePlayPause,
                onNext: monitor.next,
                onPrevious: monitor.previous,
                onToggleLike: toggleLike
            )
        case .expanded:
            MiniPlayerHeroView(
                nowPlaying: monitor.nowPlaying,
                isLiked: isLiked,
                onTogglePlay: monitor.togglePlayPause,
                onNext: monitor.next,
                onPrevious: monitor.previous,
                onToggleLike: toggleLike
            )
        }
    }

    private var isLiked: Bool? {
        auth.isLoggedIn ? (monitor.nowPlaying.trackID.flatMap { likedSongs.likedState[$0] }) : nil
    }

    private func toggleLike() {
        guard auth.isLoggedIn, let trackID = monitor.nowPlaying.trackID else {
            auth.login()
            return
        }
        Task { await likedSongs.toggleLike(for: trackID) }
    }
}
