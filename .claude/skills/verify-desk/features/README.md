# Desk verification map

This folder is the maintained source for verification of the user-facing behavior of Desk. Read this index before you drive the app. Then use the feature file for that feature as the recipe.

## Baseline preconditions

- Build with `swift build`. `scripts/doctor` reports `doctor: OK`.
- Every run uses `scripts/run-steps`, which gives it a fresh store at `DESK_STORE_URL` and a fresh suite at `DESK_DEFAULTS_SUITE`.
- A fresh store has one space, `Space01`, no notes, and the empty canvas state. The checklist counter is `00/10`. Settings are `Sharp corners`, `Mono/Sans`, and `Auto`.
- The window content is 1080 x 720 points, scale 1, translation 0. Window points have their origin at the bottom left.
- Never drive a Desk process that `run-steps` did not start.

## Driving conventions

- Each feature file names its step files in `steps/`. Commands in the feature files run from `.claude/skills/verify-desk/`, for example `scripts/run-steps notes-a steps/notes.json`.
- Start every recipe from the baseline state, unless its preconditions say otherwise.
- Prefer `clickControl` names and `menu` titles over coordinates. The coordinates in the step files are correct only for the baseline geometry.
- Wait for animations before a capture (see Wait times in `SKILL.md`).
- Put `{{EVIDENCE}}` in every capture path.

## Proof and skip reporting

- Capture the action and the result with `checkpoint` steps. Look at the PNG and read the JSON.
- Mutation proof includes a second view: a relaunch with `--store` and `--suite`, a file in `exports/`, or a file at a `savePanel` path.
- Record the feature file and the entry point with each evidence folder.
- Report an unreachable path with the attempted route and the missing prerequisite. Do not report a skipped entry point as verified through a different path.

## Feature entry contract

Each feature file starts with an H1 title and one paragraph about the user-visible behavior. It then has four H2 sections in this order.

1. `Sub-features` lists short IDs with one line for each behavior.
2. `How to get to it (user POV)` lists every user entry point.
3. `Driving it with run-steps` starts with `Preconditions:` and has labeled bullets that pair each user action with a step and an observable result.
4. `Gotchas` lists traps that can waste or invalidate a run.

## Features

- [Canvas states](./canvas-states.md) covers the empty, populated, load error, and save error states, Retry, Dismiss, and sample notes.
- [Notes](./notes.md) covers note creation from three entry points, the note page, delete, undo, redo, and persistence across a relaunch.
- [Note editor](./note-editor.md) covers block triggers, marks, the selection toolbar, the block style menu, tasks, link paste, and text undo.
- [Canvas gestures](./canvas-gestures.md) covers click, Shift-click, lasso, group drag, Escape cancel, Space pan, Select All, and Delete.
- [Viewport](./viewport.md) covers zoom commands, Fit Content, scroll pan, pinch, camera interruption, and window resize.
- [Images](./images.md) covers image drop, image paste, resize handles, and the image save panel.
- [Download](./download.md) covers Markdown export of notes to `~/Downloads` and mixed selections of notes and images.
- [Spaces](./spaces.md) covers New Space, the Spaces menu, Command-number switch, rename, delete with confirmation, and undo.
- [Paywall and routes](./paywall-and-routes.md) covers Desk Pro from Board Settings and the unreachable `desk://` routes.
- [Checklist](./checklist.md) covers the checklist sidebar, the counter, the Colors row, and persistence in the defaults suite.
- [Bookmarks](./bookmarks.md) covers the Import submenu and the unconnected Bookmarks sidebar.
- [Settings](./settings.md) covers the Settings window, its three choices, and persistence in the defaults suite.
- [Keyboard and accessibility](./keyboard-accessibility.md) covers Tab and arrow focus, control focus, the accessibility tree, and note press and pick actions.
