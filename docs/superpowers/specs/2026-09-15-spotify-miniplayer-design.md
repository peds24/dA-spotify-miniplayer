# Spotify Mini Player (Silicio Clone) — Design

## Purpose

A native macOS floating mini player for Spotify, inspired by
[Silicio](https://apps.apple.com/us/app/silicio-widgets-mini-player/id933627574?mt=12).
The two reasons to build a clone rather than use Silicio directly:

1. Full control over the visual styling.
2. An "Add to Liked Songs" heart button — a feature Silicio doesn't offer,
   since liking a song is a Spotify library edit that requires the Web API,
   not just local playback control.

## Architecture

A native SwiftUI macOS app (macOS 13+), no dock icon, two visible pieces:

- A **borderless, always-on-top, draggable `NSPanel`** hosting the SwiftUI
  mini player view. This is the actual widget the user sees and positions
  on their desktop.
- A **menu bar item** (status item) for Settings and Quit, and for
  triggering the one-time Spotify login.

## Components

### `PlaybackMonitor`

Polls the local Spotify.app via AppleScript (`NSAppleScript`) on a ~1s
timer for:

- track name, artist, album artwork
- playback position / duration
- player state (playing / paused / stopped)
- the track's `spotify:track:<id>` URI (via Spotify's AppleScript `spotify
  url` property), used to derive the track ID for Web API calls

Publishes an observable `NowPlaying` model that the UI binds to. If
Spotify.app is not running, `PlaybackMonitor` reports an idle state rather
than erroring.

Transport controls (prev / play-pause / next) are plain AppleScript
commands sent to Spotify (`playpause`, `next track`, `previous track`) —
no Web API involved, no auth required for these.

### `SpotifyAuth`

Handles the **one-time** OAuth needed only for the Liked Songs feature:

- Authorization Code + PKCE flow via `ASWebAuthenticationSession`
- Scopes: `user-library-read`, `user-library-modify`
- Refresh token stored in the macOS Keychain
- Access token held in memory, silently refreshed via the refresh token
  when expired

### `LikedSongsService`

- On every track change, calls `GET /me/tracks/contains?ids=<id>` to
  determine whether the current track is already liked, so the heart
  renders filled or outlined.
- On heart tap: `PUT /me/tracks` (like) or `DELETE /me/tracks` (unlike).
  The UI updates optimistically and reverts if the request fails.

## Styling

Ported directly from the user's existing
[digital-archives](https://peds24.github.io/digital-archives-page/) site,
whose now-playing bar is effectively the same layout this widget needs
(art thumbnail, title/artist, prev/play/next, time), and which already
uses Spotify's own brand green as its accent.

- **Font:** Space Mono (Regular + Bold), bundled as a font resource.
- **Palette (dark, default):**
  - ground `#030C06`
  - surface `#0A1F11`
  - ink (primary text) `#E1F4E8`
  - ink-dim (secondary text) `#72C08E`
  - hairline (borders) `#194328`
  - accent `#1DB954` (Spotify green — used for the filled heart and active
    states)
- **Layout:** small square artwork, title/artist stacked, 1px hairline
  separators, a slim progress bar, minimal icon buttons (prev/play/next),
  plus the heart button using the accent color when the track is liked.

Only the dark palette ships initially — no light-mode/system-appearance
switching, per YAGNI; can be added later if wanted.

## Data Flow

```
Spotify.app ──(AppleScript, ~1s poll)──> PlaybackMonitor ──> NowPlaying model ──> SwiftUI view
                                                                   │
                                                                   ▼
                                                     track ID on change ──> LikedSongsService
                                                                             ──(Web API, OAuth)──> Spotify
```

Transport button taps go directly from the SwiftUI view back through
AppleScript to Spotify.app; heart taps go through `LikedSongsService` to
the Web API.

## Error Handling

- **Spotify not running / nothing playing:** widget shows a quiet
  "Nothing playing" state. No error surfaced.
- **Not logged in (Web API):** the heart button shows a disabled/"log in"
  affordance; tapping it starts the OAuth flow.
- **Like/unlike request fails:** the optimistic UI change reverts; a
  subtle inline indicator shows the failure (no modal/alert).
- **Token refresh fails:** treated the same as "not logged in" — user is
  prompted to log in again.

## Testing

The AppleScript/local-Spotify integration and the real OAuth flow can't
be meaningfully faked in CI — verification there is manual, run against
the real Spotify.app and a real Spotify account.

Unit tests cover the pure logic that doesn't require system integration:

- time/position formatting
- the liked-state cache (optimistic update + revert logic)
- PKCE challenge generation and token-refresh logic

## Out of Scope (YAGNI)

- Light mode / system-appearance switching
- Multiple simultaneous widget instances
- Support for other players (Apple Music, etc.) — Spotify only
- Global keyboard shortcuts, launch-at-login (can be added later if
  wanted, not needed for the core ask)
