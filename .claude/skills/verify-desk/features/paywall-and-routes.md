# Paywall and routes

Desk has a Desk Pro paywall. It sells nothing. The user reaches it from Board Settings. The code also parses `desk://` URLs (`authentication`, `paywall`, `restore`, `code`), but no user path delivers such a URL to the debug binary.

## Sub-features

- `paywall-board-settings` presents the Desk Pro alert from `Board Settings > Desk Pro` and closes Board Settings.
- `route-paywall` presents the paywall for `desk://paywall`. Unreachable.
- `route-restore` refreshes StoreKit entitlements for `desk://restore`. Unreachable.
- `route-authentication` and `route-code` only write a log line. Unreachable.

## How to get to it (user POV)

- Choose `Board Settings`, then `Desk Pro`.
- Open a `desk://` URL from another app or a browser. This needs an app bundle that claims the scheme.

## Driving it with run-steps

Preconditions:

- Baseline state.

- **Desk Pro.** Run `scripts/run-steps paywall-a steps/paywall.json`. `01-before.json` has `paywallPresented` false. `02-board-settings.png` shows `Edit Space`, `Delete Space`, and `Desk Pro` with `0 / 20 items`. `03-after-desk-pro.json` has `paywallPresented` true, and the PNG has no Board Settings panel.
- **Routes.** Run `open desk://paywall` in a terminal. Result: `No application knows how to open URL desk://paywall (... kLSApplicationNotFoundErr ...)`, exit 1. Report `route-*` as verified-unreachable.

## Gotchas

- In verification mode, the paywall alert never appears. `PaywallAlert.run` sets `paywallPresented` and returns. A snapshot cannot show the alert. Proof is the flag.
- Prerequisite for `route-*`: an app bundle whose `Info.plist` has `CFBundleURLTypes` with the scheme `desk`, registered with Launch Services. `swift build` makes only a bare executable. Nothing calls `Routes.mountStartup`, so a launch argument cannot deliver a route either.
- Do not register a bundle for `desk://` on a user machine without approval. Launch Services keeps the registration after the run.
- `log.txt` always has `desk StoreKit: Unable to Complete Request`. The product IDs do not exist in any store. This is not a failure.
