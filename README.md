# RayXDR

Experimental Swift macOS utility for toggling extra brightness on Sergey's built-in MacBook XDR display.

RayXDR is a pure Swift project: shared core, CLI, long-lived brightness helper, and a menu bar app.

## Disclosure

This is an experimental personal utility for Sergey's own MacBook XDR display. It is not affiliated with Lunar, DisplayBuddy, BrightXDR, Apple, or any other brightness-control app/vendor.

The implementation is based on local research and uses macOS display behavior that can change between macOS releases. Lunar and BrightXDR were reviewed only as public references for understanding the problem space; their branding, UI, assets, and source code are not copied into this project.

Use `rayxdr reset` or the menu bar `Reset` action if the display state looks wrong.

## Layout

- `Package.swift` - Swift package for all products.
- `Sources/ExtraBrightnessCore` - shared brightness core, probe, EDR overlay, gamma restore, display helpers.
- `Sources/ExtraBrightness` - `rayxdr` CLI entrypoint.
- `Sources/ExtraBrightnessHelper` - long-lived helper process for the EDR/gamma boost.
- `Sources/RayXDRMenuBar` - menu bar app.
- `script/build-menubar-app.sh` - builds `.build/release/RayXDR.app`.
- `script/run-menubar.sh` - builds and opens the menu bar app.
- `script/build_and_run.sh` - local verify helper.

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

Menu controls:

- `Standard` - restore normal brightness mode.
- `RayXDR 150%` - enable fixed 150% mode.
- `Reset` - emergency restore and cleanup.
- Inline status block - shows whether RayXDR is running and the current target.

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

`probe`, `status`, and `reset` are safe. `on`, `set`, and `toggle` are experimental and use the EDR/gamma helper.

## Next Work

1. Improve the menu bar app UX around state refresh and errors.
2. Add optional launch-at-login for the menu bar app.
3. Research brightness-key interception as the next control layer.
