# Desk UI and animation scope

Scope date: October 17, 2026.

## Outcome

The first usable version supports one local canvas with editable notes. A user can create, select, move, resize, and delete notes. The user can undo those actions, pan the canvas, and change zoom without losing the pointer target.

This document scopes future UI and animation work. All dimensions, durations, and gesture rules below are proposed acceptance targets. They are not measurements of the reference app.

Visible content and direct interaction precede decorative motion.

## Current evidence

I launched a copy of the existing executable through a temporary app bundle. The source files remained unchanged. The window displayed an empty canvas, an empty switcher, and a clipped toolbar. Accessibility exposed window controls but no canvas controls.

I also inspected the installed reference app without changing its content. Its interface shows readable cards, compact controls near the lower corners, and native application menus. This is a visual reference only. This audit did not establish exact motion parity.

The remaining findings come from source inspection. The blank canvas prevents live checks of item gestures and item animations.

| Before | Required result | Evidence |
| --- | --- | --- |
| Startup creates no items and never calls the demo sequence. | Show an actionable empty canvas or actual items. | [Shell.swift:104](Sources/Desk/Shell.swift), [Unboxing.swift:31](Sources/Desk/Unboxing.swift) |
| Item layers start with zero bounds and lack a layout pass. Note text has height 1. | Show readable cards at their actual dimensions. | [CanvasItems.swift:54](Sources/Desk/CanvasItems.swift), [CanvasItems.swift:109](Sources/Desk/CanvasItems.swift) |
| Zoom changes the host frame without a content scale. Pointer and item coordinates differ after pan. | Use one viewport transform and its inverse. | [CanvasView.swift:46](Sources/Desk/CanvasView.swift) |
| The initial neutral pinch formula produces 2.95 from scale 1. | A neutral pinch preserves scale. | [Drivers.swift:148](Sources/Desk/Drivers.swift), [CanvasView.swift:95](Sources/Desk/CanvasView.swift) |
| A card press never selects the card. Drag only moves selected views. | A fresh card moves on the first drag. | [Drivers.swift:76](Sources/Desk/Drivers.swift) |
| Spring helpers add animations without final model values. | Each animation ends at its requested value without a return jump. | [SpringRunner.swift:37](Sources/Desk/SpringRunner.swift) |
| Toolbar and switcher classes only draw shapes. | Every visible control has a label, action, and disabled state. | [Shell.swift:171](Sources/Desk/Shell.swift) |
| Folder views have no caller or item kind. | Keep folder controls absent until folder behavior exists. | [CanvasItems.swift:4](Sources/Desk/CanvasItems.swift) |

## Shared contracts

The canvas owns item identities, geometry, order, and selection. Each item view displays that state. Views must not become an independent source of saved geometry.

The viewport owns scale and translation. Pointer conversion, lasso, resize handles, creation positions, and hit detection use the same conversion functions. Viewport movement does not change item coordinates.

Each gesture records its initial state. Preview updates change the visible state immediately. Completion creates one undo action. Cancellation restores the initial state. Text entry takes priority over canvas shortcuts.

Motion displays a state change. Motion never determines selection, item ownership, or saved values. Reduce Motion changes the transition, not the final state.

## Task 1. Make the first canvas visible

Priority: required. Owner: UI. Dependencies: none for the empty state and card layout.

Files: `Shell.swift`, `CanvasItems.swift`, `CanvasView.swift`, and the startup entry in `Unboxing.swift`.

1. Add explicit empty, populated, and load error states to the initial canvas.
2. Add a visible New Note action to the empty state.
3. Show a retry action when the local load fails.
4. Add a layout pass for the card container, content, shadow, and text.
5. Size the note text from its content area and current card size.
6. Set text and image layer resolution from the window backing scale.
7. Keep card corners, selection outlines, and shadows consistent after resize.
8. Reserve a separate overlay layer for selection and resize handles.
9. Remove the fake caret from static note previews.
10. Keep demo content behind an explicit sample action.

Acceptance: The initial window explains how to create a note. A sample note displays its full short text. A long note wraps within the card. A card retains visible content after window resize. Repeat at 520 by 380 and 1080 by 720 window sizes. No demo appears again without a user action.

The New Note action connects in Task 4. The local load and retry actions depend on D1 below. Do not simulate a successful load after an error.

## Task 2. Repair canvas geometry and navigation

Priority: required. Owner: canvas interaction. Dependencies: Task 1 visible cards.

Files: `CanvasView.swift` and the pinch helper in `Drivers.swift`.

1. Replace host frame resizing with one explicit viewport transform.
2. Add inverse conversions between viewport points and canvas points.
3. Use those conversions for all item and overlay geometry.
4. Apply pinch changes around the pointer location.
5. Preserve the canvas point below that pointer.
6. Keep scale within the existing limits of 0.3 and 4.
7. Reset pinch state on completion, cancellation, and window deactivation.
8. Permit pan in all directions.
9. Consume native scroll momentum once.
10. Remove the redundant scroll timer with no callback.
11. Add camera commands for Zoom In, Zoom Out, Actual Size, and Fit Content.
12. Keep toolbar dimensions independent of canvas zoom.

Acceptance: Repeat selection and pan at 0.3, 1, and 4 scale. A neutral pinch preserves scale. A pinch keeps its anchor within two screen points. Fit Content reaches items outside every window edge. A new gesture interrupts existing camera motion. Mouse wheel and trackpad input do not create a second momentum tail.

Do not keep the current pinch formula. Its current inputs do not produce usable behavior.

## Task 3. Complete selection, drag, and resize

Priority: required. Owner: canvas interaction. Dependencies: Task 2.

Files: `Drivers.swift`, `CanvasView.swift`, `CanvasItems.swift`, and the redundant click recognizer in `Shell.swift`.

1. Select the top visible item on click.
2. Preserve a selected group when the user presses one group member.
3. Toggle one item with Shift click.
4. Clear selection on an empty click.
5. Start item drag after four screen points of movement.
6. Move selected items from their recorded initial positions.
7. Select intersecting items with an empty space lasso.
8. Make Shift lasso add items to the initial selection.
9. Use Space drag for direct canvas pan.
10. Remove the invisible corner pan mode.
11. Restore initial geometry when Escape cancels a gesture.
12. Clear gesture state when the window loses focus.
13. Add visible corner resize handles for a single selected note.
14. Keep resize handles at a fixed screen size across zoom levels.
15. Enforce a proposed minimum note size of 160 by 100 canvas points.
16. Add one undo action for each completed move or resize.
17. Allow embedded text controls to receive pointer events.

Acceptance: A fresh note moves without prior lasso selection. Three selected notes retain their relative positions. An unselected note does not move another selected group. The top overlapping note receives the click. Escape restores a move and a resize. Repeat after pan and at all three zoom levels. Release outside the window must not leave a stuck gesture.

Group resize, rotation tools, alignment tools, and automatic snapping remain outside this task.

## Task 4. Provide the minimum useful note workflow

Priority: required. Owner: note UI. Dependencies: Tasks 1 and 3.

Files: `Shell.swift`, `CanvasItems.swift`, and item command entry points in `CanvasView.swift`. A small native note editor file is acceptable.

1. Create a note through the visible New Note control and Command N.
2. Place the note at the visible canvas center.
3. Select the new note and focus its native text editor.
4. Enter note edit mode on double click or Return.
5. Use a native text editor for selection, caret, clipboard, and input methods.
6. Route Delete to text while the editor owns focus.
7. Route Delete to selected notes while the canvas owns focus.
8. Add Command A, Undo, and Redo through the responder chain.
9. Restore deleted notes with their identity, content, geometry, and order on undo.
10. Show a visible save error through the D1 result contract.

Acceptance: Create a note, enter several paragraphs, paste text, exit edit mode, move the note, and undo the move. Delete the note and restore it with undo. Text deletion never removes the card. Canvas shortcuts never consume ordinary text input. Restart verification remains blocked until D1 works.

Rich text, link previews, media imports, and multiple canvases remain outside this task.

## Task 5. Replace placeholder chrome and finish card appearance

Priority: required. Owner: UI. Dependencies: Tasks 2 and 4 command contracts.

Files: `Shell.swift` and visual properties in `CanvasItems.swift`.

1. Replace drawn toolbar placeholders with native controls.
2. Show New Note, zoom percentage, zoom controls, and Fit Content.
3. Replace the fake switcher with one plain canvas title.
4. Add native application, File, Edit, View, and Window menus.
5. Use constraints that respect the titlebar and window controls.
6. Use compact control groups near the lower window corners, as the inspected original does.
7. Keep a proposed 16 point inset from the usable content edges.
8. Use system colors, system fonts, and suitable SF Symbols.
9. Add distinct normal, hover, pressed, disabled, and keyboard focus states.
10. Add tooltips that identify commands and shortcuts.
11. Apply consistent note padding, readable text, restrained shadows, and visible selection contrast.
12. Remove controls for commands that the prototype cannot execute.

Acceptance: Every visible control performs its named action. No control clips or overlaps at the minimum window size. The selected note remains clear over light and dark note colors. The toolbar stays usable at every zoom level. Screenshots compare the prototype and original at comparable window sizes without a claim of pixel parity.

## Task 6. Repair animation completion and add restrained feedback

Priority: required after direct interaction works. Owner: motion. Dependencies: Tasks 1 through 5 for integration.

Files: `SpringRunner.swift`, `SpringCore.swift`, and motion call sites in `CanvasItems.swift`, `Shell.swift`, and `Unboxing.swift`.

1. Read the visible presentation value before each animation replacement.
2. Commit the final model value with implicit actions disabled.
3. Replace the prior animation for that property.
4. Define cancellation as either restore initial state or retain current state for each caller.
5. Remove fill mode as a substitute for final model values.
6. Validate finite spring durations on the supported macOS version.
7. Keep pointer drag, lasso, resize, and text entry immediate.
8. Use opacity transitions for ordinary control feedback.
9. Limit proposed control feedback to 100 through 160 milliseconds.
10. Limit proposed small popover transitions to 125 through 200 milliseconds.
11. Anchor any popover motion to its actual control.
12. Keep restored items visible immediately.
13. Use an optional brief opacity transition for a newly created note.
14. Stop timers and animations when their views leave the window.

Acceptance: Interrupt position and scale transitions halfway. Repeat each transition twenty times. No item jumps to its old position after completion. No stale transform remains after cancellation. New input works during every transition. The animation owner records actual spring duration and the macOS version before accepting the constants.

The duration targets are proposed UI budgets, not measured timings of the reference app. AppKit layer rules govern the implementation. Web CSS performance rules do not directly govern this native app.

## Task 7. Complete accessibility and the native acceptance pass

Priority: required. Owner: accessibility and verification. Dependencies: Tasks 1 through 6.

Files: the UI files above. This owner integrates small accessibility fixes after the other owners finish.

1. Expose names, roles, values, and actions for controls and notes.
2. Add a visible keyboard focus indicator.
3. Keep a logical focus order between controls, canvas, notes, and the editor.
4. Respect the macOS Reduce Motion preference and changes during the session.
5. Remove decorative movement when Reduce Motion is active.
6. Preserve direct user movement and final states with Reduce Motion active.
7. Check Increase Contrast and Reduce Transparency where custom visuals use them.
8. Record the acceptance cases below against the native executable.
9. Report each blocked case with its specific missing dependency.

Acceptance: A keyboard user can create, edit, select, delete, restore, and navigate notes. VoiceOver identifies actionable controls and the selected note. Reduce Motion preserves all commands and outcomes. The owner records before and after images plus short recordings for gesture and interruption cases.

## Delivery order and ownership

Complete Tasks 1, 2, and 3 in that order. Complete Task 4 before Task 5 integration. The motion owner can repair the isolated runner earlier, but integrates Task 6 after the interaction contracts stabilize. Task 7 closes the acceptance pass.

Several tasks share files. Assign one active writer per shared file. For one implementer, execute the tasks sequentially. For several implementers, agree on command and coordinate contracts first, then integrate changes through one owner.

## D1. Local data prerequisite outside this polish scope

The current source does not load saved items into the canvas. `CanvasStore.persist` inserts rows but provides no item update operation. `CanvasItemView.baseItem` is immutable. `commitItemFrames` only schedules a context save. It does not write changed view geometry into an item row.

Evidence: [Unboxing.swift:104](Sources/Desk/Unboxing.swift), [CanvasItems.swift:43](Sources/Desk/CanvasItems.swift), [CanvasView.swift:74](Sources/Desk/CanvasView.swift).

The UI needs a local item contract for load, insert, update, delete, and restore by stable identity. It also needs success and error results. The data owner must preserve note text, geometry, order, and identity across restart.

The UI owner can complete session behavior against an in memory implementation. That result is a session prototype. A usable local app claim requires D1 and the restart cases below. This scope does not include a database redesign, cloud sync, authentication, or purchases.

## Deferred folder and media work

Folder polish cannot repair the current unreachable folder code. A later folder task needs an item kind, creation, open, close, removal, and persistent membership first.

After those prerequisites, the folder owner can scope hover feedback, source to destination motion, interruption, and lid effects. One fit formula must serve previews and drops. Preview offsets must remain stable. A canceled drop must retain its source item. A completed drop must not create a duplicate.

Image import, video controls, web clips, social providers, export, and StoreKit remain outside this pass. Do not expose placeholder commands for them.

## Acceptance record

All implementation acceptance cases remain pending. The audit verified only the current blank window, clipped toolbar, and missing accessible canvas controls.

| Case | Required evidence | Owner |
| --- | --- | --- |
| Empty, populated, and load error states | Native screenshots with usable controls | Task 1 and D1 |
| Short and long notes at both window sizes | No clipped text or chrome | Tasks 1 and 5 |
| Select, drag, lasso, and resize at 0.3, 1, and 4 scale | Pointer alignment and unchanged group offsets | Tasks 2 and 3 |
| Neutral pinch and anchored pinch | Stable scale and stable pointer anchor | Task 2 |
| Mouse wheel, trackpad flick, and Space drag | Immediate input and no duplicate momentum | Tasks 2 and 3 |
| Gesture cancel, focus loss, and release outside window | Restored or committed state without a stuck gesture | Task 3 |
| Create, edit, delete, undo, and redo | Correct focus and restored item identity | Task 4 |
| Animation interruption and repetition | No jump, stale transform, or return to the old state | Task 6 |
| Keyboard, VoiceOver, and Reduce Motion | Equivalent commands and final states | Task 7 |
| A canvas with 100 notes | A recording of pan, zoom, and group drag with no long input stalls | Tasks 2, 3, and 7 |
| Quit and reopen after create, edit, move, resize, and delete | Stable content without duplicates | D1 and Task 7 |

The 100 note case is a proposed acceptance workload. This audit did not measure performance. A build alone does not close any interaction row.
