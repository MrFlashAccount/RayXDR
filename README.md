# RayXDR

Personal Raycast-controlled extra brightness utility for Sergey's built-in MacBook XDR display.

Current state: experimental test slice. The Swift CLI builds, `probe` works, and `on` starts a small EDR/gamma helper process that can be toggled from Raycast.

## Disclosure

This is an experimental personal utility for Sergey's own MacBook XDR display. It is not affiliated with Raycast, Lunar, DisplayBuddy, BrightXDR, Apple, or any other brightness-control app/vendor.

The implementation is based on local research and uses macOS display behavior that can change between macOS releases. Lunar and BrightXDR were reviewed only as public references for understanding the problem space; their branding, UI, assets, and source code are not copied into this project.

Use `rayxdr reset` or `Turn Off RayXDR` if the display state looks wrong.

## Layout

- `SPEC.md` - original project spec.
- `RESEARCH.md` - local findings and next research checklist.
- `Package.swift` - Swift package for the `rayxdr` CLI.
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
.build/release/rayxdr status
.build/release/rayxdr status --json
.build/release/rayxdr probe
.build/release/rayxdr on 150
.build/release/rayxdr off
.build/release/rayxdr reset
.build/release/rayxdr set 120
.build/release/rayxdr toggle
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

One-command local install/import:

```bash
./script/install-local.sh
```

This starts Raycast dev mode and keeps it running in the terminal while testing.

Commands exposed:

- `Toggle RayXDR`
- `Turn On RayXDR`
- `Turn Off RayXDR`
- `Reset RayXDR`
- `RayXDR Status`

The extension has no user-facing preferences. It uses the bundled CLI/helper and fixed `150%` target.

## Raycast Script Commands

Script Commands are now fallback/legacy. The API extension above is preferred.

Add this directory in Raycast Settings -> Extensions -> Script Commands -> Add Script Directory:

```text
/Users/sergeygarin/Projects/RayXDR/raycast
```

Commands exposed:

- `Toggle RayXDR`
- `Set RayXDR Level`
- `Reset RayXDR`
- `RayXDR Status`

For the current MVP, the API extension `Toggle RayXDR` is the intended command.

## Next Work

1. Test `probe`, `on 150`, `off`, and Raycast `Toggle RayXDR` on the actual display.
2. If this software route is not good enough, research direct/private control similar to BetterDisplay's built-in XDR direct brightness path.
3. Keep `reset` safe and idempotent before adding any extra controls.
