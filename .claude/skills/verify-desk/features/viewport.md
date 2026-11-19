# Viewport

The user zooms and pans the board. Zoom commands and Fit Content animate the camera. Scroll and pinch change the view at once. Any new pointer input stops a camera animation where it is. A window resize keeps the board center in place. Scale stays between 0.3 and 4.

## Sub-features

- `view-zoom-in` multiplies the scale by 1.25 around the window center (`View > Zoom In`, Command-+).
- `view-zoom-out` divides the scale by 1.25 (`View > Zoom Out`, Command--).
- `view-actual-size` returns to scale 1 around the center (`View > Actual Size`, Command-0).
- `view-fit-content` fits all cards into the window less 64 by 80 points of margin (`View > Fit Content`, Option-Command-9).
- `view-scroll-pan` pans by the scroll deltas.
- `view-pinch` zooms around the pinch point and keeps the canvas point under it.
- `view-pinch-cancel` returns to the scale before the pinch when the pinch is cancelled.
- `view-interrupt` stops the camera animation at its current value on a click.
- `view-resize` keeps the board center fixed and keeps the corner controls in the corners at 520 x 380.

## How to get to it (user POV)

- Use the View menu or the keyboard shortcuts.
- Scroll with a trackpad or a mouse wheel.
- Pinch on a trackpad.
- Click during a zoom animation.
- Resize the window.

## Driving it with run-steps

Preconditions:

- Baseline state. The step file adds the two sample notes.

- **Zoom in with the key.** Run `scripts/run-steps viewport-a steps/viewport.json`. `02-zoom-in-key.json` has scale 1.25 and translation (-135, -90).
- **Zoom out from the menu.** Two `Zoom Out` menu steps without a wait. `03-zoom-out-menu-twice.json` has scale about 0.94 (see Gotchas).
- **Actual Size.** `04-actual-size-key.json` has scale 1 and translation (0, 0).
- **Scroll pan.** Three scroll events, -300 and 200 twice. `05-scroll-pan.json` has translation (-600, 400).
- **Fit Content.** `06-fit-content-key.json` has scale about 2.106. The PNG shows that both cards fill the window.
- **Anchored pinch.** Pinch at (420, 360) with 0.5, 0.5, 0. `07-anchored-pinch.json` has scale 2.25 and translation (-525, -450). The canvas point under (420, 360) stays (420, 360).
- **Cancelled pinch.** A pinch of 0.3 then `cancelled`. `08-cancelled-pinch.json` has scale 2.25 again.
- **Interruption.** `Zoom In`, 100 ms, a click. `09-camera-interrupted.json` has a scale between 2.25 and 2.8125, `cameraAnimating` false, and `targetScale` equal to `scale`.
- **Minimum window.** `resize` to 520 x 380. `10-min-window.json` has window 520 x 380, translation moved by (-280, -170), and the buttons at x = 24, 250, 346, 440. The PNG shows all four corner controls.

## Gotchas

- Wait 1500 ms after a zoom command or Fit Content before a capture. During the animation, `viewport.scale` is the presentation value. A 900 ms wait passed on an idle machine but gave scale 1.24988 with `cameraAnimating` true when a second run shared the machine. Assert `cameraAnimating == false` together with the scale.
- A second zoom command during an animation starts from the presentation value, not from the target. Two quick Command-- presses from scale 1 give about 0.759, not 0.64. This is a known product defect. Put a 1500 ms wait between zoom commands when you need exact values.
- The `scroll` step uses the last pointer position. Click on empty board first, so that the scroll goes to the canvas and not to a control.
- A `menu` step does not fail for a disabled item. Read `.menus` in `dumpState` for the `enabled` value. `Zoom In` is disabled at scale 4, `Zoom Out` at 0.3, and `Fit Content` with no cards.
- Card text is drawn at the 1x backing scale only. At scale 2 or more, the text in a snapshot is soft. This is a product defect, not a snapshot defect.
