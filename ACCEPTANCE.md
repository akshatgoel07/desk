# Native acceptance record

The record contains 48 verified cases and 5 blocked cases.
The shared spec record contains ten verified rows and one blocked row.
The checks use the native executable on branch `ui-polish`.
The date is October 18, 2026.
The evidence column links the screenshots in `docs/acceptance/`.
The repository does not publish the other run artifacts.

The driver sends native events through the window and uses the canvas magnify handler for pinch input.
The driver records each step duration in the script file with the `.timings.json` suffix.
The accessibility dump walks the window accessibility children.
The VoiceOver row checks names, roles, values, selection, and actions through that dump.
This run does not check speech output.

## Shared spec record

| ID | Case | Result | Evidence |
| :--- | :--- | :--- | :--- |
| R01 | Empty, populated, and load error states | verified | [empty.png](docs/acceptance/empty.png), [populated.png](docs/acceptance/populated.png), [loadError.png](docs/acceptance/loadError.png) |
| R02 | Short and long notes at both window sizes | verified | [long520.png](docs/acceptance/long520.png), [long1080.png](docs/acceptance/long1080.png) |
| R03 | Select, drag, lasso, and resize at scales 0.3, 1, and 4 | verified | [scale03.png](docs/acceptance/scale03.png), [scale4.png](docs/acceptance/scale4.png) |
| R04 | Neutral pinch and anchored pinch | verified | Not published |
| R05 | Mouse wheel, trackpad flick, and Space drag | verified | Not published |
| R06 | Gesture cancel, focus loss, and release outside the window | verified | Not published |
| R07 | Create, edit, delete, undo, and redo | verified | Not published |
| R08 | Animation interruption and repetition | verified | Not published |
| R09 | Keyboard, VoiceOver, and Reduce Motion | blocked because System Settings exposes no capturable window | Not published |
| R10 | A canvas with 100 notes | verified | [workloadBefore.png](docs/acceptance/workloadBefore.png), [workloadAfter.png](docs/acceptance/workloadAfter.png) |
| R11 | Quit and reopen after create, edit, move, resize, and delete | verified | Not published |

## Task acceptance cases

| ID | Case | Result | Evidence |
| :--- | :--- | :--- | :--- |
| T1.1 | The initial window explains note creation | verified | [empty.png](docs/acceptance/empty.png) |
| T1.2 | A sample note displays its full short text | verified | [populated.png](docs/acceptance/populated.png) |
| T1.3 | A long note wraps within the card | verified | [long520.png](docs/acceptance/long520.png), [long1080.png](docs/acceptance/long1080.png) |
| T1.4 | Window resize preserves visible content | verified | Not published |
| T1.5 | Both window sizes provide usable controls | verified | Not published |
| T1.6 | Restart adds no sample content | verified | Not published |
| T2.1 | Selection and pan work at all three scales | verified | Not published |
| T2.2 | A neutral pinch preserves scale | verified | Not published |
| T2.3 | A pinch preserves its anchor within two screen points | verified | Not published |
| T2.4 | Fit Content reaches notes outside every window edge | verified | [fitOutside.png](docs/acceptance/fitOutside.png) |
| T2.5 | A new gesture interrupts camera motion | verified | [motionBefore.png](docs/acceptance/motionBefore.png), [motionAfter.png](docs/acceptance/motionAfter.png) |
| T2.6 | Wheel and trackpad input produce no second momentum tail | verified | Not published |
| T3.1 | A fresh note moves without a prior lasso | verified | Not published |
| T3.2 | Three selected notes retain relative positions | verified | Not published |
| T3.3 | An unselected note leaves the selected group fixed | verified | Not published |
| T3.4 | The top overlapping note receives the click | verified | Not published |
| T3.5 | Escape restores a move and a resize | verified | Not published |
| T3.6 | All gesture cases work after pan at all three scales | verified | Not published |
| T3.7 | Release outside the window ends the gesture | verified | Not published |
| T4.1 | Paragraph entry, paste, edit exit, move, and move undo work | verified | Not published |
| T4.2 | Delete and undo restore note identity and content | verified | Not published |
| T4.3 | Text deletion retains the note | verified | Not published |
| T4.4 | Canvas shortcuts preserve ordinary text input | verified | Not published |
| T4.5 | Restart preserves the note workflow | verified | Not published |
| T5.1 | Every visible control performs its named action | verified | Not published |
| T5.2 | Controls fit the minimum window size | verified | [saveError.png](docs/acceptance/saveError.png) |
| T5.3 | Selection remains clear in light and dark appearances | verified | [long520.png](docs/acceptance/long520.png), [noteFocus.png](docs/acceptance/noteFocus.png) |
| T5.4 | Controls remain usable at all three scales | verified | Not published |
| T5.5 | Prototype and reference screenshots use comparable window sizes | verified, `screencapture -l` captures the reference window at 1512 × 950 pt | Not published |
| T6.1 | Pointer input interrupts camera position and scale midway | verified | Not published |
| T6.2 | Each camera transition repeats twenty times | verified | Not published |
| T6.3 | Completion preserves final positions | verified | Not published |
| T6.4 | Cancel leaves no stale transform | verified | Not published |
| T6.5 | New input works during transitions | verified | Not published |
| T6.6 | Spring duration and macOS version accompany the record | verified | Not published |
| T7.1 | Keyboard commands create, edit, select, delete, restore, and navigate notes | verified | Not published |
| T7.2 | VoiceOver data identifies actionable controls and the selected note | verified | Not published |
| T7.3 | Reduce Motion preserves commands, final states, and changes during the session | blocked because System Settings exposes no capturable window | Not published |
| T7.4 | Images and recordings cover gestures and interruptions | verified | Not published |
| X1 | Keyboard focus remains visible through the logical focus order | verified | [controlFocus.png](docs/acceptance/controlFocus.png), [noteFocus.png](docs/acceptance/noteFocus.png), [editorFocus.png](docs/acceptance/editorFocus.png) |
| X2 | Increase Contrast and Reduce Transparency preserve custom visuals | blocked because System Settings exposes no capturable window | [saveError.png](docs/acceptance/saveError.png) |
| X3 | Live input method composition preserves text and focus | blocked because the driver has no live input method composition source | Not published |

## Workload timing limits

The recorded workload creates 100 notes and executes pan, zoom, and group drag.
The group drag retains every note identity and relative offset.
Frame capture adds render and disk work to the same application thread.
The recorded run reaches 663.4 milliseconds for one input step.
A separate drag without frame capture moves all 100 notes.
That debug run records a median dispatch time of 21.8 milliseconds and a maximum of 57.9 milliseconds.
These values describe one run and synchronous event dispatch.
They do not measure frame rate or physical input latency.

## Display preference limits

NSWorkspace reports all three display preferences as false in this session.
The canvas observes the notification for display option changes.
Reduce Motion removes camera movement and commits the camera target when the preference changes.
The note view omits the new note fade with Reduce Motion active.
Increase Contrast raises outline width and border opacity.
Reduce Transparency removes note shadows.
The save error banner uses an opaque system background and a visible border.
The native checks cannot exercise the enabled preferences because System Settings exposes no capturable window.
The defaults command also rejects the preference write.
No preference changed during this run.

## Verification and scope

`swift build` passes.
`swift test --filter 'AccessibilityTests|VerifyScriptTests'` passes three tests, with eight invalid input cases.
`swift test --filter AccessibilityTests` passes after the final accessibility change.
The native gesture assertions pass all 63 cases.
The motion checks pass 82 assertions and ten additional native checks.
All twelve spring durations are finite and below two seconds.
The screenshots and videos retain native content without interpolation.
The key PNG files exist in `docs/acceptance/`.

`ACCEPTANCE.md` replaces the pending status in the spec record for this pass.
Folder and media work remain outside this note acceptance pass, as the spec states.
The checks use native events and state assertions.
The canvas model keeps note identity, order, geometry, and selection.
