import Foundation

struct NowPlaying: Equatable {
    var trackID: String?
    var title: String
    var artist: String
    var artworkURL: URL?
    var position: Double
    var duration: Double
    var isPlaying: Bool

    static let empty = NowPlaying(
        trackID: nil,
        title: "",
        artist: "",
        artworkURL: nil,
        position: 0,
        duration: 0,
        isPlaying: false
    )
}
