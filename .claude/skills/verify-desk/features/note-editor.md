# Note editor

The note page is a block editor. The first line is a large display heading. Markdown-style triggers change a block style. Keyboard shortcuts and a toolbar at the bottom of the page add marks to selected text. A block style menu changes the style of one block. Task blocks have a checkbox. A pasted web URL becomes a link. The editor has its own text undo.

## Sub-features

- `editor-heading` makes the first block a display heading and shows the placeholder "a new note" when it is empty.
- `editor-triggers` converts `# `, `## `, `### `, `- `, `* `, `[] `, and `[ ] ` at the start of a block to display, headline, subheader, list, list, task, and task.
- `editor-list-continue` continues a list or task block on Return and ends it with Return on an empty item.
- `editor-marks-keys` toggles bold (Command-B), italic (Command-I), underline (Command-U), and strikethrough (Shift-Command-X) on the selection.
- `editor-toolbar` shows the selection toolbar (Highlight, Bold, Italic, Underline, Strikethrough, Remove format) while text is selected.
- `editor-block-menu` opens the block style menu from the dots control in the left gutter and applies Display, Headline, Subheader, Body, List, or Task.
- `editor-block-keys` sets Body (Command-4), List (Command-L), and Task (Command-T).
- `editor-task-toggle` toggles a task checkbox with a click on the box.
- `editor-link-paste` makes a pasted `http` or `https` URL a link run.
- `editor-text-undo` undoes and redoes editor changes with Command-Z and Shift-Command-Z.
- `editor-card-preview` shows the formatted content on the card after the page closes.

## How to get to it (user POV)

- Open a note (see `notes.md`), then type.
- Select text with Shift and the arrow keys, or with a drag. Use the shortcuts or the toolbar at the bottom of the page.
- Click in the left gutter beside a block, then click the dots control that appears.
- Click a task checkbox.
- Copy a URL and press Command-V in the note.

## Driving it with run-steps

Preconditions:

- Baseline state. The step file creates its own note.

- **Triggers and continuation.** Run `scripts/run-steps editor-a steps/note-editor.json`. The `text` step types `Plan\n[] call the bank\n- first point\nsecond point\n\n## Details\nplain body text`. `01-blocks-from-triggers.json` has the block styles display, task, list, list, body (empty), headline, body.
- **Selection toolbar.** Four Shift-Left keys select `text`. `02-selection-toolbar.png` shows the selection and the toolbar with six buttons at the bottom.
- **Bold with the key.** `03-bold.json` has the last block runs `plain body ` (no marks) and `text` (`bold`).
- **Highlight from the toolbar.** `clickControl` `Note Highlight`. `04-highlight-from-toolbar.json` has `text` with `bold` and `highlight`.
- **Text undo.** Command-Z. `05-text-undo.json` has `text` with `bold` only.
- **Task toggle.** A click at (249, 469) hits the task checkbox. `06-task-click.json` has the task block `checked: true`. The PNG shows a filled box.
- **Block style menu.** A click at (190, 353) in the gutter beside `Details` shows the dots control. `clickControl` `Note block style` opens the menu. `07-block-menu.png` shows six rows, with `Headline` dimmed because it is the current style. `clickControl` `Note style Subheader`. `08-block-style-chosen.json` has `Details` as `subheader`.
- **Link paste.** The `pasteboard` step writes `https://example.com`. Command-Down, Return, Command-V. `09-pasted-link.json` has a new body block `https://example.com`, and `.editorRuns` has a run with `"link":"https://example.com"` and `"underline":1`.
- **Card preview.** `Back to board`. `10-card-preview.json` has the note text with all blocks. `10-card-preview.png` shows the heading `Plan`, a checked box, two bullets, `Details`, the body, and a blue link line on the card.

## Gotchas

- CAUTION: Do not run the `pasteboard` step on a machine where the user needs the clipboard. The step replaces the general system pasteboard.
- A click on a task checkbox does not show the block style control. The control appears only after a click or mouse move in the gutter, 0 to 104 points left of the text column. The driver has no mouse move step, so use a gutter click.
- `clickControl` `Note block style` succeeds even when the control is hidden. The click then lands at a stale frame and nothing opens. Check for the menu with a snapshot or with a `Note style ...` click that fails.
- The text column is 616 points wide and centered. At 1080 points, it starts at x = 232. The first line (display block) is about 70 points high, and each body, list, or task line is about 28 points high. The column top is at about y = 553 in window points.
- Shift-Left sends `"\uF702"` with keyCode 123. The editor does not react to Escape.
- `editorContent` and `editorRuns` exist in `dumpState` only while the page is open.
- The page always has room to scroll past the end, so the scroll indicator shows even for a short note.
