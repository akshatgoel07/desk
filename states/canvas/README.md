# Canvas states workbench

This folder is a throwaway workbench for the main canvas board, the window that you see when Desk starts.
It holds the fixtures, a seeder, and a switcher.
The switcher starts the real Desk binary with one seeded state at a time.
Nothing in `Sources/`, `Tests/`, or `Package.swift` is changed.

## How the states get their data

Each state uses only the existing seams of Desk:

- `DESK_STORE_URL` points to a copy of a seeded Core Data store.
- `DESK_DEFAULTS_SUITE` points to a defaults plist in the run folder.
- Error states use a damaged store file or file permissions.

`seed.sh` writes all fixtures into `.fixtures/`.
It compiles `Seeder/main.swift` together with the unchanged Desk sources, so the stores use the real `NoteStore` and `CoreDataStack` code.
The `samples` and `first-note` stores come from the Desk driver (`DESK_VERIFY_SCRIPT`) against a fresh store.
Each launch copies a fixture into a new folder in `.run/`, so your edits never change a fixture.

## States

The state name is the source of truth. Use it with `--state <name>`.

| Group | State | What you see |
|---|---|---|
| Board content | `empty` | A fresh store. "Your canvas is empty". |
| Board content | `first-note` | One note, typed through the driver. |
| Board content | `samples` | The two notes from File > Add Sample Notes. |
| Board content | `typical` | A weekly board with 12 notes: tasks, budget, trip, empty note. |
| Board content | `long-notes` | Notes that overflow their cards, long titles, an unbroken URL. |
| Board content | `tasks` | Task lists, all checked, none checked, mixed. |
| Board content | `images` | Photo cards: landscape, portrait, panorama, EXIF rotated, tiny icon, HEIC. |
| Board content | `workload-100` | 100 cards (87 notes, 13 images) on a large area. |
| Spaces | `spaces` | Five named spaces. Home is open. |
| Spaces | `first-space-empty` | The first space is empty. The other spaces have notes. |
| Storage | `upgraded-store` | A store in the oldest model. Desk migrates it on open. |
| Storage | `save-error` | The store loads, but writes fail. Make an edit to see the banner. |
| Storage | `load-error-corrupt` | A truncated store file. |
| Storage | `load-error-readonly` | A read-only store file without a journal. |
| Storage | `load-error-newer` | A store from a model that this Desk does not know. |
| Storage | `load-error-broken-image` | One image card with damaged bytes. |
| Settings | `round-corners` | The image board with Round corners. |
| Settings | `font-mono` | The weekly board with the Mono font. |
| Settings | `font-sans` | The weekly board with the Sans font. |
| Settings | `theme-light` | The weekly board with the Light theme. |
| Settings | `theme-dark` | The weekly board with the Dark theme. |
| Checklist | `checklist-started` | The checklist counter at 01/10. |

## Missing states

The design implies these states, but the code cannot show them through a seam:

- Pro and free accounts. `PaywallService` limits and `StoreKitService.isProCustomer` are not read by the canvas.
- A limit reached state. No code checks the item or canvas limits.
- A loading state. The store loads synchronously before the first frame.
- Video and web clip cards. `NoteStore.load` reads only notes and images.
- Sticky colors, folders, and stacks. The columns exist, but no code reads them.
- A checklist above 01/10. Only "Create a Note" can complete.
- A save error at launch. Desk does not write at launch, so the banner shows after the first edit.
- Reduce Motion, Increase Contrast, and Reduce Transparency. Desk reads them from the system only.
- A zoomed or panned board. Desk does not save the viewport.

Menus, the note page, and selection are interaction states, not data states. Only the invisible driver can open them, so the switcher does not list them.

## Launch

Run these commands from the repository root.

1. Start the switcher. It builds Desk and seeds the fixtures if they are missing.

   ```bash
   swift states/canvas/switcher.swift
   ```

2. To start at one state, add its name.

   ```bash
   swift states/canvas/switcher.swift --state save-error
   ```

3. To start Desk with one state and no panel, add `--no-panel`.

   ```bash
   swift states/canvas/switcher.swift --state typical --no-panel
   ```

4. To render every state through the driver into PNG files, use `--snapshot`.

   ```bash
   swift states/canvas/switcher.swift --snapshot /private/tmp/claude-501/desk-states-evidence
   ```

5. To write the fixtures again, run `states/canvas/seed.sh`.

`--list` prints the states by group.

## Keys

The keys work when the switcher panel is the key window.

| Key | Action |
|---|---|
| Down or Right | Go to the next state and start Desk again. |
| Up or Left | Go to the previous state and start Desk again. |
| H | Hide or show the panel. |
| Click a row | Go to that state. |
| Command Q | Quit the switcher. This also stops Desk. |

After each switch, the panel becomes the key window again. To use Desk, click the Desk window.
Desk does not save the viewport, so each switch starts at 100 percent zoom.

## Remove

```bash
rm -rf states/
```

The fixtures, run folders, and defaults plists are all in this folder, so this one command removes everything.
