# Canvas gestures

The user selects, moves, and deletes cards on the board with the pointer and the keyboard. Each move is one undo step. Escape during a drag puts the cards back. Space with a drag pans the board.

## Sub-features

- `gesture-click-select` selects the top card under the pointer on mouse down. A click without movement then opens a note (see `notes.md`).
- `gesture-shift-click` adds or removes a card from the selection, and does not open the note.
- `gesture-lasso` selects every card that the rectangle touches, from a drag that starts on empty board.
- `gesture-group-drag` moves all selected cards by the same offset.
- `gesture-escape-cancel` restores frames and selection when Escape comes before mouse up.
- `gesture-space-pan` pans the board with a drag while Space is held.
- `gesture-select-all` selects every card with Command-A.
- `gesture-delete` deletes the selection with Delete.
- `gesture-undo-move` restores the frames of a move with Command-Z.
- `gesture-click-empty` clears the selection with a click on empty board.

## How to get to it (user POV)

- Click a card. Shift-click more cards. Drag from empty board around cards.
- Drag a selected card. Press Escape before you release.
- Hold Space and drag.
- Press Command-A, then Delete. Press Command-Z.

## Driving it with run-steps

Preconditions:

- Baseline state. The step file adds the two sample notes.

- **Lasso.** Run `scripts/run-steps gestures-a steps/canvas-gestures.json`. A drag from (200, 560) to (800, 200) selects both notes. `02-lasso-selects-both.json` has two IDs in `selection` and `gesture` `idle`.
- **Group drag.** A drag from (420, 360) to (470, 310). `03-group-drag.json` has frames (364, 252) and (604, 189), so both moved by (+50, -50).
- **Undo move.** `04-undo-move.json` has frames (314, 302) and (554, 239) again.
- **Shift-click.** A click on empty board, then Shift-clicks at (420, 360) and (660, 360). `05-shift-click-both.json` has both notes selected and `editor.destination` `board`.
- **Escape cancel.** `mouseDown` (420, 360), two `mouseDragged`, then `06-mid-drag.json` has `gesture` `draggingItems` and the first note at (394, 362). Escape and `mouseUp`. `07-escape-restores.json` has the note at (314, 302) and an empty selection, which was the selection before the press.
- **Space pan.** `keyDown` Space, a drag from (150, 600) to (250, 550), `keyUp` Space. `08-space-pan.json` has viewport translation (100, -50) and unchanged note frames.
- **Select All and Delete.** `09-select-all.json` has two IDs selected. `10-delete-selection.json` has no notes.
- **Undo delete.** `11-undo-delete.json` has both notes with the same IDs, selected.

## Gotchas

- A press on a card that is not selected replaces the selection with that card. To drag a group, select the group first, then drag one of its cards.
- A `drag` step goes straight to the window as one event sequence. A `click` on a note is a press without movement, so it opens the note page. Use `modifiers: ["shift"]` to select without the page.
- Escape restores the selection that existed before the press, not the selection after it.
- The Delete key works only when the canvas or a card has focus. After a Tab past the last note, focus can be on the window (see `keyboard-accessibility.md`).
- Note cards have no resize handles. Do not look for `handles` with a note selected.
