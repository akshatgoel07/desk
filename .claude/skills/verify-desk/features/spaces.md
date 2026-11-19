# Spaces

A space is a separate board with its own notes. The user makes spaces, switches between them, renames the current space, and deletes it with a confirmation. Space changes are undoable. A store always has at least one space.

## Sub-features

- `space-new-menu` makes `SpaceNN` (next number) with `File > New Space` and switches to it.
- `space-new-plus` makes a space with `Add Content > New Space`.
- `space-menu` lists the spaces in the Spaces menu, marks the current one, and switches on a click.
- `space-key` switches to space N with Command-N for N from 1 to 9 (`View > Space N`).
- `space-rename` renames the current space with `Board Settings > Edit Space`, then Return.
- `space-rename-undo` restores the old name with Command-Z.
- `space-delete` deletes the current space and its notes after `Delete Space` and `Delete Space` in the confirmation, and goes to another space.
- `space-delete-undo` restores the space and its notes with Command-Z.
- `space-delete-last` replaces the last space with a new empty `Space01`.
- `space-settings-close` closes Board Settings with Escape or a click outside.

## How to get to it (user POV)

- Choose `File > New Space`, or `Add Content` then `New Space`.
- Choose the `Spaces` button (antenna icon with a caret) and click a space.
- Press Command-1, Command-2, and so on.
- Choose `Board Settings` (sliders icon, bottom left). Choose `Edit Space`, `Delete Space`, or `Desk Pro`.

## Driving it with run-steps

Preconditions:

- Baseline state.

- **Note in the first space.** Run `scripts/run-steps spaces-a steps/spaces.json`. `01-space01-with-note.json` has `currentSpace` `Space01` and one note.
- **New Space from the menu.** `02-new-space-menu.json` has `Space02` current, two spaces, and no notes.
- **New Space from the plus menu.** `03-new-space-plus-menu.json` has `Space03` current and three spaces.
- **Spaces menu.** `04-spaces-menu.png` shows three rows with `⌘ 1` to `⌘ 3`, and `Space03` dimmed as current. `clickControl` `Space01`. `05-switched-by-menu.json` has `Space01` current and its note.
- **Command-2.** `06-cmd-2.json` has `Space02` current.
- **Rename.** Command-1, `Board Settings`, `Edit Space`, `text` `Ideas\n`. `08-renamed.json` has `currentSpace` `Ideas`.
- **Undo rename.** `09-undo-rename.json` has `Space01` again.
- **Delete with confirmation.** `Board Settings`, `Delete Space`. `10-delete-confirm.png` shows "Delete this space and all its notes?", `Cancel`, and `Delete Space`. `clickControl` `Confirm Delete Space`. `11-deleted.json` has spaces `Space02`, `Space03` and `Space02` current.
- **Undo delete.** `12-undo-delete.json` has `Space01` current with its note and three spaces.
- **Escape.** `Board Settings`, Escape. `14-escape-closes.json` has focus `CanvasView`, and the PNG has no settings panel.
- **Delete the last space.** Run `scripts/run-steps spaces-b steps/spaces-delete-last.json`. `02-replaced-by-new-space01.json` has one space `Space01` with a new random ID (not `00000000-...`) and no notes. `03-undo-restores.json` has the old ID `00000000-0000-0000-0000-000000000000` and the note.
- **Cancel a rename.** The same run types `Draft` in the name field and presses Escape. `04-escape-cancels-rename.json` has the name `Space01`, focus `BoardSettingsOverlay`, and the `Edit Space` row visible again.
- **Persistence.** Add `--keep`, then run `steps/restart-check.json` with `--store` and `--suite`. The spaces and their notes are the same.

## Gotchas

- The confirm button title is `Delete Space`, the same as the row title. Use the identifier `Confirm Delete Space`. `clickControl` `Delete Space` hits the row.
- `Space N` menu items exist for 1 to 9 even when fewer spaces exist. A `menu` step for a missing space does nothing. Read `.menus` for `enabled`.
- `text` with `\n` in the name field commits the rename. Escape in the field cancels the edit and keeps the panel open.
- A new space opens at scale 1 and translation 0. A switch also resets the viewport.
- The `Desk Pro` row shows `<count> / 20 items`. The count is the number of cards in the current space. No limit applies.
