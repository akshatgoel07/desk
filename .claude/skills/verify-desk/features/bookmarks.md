# Bookmarks

The plus menu has an Import row. Its submenu has a "Bookmarks from / Not connected" row that opens a Bookmarks sidebar. No account can connect in this build, so the sidebar shows an empty, not connected state with disabled actions.

## Sub-features

- `bookmarks-import-hover` shows the Import submenu while the pointer is on the `Import` row.
- `bookmarks-open` opens the Bookmarks sidebar from `Bookmarks from`.
- `bookmarks-empty` shows "Not connected / Bookmarks", "No account connected.", and "Bookmarks require an account.".
- `bookmarks-disabled` shows `Refresh bookmarks` and `Add to Space` disabled.
- `bookmarks-close` closes the sidebar with the round arrow button or Escape.

## How to get to it (user POV)

- Choose `Add Content` (plus button). Move the pointer to `Import`. Choose `Bookmarks from` in the submenu.

## Driving it with run-steps

Preconditions:

- Baseline state.

- **Import submenu.** Run `scripts/run-steps bookmarks-a steps/bookmarks.json`. `hoverControl` `Import` after the plus menu opens. `01-import-submenu.png` shows a second panel to the left with `Bookmarks from` and `Not connected`.
- **Open.** `clickControl` `Bookmarks from`. `02-bookmarks-sidebar.json` has focus `BookmarksSidebar` and the labels `Not connected / Bookmarks` and `No account connected.`. The PNG shows the panel on the right.
- **Close with the button.** `clickControl` `Close bookmarks`. `03-closed-by-button.json` has focus `CanvasView`.
- **Close with Escape.** `04-closed-by-escape.json` has focus `CanvasView`.

## Gotchas

- `Import` has no click action. The submenu opens only on hover. Use `hoverControl` `Import`. It closes 150 ms after the pointer leaves, so click `Bookmarks from` right after the hover.
- `clickControl` `Bookmarks from` finds the row even when the submenu is hidden, and the click then does nothing. Prove the open state with `focus` or the labels.
- The plus menu needs 700 ms for its entrance before a hover or a click.
