import Foundation

enum SpotifyScript {
    static func run(_ source: String) -> String? {
        guard let script = NSAppleScript(source: source) else { return nil }
        var error: NSDictionary?
        let result = script.executeAndReturnError(&error)
        if error != nil { return nil }
        return result.stringValue
    }

    static func isRunning() -> Bool {
        run("application \"Spotify\" is running") == "true"
    }

    static func currentTrackInfo() -> String? {
        run("""
        tell application "Spotify"
            if player state is stopped then
                return "STOPPED"
            end if
            set trackName to name of current track
            set trackArtist to artist of current track
            set trackArt to artwork url of current track
            set trackURI to spotify url of current track
            set trackDuration to duration of current track
            set trackPosition to player position
            set stateStr to player state as string
            return trackName & "\t" & trackArtist & "\t" & trackArt & "\t" & trackURI & "\t" & (trackDuration as string) & "\t" & (trackPosition as string) & "\t" & stateStr
        end tell
        """)
    }

    static func playPause() {
        _ = run("tell application \"Spotify\" to playpause")
    }

    static func next() {
        _ = run("tell application \"Spotify\" to next track")
    }

    static func previous() {
        _ = run("tell application \"Spotify\" to previous track")
    }
}
