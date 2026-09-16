import Foundation

enum Config {
    static var spotifyClientID: String {
        guard let url = Bundle.main.url(forResource: "Config", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: String],
              let clientID = plist["SpotifyClientID"] else {
            fatalError("Missing Sources/DAMiniPlayer/Resources/Config.plist — copy Config.plist.example to Config.plist and fill in your Spotify app's client ID.")
        }
        return clientID
    }
}
