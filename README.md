# RayCast Ultra Brightness

Personal Raycast-controlled brightness utility for Sergey's built-in MacBook XDR display.

Current state: experimental test slice. The Swift CLI builds, `probe` works, and `on` starts a small EDR/gamma helper process that can be toggled from Raycast.

## Disclosure

This is an experimental personal utility for Sergey's own MacBook XDR display. It is not affiliated with Raycast, Lunar, DisplayBuddy, BrightXDR, Apple, or any other brightness-control app/vendor.

The implementation is based on local research and uses macOS display behavior that can change between macOS releases. Lunar and BrightXDR were reviewed only as public references for understanding the problem space; their branding, UI, assets, and source code are not copied into this project.

Use `extra-brightness reset` or `Turn Off Extra Brightness` if the display state looks wrong.

## Layout

- `SPEC.md` - original project spec.
- `RESEARCH.md` - local findings and next research checklist.
- `Package.swift` - Swift package for the `extra-brightness` CLI.
- `Sources/ExtraBrightness` - CLI entrypoint, state store, brightness controller boundary.
- `Sources/ExtraBrightnessCore` - probe, EDR overlay, gamma restore, display helpers.
- `Sources/ExtraBrightnessHelper` - long-lived helper process for experimental UltraBrightness.
- `raycast-extension` - primary Raycast API extension.
- `raycast` - legacy Raycast Script Commands fallback.

## Build CLI

```bash
swift build -c release
```

Useful commands:

```bash
.build/release/extra-brightness status
.build/release/extra-brightness status --json
.build/release/extra-brightness probe
.build/release/extra-brightness on 150
.build/release/extra-brightness off
.build/release/extra-brightness reset
.build/release/extra-brightness set 120
.build/release/extra-brightness toggle
```

`probe`, `status`, and `reset` are safe. `on`, `set`, and `toggle` are experimental and use the EDR/gamma helper.

## Raycast API Extension

The primary Raycast integration lives in `raycast-extension`.

```bash
cd raycast-extension
npm install
npm run build
```

`npm run build` first builds the Swift CLI/helper and bundles both binaries into `raycast-extension/assets/bin`, then builds the Raycast extension.

For local Raycast development:

```bash
npm run dev
```

Commands exposed:

- `Toggle Extra Brightness`
- `Turn On Extra Brightness`
- `Turn Off Extra Brightness`
- `Reset Extra Brightness`
- `Extra Brightness Status`

The extension has no user-facing preferences. It uses the bundled CLI/helper and fixed `150%` target.

## Raycast Script Commands

Script Commands are now fallback/legacy. The API extension above is preferred.

Add this directory in Raycast Settings -> Extensions -> Script Commands -> Add Script Directory:

```text
/Users/sergeygarin/Projects/RayCast Ultra Brightness/raycast
```

Commands exposed:

- `Toggle Extra Brightness`
- `Set Extra Brightness Level`
- `Reset Extra Brightness`
- `Extra Brightness Status`

For the current MVP, the API extension `Toggle Extra Brightness` is the intended command.

## Next Work

1. Test `probe`, `on 150`, `off`, and Raycast `Toggle Extra Brightness` on the actual display.
2. If this software route is not good enough, research direct/private control similar to BetterDisplay's built-in XDR direct brightness path.
3. Keep `reset` safe and idempotent before adding any extra controls.
