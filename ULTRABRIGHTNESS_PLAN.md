# UltraBrightness Extraction Plan

## Goal

Implement only:

- `rayxdr on` -> built-in MacBook XDR display boosted to fixed target, initially equivalent to about `150%`.
- `rayxdr off` / `reset` -> remove boost, restore normal macOS brightness range.
- Raycast command -> toggle on/off.

No sliders, adaptive brightness, schedules, external displays, menu bar app, onboarding, StoreKit, widgets, hotkeys, battery automation.

## Current Facts

- Local machine: `MacBookPro18,4`, built-in Liquid Retina XDR Display.
- This model is listed as supported by BrightIntosh.
- macOS: `26.3.1`.
- Lunar changelog says macOS `26.3+` blocked its native XDR algorithm and Lunar fell back to tone-mapping XDR logic.

## Researched Sources

- Lunar: https://github.com/alin23/Lunar
- BrightXDR: https://github.com/starkdmi/BrightXDR
- BrightIntosh: https://github.com/niklasr22/BrightIntosh
- nriley brightness CLI: https://github.com/nriley/brightness
- Raycast Script Commands: https://manual.raycast.com/script-commands

## Licensing

- Lunar repo is MIT, but important Pro/Full Range code is hidden/encrypted and the repo says it cannot be built as-is.
- BrightXDR is GPL-3.0.
- BrightIntosh is GPL-3.0.
- `nriley/brightness` is BSD-style, useful for normal 0..1 brightness control, not UltraBrightness.

Decision: do not copy GPL code verbatim unless we explicitly accept GPL for this project. Use BrightIntosh/BrightXDR as behavioral reference, then write our own minimal implementation.

## How The Relevant Approaches Work

### Lunar

Open code shows:

- Apple display brightness uses private-ish `DisplayServices` and `CoreDisplay` calls.
- Normal brightness is still `0.0...1.0`.
- Lunar models full-range brightness as `-1.0...2.0`:
  - `0.0...1.0`: normal brightness
  - `1.0...2.0`: XDR brightness
- It uses `MPDisplay` / MonitorPanel private framework for Full Range XDR state.

Problem: actual `handleFullRange`, `handleEnhance`, `getSupportsFullRangeXDR` implementation is not available in open source. On macOS 26.3+ Lunar changelog also says native XDR algorithm is blocked.

Conclusion: not best base for this MVP.

### BrightXDR

BrightXDR creates a transparent borderless overlay window above the screen. Its Metal view renders EDR/HDR content using:

- `MTKView`
- `CAMetalLayer.wantsExtendedDynamicRangeContent = true`
- `rgba16Float`
- extended color space
- transparent/full-screen overlay

This makes macOS enter EDR/HDR behavior and perceived screen brightness increases.

Problem: old PoC, full-screen overlay, visible Mission Control/Spaces limitations, GPL.

### BrightIntosh

BrightIntosh is closest to our need:

- creates a tiny `1x1` HDR overlay window on supported XDR displays
- waits until `NSScreen.maximumExtendedDynamicRangeColorComponentValue > 1.05`
- captures current gamma table
- applies a gamma multiplier while HDR/EDR is ready
- on disable, closes overlay windows and restores gamma / ColorSync

Core moving parts:

- screen detection: built-in display + model whitelist
- overlay: `NSWindow` + `MTKView` + `CAMetalLayer.wantsExtendedDynamicRangeContent`
- HDR readiness polling: `maximumExtendedDynamicRangeColorComponentValue`
- brightness factor calculation from requested boost and available EDR
- reset: restore gamma and close overlay

Problems for direct copy:

- GPL-3.0
- lots of non-MVP code: UI, StoreKit, widgets, app settings, automation, hotkeys, external XDR handling

Conclusion: best architecture reference, not code source.

## Chosen MVP Architecture

Raycast cannot own long-lived overlay state reliably by itself. A CLI process exits after each command, but the overlay must stay alive while UltraBrightness is on.

Use two binaries/process roles:

1. `rayxdr` CLI
   - Raycast calls this.
   - Commands: `on`, `off`, `toggle`, `status`, `reset`.
   - Starts/stops helper process.
   - Writes small state file.

2. `rayxdr-helper`
   - Long-lived foreground/background agent process.
   - Owns NSApplication event loop.
   - Creates one 1x1 HDR overlay for built-in display only.
   - Applies fixed boost factor target.
   - Handles SIGTERM/SIGINT by restoring gamma and closing overlay.

For MVP, helper can be launched by CLI with `Process` and stored PID. No autostart agent.

## Minimal State

Path:

```text
~/Library/Application Support/ExtraBrightness/state.json
```

Fields:

- `enabled: Bool`
- `targetLevel: Int` (`150`)
- `helperPID: Int?`
- `displayID: UInt32?`
- `mode: "edr-gamma-overlay"`
- `updatedAt`

State is convenience only. `reset` must also find/kill stale helpers by bundle/process marker.

## Commands

```bash
rayxdr on
rayxdr off
rayxdr toggle
rayxdr status
rayxdr reset
```

Mappings:

- `on`: start helper if not running; target fixed `150`.
- `off`: terminate helper; restore gamma; delete state.
- `toggle`: if state/helper alive -> `off`; else `on`.
- `status`: check PID + state + maybe helper heartbeat.
- `reset`: kill any helper process, restore gamma best-effort, delete state.

Raycast MVP:

- one command: `Toggle UltraBrightness`
- optional command: `Reset UltraBrightness`
- optional command: `UltraBrightness Status`

## Implementation Pieces To Build

### Helper

Files:

- `Sources/ExtraBrightnessHelper/main.swift`
- `Sources/ExtraBrightnessCore/BuiltInDisplay.swift`
- `Sources/ExtraBrightnessCore/EDROverlayWindow.swift`
- `Sources/ExtraBrightnessCore/GammaController.swift`
- `Sources/ExtraBrightnessCore/HelperState.swift`

Responsibilities:

- find `NSScreen` where `CGDisplayIsBuiltin(displayID) != 0`
- verify model `MacBookPro18,4`
- verify display can enter EDR
- create 1x1 borderless ignored-mouse overlay at top-left or top-right corner
- configure Metal layer for EDR
- poll `maximumExtendedDynamicRangeColorComponentValue`
- capture gamma table before applying boost
- apply fixed factor for target `150`
- restore gamma on exit

### CLI

Replace `PlaceholderBrightnessController` with process manager:

- start helper with `Process`
- stop helper via stored PID
- check liveness with `kill(pid, 0)`
- call `reset` fallback using process scan if state stale

### Raycast

Keep Script Commands, point them to:

- `rayxdr toggle`
- `rayxdr reset`
- `rayxdr status`

For target simplicity, remove level prompt for now. Hardcode `150`.

## Target Level Mapping

For MVP:

- Off: no overlay, gamma restored, normal macOS brightness range.
- On: overlay active, gamma boost factor approximates `150%`.

Implementation should store level as `150`, but factor should be capped by actual EDR:

```text
requestedBoost = 1.5
maxAllowed = current EDR-derived cap
factor = min(requestedBoost, maxAllowed)
```

Need calibrate visually on Sergey machine after first build. BrightIntosh uses device-dependent caps around `1.59` for M1 14/16 MacBook Pro, so `1.5` is plausible.

## Risks

- EDR overlay approach may clip HDR video while enabled.
- f.lux / gamma-changing apps may conflict.
- Mission Control / Spaces can briefly disable or reveal overlay artifacts.
- macOS thermal/power policy can cap actual brightness.
- Restoring gamma must be robust; `reset` must be easy to run.

## First Implementation Slice

Implemented:

- `rayxdr probe`
- `rayxdr on [level]`
- `rayxdr off`
- `rayxdr toggle`
- `rayxdr reset`
- `rayxdr-helper` long-lived process
- 1x1 EDR Metal overlay
- gamma capture/apply/restore
- Raycast probe/status/toggle/reset wrappers

1. Add helper executable target and shared core target.
2. Implement built-in display detection and model guard.
3. Implement 1x1 EDR overlay helper that stays alive.
4. Implement gamma capture/apply/restore.
5. Wire CLI `on/off/toggle/status/reset`.
6. Update Raycast scripts to toggle/reset/status only.
7. Test manually:
   - `on` visible boost
   - repeated `on` no duplicate overlays
   - `off` restores
   - `reset` restores after stale state
   - Raycast command works
