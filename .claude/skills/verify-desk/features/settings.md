# Settings

The Settings window has three choices that work: corner style for cards, the note font, and the color theme. A choice applies to the board at once and persists in user defaults. The Scratch Pad hotkey row is visible but disabled.

## Sub-features

- `settings-open` opens the Settings window with `Desk > Settings…` or Command-comma.
- `settings-corners` sets `Sharp corners` or `Round corners` for note and image cards.
- `settings-font` sets `Mono/Sans`, `Mono`, or `Sans` for note text.
- `settings-theme` sets `Auto`, `Dark`, or `Light` for the board.
- `settings-close` closes the window with Escape. Escape first closes an open choice list.
- `settings-persist` keeps the choices after a relaunch with the same defaults suite.
- `settings-hotkey-disabled` shows the Scratch Pad hotkey controls disabled.

## How to get to it (user POV)

- Choose `Desk > Settings…`, or press Command-comma.
- Click a choice button, then click a value in the list.

## Driving it with run-steps

Preconditions:

- A fresh defaults suite. The step file adds the sample notes.

- **Defaults.** Run `scripts/run-steps settings-a steps/settings.json --keep`. `01-defaults.json` has `preferences` `Auto`, `Sharp corners`, `Mono/Sans`.
- **Open.** Command-comma. `02-settings-window.json` has `windowTitle` `Settings`, window 600 x 466, and focus `PreferencesContent`. The PNG shows four rows and the credits.
- **Choice list.** `clickControl` `Corner style`. `03-corner-choices.png` shows `Sharp corners` and `Round corners` below the button.
- **Choose.** `Corner style: Round corners`, `Note font: Mono`, `Appearance: Light`. `04-choices-made.json` has `preferences` `Light`, `Round corners`, `Mono`.
- **Board after close.** Escape. `05-board-after-settings.json` has `windowTitle` empty and window 1080 x 720. The PNG shows a light gray board, white cards with round corners, and monospaced text.
- **Menu entry.** `menu` `Settings…`. `06-reopened-by-menu.json` has `windowTitle` `Settings`.
- **Relaunch.** Run `scripts/run-steps settings-b steps/restart-check.json --store <kept store> --suite <kept suite>`. `after-restart.json` has the three new values, and the PNG shows the light board.

## Gotchas

- While the Settings window is open, every step goes to the Settings window: `snapshot`, `clickControl`, `key`, and the `buttons` and `window` fields of `dumpState`. Close it with Escape before you drive the board.
- The choice list covers the next row. Close the list before you click the button below it, or click a value first.
- The `menu` name has the ellipsis character `…`, not three periods.
- The corner style label in the window reads "Display images and videos with", but the choice also changes note cards.
- `appearance` is a driver-only step. It does not change the saved theme. Use `Appearance: Light` for a user path.
