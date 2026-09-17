import AppKit
import SwiftUI

struct MiniPlayerContainerView: View {
    @ObservedObject var monitor: PlaybackMonitor
    @ObservedObject var likedSongs: LikedSongsService
    @ObservedObject var auth: SpotifyAuth
    @ObservedObject var layoutState: PlayerLayoutState
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        content
            .environment(\.playerTheme, colorScheme == .dark ? .dark : .light)
            .onAppear(perform: refreshLikedStateIfNeeded)
            // Single-value onChange (not the two-value macOS 14+ overload) —
            // deployment target here is macOS 13. Refresh on either the
            // track changing OR login completing — logging in while a
            // track is already playing doesn't change trackID, so that
            // transition needs its own trigger too.
            .onChange(of: monitor.nowPlaying.trackID) { _ in refreshLikedStateIfNeeded() }
            .onChange(of: auth.isLoggedIn) { _ in refreshLikedStateIfNeeded() }
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
                onToggleLike: toggleLike,
                onToggleLayout: toggleLayout,
                onClose: close
            )
        case .expanded:
            MiniPlayerHeroView(
                nowPlaying: monitor.nowPlaying,
                isLiked: isLiked,
                onTogglePlay: monitor.togglePlayPause,
                onNext: monitor.next,
                onPrevious: monitor.previous,
                onToggleLike: toggleLike,
                onToggleLayout: toggleLayout,
                onClose: close
            )
        }
    }

    private func toggleLayout() {
        layoutState.mode = layoutState.mode == .compact ? .expanded : .compact
    }

    private func close() {
        NSApp.terminate(nil)
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

    private func refreshLikedStateIfNeeded() {
        guard auth.isLoggedIn, let trackID = monitor.nowPlaying.trackID else { return }
        Task { await likedSongs.refreshLikedState(for: trackID) }
    }
}
