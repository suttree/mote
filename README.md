# mote

A personal macOS menu-bar companion for shuffled Music playlists and a read-only
three-day view of weather and Calendar.

## Current scope

- Menu-bar-only SwiftUI app; no Dock or app-switcher icon.
- Popover-style, 380-point-wide single-column interface.
- Lists visible Music playlists, starts the selected playlist with song shuffle,
  shows progress while switching, and offers play/pause and next controls.
- Reads the next 72 hours from macOS Calendar using EventKit.
- Reads three forecast days from Open-Meteo.
- Uses forecast coordinates for `SE18 6RU`.
- Stores only the chosen playlist in `UserDefaults`.

## Build

Requirements: macOS 14 or newer and Xcode.

```sh
make test
make app
open .build/mote.app
```

The build script creates and ad-hoc signs `.build/mote.app`. Pass a destination
path to build elsewhere:

```sh
./scripts/build-app.sh /path/to/mote.app
```

## First launch

Click the mote icon in the menu bar. macOS will ask once for:

- Music automation, to list playlists and control playback.
- Calendar access, to read the next 72 hours.

The local build uses a stable designated requirement so these grants survive
subsequent mote rebuilds. The first build using this identity may require one
final approval.

The personal weather postcode is compiled into this build.

## Popover position

macOS positions and clamps menu-bar popovers to the visible screen. If the mote
icon sits close to the right edge, Command-drag it farther left in the menu bar
to leave enough room for the popover to centre beneath it. Clicking elsewhere
dismisses the popover.

## Design and privacy

Music is the only active dashboard card. Weather and Calendar are reference-only.
mote does not write to Calendar or maintain its own copy of its content.

Weather data comes from [Open-Meteo](https://open-meteo.com/).
