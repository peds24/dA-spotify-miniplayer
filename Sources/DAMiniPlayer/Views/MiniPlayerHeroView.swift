import SwiftUI

struct MiniPlayerHeroView: View {
    let nowPlaying: NowPlaying
    let isLiked: Bool?
    let onTogglePlay: () -> Void
    let onNext: () -> Void
    let onPrevious: () -> Void
    let onToggleLike: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            artwork
                .frame(width: 222, height: 200)
                .clipped()

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(nowPlaying.title.isEmpty ? "Nothing playing" : nowPlaying.title)
                            .font(.custom("SpaceMono-Bold", size: 13))
                            .foregroundColor(PlayerTheme.ink)
                            .lineLimit(1)
                        Text(nowPlaying.artist)
                            .font(.custom("SpaceMono-Regular", size: 11))
                            .foregroundColor(PlayerTheme.inkDim)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 8)
                    HeartButton(isLiked: isLiked, action: onToggleLike)
                }

                Text("\(TimeFormatter.format(nowPlaying.position)) / \(TimeFormatter.format(nowPlaying.duration))")
                    .font(.custom("SpaceMono-Regular", size: 10))
                    .foregroundColor(PlayerTheme.inkDim)
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
            .padding(12)
        }
        .foregroundColor(PlayerTheme.ink)
        .frame(width: 222, height: 300)
        .background(PlayerTheme.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(PlayerTheme.hairline, lineWidth: 1)
        )
        .cornerRadius(10)
    }

    @ViewBuilder
    private var artwork: some View {
        if let url = nowPlaying.artworkURL {
            AsyncImage(url: url) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle().fill(PlayerTheme.ground)
            }
        } else {
            Rectangle().fill(PlayerTheme.ground)
        }
    }
}
