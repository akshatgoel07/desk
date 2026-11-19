# Notes

A user creates a note, opens it as a full note page, types text, returns to the board, and sees the card preview. The user deletes a note, undoes and redoes the delete, and sees the same notes after a relaunch.

## Sub-features

- `note-create-key` creates a note with Command-N.
- `note-create-menu` creates a note with `File > New Note`.
- `note-create-plus` creates a note with `Add Content > Note`.
- `note-open-click` opens the note page with a single click on a note card.
- `note-open-return` opens the note page with Return when one note is selected.
- `note-back` returns to the board with `Back to board` and saves the text.
- `note-delete` deletes the selected notes with the Delete key or `Edit > Delete`.
- `note-undo-redo` restores and removes the deleted note with Command-Z and Shift-Command-Z.
- `note-persist` keeps the notes, their text, and their identity after a relaunch.

## How to get to it (user POV)

- Press Command-N, choose `File > New Note`, or choose `Add Content` (plus button) then `Note`.
- Click a note card. Or select it with Tab and press Return.
- Choose the round arrow button at the top left of the note page.
- Select a note and press Delete. Press Command-Z and Shift-Command-Z.
- Quit and open Desk again.

## Driving it with run-steps

Preconditions:

- Baseline state.

- **Create with the key.** Run `scripts/run-steps notes-a steps/notes.json --keep`. `02-created-cmd-n.json` has one note with frame (469, 270, 140 x 200), empty text, and `"state":"populated"`.
- **Open with a click.** The step clicks (539, 370). `03-editor-typed.json` has `editor.destination` `page`, focus `NoteTextView`, and the buttons `Back to board`, `Board Settings (disabled)`, `Spaces (disabled)`, `Add Content (disabled)`. The PNG shows the large heading `Shopping list` and the body `Milk and eggs`.
- **Back to the board.** `clickControl` `Back to board`. `04-back-on-board.json` has the note text `Shopping list\nMilk and eggs`, the note selected, and the content action bar. The PNG shows the card with a white outline and the counter `01/10`.
- **Create from the menu and the plus menu.** `05-plus-menu.png` shows the plus menu with `Note` and `New Space` enabled. `06-three-notes.json` has three notes at the same frame.
- **Open with Return.** Tab selects the first note and Return opens it. `07-return-opens-editor.json` has `editor.destination` `page`.
- **Delete.** Tab and Delete. `08-deleted.json` has two notes.
- **Undo and redo.** `09-undo-delete.json` has three notes, the restored note has the same ID and text, and it is selected. `10-redo-delete.json` has two notes.
- **Relaunch.** Run `scripts/run-steps notes-b steps/restart-check.json --store <kept store> --suite <kept suite>`. `after-restart.json` has the same two note IDs as `10-redo-delete.json`.

## Gotchas

- A single click on a note opens the note page. A drag of 4 points or more moves the note. Use a lasso, Tab, or Shift-click to select without opening.
- While the note page is open, `notes[].text` in `dumpState` still has the old text. The app saves the text when the page closes. Read `editorContent` for the live text.
- Escape does nothing on the note page. Use `Back to board`, or click outside the text column (more than 96 points left of the column or right of it).
- All new notes go to the same frame. A click at the center hits the top note.
- Note cards have no resize handles. Only image cards have handles (see `images.md`).
- The card preview draws the first block at 1/6 of the 56 pt display size and body text at 1/6 of 16 pt. Body text on a card is about 2.7 pt and is not readable at scale 1. Read text from `dumpState`, not from the PNG.
