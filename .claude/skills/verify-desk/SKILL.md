---
name: verify-desk
description: Drive the Desk macOS canvas app (Swift, AppKit) the way a user does through its built-in native verification driver, in invisible windows with an isolated note store and defaults suite, and capture PNG plus state JSON evidence. Use it to prove that a Desk feature works (notes, note editor, canvas gestures, viewport, images, export, spaces, checklist, bookmarks, settings, keyboard and accessibility, load and save error states) after a change, or to reproduce a Desk bug.
---

# Verify Desk

Desk is a single-window AppKit app. The primary surface is the canvas window. The app has no server, no network service, and no CLI. The app binary has a built-in driver: when `DESK_VERIFY_SCRIPT` names a JSON array of steps, the app runs the steps in invisible windows and exits after the last step. Each verification run is one short-lived process with its own store. There is no long-lived instance to keep alive.

All paths below are relative to the repository root, unless they start with `/`.

## Launch

The unit of work is one run: one process, one fresh sqlite store, one fresh user defaults suite.

1. Build the binary once per source change.

   ```bash
   swift build
   ```

   The binary is `.build/debug/Desk`. A clean build takes about 25 seconds.

2. Write a step file (see Drive) or use one from `.claude/skills/verify-desk/steps/`.

3. Run it with the helper.

   ```bash
   .claude/skills/verify-desk/scripts/run-steps <run-name> <steps.json> [options]
   ```

   The helper does these things:
   - It makes a fresh store at `<scratch>/<run-name>-<stamp>/store.sqlite` and a fresh suite `desk.verify.<run-name>.<stamp>`.
   - It replaces `{{EVIDENCE}}`, `{{FIXTURES}}`, and `{{STORE}}` in the step file and writes the result to `<evidence>/steps.json`.
   - It starts `.build/debug/Desk` with `DESK_STORE_URL`, `DESK_DEFAULTS_SUITE`, and `DESK_VERIFY_SCRIPT`, and records the PID.
   - It kills that PID only, and only after `--timeout` seconds (default 120).
   - When the driver exits non-zero, it reruns prefixes of the script on copies of the start state and prints `first_failing_step_index` and the step JSON. The driver itself only logs `Desk verify failed: event`.
   - It moves files that the run wrote into `~/Downloads/Desk Export <date>/` into `<evidence>/exports/` (see Evidence).
   - It deletes the scratch store and suite, unless you give `--keep`.

   Options:

   | Option | Use |
   | --- | --- |
   | `--keep` | Keep the fresh store and suite. The helper prints `kept: store=... suite=...`. Use it before a restart proof. |
   | `--store <abs path>` | Run against this store. Use it for the second launch of a restart proof. |
   | `--suite <name>` | Run with this defaults suite. Use it to prove that settings and checklist progress persist. |
   | `--broken-store` | Write a non-sqlite file at the fresh store path. The app starts in the load error state. |
   | `--read-only-store` | With `--store`: make the store files read-only for the run, then restore them. Every write fails with a save error. |
   | `--at <sec> '<bash>'` | Run a shell command while Desk runs. `STORE` and `EVIDENCE` are exported. Example: `--at 1.5 'rm -f "$STORE"'`. |
   | `--timeout <sec>` | Kill limit for the Desk process. |
   | `--no-bisect` | Do not search for the step that failed. The search does not repeat `--at` or `--read-only-store`, so for those runs its result is only a hint. |

Ready means that the first step ran. The driver waits 100 ms after launch, then runs the steps. No log line marks readiness. A `dumpState` with `"state":"empty"` and `"canvasAttached":true` as the first step proves a usable app. From an empty store, the app makes one space, `Space01`, and shows the empty canvas. No seed data exists. Use the `Add Sample Notes` menu step to get two known notes.

Never run the binary without `DESK_STORE_URL`. Without it, the app opens the real user store at `~/Library/Application Support/Desk/store.sqlite`. Never run it without `DESK_DEFAULTS_SUITE`. Without it, settings and checklist progress go into the real `standard` defaults.

Two runs can execute at the same time, because each run has its own store, suite, and evidence folder. The windows are invisible (`alphaValue` 0, ignore mouse events, activation policy prohibited), so a run does not take focus from the user.

## Doctor

Run this first, and again after any run that did something you did not expect.

```bash
.claude/skills/verify-desk/scripts/doctor
```

Doctor checks these items and prints one `PASS` or `FAIL` line for each:
- macOS 15 or newer, the Swift toolchain, and `jq`.
- `.build/debug/Desk` exists and is newer than every file in `Sources/` and `Package.swift`. A `FAIL` here means that the binary is stale. Run `swift build`.
- `DESK_STORE_URL` is not set in your shell.
- No process from an earlier run is alive (it reads the `desk.pid` files in the scratch root).
- The evidence root is writable.
- A smoke run: one `dumpState` against a fresh store. It requires `state == "empty"`, `window.headless == true`, `window.alpha == 0`, `window.processActive == false`, no notes, and an attached canvas.

The smoke run writes only to a fresh scratch store and to `<evidence-root>/doctor-<stamp>/`. Doctor exits 0 only when every line passes.

## Drive

A step file is a JSON array. Each object has a `kind`. The decoder is in `Sources/Desk/VerifyDriver.swift` (`VerifyStep.init(from:)`). An unknown kind or field value makes the whole file fail to decode, and the process exits 1 before the first step.

### Coordinates

- All `x` and `y` values are window points in the content view, with the origin at the bottom left. The default content size is 1080 x 720. The minimum is 520 x 380.
- Snapshots are Retina PNGs at 2x: 2160 x 1440 for the default window. Pixel row = (720 - y) x 2.
- At scale 1 and translation 0 (the start state), canvas points equal window points. `dumpState` gives each note `frame` (canvas points) and `viewFrame` (window points). Click inside `viewFrame`.
- Known geometry at start: `Add Sample Notes` makes notes at canvas (314, 302, 212 x 116) and (554, 239, 212 x 242). `New Note` makes a 140 x 200 note at (469, 270). Every new note goes to the same place, so new notes stack.
- Corner controls: `Board Settings` at (24, 24, 56 x 42), `Checklist` at (810, 24, 84 x 42), `Spaces` at (906, 24, 82 x 42), `Add Content` at (1000, 24, 56 x 42).

### Stable handles

Prefer `clickControl` with a control name over coordinates. `clickControl`, `focusControl`, `hoverControl`, and `pressControl` find the first `NSButton` whose identifier or title equals `name`, in the driver window. Names that exist:

| Surface | Names |
| --- | --- |
| Corner controls | `Board Settings`, `Checklist`, `Spaces`, `Add Content` |
| Plus menu | `Note`, `New Space`, `Import` (hover only), `Bookmarks from` (after hover on `Import`). `Sticky`, `Folder`, `Webclip` are disabled. |
| Content action bar | `Download Selected Items`, `Move to Folder` (disabled), `Color` (disabled, image selections only) |
| Note editor | `Back to board`, `Note Highlight`, `Note Bold`, `Note Italic`, `Note Underline`, `Note Strikethrough`, `Note Remove format`, `Note block style`, `Note style Display`, `Note style Headline`, `Note style Subheader`, `Note style Body`, `Note style List`, `Note style Task` |
| Spaces menu | one button for each space, named after the space, such as `Space01` |
| Board settings | `Edit Space`, `Delete Space`, `Desk Pro`, `Cancel Delete Space`, `Confirm Delete Space` |
| States | `Retry`, `Dismiss` |
| Checklist | `Close checklist`, `Colors` |
| Bookmarks | `Close bookmarks`, `Add to Space` (disabled) |
| Settings window | `Corner style`, `Note font`, `Appearance`, then `Corner style: Round corners`, `Note font: Mono`, `Appearance: Light`, and the other values |

Menu items: use `{"kind":"menu","name":"<exact title>"}`. Titles: `Settings…` (with the ellipsis character), `New Note`, `New Space`, `Add Sample Notes`, `Close Window`, `Undo`, `Redo`, `Cut`, `Copy`, `Paste`, `Delete`, `Select All`, `Zoom In`, `Zoom Out`, `Actual Size`, `Fit Content`, `Space 1` to `Space 9`. The `menu` step does not report whether the item is enabled, and every Desk action has its own guard, so a disabled item does nothing. `dumpState` gives `menus` with the validated `enabled` value for each item. Read it to prove that an item is disabled.

### Step kinds

| Kind | Fields | Effect |
| --- | --- | --- |
| `click`, `doubleClick` | `x`, `y`, `modifiers` | Mouse down and up at a window point. |
| `drag` | `from`, `to`, `steps` (1 to 10000), `modifiers` | Down, `steps` drag events, up. |
| `mouseDown`, `mouseDragged`, `mouseUp` | `x`, `y` | One mouse event. Use them to put a key press or a `dumpState` inside a gesture. |
| `key` | `chars`, `keyCode`, `modifiers` | Key down and key up to the first responder. Command keys go through the main menu first. |
| `keyDown`, `keyUp` | `chars`, `keyCode` | One key event. Use them to hold Space. |
| `text` | `text` | One key down and up for each character. `\n` sends Return. |
| `pasteboard` | `text` | Writes plain text to the general system pasteboard. |
| `scroll` | `dx`, `dy`, `phase`, `momentumPhase`, `precise` | Scroll at the last pointer position. |
| `pinch` | `x`, `y`, `magnification`, `phase` | Calls the canvas magnify handler. Scale becomes scale x (1 + magnification). |
| `menu` | `name` | Runs the main menu item with that title. |
| `clickControl`, `focusControl`, `hoverControl` | `name` | See Stable handles. |
| `pressControl` | `name`, `path` | Mouse down, PNG of the pressed state after 80 ms, mouse up. |
| `axAction` | `name` (note label), `text` (`press` or `pick`) | Accessibility press (focus) or pick (open editor) on a note. |
| `dropImages` | `paths`, `x`, `y` | File URL drop on the canvas. |
| `pasteImage` | `path` | Image paste through Command-V with a private pasteboard. |
| `savePanel` | `path` (optional) | Completes the open save panel at `path`, or cancels it when `path` is absent. |
| `resize` | `w`, `h` | Sets the window content size. |
| `wait` | `ms` | Sleep. |
| `snapshot` | `path` | PNG of the driver window content. |
| `dumpState` | `path` | JSON of the app state. |
| `checkpoint` | `path` | Writes `<path>.png` and `<path>.json`. |
| `axDump` | `path` | JSON of the accessibility tree. |
| `record`, `stopRecord` | `path`, `fps` (15 or 60), `region` | PNG frames in the `path` folder and `frames.json`. |

Driver-only kinds that change the app in ways a user cannot: `appearance`, `textControl`, `deactivate`, `detachCanvas`. Do not use them as proof of a user path.

Key codes and chars that work: Return `36` `"\r"`, Tab `48` `"\t"`, Space `49` `" "`, Delete `51` `"\u007f"`, Escape `53` `"\u001b"`, Left `123` `"\uF702"`, Right `124` `"\uF703"`, Down `125` `"\uF701"`, Up `126` `"\uF700"`, `n` `45`, `z` `6`, `a` `0`, `b` `11`, `v` `9`, `,` `43`, `+` `24`, `-` `27`, `0` `29`, `9` `25`, `1` `18`, `2` `19`. Modifiers: `command`, `shift`, `option`, `control`.

### Wait times

Animations are real. Wait for them before you capture or click:
- Note editor open and close: 800 ms.
- Plus menu entrance: 700 ms.
- Checklist sidebar entrance: 1000 ms.
- Camera moves (zoom commands, Fit Content): 1500 ms. The camera is a spring with a long tail, and a loaded machine slows it. Before you assert an exact scale, check that `viewport.cameraAnimating` is false in the same dump.
- Every other overlay: 300 ms.

The driver adds 30 ms after every step.

### Read state

```bash
.claude/skills/verify-desk/scripts/summarize-state <dumpState.json>
```

It prints the load state, save error, paywall flag, checklist counter, preferences, current space and the space list, notes (short ID, kind, text, frame), selection, focus, gesture, viewport, editor destination and blocks, undo state, save panel state, window title and size, visible buttons (with disabled and focused flags), and visible labels. Use `jq` on the raw file for other fields, for example `.notes[].viewFrame`, `.handles`, `.editorRuns`, `.menus`.

### Feature map

`features/README.md` is the index. Each feature file names its step files in `steps/`. A full proof of a feature drives every entry point that its file lists.

## Evidence

The evidence root is `/private/tmp/claude-<uid>/desk-verify-evidence/` (override with `DESK_VERIFY_EVIDENCE_ROOT`). Each run writes `<root>/<run-name>/`, and the helper refuses a run name that already exists. Each folder contains:
- `steps.json`: the rendered script that ran.
- `steps.json.timings.json`: duration of each step. The driver writes it only when every step passed.
- `log.txt`: app stdout and stderr. `desk StoreKit: Unable to Complete Request` is normal.
- `exit-code` and `meta.txt`: exit status, binary time, git revision, store, suite, and hook.
- `failing-step.txt`: only after a failure, from the bisect.
- `exports/`: Markdown files that the app wrote to `~/Downloads`, plus `created-paths.txt`.
- Every PNG and JSON that the steps named with `{{EVIDENCE}}`.

Proof standards:
- Drive the real user path: menus, keys, clicks on named controls, drops. Do not use the driver-only kinds as proof.
- Capture the action and the result. Put a `checkpoint` before and after each action that you prove.
- Look at the PNG, not only the JSON. The JSON shows the model. The PNG shows what the user sees.
- Prove side effects with a second view. For persistence, relaunch with `--store` and `--suite` and dump state again. For export, read the file in `exports/` or at the `savePanel` path.
- The save panel is not a real panel in verification mode. `savePanel` completes the app callback with a URL. It proves the app write, not the system panel.
- The paywall alert does not appear in verification mode. Proof is `paywallPresented: true` in `dumpState`.

## Cleanup

`run-steps` removes its own store, suite, and scratch folder at the end of each run, unless you gave `--keep`. After `--keep` runs, after a timeout, or after you stop a run by hand, run:

```bash
.claude/skills/verify-desk/scripts/cleanup
```

It kills only processes whose PID is in a `desk.pid` file under the scratch root, and only when the command ends in `/Desk`. It deletes every `desk.verify.*` defaults suite, and every folder in the scratch root (`/private/tmp/claude-<uid>/desk-verify-scratch/`, override with `DESK_VERIFY_SCRATCH_ROOT`). It never touches the evidence root. It prints the evidence folders that remain.

Never kill Desk by process name. The user can have a real Desk session open.

## Helpers

| Script | Invocation |
| --- | --- |
| `scripts/run-steps` | `.claude/skills/verify-desk/scripts/run-steps notes-check .claude/skills/verify-desk/steps/notes.json --keep` |
| `scripts/doctor` | `.claude/skills/verify-desk/scripts/doctor` |
| `scripts/summarize-state` | `.claude/skills/verify-desk/scripts/summarize-state /private/tmp/claude-$(id -u)/desk-verify-evidence/notes-check/04-back-on-board.json` |
| `scripts/cleanup` | `.claude/skills/verify-desk/scripts/cleanup` |

`fixtures/photo.png` and `fixtures/photo-copy.png` are identical 480 x 320 PNGs with four color blocks. A drop or paste of one makes a 320 x 213.33 image card.

Restart proof, end to end:

```bash
S=.claude/skills/verify-desk
$S/scripts/run-steps notes-a $S/steps/notes.json --keep
$S/scripts/run-steps notes-b $S/steps/restart-check.json --store <store from the kept line> --suite <suite from the kept line>
$S/scripts/summarize-state /private/tmp/claude-$(id -u)/desk-verify-evidence/notes-b/after-restart.json
$S/scripts/cleanup
```

Write ad hoc step files in your own scratch folder, not in the scratch root. `cleanup` deletes the scratch root.
