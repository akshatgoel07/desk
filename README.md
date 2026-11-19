# Desk

Desk is a Swift and AppKit canvas app for notes and images on a zoomable board.

Desk is an independent clean-room study inspired by the interaction design of the Spatial macOS app, with no copied source, assets, or fonts, and no affiliation.

## Run

The app requires macOS 15 or newer and the Swift 6.2 toolchain.

Build the executable.

```bash
swift build
```

Start the app.

```bash
.build/debug/Desk
```

The app stores notes in `~/Library/Application Support/Desk/store.sqlite`.
`DESK_STORE_URL` selects a separate note store for native verification.
`DESK_VERIFY_SCRIPT` selects a JSON array of driver steps.
Verification runs use invisible windows and preserve the active app, Dock, and menu bar.
The `savePanel` step confirms an export with `path`, or cancels the export without `path`.
The driver exits after the final step.

```bash
DESK_STORE_URL=/absolute/path/notes.sqlite \
DESK_VERIFY_SCRIPT=/absolute/path/script.json \
.build/debug/Desk
```

The driver supports `snapshot`, `dumpState`, and `axDump` with a `path` field.
`record` saves native PNG frames in its `path` directory.
`stopRecord` saves the frame times in `frames.json`.
Each script produces a file with the `.timings.json` suffix for step durations.
[ACCEPTANCE.md](ACCEPTANCE.md) contains the native results and blocked cases.
The app uses ffmpeg from `/opt/homebrew/bin` when that tool exists.

## What is implemented

| Area | State |
|---|---|
| Window shell with full size content | working |
| Canvas selection, group drag, lasso, Space pan, and corner resize | Native replay verifies scales 0.3, 1, and 4 |
| Viewport pan, anchored pinch, zoom controls, and Fit Content | Native replay verifies pointer alignment and camera interruption |
| Spring core and native opacity feedback | Forty camera transitions preserve their final targets |
| Local note persistence in Core Data | Create, edit, move, resize, and delete survive restart with stable identity |
| Native note editor | Paragraphs, clipboard, text undo, and card undo pass. Live input method composition remains open |
| ffmpeg remux profile, yuv420p faststart, AAC `aac_at 128k` fallback, serial process queue, probe via ffprobe | working, needs real media files |
| Video item with `AVPlayerLooper` | working with any local mp4 passed in code |
| StoreKit 2 service, ids `pro.lifetime`, `pro.yearly`, `pro.monthly`, entitlement scan | working, sells nothing |
| Paywall limit math with new user variants and nag intervals | working |
| `desk://` routes authentication, paywall, restore, code | routes are parsed in code, real scheme registration needs an app bundle Info.plist |
| Empty, populated, load error, and save error states | Samples require an explicit command. Retry and Dismiss perform their named actions |
| Native controls, keyboard focus, and note accessibility | Names, roles, values, note actions, and focus order pass |
| Display accessibility preferences | Reduce Motion, Increase Contrast, and Reduce Transparency branches require enabled preference checks |
| Missing on purpose | | sidebar, bookmarks, web clips, social providers, importers, xAuth PKCE, toasts, gestures beyond the canvas itself |

## Where to extend

- `SpringCore.swift`, the spring constants and the ladder encoding.
- `Drivers.swift`, the drag state machine and the pinch momentum math.
- `DataStore.swift`, the programmatic Core Data model.
- `MediaPipeline.swift`, the ffmpeg subprocess queue and remux profiles.
- `Billing.swift`, StoreKit and the paywall limits.
- `Shell.swift`, window, routes, and the switch surface.

## Legal note

This is a behavior study. The reference app, its name, artwork, fonts, store presence,
and binaries are not copied or distributed here.
