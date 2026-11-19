# Canvas states

The canvas tells the user when it is empty, when the note store cannot load, and when a write fails. A load error disables note creation and offers Retry. A save error shows a red banner with Dismiss and keeps the canvas usable.

## Sub-features

- `state-empty` shows "Your canvas is empty" and the plus menu hint on a fresh store.
- `state-samples` adds two known notes through `File > Add Sample Notes`.
- `state-load-error` shows "Cannot load notes", the store error, and `Retry`, and disables `Add Content`, `Spaces`, `Board Settings`, and `New Note`.
- `state-retry` reloads the store and leaves the error state when the store becomes readable.
- `state-save-error` shows the red banner with the store message when a write fails.
- `state-dismiss` removes the save error banner.

## How to get to it (user POV)

- Launch Desk with a new store: the empty state.
- Choose `File > Add Sample Notes`.
- Launch Desk when the store file is damaged: the load error state. Choose `Retry`.
- Make a change when the store cannot be written: the save error banner. Choose `Dismiss`.

## Driving it with run-steps

Preconditions:

- Baseline state for `state-empty` and `state-samples`.
- `steps/canvas-states.json` needs `--broken-store` and a hook that removes the broken file before Retry.
- `steps/canvas-states-save-error.json` needs a seeded store and `--read-only-store`.

- **Load error.** Run `scripts/run-steps states-a steps/canvas-states.json --broken-store --at 1.5 'rm -f "$STORE"'`. `01-load-error.json` has `"state":"loadError"`, the labels `Cannot load notes` and `... isn’t in the correct format.`, `Add Content (disabled)`, and `Retry`. The PNG shows the centered message and the Retry button.
- **Creation blocked.** The same run sends Command-N. `02-create-blocked.json` still has no notes.
- **Retry recovers.** The hook removes the file at 1.5 s, and the run clicks `Retry` at about 2.6 s. `03-retry-recovers-empty.json` has `"state":"empty"` and the label `Your canvas is empty`.
- **Sample notes.** The run chooses `Add Sample Notes`. `04-samples-populated.json` has `"state":"populated"` and the notes `A place for your ideas.` and `A note can hold several paragraphs...`.
- **Seed a store.** Run `scripts/run-steps states-seed steps/seed-samples.json --keep`. Copy the `store=` path from the `kept:` line.
- **Save error.** Run `scripts/run-steps states-b steps/canvas-states-save-error.json --store <kept store> --read-only-store`. `02-save-error.json` has `saveError` `Cannot access the note store. The file couldn’t be saved because you don’t have permission.` and the button `Dismiss`. The note count does not change. The PNG shows the red banner above `Board Settings`.
- **Dismiss.** `03-dismissed.json` has an empty `saveError` and no `Dismiss` button.

## Gotchas

- A `chmod` on the store while Desk runs does not cause a save error. SQLite keeps its open file handle. The store must be read-only at launch, which `--read-only-store` does.
- With a fresh store and `--broken-store`, Retry stays in the load error state until the broken file is gone. Without the `--at` hook, `03` shows `loadError`.
- `Retry` and `Dismiss` always exist as hidden buttons. `clickControl` finds hidden buttons and sends a click to their frame without an error. Check `buttons` in `dumpState` (hidden buttons are not listed) before you trust a click on them.
- `Add Sample Notes` does not count as `Create a Note` in the checklist.
- The `Checklist` button stays enabled in the load error state.
