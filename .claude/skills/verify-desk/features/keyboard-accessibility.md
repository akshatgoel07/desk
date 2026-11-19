# Keyboard and accessibility

The user moves focus between notes with Tab and the arrow keys, and opens the focused note with Return. A focused corner control responds to Space. The accessibility tree exposes the canvas as a group with one child for each note. Each note child has a label, a selected value, and the actions press (focus) and pick (open).

## Sub-features

- `kbd-tab-notes` focuses and selects the next note in z order with Tab, and the previous one with Shift-Tab.
- `kbd-arrows` focuses the next note with Right or Down, and the previous note with Left or Up.
- `kbd-tab-exit` moves focus to `Add Content` after the last note. The next Tab moves focus to the canvas, and the Tab after that focuses the first note again.
- `kbd-control-space` presses a focused corner control with Space.
- `ax-tree` shows the `Canvas` group, its value (the selected note text, or "No selected notes"), and one `AXGroup` child for each note with `AXPress` and `AXPick`.
- `ax-press` focuses and selects a note.
- `ax-pick` opens the note page.
- `ax-buttons` labels every corner control and action bar button, with disabled state.

## How to get to it (user POV)

- Press Tab, Shift-Tab, and the arrow keys on the board. Press Return on a focused note.
- Use VoiceOver: interact with the Canvas group, then press or open a note.

## Driving it with run-steps

Preconditions:

- Baseline state. The step file adds the two sample notes.
- System Settings > Keyboard > Keyboard navigation is off (the macOS default, `AppleKeyboardUIMode` not set). Check with `defaults read -g AppleKeyboardUIMode`.

- **Tab to the first note.** Run `scripts/run-steps keyboard-a steps/keyboard-accessibility.json`. `01-tab-focuses-first-note.json` has focus `CanvasItemView`, `focusedNote` equal to the first note, and that note selected. The PNG shows the focus ring.
- **Arrow.** Right. `02-arrow-right.json` has the second note focused and selected.
- **Tab past the last note.** `03-tab-leaves-canvas.json` has focus `CornerCapsule`, no focused note, and `Add Content` as the focused button. The PNG shows the focus ring on `Add Content`.
- **Space.** `04-space-presses-focused-control.json` has focus `ContentMenuOverlay`, because Space pressed `Add Content` and the plus menu opened. The Escape step closes the menu.
- **Accessibility tree.** `05-ax.json` has the `Canvas` group with two `AXGroup` children labeled with the note text, each with `["AXPress","AXPick"]`, and buttons labeled `Board Settings`, `Checklist`, `Spaces`, `Add Content`, `Download Selected Items`, and `Move to Folder` (disabled).
- **Press.** `axAction` `press` on `A place for your ideas.`. `06-ax-press.json` has that note focused and selected.
- **Pick.** `axAction` `pick`. `07-ax-pick-opens-editor.json` has `editor.destination` `page` and focus `NoteTextView`.
- **Control and Space.** For `kbd-control-space`, use `focusControl` `Add Content`, then Space. The plus menu opens (focus `ContentMenuOverlay`).

## Gotchas

- The Tab order is note 1, note 2, ..., `Add Content`, the canvas, then note 1 again. This order is the same with macOS Keyboard navigation on or off. The other corner controls are not in the Tab order. Use `focusControl` to focus them.
- `axAction` matches the note label exactly. The label is the full note text, or `Empty note`.
- The `axDump` tree has the canvas children only while the main window is the driver window.
- VoiceOver speech is out of scope. The dump proves names, roles, values, and actions only.
- Reduce Motion, Increase Contrast, and Reduce Transparency change animations and outlines. The driver cannot set them, and `defaults write` for them fails. `dumpState.displayPreferences` shows the current values. Report those branches as verified-unreachable unless the machine has them on.
