# DA Spotify Mini Player Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a native macOS floating mini player for Spotify with custom styling and a "Add to Liked Songs" heart button.

**Architecture:** A SwiftUI/AppKit macOS app (no dock icon) with a borderless always-on-top `NSPanel` showing the mini player, and a status-bar menu for login/quit. Local playback state and transport controls go through AppleScript to Spotify.app; the Liked Songs heart button goes through the Spotify Web API (OAuth PKCE, token cached in Keychain).

**Tech Stack:** Swift 6 / SwiftUI / AppKit, XcodeGen (project generation), XCTest, `ASWebAuthenticationSession`, Keychain Services, `NSAppleScript`.

**Spec:** `docs/superpowers/specs/2026-09-15-spotify-miniplayer-design.md`

## Global Constraints

- Deployment target: macOS 13.0+.
- Swift version: 6.0 (Swift tools 6.4 is installed; project settings pin language version to 6.0 for stability).
- Project file is **generated** by XcodeGen from `project.yml` — never hand-edit `DAMiniPlayer.xcodeproj`; edit `project.yml` and re-run `xcodegen generate`. The `.xcodeproj` is gitignored.
- Bundle identifier: `com.pedro.da-miniplayer`.
- App is `LSUIElement` (no Dock icon, no app switcher entry) — menu bar + floating panel only.
- OAuth redirect URI: custom scheme `da-miniplayer://callback` (registered as a `CFBundleURLTypes` entry).
- Spotify Web API scopes: `user-library-read user-library-modify` — used only for the like/unlike feature.
- Color tokens (exact values from spec, dark palette only):
  - ground `#030C06`, surface `#0A1F11`, ink `#E1F4E8`, ink-dim `#72C08E`, hairline `#194328`, accent `#1DB954`.
- Font: Space Mono (Regular + Bold), embedded as bundled `.ttf` resources, registered at runtime — not system-installed.
- No light mode / system-appearance switching, no other music players, no global hotkeys, no launch-at-login (out of scope per spec).

---

## Task 1: Project Scaffolding — XcodeGen + Minimal Menu Bar App

**Files:**
- Create: `project.yml`
- Create: `.gitignore`
- Create: `Sources/DAMiniPlayer/App/DAMiniPlayerApp.swift`
- Create: `Sources/DAMiniPlayer/App/AppDelegate.swift`
- Create: `Tests/DAMiniPlayerTests/SanityTests.swift`

**Interfaces:**
- Produces: an `AppDelegate` class (NSApplicationDelegate) that later tasks extend to own the status item and the floating panel.

- [ ] **Step 1: Install XcodeGen**

Run: `brew install xcodegen`
Expected: XcodeGen installs successfully; `xcodegen --version` prints a version number.

- [ ] **Step 2: Write `project.yml`**

```yaml
name: DAMiniPlayer
options:
  bundleIdPrefix: com.pedro
  deploymentTarget:
    macOS: "13.0"
settings:
  base:
    SWIFT_VERSION: "6.0"
    ENABLE_HARDENED_RUNTIME: true
    CODE_SIGN_STYLE: Automatic
targets:
  DAMiniPlayer:
    type: application
    platform: macOS
    sources:
      - path: Sources/DAMiniPlayer
    info:
      properties:
        LSUIElement: true
        CFBundleURLTypes:
          - CFBundleURLSchemes: [da-miniplayer]
        NSAppleEventsUsageDescription: "DA Mini Player needs to control Spotify to show what's playing and manage playback."
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.pedro.da-miniplayer
        MARKETING_VERSION: "1.0"
        CURRENT_PROJECT_VERSION: "1"
  DAMiniPlayerTests:
    type: bundle.unit-test
    platform: macOS
    sources:
      - path: Tests/DAMiniPlayerTests
    dependencies:
      - target: DAMiniPlayer
schemes:
  DAMiniPlayer:
    build:
      targets:
        DAMiniPlayer: all
        DAMiniPlayerTests: [test]
    test:
      targets:
        - DAMiniPlayerTests
    run:
      config: Debug
```

- [ ] **Step 3: Write `.gitignore`**

```
.build/
DerivedData/
*.xcodeproj
xcuserdata/
Sources/DAMiniPlayer/Resources/Config.plist
.DS_Store
```

- [ ] **Step 4: Write `Sources/DAMiniPlayer/App/AppDelegate.swift`**

```swift
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusBarItem.button?.title = "♪"

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Quit DA Mini Player", action: #selector(quit), keyEquivalent: "q"))
        statusBarItem.menu = menu

        self.statusItem = statusBarItem
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
```

- [ ] **Step 5: Write `Sources/DAMiniPlayer/App/DAMiniPlayerApp.swift`**

```swift
import SwiftUI

@main
struct DAMiniPlayerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
```

- [ ] **Step 6: Write a trivial sanity test in `Tests/DAMiniPlayerTests/SanityTests.swift`**

```swift
import XCTest

final class SanityTests: XCTestCase {
    func testTrue() {
        XCTAssertTrue(true)
    }
}
```

- [ ] **Step 7: Generate the Xcode project and build**

Run: `xcodegen generate && xcodebuild -project DAMiniPlayer.xcodeproj -scheme DAMiniPlayer -configuration Debug build`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 8: Run the test target**

Run: `xcodebuild -project DAMiniPlayer.xcodeproj -scheme DAMiniPlayer -destination 'platform=macOS' test`
Expected: `** TEST SUCCEEDED **`, `testTrue` passes.

- [ ] **Step 9: Manually launch and verify the menu bar item**

Run: `open /path/to/DerivedData/.../DAMiniPlayer.app` (or `xcodebuild -showBuildSettings` to find `BUILT_PRODUCTS_DIR`, then `open "$BUILT_PRODUCTS_DIR/DAMiniPlayer.app"`)
Expected: a "♪" icon appears in the menu bar, no Dock icon appears, clicking it shows a "Quit DA Mini Player" item that quits the app.

- [ ] **Step 10: Commit**

```bash
git add project.yml .gitignore Sources Tests
git commit -m "Scaffold XcodeGen project with minimal menu bar app"
```

---

## Task 2: Time Formatting (TDD)

**Files:**
- Create: `Sources/DAMiniPlayer/Formatting/TimeFormatter.swift`
- Test: `Tests/DAMiniPlayerTests/TimeFormatterTests.swift`

**Interfaces:**
- Produces: `enum TimeFormatter { static func format(_ seconds: Double) -> String }`

- [ ] **Step 1: Write the failing tests**

```swift
import XCTest
@testable import DAMiniPlayer

final class TimeFormatterTests: XCTestCase {
    func testZero() {
        XCTAssertEqual(TimeFormatter.format(0), "0:00")
    }

    func testUnderAMinute() {
        XCTAssertEqual(TimeFormatter.format(5), "0:05")
    }

    func testOverAMinute() {
        XCTAssertEqual(TimeFormatter.format(65), "1:05")
    }

    func testExactMinute() {
        XCTAssertEqual(TimeFormatter.format(120), "2:00")
    }

    func testNegativeClampsToZero() {
        XCTAssertEqual(TimeFormatter.format(-5), "0:00")
    }

    func testNaNClampsToZero() {
        XCTAssertEqual(TimeFormatter.format(.nan), "0:00")
    }

    func testFractionalSecondsTruncate() {
        XCTAssertEqual(TimeFormatter.format(59.9), "0:59")
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `xcodegen generate && xcodebuild -project DAMiniPlayer.xcodeproj -scheme DAMiniPlayer -destination 'platform=macOS' test`
Expected: FAIL — `TimeFormatter` does not exist.

- [ ] **Step 3: Write the implementation**

```swift
import Foundation

enum TimeFormatter {
    static func format(_ seconds: Double) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "0:00" }
        let total = Int(seconds)
        let minutes = total / 60
        let secs = total % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `xcodebuild -project DAMiniPlayer.xcodeproj -scheme DAMiniPlayer -destination 'platform=macOS' test`
Expected: `** TEST SUCCEEDED **`, all `TimeFormatterTests` pass.

- [ ] **Step 5: Commit**

```bash
git add Sources/DAMiniPlayer/Formatting/TimeFormatter.swift Tests/DAMiniPlayerTests/TimeFormatterTests.swift
git commit -m "Add TimeFormatter with unit tests"
```

---

## Task 3: PKCE + Token Expiry Logic (TDD)

**Files:**
- Create: `Sources/DAMiniPlayer/Auth/PKCE.swift`
- Create: `Sources/DAMiniPlayer/Auth/TokenExpiry.swift`
- Test: `Tests/DAMiniPlayerTests/PKCETests.swift`
- Test: `Tests/DAMiniPlayerTests/TokenExpiryTests.swift`

**Interfaces:**
- Produces: `enum PKCE { static func generateCodeVerifier() -> String; static func codeChallenge(for verifier: String) -> String; static func base64URLEncode(_ data: Data) -> String }`
- Produces: `enum TokenExpiry { static func isExpired(expiresAt: Date, now: Date = Date()) -> Bool }`

- [ ] **Step 1: Write the failing PKCE test using the RFC 7636 Appendix B test vector**

```swift
import XCTest
@testable import DAMiniPlayer

final class PKCETests: XCTestCase {
    func testKnownVectorFromRFC7636() {
        // RFC 7636 Appendix B fixed test vector.
        let verifier = "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk"
        let expectedChallenge = "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM"
        XCTAssertEqual(PKCE.codeChallenge(for: verifier), expectedChallenge)
    }

    func testGeneratedVerifierIsURLSafeAndLongEnough() {
        let verifier = PKCE.generateCodeVerifier()
        XCTAssertGreaterThanOrEqual(verifier.count, 43)
        XCTAssertLessThanOrEqual(verifier.count, 128)
        let allowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_")
        XCTAssertTrue(verifier.unicodeScalars.allSatisfy { allowed.contains($0) })
    }

    func testChallengeIsDeterministic() {
        let verifier = PKCE.generateCodeVerifier()
        XCTAssertEqual(PKCE.codeChallenge(for: verifier), PKCE.codeChallenge(for: verifier))
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `xcodegen generate && xcodebuild -project DAMiniPlayer.xcodeproj -scheme DAMiniPlayer -destination 'platform=macOS' test`
Expected: FAIL — `PKCE` does not exist.

- [ ] **Step 3: Write the PKCE implementation**

```swift
import Foundation
import CryptoKit

enum PKCE {
    static func generateCodeVerifier() -> String {
        var buffer = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, buffer.count, &buffer)
        return base64URLEncode(Data(buffer))
    }

    static func codeChallenge(for verifier: String) -> String {
        let hashed = SHA256.hash(data: Data(verifier.utf8))
        return base64URLEncode(Data(hashed))
    }

    static func base64URLEncode(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `xcodebuild -project DAMiniPlayer.xcodeproj -scheme DAMiniPlayer -destination 'platform=macOS' test`
Expected: `** TEST SUCCEEDED **`, all `PKCETests` pass.

- [ ] **Step 5: Write the failing TokenExpiry test**

```swift
import XCTest
@testable import DAMiniPlayer

final class TokenExpiryTests: XCTestCase {
    func testNotYetExpired() {
        let future = Date().addingTimeInterval(60)
        XCTAssertFalse(TokenExpiry.isExpired(expiresAt: future, now: Date()))
    }

    func testAlreadyExpired() {
        let past = Date().addingTimeInterval(-60)
        XCTAssertTrue(TokenExpiry.isExpired(expiresAt: past, now: Date()))
    }

    func testExactlyAtExpiry() {
        let now = Date()
        XCTAssertTrue(TokenExpiry.isExpired(expiresAt: now, now: now))
    }
}
```

- [ ] **Step 6: Run test to verify it fails**

Run: `xcodebuild -project DAMiniPlayer.xcodeproj -scheme DAMiniPlayer -destination 'platform=macOS' test`
Expected: FAIL — `TokenExpiry` does not exist.

- [ ] **Step 7: Write the TokenExpiry implementation**

```swift
import Foundation

enum TokenExpiry {
    static func isExpired(expiresAt: Date, now: Date = Date()) -> Bool {
        now >= expiresAt
    }
}
```

- [ ] **Step 8: Run tests to verify they pass**

Run: `xcodebuild -project DAMiniPlayer.xcodeproj -scheme DAMiniPlayer -destination 'platform=macOS' test`
Expected: `** TEST SUCCEEDED **`, all tests pass.

- [ ] **Step 9: Commit**

```bash
git add Sources/DAMiniPlayer/Auth/PKCE.swift Sources/DAMiniPlayer/Auth/TokenExpiry.swift Tests/DAMiniPlayerTests/PKCETests.swift Tests/DAMiniPlayerTests/TokenExpiryTests.swift
git commit -m "Add PKCE and token expiry logic with unit tests"
```

---

## Task 4: NowPlaying Model + Spotify AppleScript Parser (TDD)

**Files:**
- Create: `Sources/DAMiniPlayer/Models/NowPlaying.swift`
- Create: `Sources/DAMiniPlayer/Playback/SpotifyTrackParser.swift`
- Test: `Tests/DAMiniPlayerTests/SpotifyTrackParserTests.swift`

**Interfaces:**
- Produces: `struct NowPlaying: Equatable { var trackID: String?; var title: String; var artist: String; var artworkURL: URL?; var position: Double; var duration: Double; var isPlaying: Bool; static let empty: NowPlaying }`
- Produces: `enum SpotifyTrackParser { static func parse(_ raw: String) -> NowPlaying? }`
- Consumes: nothing from earlier tasks.

- [ ] **Step 1: Write `NowPlaying.swift`**

```swift
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
```

This is a plain data model, no test needed on its own — it's exercised by the parser tests below.

- [ ] **Step 2: Write the failing parser tests**

The raw format is a tab-separated string produced by the AppleScript in Task 5:
`title\tartist\tartworkURL\tspotifyURI\tdurationMs\tpositionSec\tplayerState`

```swift
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
```

- [ ] **Step 3: Run tests to verify they fail**

Run: `xcodegen generate && xcodebuild -project DAMiniPlayer.xcodeproj -scheme DAMiniPlayer -destination 'platform=macOS' test`
Expected: FAIL — `SpotifyTrackParser` does not exist.

- [ ] **Step 4: Write `SpotifyTrackParser.swift`**

```swift
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
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `xcodebuild -project DAMiniPlayer.xcodeproj -scheme DAMiniPlayer -destination 'platform=macOS' test`
Expected: `** TEST SUCCEEDED **`, all `SpotifyTrackParserTests` pass.

- [ ] **Step 6: Commit**

```bash
git add Sources/DAMiniPlayer/Models/NowPlaying.swift Sources/DAMiniPlayer/Playback/SpotifyTrackParser.swift Tests/DAMiniPlayerTests/SpotifyTrackParserTests.swift
git commit -m "Add NowPlaying model and Spotify AppleScript output parser"
```

---

## Task 5: Player Theme (Colors + Space Mono Font)

**Files:**
- Create: `Sources/DAMiniPlayer/Views/PlayerTheme.swift`
- Create: `Sources/DAMiniPlayer/Resources/Fonts/SpaceMono-Regular.ttf` (downloaded binary)
- Create: `Sources/DAMiniPlayer/Resources/Fonts/SpaceMono-Bold.ttf` (downloaded binary)
- Test: `Tests/DAMiniPlayerTests/PlayerThemeTests.swift`

**Interfaces:**
- Produces: `enum PlayerTheme { static let ground, surface, ink, inkDim, hairline, accent: Color; static func registerFonts(bundle: Bundle) }`
- Produces: `extension Color { init(hex: UInt32) }`

- [ ] **Step 1: Download the Space Mono font files (SIL Open Font License, from Google's font repo)**

Run:
```bash
mkdir -p Sources/DAMiniPlayer/Resources/Fonts
curl -sL -o Sources/DAMiniPlayer/Resources/Fonts/SpaceMono-Regular.ttf \
  https://github.com/google/fonts/raw/main/ofl/spacemono/SpaceMono-Regular.ttf
curl -sL -o Sources/DAMiniPlayer/Resources/Fonts/SpaceMono-Bold.ttf \
  https://github.com/google/fonts/raw/main/ofl/spacemono/SpaceMono-Bold.ttf
```
Expected: both `.ttf` files exist and are non-empty (`ls -la Sources/DAMiniPlayer/Resources/Fonts`).

- [ ] **Step 2: Add the fonts directory as a resource for both targets in `project.yml`**

Modify `project.yml`'s `DAMiniPlayer` target to add a `resources` key (it currently has none), and add one to the `DAMiniPlayerTests` target too (it currently has none — the font files didn't exist yet when Task 1 wrote it):

```yaml
  DAMiniPlayer:
    type: application
    platform: macOS
    sources:
      - path: Sources/DAMiniPlayer
    resources:
      - path: Sources/DAMiniPlayer/Resources/Fonts
  DAMiniPlayerTests:
    type: bundle.unit-test
    platform: macOS
    sources:
      - path: Tests/DAMiniPlayerTests
    resources:
      - path: Sources/DAMiniPlayer/Resources/Fonts
    dependencies:
      - target: DAMiniPlayer
```

- [ ] **Step 3: Write the failing font registration test**

```swift
import XCTest
import AppKit
import SwiftUI
@testable import DAMiniPlayer

final class PlayerThemeTests: XCTestCase {
    func testFontsRegisterSuccessfully() {
        // XcodeGen doesn't generate a Resources copy phase for the unit-test
        // target when it shares an identical resource path with the app
        // target, so the fonts never land inside DAMiniPlayerTests.xctest.
        // Load them straight from source instead of via bundle resources.
        let fontsDirectory = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Sources/DAMiniPlayer/Resources/Fonts")
        let testBundle = Bundle(url: fontsDirectory)!
        PlayerTheme.registerFonts(bundle: testBundle)
        XCTAssertNotNil(NSFont(name: "SpaceMono-Regular", size: 12))
        XCTAssertNotNil(NSFont(name: "SpaceMono-Bold", size: 12))
    }

    func testHexColorInit() {
        let color = Color(hex: 0x1DB954)
        XCTAssertEqual(color, Color(red: 0x1D.hexDouble, green: 0xB9.hexDouble, blue: 0x54.hexDouble))
    }
}

private extension Int {
    var hexDouble: Double { Double(self) / 255.0 }
}
```

- [ ] **Step 4: Run tests to verify they fail**

Run: `xcodegen generate && xcodebuild -project DAMiniPlayer.xcodeproj -scheme DAMiniPlayer -destination 'platform=macOS' test`
Expected: FAIL — `PlayerTheme` does not exist.

- [ ] **Step 5: Write `PlayerTheme.swift`**

```swift
import SwiftUI
import CoreText

enum PlayerTheme {
    static let ground = Color(hex: 0x030C06)
    static let surface = Color(hex: 0x0A1F11)
    static let ink = Color(hex: 0xE1F4E8)
    static let inkDim = Color(hex: 0x72C08E)
    static let hairline = Color(hex: 0x194328)
    static let accent = Color(hex: 0x1DB954)

    static func registerFonts(bundle: Bundle = .main) {
        for name in ["SpaceMono-Regular", "SpaceMono-Bold"] {
            guard let url = bundle.url(forResource: name, withExtension: "ttf") else { continue }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}

extension Color {
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
```

- [ ] **Step 6: Run tests to verify they pass**

Run: `xcodebuild -project DAMiniPlayer.xcodeproj -scheme DAMiniPlayer -destination 'platform=macOS' test`
Expected: `** TEST SUCCEEDED **`, `PlayerThemeTests` pass.

- [ ] **Step 7: Call `PlayerTheme.registerFonts()` at app launch**

Modify `Sources/DAMiniPlayer/App/AppDelegate.swift` — add this line as the first line inside `applicationDidFinishLaunching`:

```swift
func applicationDidFinishLaunching(_ notification: Notification) {
    PlayerTheme.registerFonts()
    NSApp.setActivationPolicy(.accessory)
    // ... rest unchanged
```

- [ ] **Step 8: Rebuild to confirm the app still builds**

Run: `xcodegen generate && xcodebuild -project DAMiniPlayer.xcodeproj -scheme DAMiniPlayer -configuration Debug build`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 9: Commit**

```bash
git add project.yml Sources/DAMiniPlayer/Views/PlayerTheme.swift Sources/DAMiniPlayer/Resources/Fonts Sources/DAMiniPlayer/App/AppDelegate.swift Tests/DAMiniPlayerTests/PlayerThemeTests.swift
git commit -m "Add PlayerTheme colors and bundled Space Mono font"
```

---

## Task 6: Mini Player UI (Mock Data) + Floating Panel

**Files:**
- Create: `Sources/DAMiniPlayer/Views/MiniPlayerView.swift`
- Create: `Sources/DAMiniPlayer/Views/HeartButton.swift`
- Create: `Sources/DAMiniPlayer/App/MiniPlayerPanel.swift`
- Modify: `Sources/DAMiniPlayer/App/AppDelegate.swift`

**Interfaces:**
- Consumes: `NowPlaying` (Task 4), `PlayerTheme` (Task 5).
- Produces: `struct MiniPlayerView: View` with `init(nowPlaying: NowPlaying, isLiked: Bool?, onTogglePlay: @escaping () -> Void, onNext: @escaping () -> Void, onPrevious: @escaping () -> Void, onToggleLike: @escaping () -> Void)`. Later tasks wire real callbacks/state into this same initializer — do not change its signature without updating this doc.
- Produces: `final class MiniPlayerPanel: NSPanel` — a reusable draggable, always-on-top, borderless panel that hosts a SwiftUI view via `NSHostingView`.

- [ ] **Step 1: Write `HeartButton.swift`**

```swift
import SwiftUI

struct HeartButton: View {
    let isLiked: Bool?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: isLiked == true ? "heart.fill" : "heart")
                .foregroundColor(isLiked == true ? PlayerTheme.accent : PlayerTheme.inkDim)
        }
        .buttonStyle(.plain)
        .opacity(isLiked == nil ? 0.4 : 1.0)
        .disabled(isLiked == nil)
    }
}
```

- [ ] **Step 2: Write `MiniPlayerView.swift`**

```swift
import SwiftUI

struct MiniPlayerView: View {
    let nowPlaying: NowPlaying
    let isLiked: Bool?
    let onTogglePlay: () -> Void
    let onNext: () -> Void
    let onPrevious: () -> Void
    let onToggleLike: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Button(action: onPrevious) {
                Image(systemName: "backward.end.fill")
            }
            .buttonStyle(.plain)

            artwork

            VStack(alignment: .leading, spacing: 2) {
                Text(nowPlaying.title.isEmpty ? "Nothing playing" : nowPlaying.title)
                    .font(.custom("SpaceMono-Bold", size: 12))
                    .foregroundColor(PlayerTheme.ink)
                    .lineLimit(1)
                Text(nowPlaying.artist)
                    .font(.custom("SpaceMono-Regular", size: 11))
                    .foregroundColor(PlayerTheme.inkDim)
                    .lineLimit(1)
            }
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)

            Text("\(TimeFormatter.format(nowPlaying.position)) / \(TimeFormatter.format(nowPlaying.duration))")
                .font(.custom("SpaceMono-Regular", size: 10))
                .foregroundColor(PlayerTheme.inkDim)

            Button(action: onTogglePlay) {
                Image(systemName: nowPlaying.isPlaying ? "pause.fill" : "play.fill")
            }
            .buttonStyle(.plain)

            Button(action: onNext) {
                Image(systemName: "forward.end.fill")
            }
            .buttonStyle(.plain)

            HeartButton(isLiked: isLiked, action: onToggleLike)
        }
        .foregroundColor(PlayerTheme.ink)
        .padding(10)
        .frame(width: 320, height: 56)
        .background(PlayerTheme.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(PlayerTheme.hairline, lineWidth: 1)
        )
        .cornerRadius(8)
    }

    @ViewBuilder
    private var artwork: some View {
        if let url = nowPlaying.artworkURL {
            AsyncImage(url: url) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle().fill(PlayerTheme.ground)
            }
            .frame(width: 36, height: 36)
            .clipped()
        } else {
            Rectangle()
                .fill(PlayerTheme.ground)
                .frame(width: 36, height: 36)
        }
    }
}
```

- [ ] **Step 3: Write `MiniPlayerPanel.swift`**

```swift
import AppKit
import SwiftUI

final class MiniPlayerPanel: NSPanel {
    init<Content: View>(@ViewBuilder content: () -> Content) {
        super.init(
            contentRect: NSRect(x: 100, y: 100, width: 320, height: 56),
            styleMask: [.nonactivatingPanel, .borderless],
            backing: .buffered,
            defer: false
        )
        isFloatingPanel = true
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isMovableByWindowBackground = true
        backgroundColor = .clear
        isOpaque = false
        hasShadow = true
        contentView = NSHostingView(rootView: content())
    }
}
```

- [ ] **Step 4: Wire the panel into `AppDelegate.swift`**

Replace the full contents of `Sources/DAMiniPlayer/App/AppDelegate.swift` with:

```swift
import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var panel: MiniPlayerPanel?

    func applicationDidFinishLaunching(_ notification: Notification) {
        PlayerTheme.registerFonts()
        NSApp.setActivationPolicy(.accessory)

        let mockNowPlaying = NowPlaying(
            trackID: "mock",
            title: "My Rival",
            artist: "Steely Dan",
            artworkURL: nil,
            position: 42,
            duration: 273,
            isPlaying: true
        )

        let panel = MiniPlayerPanel {
            MiniPlayerView(
                nowPlaying: mockNowPlaying,
                isLiked: false,
                onTogglePlay: {},
                onNext: {},
                onPrevious: {},
                onToggleLike: {}
            )
        }
        panel.orderFrontRegardless()
        self.panel = panel

        let statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusBarItem.button?.title = "♪"

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Quit DA Mini Player", action: #selector(quit), keyEquivalent: "q"))
        statusBarItem.menu = menu

        self.statusItem = statusBarItem
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
```

- [ ] **Step 5: Build**

Run: `xcodegen generate && xcodebuild -project DAMiniPlayer.xcodeproj -scheme DAMiniPlayer -configuration Debug build`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 6: Manually verify the panel visually**

Run:
```bash
BUILT_PRODUCTS_DIR=$(xcodebuild -project DAMiniPlayer.xcodeproj -scheme DAMiniPlayer -configuration Debug -showBuildSettings | awk -F'= ' '/ BUILT_PRODUCTS_DIR/{print $2; exit}')
open "$BUILT_PRODUCTS_DIR/DAMiniPlayer.app"
sleep 2
screencapture -x /tmp/da-miniplayer-panel.png
```
Then read `/tmp/da-miniplayer-panel.png` (e.g. with the Read tool) and confirm: a small dark panel with "My Rival" / "Steely Dan", prev/play/next icons, a time label, and an outlined heart icon is visible on screen; drag it by clicking and holding on its body to confirm it moves. Quit the app afterward from its menu bar item (`killall DAMiniPlayer` also works for cleanup).

- [ ] **Step 7: Commit**

```bash
git add Sources/DAMiniPlayer/Views/MiniPlayerView.swift Sources/DAMiniPlayer/Views/HeartButton.swift Sources/DAMiniPlayer/App/MiniPlayerPanel.swift Sources/DAMiniPlayer/App/AppDelegate.swift
git commit -m "Add floating mini player panel with mock data"
```

---

## Task 7: Real Spotify Playback Integration

**Files:**
- Create: `Sources/DAMiniPlayer/Playback/SpotifyScript.swift`
- Create: `Sources/DAMiniPlayer/Playback/PlaybackMonitor.swift`
- Modify: `Sources/DAMiniPlayer/App/AppDelegate.swift`

**Interfaces:**
- Consumes: `SpotifyTrackParser.parse` (Task 4), `NowPlaying` (Task 4).
- Produces: `@MainActor final class PlaybackMonitor: ObservableObject { @Published private(set) var nowPlaying: NowPlaying; @Published private(set) var isSpotifyRunning: Bool; func start(); func stop(); func togglePlayPause(); func next(); func previous() }`

- [ ] **Step 1: Write `SpotifyScript.swift`**

```swift
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
```

This talks to a real running Spotify.app, so it is not unit tested — `SpotifyTrackParser` (Task 4) already covers the parsing logic in isolation. Verification here is manual (Step 4).

- [ ] **Step 2: Write `PlaybackMonitor.swift`**

```swift
import Foundation

@MainActor
final class PlaybackMonitor: ObservableObject {
    @Published private(set) var nowPlaying: NowPlaying = .empty
    @Published private(set) var isSpotifyRunning: Bool = false

    private var timer: Timer?

    func start() {
        poll()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.poll() }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func togglePlayPause() {
        SpotifyScript.playPause()
    }

    func next() {
        SpotifyScript.next()
    }

    func previous() {
        SpotifyScript.previous()
    }

    private func poll() {
        isSpotifyRunning = SpotifyScript.isRunning()
        guard isSpotifyRunning,
              let raw = SpotifyScript.currentTrackInfo(),
              let parsed = SpotifyTrackParser.parse(raw) else {
            nowPlaying = .empty
            return
        }
        nowPlaying = parsed
    }
}
```

- [ ] **Step 3: Wire `PlaybackMonitor` into `AppDelegate`, replacing the mock data**

Replace the full contents of `Sources/DAMiniPlayer/App/AppDelegate.swift` with:

```swift
import AppKit
import SwiftUI
import Combine

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var panel: MiniPlayerPanel?
    private let monitor = PlaybackMonitor()
    private var cancellable: AnyCancellable?

    func applicationDidFinishLaunching(_ notification: Notification) {
        PlayerTheme.registerFonts()
        NSApp.setActivationPolicy(.accessory)

        let panel = MiniPlayerPanel {
            MiniPlayerContainerView(monitor: self.monitor)
        }
        panel.orderFrontRegardless()
        self.panel = panel

        monitor.start()

        let statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusBarItem.button?.title = "♪"

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Quit DA Mini Player", action: #selector(quit), keyEquivalent: "q"))
        statusBarItem.menu = menu

        self.statusItem = statusBarItem
    }

    func applicationWillTerminate(_ notification: Notification) {
        monitor.stop()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
```

- [ ] **Step 4: Add a small container view that observes `PlaybackMonitor` and feeds `MiniPlayerView`**

Create `Sources/DAMiniPlayer/Views/MiniPlayerContainerView.swift`:

```swift
import SwiftUI

struct MiniPlayerContainerView: View {
    @ObservedObject var monitor: PlaybackMonitor

    var body: some View {
        MiniPlayerView(
            nowPlaying: monitor.nowPlaying,
            isLiked: nil,
            onTogglePlay: monitor.togglePlayPause,
            onNext: monitor.next,
            onPrevious: monitor.previous,
            onToggleLike: {}
        )
    }
}
```

`isLiked` stays `nil` (heart disabled) until Task 10 wires in `LikedSongsService`; `onToggleLike` stays a no-op until then.

- [ ] **Step 5: Build**

Run: `xcodegen generate && xcodebuild -project DAMiniPlayer.xcodeproj -scheme DAMiniPlayer -configuration Debug build`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 6: Manually verify against a real Spotify session**

1. Open Spotify.app and start playing any track.
2. Run the built app (same `open`/`BUILT_PRODUCTS_DIR` steps as Task 6).
3. macOS will show an Automation permission prompt ("DAMiniPlayer wants to control Spotify") — approve it.
4. Confirm the panel shows the real track title/artist and the time updates roughly every second.
5. Click play/pause, next, and previous on the panel and confirm Spotify responds accordingly.
6. Quit Spotify entirely and confirm the panel falls back to "Nothing playing" without crashing.

- [ ] **Step 7: Commit**

```bash
git add Sources/DAMiniPlayer/Playback/SpotifyScript.swift Sources/DAMiniPlayer/Playback/PlaybackMonitor.swift Sources/DAMiniPlayer/Views/MiniPlayerContainerView.swift Sources/DAMiniPlayer/App/AppDelegate.swift
git commit -m "Wire real Spotify playback state and transport controls via AppleScript"
```

---

## Task 8: Keychain Token Storage

**Files:**
- Create: `Sources/DAMiniPlayer/Auth/TokenStore.swift`
- Test: `Tests/DAMiniPlayerTests/KeychainTokenStoreTests.swift`

**Interfaces:**
- Produces: `protocol TokenStore { func saveRefreshToken(_ token: String); func loadRefreshToken() -> String?; func clear() }`
- Produces: `final class KeychainTokenStore: TokenStore` and `final class InMemoryTokenStore: TokenStore`.

- [ ] **Step 1: Write `TokenStore.swift`**

```swift
import Foundation
import Security

protocol TokenStore {
    func saveRefreshToken(_ token: String)
    func loadRefreshToken() -> String?
    func clear()
}

final class KeychainTokenStore: TokenStore {
    private let service = "com.pedro.da-miniplayer.spotify"
    private let account = "refresh-token"

    func saveRefreshToken(_ token: String) {
        clear()
        let data = Data(token.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]
        SecItemAdd(query as CFDictionary, nil)
    }

    func loadRefreshToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func clear() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}

final class InMemoryTokenStore: TokenStore {
    private var token: String?

    func saveRefreshToken(_ token: String) {
        self.token = token
    }

    func loadRefreshToken() -> String? {
        token
    }

    func clear() {
        token = nil
    }
}
```

- [ ] **Step 2: Write the failing Keychain round-trip test**

```swift
import XCTest
@testable import DAMiniPlayer

final class KeychainTokenStoreTests: XCTestCase {
    func testSaveLoadClearRoundTrip() {
        let store = KeychainTokenStore()
        store.clear()
        XCTAssertNil(store.loadRefreshToken())

        store.saveRefreshToken("test-refresh-token-123")
        XCTAssertEqual(store.loadRefreshToken(), "test-refresh-token-123")

        store.saveRefreshToken("replacement-token")
        XCTAssertEqual(store.loadRefreshToken(), "replacement-token")

        store.clear()
        XCTAssertNil(store.loadRefreshToken())
    }

    func testInMemoryStoreRoundTrip() {
        let store = InMemoryTokenStore()
        XCTAssertNil(store.loadRefreshToken())
        store.saveRefreshToken("abc")
        XCTAssertEqual(store.loadRefreshToken(), "abc")
        store.clear()
        XCTAssertNil(store.loadRefreshToken())
    }
}
```

- [ ] **Step 3: Run tests**

Run: `xcodegen generate && xcodebuild -project DAMiniPlayer.xcodeproj -scheme DAMiniPlayer -destination 'platform=macOS' test`
Expected: `** TEST SUCCEEDED **`. If `testSaveLoadClearRoundTrip` fails with a Keychain access error (`errSecInteractionNotAllowed` or similar) rather than a logic error, this is a local code-signing/entitlements issue with running XCTest against the Keychain, not a bug in `KeychainTokenStore` — note it and proceed; `InMemoryTokenStore` is what later tasks' tests actually depend on for isolation, and the real login flow is verified manually in Task 9.

- [ ] **Step 4: Commit**

```bash
git add Sources/DAMiniPlayer/Auth/TokenStore.swift Tests/DAMiniPlayerTests/KeychainTokenStoreTests.swift
git commit -m "Add Keychain-backed and in-memory token stores"
```

---

## Task 9: Spotify OAuth Login (PKCE)

**Files:**
- Create: `Sources/DAMiniPlayer/Auth/Config.swift`
- Create: `Sources/DAMiniPlayer/Resources/Config.plist.example`
- Create: `Sources/DAMiniPlayer/Auth/SpotifyAuth.swift`
- Modify: `Sources/DAMiniPlayer/App/AppDelegate.swift`
- Modify: `README.md` (a top-level README with project description and license already exists — this task appends a "## Setup" section to it, it does not replace it)

**Interfaces:**
- Consumes: `PKCE` (Task 3), `TokenExpiry` (Task 3), `TokenStore` (Task 8).
- Produces: `@MainActor final class SpotifyAuth: NSObject, ObservableObject, ASWebAuthenticationPresentationContextProviding { @Published private(set) var isLoggedIn: Bool; func login(); func logout(); func validAccessToken() async -> String? }`. `LikedSongsService` (Task 10) calls `validAccessToken()` to get a bearer token for Web API requests.

- [ ] **Step 1: Write `Config.plist.example`**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>SpotifyClientID</key>
    <string>your-client-id-here</string>
</dict>
</plist>
```

- [ ] **Step 2: Write `Config.swift`**

```swift
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
```

- [ ] **Step 3: Add `Config.plist` as a (gitignored, optional) resource in `project.yml`**

Update the `DAMiniPlayer` target's `resources` list:

```yaml
    resources:
      - path: Sources/DAMiniPlayer/Resources/Fonts
      - path: Sources/DAMiniPlayer/Resources/Config.plist
        optional: true
```

- [ ] **Step 4: Write `SpotifyAuth.swift`**

```swift
import Foundation
import AuthenticationServices
import AppKit

struct SpotifyTokenResponse: Decodable {
    let access_token: String
    let expires_in: Int
    let refresh_token: String?
}

@MainActor
final class SpotifyAuth: NSObject, ObservableObject, ASWebAuthenticationPresentationContextProviding {
    @Published private(set) var isLoggedIn: Bool

    private let clientID: String
    private let redirectURI = "da-miniplayer://callback"
    private let scopes = "user-library-read user-library-modify"
    private let tokenStore: TokenStore
    private var accessToken: String?
    private var expiresAt: Date = .distantPast
    private var session: ASWebAuthenticationSession?

    init(clientID: String, tokenStore: TokenStore) {
        self.clientID = clientID
        self.tokenStore = tokenStore
        self.isLoggedIn = tokenStore.loadRefreshToken() != nil
        super.init()
    }

    func login() {
        let verifier = PKCE.generateCodeVerifier()
        let challenge = PKCE.codeChallenge(for: verifier)
        var components = URLComponents(string: "https://accounts.spotify.com/authorize")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "code_challenge", value: challenge),
            URLQueryItem(name: "scope", value: scopes)
        ]

        let authSession = ASWebAuthenticationSession(
            url: components.url!,
            callbackURLScheme: "da-miniplayer"
        ) { [weak self] callbackURL, error in
            guard let self, let callbackURL, error == nil,
                  let code = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?
                      .queryItems?.first(where: { $0.name == "code" })?.value else { return }
            Task { await self.exchangeCode(code, verifier: verifier) }
        }
        authSession.presentationContextProvider = self
        authSession.start()
        self.session = authSession
    }

    func logout() {
        tokenStore.clear()
        accessToken = nil
        expiresAt = .distantPast
        isLoggedIn = false
    }

    func validAccessToken() async -> String? {
        if let token = accessToken, !TokenExpiry.isExpired(expiresAt: expiresAt) {
            return token
        }
        return await refreshAccessToken()
    }

    nonisolated func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        NSApplication.shared.windows.first ?? ASPresentationAnchor()
    }

    private func exchangeCode(_ code: String, verifier: String) async {
        let body = [
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": redirectURI,
            "client_id": clientID,
            "code_verifier": verifier
        ]
        guard let token = await requestToken(body: body) else { return }
        apply(token)
    }

    private func refreshAccessToken() async -> String? {
        guard let refreshToken = tokenStore.loadRefreshToken() else { return nil }
        let body = [
            "grant_type": "refresh_token",
            "refresh_token": refreshToken,
            "client_id": clientID
        ]
        guard let token = await requestToken(body: body) else {
            logout()
            return nil
        }
        apply(token)
        return token.access_token
    }

    private func requestToken(body: [String: String]) async -> SpotifyTokenResponse? {
        var request = URLRequest(url: URL(string: "https://accounts.spotify.com/api/token")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)

        guard let (data, _) = try? await URLSession.shared.data(for: request) else { return nil }
        return try? JSONDecoder().decode(SpotifyTokenResponse.self, from: data)
    }

    private func apply(_ token: SpotifyTokenResponse) {
        accessToken = token.access_token
        expiresAt = Date().addingTimeInterval(TimeInterval(token.expires_in - 60))
        if let refresh = token.refresh_token {
            tokenStore.saveRefreshToken(refresh)
        }
        isLoggedIn = true
    }
}
```

This class does real network + system UI work and is not unit tested directly — `PKCE` and `TokenExpiry` (Task 3) already cover its pure logic in isolation. Verification is manual (Step 7).

- [ ] **Step 5: Instantiate `SpotifyAuth` in `AppDelegate` and add menu items for login/logout**

Replace the full contents of `Sources/DAMiniPlayer/App/AppDelegate.swift` with:

```swift
import AppKit
import SwiftUI
import Combine

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var panel: MiniPlayerPanel?
    private let monitor = PlaybackMonitor()
    private let auth = SpotifyAuth(clientID: Config.spotifyClientID, tokenStore: KeychainTokenStore())
    private var loginMenuItem: NSMenuItem?
    private var authCancellable: AnyCancellable?

    func applicationDidFinishLaunching(_ notification: Notification) {
        PlayerTheme.registerFonts()
        NSApp.setActivationPolicy(.accessory)

        let panel = MiniPlayerPanel {
            MiniPlayerContainerView(monitor: self.monitor)
        }
        panel.orderFrontRegardless()
        self.panel = panel

        monitor.start()

        let statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusBarItem.button?.title = "♪"

        let menu = NSMenu()
        let loginItem = NSMenuItem(title: loginTitle, action: #selector(toggleLogin), keyEquivalent: "")
        menu.addItem(loginItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit DA Mini Player", action: #selector(quit), keyEquivalent: "q"))
        statusBarItem.menu = menu
        self.loginMenuItem = loginItem

        authCancellable = auth.$isLoggedIn.sink { [weak self] _ in
            self?.loginMenuItem?.title = self?.loginTitle ?? ""
        }

        self.statusItem = statusBarItem
    }

    func applicationWillTerminate(_ notification: Notification) {
        monitor.stop()
    }

    private var loginTitle: String {
        auth.isLoggedIn ? "Log Out of Spotify" : "Log In to Spotify"
    }

    @objc private func toggleLogin() {
        if auth.isLoggedIn {
            auth.logout()
        } else {
            auth.login()
        }
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
```

- [ ] **Step 6: Append a "## Setup" section to the existing `README.md`**

The repo root already has a `README.md` with a project description and a
`## License` section (added before this plan's implementation started).
Insert a new `## Setup` section **before** the existing `## License`
section — do not change anything else in the file. The section to insert:

```markdown
## Setup

### 1. Install dependencies

```bash
brew install xcodegen
```

### 2. Create a Spotify app

1. Go to the [Spotify Developer Dashboard](https://developer.spotify.com/dashboard)
   and create an app.
2. Add `da-miniplayer://callback` as a Redirect URI in the app's settings.
3. Copy the app's Client ID.

### 3. Configure the client ID

```bash
cp Sources/DAMiniPlayer/Resources/Config.plist.example Sources/DAMiniPlayer/Resources/Config.plist
```

Edit `Sources/DAMiniPlayer/Resources/Config.plist` and paste in your Client ID.

### 4. Build and run

```bash
xcodegen generate
xcodebuild -project DAMiniPlayer.xcodeproj -scheme DAMiniPlayer -configuration Debug build
```

Then open the built `DAMiniPlayer.app` (find it via `xcodebuild -showBuildSettings`
under `BUILT_PRODUCTS_DIR`), or open `DAMiniPlayer.xcodeproj` in Xcode and run
from there.

On first launch, macOS will prompt you to allow DA Mini Player to control
Spotify — approve it so the mini player can read the current track and
send playback commands.

Click the "♪" menu bar icon and choose "Log In to Spotify" once to enable
the Liked Songs heart button.
```

- [ ] **Step 7: Build and manually verify the login flow**

Run: `xcodegen generate && xcodebuild -project DAMiniPlayer.xcodeproj -scheme DAMiniPlayer -configuration Debug build`
Expected: `** BUILD SUCCEEDED **`

Then:
1. Follow the README to create a Spotify app and fill in `Config.plist`.
2. Launch the built app, click the "♪" menu bar icon, choose "Log In to Spotify".
3. Confirm a system web-auth sheet opens showing Spotify's login/consent page.
4. Approve access; confirm the sheet closes and the menu item now reads "Log Out of Spotify".
5. Quit and relaunch the app; confirm it still shows "Log Out of Spotify" (i.e. the refresh token persisted in Keychain).

- [ ] **Step 8: Commit**

```bash
git add Sources/DAMiniPlayer/Auth/Config.swift Sources/DAMiniPlayer/Resources/Config.plist.example Sources/DAMiniPlayer/Auth/SpotifyAuth.swift Sources/DAMiniPlayer/App/AppDelegate.swift project.yml README.md
git commit -m "Add Spotify OAuth PKCE login flow and setup instructions"
```

---

## Task 10: Liked Songs Service

**Files:**
- Create: `Sources/DAMiniPlayer/LikedSongs/SpotifyLibraryClient.swift`
- Create: `Sources/DAMiniPlayer/LikedSongs/LikedSongsService.swift`
- Test: `Tests/DAMiniPlayerTests/LikedSongsServiceTests.swift`

**Interfaces:**
- Consumes: `SpotifyAuth.validAccessToken()` (Task 9).
- Produces: `protocol SpotifyLibraryClient { func containsTrack(id: String) async throws -> Bool; func saveTrack(id: String) async throws; func removeTrack(id: String) async throws }`, a real `SpotifyWebAPIClient: SpotifyLibraryClient`, and `@MainActor final class LikedSongsService: ObservableObject { @Published private(set) var likedState: [String: Bool]; func refreshLikedState(for trackID: String) async; func toggleLike(for trackID: String) async }`. Task 11 reads `likedState[trackID]` and calls `toggleLike(for:)`.

- [ ] **Step 1: Write `SpotifyLibraryClient.swift`**

```swift
import Foundation

protocol SpotifyLibraryClient {
    func containsTrack(id: String) async throws -> Bool
    func saveTrack(id: String) async throws
    func removeTrack(id: String) async throws
}

enum SpotifyLibraryClientError: Error {
    case notAuthenticated
    case requestFailed
}

final class SpotifyWebAPIClient: SpotifyLibraryClient {
    private let auth: SpotifyAuth

    init(auth: SpotifyAuth) {
        self.auth = auth
    }

    func containsTrack(id: String) async throws -> Bool {
        guard let token = await auth.validAccessToken() else { throw SpotifyLibraryClientError.notAuthenticated }
        var request = URLRequest(url: URL(string: "https://api.spotify.com/v1/me/tracks/contains?ids=\(id)")!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw SpotifyLibraryClientError.requestFailed
        }
        let result = try JSONDecoder().decode([Bool].self, from: data)
        return result.first ?? false
    }

    func saveTrack(id: String) async throws {
        try await mutate(id: id, method: "PUT")
    }

    func removeTrack(id: String) async throws {
        try await mutate(id: id, method: "DELETE")
    }

    private func mutate(id: String, method: String) async throws {
        guard let token = await auth.validAccessToken() else { throw SpotifyLibraryClientError.notAuthenticated }
        var request = URLRequest(url: URL(string: "https://api.spotify.com/v1/me/tracks?ids=\(id)")!)
        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw SpotifyLibraryClientError.requestFailed
        }
    }
}
```

- [ ] **Step 2: Write the failing `LikedSongsService` tests using a fake client**

```swift
import XCTest
@testable import DAMiniPlayer

private final class FakeSpotifyLibraryClient: SpotifyLibraryClient {
    var containsResult: Result<Bool, Error> = .success(false)
    var saveResult: Result<Void, Error> = .success(())
    var removeResult: Result<Void, Error> = .success(())
    var saveCallCount = 0
    var removeCallCount = 0

    func containsTrack(id: String) async throws -> Bool {
        try containsResult.get()
    }

    func saveTrack(id: String) async throws {
        saveCallCount += 1
        try saveResult.get()
    }

    func removeTrack(id: String) async throws {
        removeCallCount += 1
        try removeResult.get()
    }
}

private struct TestError: Error {}

@MainActor
final class LikedSongsServiceTests: XCTestCase {
    func testRefreshLikedStateSetsTrueWhenAlreadyLiked() async {
        let client = FakeSpotifyLibraryClient()
        client.containsResult = .success(true)
        let service = LikedSongsService(client: client)

        await service.refreshLikedState(for: "track1")

        XCTAssertEqual(service.likedState["track1"], true)
    }

    func testRefreshLikedStateDoesNotReFetchOnceKnown() async {
        let client = FakeSpotifyLibraryClient()
        client.containsResult = .success(false)
        let service = LikedSongsService(client: client)

        await service.refreshLikedState(for: "track1")
        client.containsResult = .success(true) // would flip the result if fetched again
        await service.refreshLikedState(for: "track1")

        XCTAssertEqual(service.likedState["track1"], false)
    }

    func testToggleLikeOptimisticallySetsTrueAndCallsSave() async {
        let client = FakeSpotifyLibraryClient()
        let service = LikedSongsService(client: client)

        await service.toggleLike(for: "track1")

        XCTAssertEqual(service.likedState["track1"], true)
        XCTAssertEqual(client.saveCallCount, 1)
    }

    func testToggleLikeTwiceCallsRemove() async {
        let client = FakeSpotifyLibraryClient()
        let service = LikedSongsService(client: client)

        await service.toggleLike(for: "track1")
        await service.toggleLike(for: "track1")

        XCTAssertEqual(service.likedState["track1"], false)
        XCTAssertEqual(client.removeCallCount, 1)
    }

    func testToggleLikeRevertsOnFailure() async {
        let client = FakeSpotifyLibraryClient()
        client.saveResult = .failure(TestError())
        let service = LikedSongsService(client: client)

        await service.toggleLike(for: "track1")

        XCTAssertEqual(service.likedState["track1"], false)
    }
}
```

- [ ] **Step 3: Run tests to verify they fail**

Run: `xcodegen generate && xcodebuild -project DAMiniPlayer.xcodeproj -scheme DAMiniPlayer -destination 'platform=macOS' test`
Expected: FAIL — `LikedSongsService` does not exist.

- [ ] **Step 4: Write `LikedSongsService.swift`**

```swift
import Foundation

@MainActor
final class LikedSongsService: ObservableObject {
    @Published private(set) var likedState: [String: Bool] = [:]

    private let client: SpotifyLibraryClient

    init(client: SpotifyLibraryClient) {
        self.client = client
    }

    func refreshLikedState(for trackID: String) async {
        guard likedState[trackID] == nil else { return }
        if let liked = try? await client.containsTrack(id: trackID) {
            likedState[trackID] = liked
        }
    }

    func toggleLike(for trackID: String) async {
        let previous = likedState[trackID] ?? false
        likedState[trackID] = !previous
        do {
            if previous {
                try await client.removeTrack(id: trackID)
            } else {
                try await client.saveTrack(id: trackID)
            }
        } catch {
            likedState[trackID] = previous
        }
    }
}
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `xcodebuild -project DAMiniPlayer.xcodeproj -scheme DAMiniPlayer -destination 'platform=macOS' test`
Expected: `** TEST SUCCEEDED **`, all `LikedSongsServiceTests` pass.

- [ ] **Step 6: Commit**

```bash
git add Sources/DAMiniPlayer/LikedSongs/SpotifyLibraryClient.swift Sources/DAMiniPlayer/LikedSongs/LikedSongsService.swift Tests/DAMiniPlayerTests/LikedSongsServiceTests.swift
git commit -m "Add LikedSongsService with optimistic like/unlike and unit tests"
```

---

## Task 11: Wire the Heart Button End-to-End

**Files:**
- Modify: `Sources/DAMiniPlayer/Views/MiniPlayerContainerView.swift`
- Modify: `Sources/DAMiniPlayer/App/AppDelegate.swift`

**Interfaces:**
- Consumes: `LikedSongsService` (Task 10), `SpotifyAuth` (Task 9), `PlaybackMonitor` (Task 7), `MiniPlayerView` (Task 6, unchanged signature).

- [ ] **Step 1: Update `MiniPlayerContainerView.swift` to observe `LikedSongsService` and `SpotifyAuth`**

```swift
import SwiftUI

struct MiniPlayerContainerView: View {
    @ObservedObject var monitor: PlaybackMonitor
    @ObservedObject var likedSongs: LikedSongsService
    @ObservedObject var auth: SpotifyAuth

    var body: some View {
        MiniPlayerView(
            nowPlaying: monitor.nowPlaying,
            isLiked: auth.isLoggedIn ? (monitor.nowPlaying.trackID.flatMap { likedSongs.likedState[$0] }) : nil,
            onTogglePlay: monitor.togglePlayPause,
            onNext: monitor.next,
            onPrevious: monitor.previous,
            onToggleLike: {
                guard auth.isLoggedIn, let trackID = monitor.nowPlaying.trackID else {
                    auth.login()
                    return
                }
                Task { await likedSongs.toggleLike(for: trackID) }
            }
        )
        // Single-value onChange (not the two-value macOS 14+ overload) —
        // deployment target here is macOS 13.
        .onChange(of: monitor.nowPlaying.trackID) { newID in
            guard auth.isLoggedIn, let newID else { return }
            Task { await likedSongs.refreshLikedState(for: newID) }
        }
    }
}
```

- [ ] **Step 2: Instantiate `LikedSongsService` in `AppDelegate` and pass it (and `auth`) into the container view**

Replace the full contents of `Sources/DAMiniPlayer/App/AppDelegate.swift` with:

```swift
import AppKit
import SwiftUI
import Combine

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var panel: MiniPlayerPanel?
    private let monitor = PlaybackMonitor()
    private let auth = SpotifyAuth(clientID: Config.spotifyClientID, tokenStore: KeychainTokenStore())
    private lazy var likedSongs = LikedSongsService(client: SpotifyWebAPIClient(auth: auth))
    private var loginMenuItem: NSMenuItem?
    private var authCancellable: AnyCancellable?

    func applicationDidFinishLaunching(_ notification: Notification) {
        PlayerTheme.registerFonts()
        NSApp.setActivationPolicy(.accessory)

        let panel = MiniPlayerPanel {
            MiniPlayerContainerView(monitor: self.monitor, likedSongs: self.likedSongs, auth: self.auth)
        }
        panel.orderFrontRegardless()
        self.panel = panel

        monitor.start()

        let statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusBarItem.button?.title = "♪"

        let menu = NSMenu()
        let loginItem = NSMenuItem(title: loginTitle, action: #selector(toggleLogin), keyEquivalent: "")
        menu.addItem(loginItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit DA Mini Player", action: #selector(quit), keyEquivalent: "q"))
        statusBarItem.menu = menu
        self.loginMenuItem = loginItem

        authCancellable = auth.$isLoggedIn.sink { [weak self] _ in
            self?.loginMenuItem?.title = self?.loginTitle ?? ""
        }

        self.statusItem = statusBarItem
    }

    func applicationWillTerminate(_ notification: Notification) {
        monitor.stop()
    }

    private var loginTitle: String {
        auth.isLoggedIn ? "Log Out of Spotify" : "Log In to Spotify"
    }

    @objc private func toggleLogin() {
        if auth.isLoggedIn {
            auth.logout()
        } else {
            auth.login()
        }
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
```

- [ ] **Step 3: Build**

Run: `xcodegen generate && xcodebuild -project DAMiniPlayer.xcodeproj -scheme DAMiniPlayer -configuration Debug build`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Run the full test suite one more time**

Run: `xcodebuild -project DAMiniPlayer.xcodeproj -scheme DAMiniPlayer -destination 'platform=macOS' test`
Expected: `** TEST SUCCEEDED **`, every test from Tasks 2–10 still passes.

- [ ] **Step 5: Manually verify the full end-to-end flow**

1. Launch the app with Spotify playing a track, logged in (Task 9's login flow already completed).
2. Confirm the heart renders outlined or filled correctly matching the track's actual Liked Songs status in Spotify (check the Spotify app/website directly).
3. Tap the heart on an unliked track; confirm it fills in immediately and the track appears in Liked Songs in Spotify shortly after.
4. Tap it again; confirm it un-fills and the track is removed from Liked Songs.
5. Skip to a different track (via next/previous or in Spotify itself) and confirm the heart updates to reflect that track's own liked state.
6. Turn off Wi-Fi briefly, tap the heart, confirm it reverts to its previous state after the request fails, then turn Wi-Fi back on.

- [ ] **Step 6: Commit**

```bash
git add Sources/DAMiniPlayer/Views/MiniPlayerContainerView.swift Sources/DAMiniPlayer/App/AppDelegate.swift
git commit -m "Wire Liked Songs heart button end-to-end"
```
