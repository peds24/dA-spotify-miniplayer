import SwiftUI

struct MiniPlayerHeroView: View {
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
        VStack(spacing: 0) {
            artwork
                .frame(width: theme.usesGlass ? 206 : 222, height: theme.usesGlass ? 184 : 200)
                .clipShape(artworkShape)
                .overlay(alignment: .topTrailing) {
                    PlayerChromeButtons(
                        mode: .expanded,
                        onToggleLayout: onToggleLayout,
                        onClose: onClose,
                        dimColor: .white.opacity(0.8),
                        brightColor: .white
                    )
                    .padding(8)
                    .modifier(ChromeCapsule(usesGlass: theme.usesGlass))
                    .padding(8)
                }
                .padding(theme.usesGlass ? 8 : 0)

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        MarqueeText(
                            text: nowPlaying.title.isEmpty ? "Nothing playing" : nowPlaying.title,
                            font: theme.titleFont(size: 13),
                            color: theme.ink,
                            height: 16
                        )
                        Text(nowPlaying.artist)
                            .font(theme.bodyFont(size: 11))
                            .foregroundColor(theme.inkDim)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 8)
                    HeartButton(isLiked: isLiked, action: onToggleLike)
                }

                Text("\(TimeFormatter.format(nowPlaying.position)) / \(TimeFormatter.format(nowPlaying.duration))")
                    .font(theme.numericFont(size: 10))
                    .foregroundColor(theme.inkDim)
                    .frame(maxWidth: .infinity, alignment: .center)

                HStack(spacing: 28) {
                    Button(action: onPrevious) {
                        Image(systemName: "backward.end.fill")
                    }
                    .buttonStyle(.plain)

                    Button(action: onTogglePlay) {
                        Image(systemName: nowPlaying.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 18))
                    }
                    .buttonStyle(.plain)

                    Button(action: onNext) {
                        Image(systemName: "forward.end.fill")
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, theme.usesGlass ? 6 : 12)
            .frame(maxHeight: .infinity)
        }
        .foregroundColor(theme.ink)
        .frame(width: 222, height: 300)
        .playerSurface(RoundedRectangle(cornerRadius: theme.usesGlass ? 22 : 10, style: .continuous))
    }

    /// Glass insets the art by 8pt, so its corners are the panel's 22pt
    /// radius minus that inset — concentric, the way macOS 26 nests shapes.
    private var artworkShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: theme.usesGlass ? 14 : 0, style: .continuous)
    }

    @ViewBuilder
    private var artwork: some View {
        if let url = nowPlaying.artworkURL {
            AsyncImage(url: url) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle().fill(theme.ground)
            }
        } else {
            Rectangle().fill(theme.ground)
        }
    }
}

/// Backdrop behind the chevron/close buttons where they float over album
/// art: a dimmed-glass pill in the glass theme, a flat dark capsule otherwise.
/// Either way it stays dark, so the fixed white glyphs read over any artwork.
private struct ChromeCapsule: ViewModifier {
    let usesGlass: Bool

    func body(content: Content) -> some View {
        if usesGlass, #available(macOS 26.0, *) {
            content.glassEffect(.regular.tint(.black.opacity(0.35)).interactive(), in: Capsule())
        } else {
            content.background(.black.opacity(0.45), in: Capsule())
        }
    }
}
