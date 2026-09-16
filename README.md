# dA Spotify Mini Player

A native macOS floating mini player for Spotify. It sits as a small,
always-on-top, draggable panel showing the current track, with playback
controls and a button to add the current song straight to your Spotify
Liked Songs.

## Features

- Floating panel — drag it anywhere on screen, stays on top of other windows
- Live "now playing" info (track, artist, artwork) read directly from the
  Spotify desktop app
- Playback controls: previous / play-pause / next
- One-click "Add to Liked Songs," with the heart reflecting whether the
  current track is already liked
- Lives in the menu bar — no Dock icon

## Requirements

- macOS 13.0 or later
- The [Spotify](https://www.spotify.com/download/) desktop app, running

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

## License

Licensed under the [GNU General Public License v3.0](./LICENSE).

Copyright (C) 2026 Pedro Serdio Hank
