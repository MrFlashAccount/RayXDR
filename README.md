<p align="center">
  <img src="assets/readme-hero.png" alt="RayXDR glowing display hero" width="760">
</p>

<h1 align="center">RayXDR</h1>

<p align="center">
  Extra brightness controls for built-in MacBook XDR displays.
</p>

RayXDR is an experimental Swift macOS utility for toggling extra brightness on built-in MacBook XDR displays.

It ships as a pure Swift package with a shared core, CLI, long-lived brightness helper, and menu bar app.

## What It Does

- `Standard` restores normal brightness mode.
- `RayXDR 150%` enables fixed 150% mode.
- `Reset` performs emergency restore and cleanup.
- `status`, `probe`, and `reset` are safe diagnostic commands.

The brightness boost path is experimental and uses an EDR overlay plus gamma adjustment helper.

## Build

```bash
swift build -c release
```

Products:

```text
rayxdr
rayxdr-helper
rayxdr-menubar
```

## Menu Bar App

```bash
./script/run-menubar.sh
```

This builds and opens `.build/release/RayXDR.app`.

## CLI

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

## Release

Local DMG build:

```bash
./script/build-dmg.sh 0.1.0
```

GitHub Release is published manually from Actions:

1. Open `Actions` -> `Release` -> `Run workflow`.
2. Enter `0.1.0` or `v0.1.0`.
3. Run from the branch or commit that should be released.

The workflow creates tag `v0.1.0`, builds `RayXDR-0.1.0.dmg`, and uploads it to the GitHub Release.

## Project Layout

- `Package.swift` - Swift package for all products.
- `Sources/ExtraBrightnessCore` - shared brightness core, probe, EDR overlay, gamma restore, display helpers.
- `Sources/ExtraBrightness` - `rayxdr` CLI entrypoint.
- `Sources/ExtraBrightnessHelper` - long-lived helper process for the EDR/gamma boost.
- `Sources/RayXDRMenuBar` - menu bar app.
- `script/build-menubar-app.sh` - builds `.build/release/RayXDR.app`.
- `script/build-dmg.sh` - builds `dist/RayXDR-<version>.dmg`.
- `script/run-menubar.sh` - builds and opens the menu bar app.
- `script/build_and_run.sh` - local verify helper.

## Safety

This is an experimental utility for built-in MacBook XDR displays. macOS display behavior can change between releases.

Use `rayxdr reset` or the menu bar `Reset` action if the display state looks wrong.

RayXDR is not affiliated with Lunar, DisplayBuddy, BrightXDR, Apple, or any other brightness-control app/vendor. Public references were reviewed only to understand the problem space; branding, UI, assets, and source code are not copied.

## Next Work

1. Improve the menu bar app UX around state refresh and errors.
2. Add optional launch-at-login for the menu bar app.
3. Research brightness-key interception as the next control layer.
