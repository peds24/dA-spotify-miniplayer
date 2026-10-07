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
                    font: theme.titleFont(size: 12),
                    color: theme.ink,
                    height: 15
                )
                HStack(spacing: 6) {
                    Text(nowPlaying.artist)
                        .font(theme.bodyFont(size: 11))
                        .foregroundColor(theme.inkDim)
                        .lineLimit(1)
                    // Glass's capsule padding leaves no room for a separate
                    // time column, so it rides along on the artist line.
                    if theme.usesGlass {
                        Spacer(minLength: 0)
                        timeLabel
                    }
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)

            if !theme.usesGlass {
                timeLabel
            }

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
        .padding(.vertical, 10)
        .padding(.horizontal, theme.usesGlass ? 12 : 10)
        .frame(width: PlayerLayoutMode.compact.size.width, height: PlayerLayoutMode.compact.size.height)
    }

    private var timeLabel: some View {
        Text("\(TimeFormatter.format(nowPlaying.position)) / \(TimeFormatter.format(nowPlaying.duration))")
            .font(theme.numericFont(size: 10))
            .foregroundColor(theme.inkDim)
            .fixedSize()
    }

    /// Glass rounds the art to sit concentric with the panel's larger corners.
    private var artworkShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: theme.usesGlass ? 8 : 0, style: .continuous)
    }

    private var artwork: some View {
        ArtworkImage(url: nowPlaying.artworkURL)
            .frame(width: 36, height: 36)
            .clipShape(artworkShape)
    }
}
