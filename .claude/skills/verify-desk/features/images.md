# Images

The user adds images to the board with a file drop or a paste. Each image becomes a card at most 320 points on its long side. An image card has eight resize handles that keep the aspect ratio. The content action bar can save the image to a file through a save panel.

## Sub-features

- `image-drop` adds one card for each dropped image file, offset by 24 points, with the top-left corner at the drop point, and selects them.
- `image-paste` adds a pasted image centered in the window and selects it.
- `image-handles` shows eight handles when exactly one image card is selected.
- `image-resize` resizes from a corner handle and keeps the aspect ratio, with a minimum of 32 points on the short side.
- `image-save` opens a save panel from `Download Selected Items` with one image selected and writes the original bytes.
- `image-save-cancel` writes nothing when the save panel is cancelled.
- `image-action-bar` shows `Download Selected Items`, a disabled `Color`, and a disabled `Move to Folder` for an image selection.

## How to get to it (user POV)

- Drag image files from Finder onto the board.
- Copy an image and press Command-V on the board.
- Select one image card and drag a corner.
- Select an image card and choose the download arrow in the bar at the bottom center.

## Driving it with run-steps

Preconditions:

- Baseline state.
- `fixtures/photo.png` and `fixtures/photo-copy.png` (480 x 320).

- **Drop two files.** Run `scripts/run-steps images-a steps/images.json`. `01-dropped-two.json` has two `image` cards of 320 x 213.33 at (200, 386.67) and (224, 362.67), `imageBytes` 1355, both selected, and `handles` empty.
- **Select one.** A click on empty board and a click at (300, 450) select the top card (the second one). `02-image-selected-handles.json` has one ID selected and eight `handles`. The bottom-right handle is centered on (544, 362.67).
- **Corner resize.** A drag from (544, 362.67) to (624, 316). `03-corner-resize.json` has the second card at about 396.9 x 264.6 with its top-left corner fixed. Width / height stays 1.5.
- **Paste.** `pasteImage` with `fixtures/photo.png`. `04-pasted-centered.json` has a third card at (380, 253.33), centered at (540, 360), and selected. The PNG shows the action bar with three buttons.
- **Save.** `clickControl` `Download Selected Items`. `05-save-panel-pending.json` has `window.savePanelPending` true. `savePanel` with `{{EVIDENCE}}/exported-photo.png`. Run `cmp <evidence>/exported-photo.png fixtures/photo.png`. The files are identical.
- **Cancel.** A second download and `savePanel` without `path`. `06-after-export-and-cancel.json` has `savePanelPending` false and no new file.

## Gotchas

- Overlapped cards: the click and the handle hit test use the top card. Read `handles` from `dumpState` after the selection, and start the drag on a handle frame. A drag that starts inside the card moves it.
- Handles exist only for a single selected image. Note cards never have handles.
- `savePanel` without an open panel fails the step. Download opens a panel only when the first selected card (in z order) is an image.
- The save panel in verification mode is a stand-in. The step proves the app callback and the file write, not the system panel UI.
- `pasteImage` uses a private pasteboard, so it does not change the user clipboard. The `pasteboard` text step does change it.
- Images do not count toward the checklist. `Add an Image` stays unavailable.
