# Download

`Download Selected Items` exports the selected notes as Markdown files into a dated folder in the user Downloads folder. There is no panel and no message. Block styles and marks become Markdown syntax. For an image selection, the same button opens a save panel (see `images.md`).

## Sub-features

- `download-markdown` writes one `.md` file for each selected note to `~/Downloads/Desk Export <MMM d>/`.
- `download-name` names the file from the first 20 letters and digits of the note text, or `Untitled`, and adds ` 2`, ` 3` on a name clash.
- `download-syntax` writes `# ` for display, `## ` for headline, `### ` for subheader, `- ` for list, `- [ ] ` and `- [x] ` for tasks, `**` for bold, `*` for italic, `<u>` for underline, `~~` for strikethrough, `==` for highlight, and `[text](url)` for links.
- `download-mixed` exports only one kind for a mixed selection (see Gotchas).

## How to get to it (user POV)

- Select one or more note cards and choose the download arrow in the bar at the bottom center.

## Driving it with run-steps

Preconditions:

- Baseline state.
- `run-steps` lists the `Desk Export` files in `~/Downloads` before the run. After the run, it copies each new file into `<evidence>/exports/`, lists the original paths in `exports/created-paths.txt`, and deletes only those new files and the folder if it is then empty.

- **Prepare the note.** Run `scripts/run-steps download-a steps/download.json`. The steps create a note with `Trip plan`, a task `book hotel`, and a list item `passport` with `port` in bold. `01-note-selected.json` has the note selected and the action bar visible.
- **Export.** `clickControl` `Download Selected Items`. `exports/Tripplanbookhotelpas.md` contains:

  ```
  # Trip plan
  - [ ] book hotel
  - pass**port**
  ```

- **Mixed selection.** The steps drop `fixtures/photo.png`, press Command-A, and download again. `03-mixed-selection-export.json` has two IDs selected and `savePanelPending` false. `exports/` has a second file `Tripplanbookhotelpas 2.md` and no image.
- **Clean Downloads.** After the run, `ls ~/Downloads | grep "Desk Export"` shows no folder that the run made.

## Gotchas

- CAUTION: Do not run note export without `run-steps`. The app writes into the real `~/Downloads` folder, and no environment variable moves it.
- The folder name has the local date, for example `Desk Export Nov 19`. A run near midnight can write two folders.
- A mixed selection exports only one kind. When the first selected card in z order is an image, only the image goes to the save panel and the notes are not exported. When it is a note, only the notes are exported and the images are skipped. The app shows nothing about the skipped items.
- The action bar does not take clicks while a note page is open. Close the page with `Back to board` before you download.
- An export failure goes to `window.savePanelError` in `dumpState`. The app shows no alert in verification mode.
