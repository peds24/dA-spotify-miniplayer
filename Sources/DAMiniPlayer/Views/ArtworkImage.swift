import AppKit
import SwiftUI

/// Album art shared by both layouts. Unlike `AsyncImage`, an already-loaded
/// image is read from a cache synchronously on the view's first render —
/// toggling layouts creates a fresh view, and `AsyncImage` would flash its
/// placeholder there (mid-morph) even for an image it fetched moments ago.
struct ArtworkImage: View {
    let url: URL?
    @Environment(\.playerTheme) private var theme
    /// Set once a fetch lands in the cache, purely to re-render — the cache
    /// itself is the only source of the image.
    @State private var loadedURL: URL?

    var body: some View {
        ZStack {
            Rectangle().fill(theme.ground)
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            }
        }
        .task(id: url) { await load() }
    }

    private var image: NSImage? {
        _ = loadedURL // establish the dependency so a finished fetch re-renders
        guard let url else { return nil }
        return ArtworkCache.images.object(forKey: url as NSURL)
    }

    private func load() async {
        guard let url, ArtworkCache.images.object(forKey: url as NSURL) == nil else { return }
        guard let (data, _) = try? await URLSession.shared.data(from: url),
              let fetched = NSImage(data: data) else { return }
        ArtworkCache.images.setObject(fetched, forKey: url as NSURL)
        loadedURL = url
    }
}

@MainActor
private enum ArtworkCache {
    static let images: NSCache<NSURL, NSImage> = {
        let cache = NSCache<NSURL, NSImage>()
        cache.countLimit = 20
        return cache
    }()
}
