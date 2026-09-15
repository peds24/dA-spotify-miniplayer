import Foundation

enum SpotifyTrackParser {
    static func parse(_ raw: String) -> NowPlaying? {
        if raw == "STOPPED" { return nil }
        let parts = raw.components(separatedBy: "\t")
        guard parts.count == 7 else { return nil }

        let title = parts[0]
        let artist = parts[1]
        let artworkURL = URL(string: parts[2])
        let trackID = parts[3].components(separatedBy: ":").last
        let durationMs = Double(parts[4]) ?? 0
        let position = Double(parts[5]) ?? 0
        let isPlaying = parts[6] == "playing"

        return NowPlaying(
            trackID: trackID,
            title: title,
            artist: artist,
            artworkURL: artworkURL,
            position: position,
            duration: durationMs / 1000.0,
            isPlaying: isPlaying
        )
    }
}
