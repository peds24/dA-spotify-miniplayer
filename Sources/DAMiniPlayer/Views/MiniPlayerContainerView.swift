import AppKit
import SwiftUI

struct MiniPlayerContainerView: View {
    @ObservedObject var monitor: PlaybackMonitor
    @ObservedObject var likedSongs: LikedSongsService
    @ObservedObject var auth: SpotifyAuth
    @ObservedObject var layoutState: PlayerLayoutState
    @ObservedObject var styleState: PlayerStyleState
    @Environment(\.colorScheme) private var colorScheme

    private var theme: PlayerTheme {
        PlayerTheme.resolve(style: styleState.style, colorScheme: colorScheme)
    }

    var body: some View {
        panel
            .environment(\.playerTheme, theme)
            .onAppear(perform: refreshLikedStateIfNeeded)
            // Single-value onChange (not the two-value macOS 14+ overload) —
            // deployment target here is macOS 13. Refresh on either the
            // track changing OR login completing — logging in while a
            // track is already playing doesn't change trackID, so that
            // transition needs its own trigger too.
            .onChange(of: monitor.nowPlaying.trackID) { _ in refreshLikedStateIfNeeded() }
            .onChange(of: auth.isLoggedIn) { _ in refreshLikedStateIfNeeded() }
    }

    /// One surface that morphs between the two layouts' sizes and corner
    /// radii, centered in the fixed-size window — so the compact bar sits
    /// at the expanded panel's vertical midpoint and toggling never drifts.
    /// The layouts themselves crossfade inside it.
    private var panel: some View {
        let size = layoutState.mode.size
        return ZStack {
            content
        }
        .frame(width: size.width, height: size.height)
        .playerSurface(RoundedRectangle(cornerRadius: theme.panelCornerRadius(for: layoutState.mode), style: .continuous))
        .shadow(color: .black.opacity(0.28), radius: 10, y: 4)
        .frame(width: PlayerLayoutMode.canvasSize.width, height: PlayerLayoutMode.canvasSize.height)
        .animation(.spring(response: 0.42, dampingFraction: 0.86), value: layoutState.mode)
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
            .transition(.opacity)
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
            .transition(.opacity)
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
