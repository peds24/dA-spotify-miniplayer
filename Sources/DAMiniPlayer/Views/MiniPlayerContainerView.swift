import SwiftUI

struct MiniPlayerContainerView: View {
    @ObservedObject var monitor: PlaybackMonitor

    var body: some View {
        MiniPlayerView(
            nowPlaying: monitor.nowPlaying,
            isLiked: nil,
            onTogglePlay: monitor.togglePlayPause,
            onNext: monitor.next,
            onPrevious: monitor.previous,
            onToggleLike: {}
        )
    }
}
