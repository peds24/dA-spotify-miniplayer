import SwiftUI

struct MiniPlayerView: View {
    let nowPlaying: NowPlaying
    let isLiked: Bool?
    let onTogglePlay: () -> Void
    let onNext: () -> Void
    let onPrevious: () -> Void
    let onToggleLike: () -> Void
    let onToggleLayout: () -> Void
    let onClose: () -> Void
    @Environment(\.playerTheme) private var theme

    var body: some View {
        HStack(spacing: 8) {
            Button(action: onPrevious) {
                Image(systemName: "backward.end.fill")
            }
            .buttonStyle(.plain)

            artwork

            VStack(alignment: .leading, spacing: 2) {
                MarqueeText(
                    text: nowPlaying.title.isEmpty ? "Nothing playing" : nowPlaying.title,
                    font: .custom("SpaceMono-Bold", size: 12),
                    color: theme.ink,
                    height: 15
                )
                Text(nowPlaying.artist)
                    .font(.custom("SpaceMono-Regular", size: 11))
                    .foregroundColor(theme.inkDim)
                    .lineLimit(1)
            }
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)

            Text("\(TimeFormatter.format(nowPlaying.position)) / \(TimeFormatter.format(nowPlaying.duration))")
                .font(.custom("SpaceMono-Regular", size: 10))
                .foregroundColor(theme.inkDim)

            Button(action: onTogglePlay) {
                Image(systemName: nowPlaying.isPlaying ? "pause.fill" : "play.fill")
            }
            .buttonStyle(.plain)

            Button(action: onNext) {
                Image(systemName: "forward.end.fill")
            }
            .buttonStyle(.plain)

            HeartButton(isLiked: isLiked, action: onToggleLike)

            PlayerChromeButtons(mode: .compact, onToggleLayout: onToggleLayout, onClose: onClose)
        }
        .foregroundColor(theme.ink)
        .padding(10)
        .frame(width: 320, height: 56)
        .background(theme.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(theme.hairline, lineWidth: 1)
        )
        .cornerRadius(8)
    }

    @ViewBuilder
    private var artwork: some View {
        if let url = nowPlaying.artworkURL {
            AsyncImage(url: url) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle().fill(theme.ground)
            }
            .frame(width: 36, height: 36)
            .clipped()
        } else {
            Rectangle()
                .fill(theme.ground)
                .frame(width: 36, height: 36)
        }
    }
}
