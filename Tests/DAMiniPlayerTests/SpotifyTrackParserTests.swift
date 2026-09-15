import XCTest
@testable import DAMiniPlayer

final class SpotifyTrackParserTests: XCTestCase {
    func testParsesWellFormedLine() {
        let raw = "My Rival\tSteely Dan\thttps://example.com/art.jpg\tspotify:track:abc123\t273000\t42.5\tplaying"
        let result = SpotifyTrackParser.parse(raw)
        XCTAssertEqual(result?.title, "My Rival")
        XCTAssertEqual(result?.artist, "Steely Dan")
        XCTAssertEqual(result?.artworkURL, URL(string: "https://example.com/art.jpg"))
        XCTAssertEqual(result?.trackID, "abc123")
        XCTAssertEqual(result?.duration, 273.0)
        XCTAssertEqual(result?.position, 42.5)
        XCTAssertTrue(result?.isPlaying ?? false)
    }

    func testPausedState() {
        let raw = "Title\tArtist\thttps://example.com/a.jpg\tspotify:track:xyz\t1000\t0\tpaused"
        XCTAssertEqual(SpotifyTrackParser.parse(raw)?.isPlaying, false)
    }

    func testStoppedReturnsNil() {
        XCTAssertNil(SpotifyTrackParser.parse("STOPPED"))
    }

    func testMalformedReturnsNil() {
        XCTAssertNil(SpotifyTrackParser.parse("not enough fields"))
    }
}
