# Checklist

The counter button at the bottom right shows onboarding progress as `NN/10`. It opens a checklist sidebar with ten tasks. Only `Create a Note` can complete in this build. The Colors row expands to show help text. Progress persists in user defaults.

## Sub-features

- `checklist-counter` shows `00/10` on a fresh defaults suite and `01/10` after the first note creation.
- `checklist-sidebar` opens a 428 point sidebar from the right with the header "Checklist / Learn the basics".
- `checklist-complete` draws `Create a Note` with a filled box and a strikethrough after a note creation.
- `checklist-colors` collapses and expands the Colors help text on a click.
- `checklist-close` closes the sidebar with the arrow button, Escape, or the counter button.
- `checklist-persist` keeps the progress after a relaunch with the same defaults suite.

## How to get to it (user POV)

- Choose the counter button (`00/10`) at the bottom right.
- Create a note with Command-N, `File > New Note`, or the plus menu.

## Driving it with run-steps

Preconditions:

- A fresh defaults suite. `run-steps` gives one unless you pass `--suite`.

- **Counter at start.** Run `scripts/run-steps checklist-a steps/checklist.json --keep`. `01-counter-start.json` has `checklistCounter` `00/10` in `summarize-state`.
- **Open.** `clickControl` `Checklist`, wait 1000 ms. `02-sidebar-open.json` has focus `ChecklistSidebar` and the label `Checklist / Learn the basics`. The PNG shows ten rows and the Colors help text.
- **Colors.** `clickControl` `Colors`. `03-colors-collapsed.png` shows the Colors row without help text. `03-ax.json` has `Create a Note` as `AXCheckBox` with value `Incomplete`, and `Colors` as an enabled `AXButton`.
- **Complete a task.** `Close checklist`, Command-N. `04-counter-after-note.json` has `checklistCounter` `01/10`. `05-create-note-checked.png` shows `Create a Note` with a filled box and a line through it.
- **Escape.** `06-escape-closes.json` has focus `CornerCapsule` (the counter button).
- **Relaunch.** Run `scripts/run-steps checklist-b steps/restart-check.json --store <kept store> --suite <kept suite>`. `after-restart.json` has `checklistCounter` `01/10`.

## Gotchas

- The counter counts note creation with Command-N, the menu, or the plus menu. `Add Sample Notes` does not count.
- Without `DESK_DEFAULTS_SUITE`, the app writes progress to the real standard defaults. Always use `run-steps`.
- Nine rows (all except Colors) are disabled, `Create a Note` among them. Every row except `Create a Note` has the tooltip "This feature is unavailable in the clone."
- `checklistCounter` is `null` in `summarize-state` while the Settings window is the driver window.
