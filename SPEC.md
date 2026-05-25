# Extra Brightness Raycast Utility Specification

## 1. Title

Extra Brightness: minimal Raycast-controlled MacBook XDR brightness utility.

## 2. Objective

Build a one-machine MVP/PoC that lets Sergey temporarily push the built-in MacBook XDR display above the normal macOS 100% brightness cap, control it from Raycast, and safely restore normal brightness.

Primary implementation instruction for Codex: first produce a short research note from local inspection, then implement the smallest working MVP. Do not broaden scope before the MVP works.

## 3. Product constraints / scope

- Personal utility for Sergey’s current MacBook and current macOS only.
- Optimize for a one-day MVP/PoC, not a general product.
- Built-in display only.
- Raycast is the UX layer.
- Swift CLI/helper is the core brightness control layer.
- Prefer the smallest reliable path inspired by Lunar-style XDR/full-range behavior or a BrightXDR-style EDR overlay approach if direct full-range control is not viable.
- No polished app shell, menu bar app, onboarding, settings UI, installer, updater, analytics, telemetry, or external-display support.
- Keep code understandable and reversible.

## 4. Non-goals

- Do not ship a universal macOS app.
- Do not build a SwiftUI app UI.
- Do not support external monitors in the MVP.
- Do not support arbitrary hardware/macOS versions.
- Do not implement adaptive brightness, schedules, ambient-light logic, app presets, per-display curves, DDC/CI, HDR media workflows, or multi-monitor state.
- Do not copy Lunar branding, icons, product names, images, assets, UI, or paid-feature behavior wholesale.
- Do not claim App Store readiness or public distribution.

## 5. Target user/environment

- User: Sergey.
- Machine: Sergey’s current MacBook with Apple XDR-capable built-in display.
- OS: inspect locally before coding; target only the currently installed macOS version.
- Launcher: Raycast installed locally.
- Development assumptions: Swift available through Xcode Command Line Tools or Xcode; shell scripts can be indexed by Raycast Script Commands.

## 6. Proposed MVP architecture

### Swift CLI/helper as core

Create a tiny Swift command-line tool, tentatively `extra-brightness`, with subcommands for status, set, toggle, and reset. It owns all brightness-specific logic and exposes a stable CLI surface for Raycast wrappers.

The helper should research and choose one viable local implementation route:

1. Direct display brightness/full-range route if safe and available on Sergey’s macOS/hardware.
2. EDR/HDR overlay/window route if direct control is not viable.
3. Explicit unsupported result if neither route can be made safe in the one-day MVP.

Do not hard-code unverified private API claims in the implementation plan. Treat private/system display APIs as a research target and document what was verified locally.

### Raycast wrapper/script commands as UX

Use Raycast Script Commands for the MVP. Each Raycast command should call the Swift helper and print short human-readable output for compact/silent modes. A full Raycast TypeScript extension is optional later, not part of the MVP unless Script Commands prove insufficient.

Raycast script commands are appropriate because Raycast can run local scripts in a few keystrokes/hotkeys and supports Swift-backed scripts or shell wrappers that invoke compiled Swift helpers.

### Optional tiny state/config

Only add state if needed for safe toggling/restoration. If needed, store a small JSON file under a user-local app support path, for example:

- `~/Library/Application Support/ExtraBrightness/state.json`

Possible state fields:

- `enabled: Bool`
- `lastRequestedLevel: Int`
- `previousSystemBrightness: Double?`
- `implementationMode: "direct" | "overlay"`
- `updatedAt: ISO-8601 string`

State must not be required for `reset` to restore a safe normal mode.

## 7. Commands / UX

### Toggle Extra Brightness

Raycast command: `Toggle Extra Brightness`

Expected behavior:

- If off, enable the last selected extra-brightness level or a conservative default such as `120`.
- If on, restore normal brightness mode.
- Idempotent and safe under repeated hotkey presses.
- Output examples: `Extra Brightness on: 120%` or `Extra Brightness off: normal mode restored`.

Suggested CLI:

- `extra-brightness toggle`

### Set Extra Brightness Level or presets

Raycast command: `Set Extra Brightness Level`

Expected behavior:

- Accept either numeric levels or named presets.
- Suggested numeric presets: `100`, `120`, `140`, `160`.
- Suggested named presets: `low`, `medium`, `high`, `max`.
- Clamp to researched safe bounds for Sergey’s machine.
- Treat `100` as normal brightness/no extra mode unless research proves a better model.

Suggested CLI:

- `extra-brightness set 120`
- `extra-brightness set medium`

### Reset to normal brightness

Raycast command: `Reset Extra Brightness`

Expected behavior:

- Always restore normal macOS brightness/display mode as safely as possible.
- Must work even if state file is missing, stale, or corrupt.
- Should remove/disable overlay windows if the overlay route is used.
- Output example: `Normal brightness restored`.

Suggested CLI:

- `extra-brightness reset`

### Status

Raycast command: `Extra Brightness Status`

Expected behavior:

- Report implementation mode, enabled/off state, requested level, and any known unsupported reason.
- Plain output is enough for Raycast compact mode.
- JSON output is useful for debugging and future extension UI.

Suggested CLI:

- `extra-brightness status`
- `extra-brightness status --json`

## 8. Technical research tasks for Codex before coding

Before implementation, create a short `RESEARCH.md` or top-of-PR note covering:

1. Current machine/OS inspection
   - Run local inspection for macOS version, Mac model, display type, and whether the built-in display reports XDR/EDR capability.
   - Keep the MVP target pinned to those findings.

2. Raycast local conventions
   - Inspect Sergey’s local Raycast Script Commands directory/conventions if present.
   - Confirm metadata header format, command modes, arguments, and where scripts should live.
   - Prefer the existing local style over inventing a new layout.

3. Lunar/BrightXDR approaches and license
   - Inspect Lunar’s relevant public source and license before borrowing any implementation detail.
   - Inspect BrightXDR as a PoC/reference, including its GPL-3.0 license and EDR overlay approach.
   - Record what can be used as reference vs copied code.

4. Safe/private API route or viable fallback
   - Identify whether there is a safe enough direct route for built-in XDR/full-range brightness on Sergey’s exact macOS.
   - If private APIs are needed, document the risk and keep the implementation isolated behind the Swift helper.
   - If direct route is not viable in one day, evaluate the EDR overlay fallback.
   - Do not ship both approaches unless one is clearly selected for MVP and the other remains documented fallback.

## 9. Implementation requirements

- Swift CLI/helper is the core.
- Raycast Script Commands are the default UX.
- Built-in display only.
- No external display support in MVP.
- No daemon/background service unless research proves it is required for the selected implementation route.
- No app UI unless the selected overlay implementation strictly requires a minimal helper process/window; even then, keep it invisible/minimal and controlled by CLI/Raycast.
- Commands must be idempotent.
- `reset` must be safe and reliable.
- Repeated `toggle`, `set`, and `reset` calls must not stack duplicate overlays, helper processes, or state entries.
- CLI should return meaningful exit codes:
  - `0`: success
  - `1`: user/actionable error
  - `2`: unsupported environment
  - `3`: internal failure after attempting rollback
- Output should be Raycast-friendly:
  - Plain one-line output for normal commands.
  - Optional `--json` for `status` and debugging.
- Errors should be short and actionable, for example: `Unsupported: built-in XDR display not detected`.
- Avoid broad dependencies. Prefer Swift standard libraries and macOS frameworks already available locally.

## 10. Safety / rollback requirements

- Always provide a `reset` command that attempts to restore normal brightness/display behavior.
- If applying extra brightness fails midway, attempt rollback before exiting.
- If using overlay/window technique, ensure only one overlay instance exists and that `reset` removes it.
- If storing previous brightness, treat it as a convenience, not the only rollback path.
- On unsupported hardware or unexpected display state, fail closed: do not apply partial extra brightness.
- Do not run as root unless research proves there is no other safe path; if root is needed, stop and document why before implementing.
- Do not install launch agents, login items, or daemons for MVP unless absolutely required and explicitly documented.
- Keep a manual emergency rollback path in the README/spec, such as quitting the helper process and running `extra-brightness reset`.

## 11. Licensing requirements

- Lunar repository is MIT-licensed, but verify the exact file/license locally before copying any code.
- If borrowing any Lunar code or adapted implementation detail, preserve the MIT copyright and license notice in the repository and relevant source files.
- BrightXDR is GPL-3.0 licensed. Treat it primarily as a reference unless Sergey explicitly accepts GPL obligations for copied/derived code.
- Do not copy Lunar brand/assets, icons, screenshots, names, or product UI.
- Do not copy BrightXDR code without first deciding whether GPL-3.0 is acceptable for this personal utility.
- Prefer original implementation after studying references.

## 12. Acceptance criteria

MVP is accepted when:

- Research note exists and states the inspected macOS version, hardware/display, Raycast convention, chosen implementation route, and license implications.
- Swift helper builds locally.
- Raycast exposes at least these commands:
  - `Toggle Extra Brightness`
  - `Set Extra Brightness Level` or preset commands
  - `Reset Extra Brightness`
  - `Extra Brightness Status`
- On Sergey’s built-in display, `set 120` or equivalent visibly increases perceived brightness beyond normal 100%, or the research note clearly documents why this is unsupported.
- `reset` restores normal brightness/display behavior.
- Commands are safe to run repeatedly.
- No external monitor path is implemented or required.
- No full app UI is shipped.
- Any borrowed code includes required license notices.

## 13. Suggested file layout

Keep the layout small. Suggested structure:

- `README.md` — setup, Raycast command install, manual rollback.
- `RESEARCH.md` — local inspection and chosen technical route.
- `Sources/ExtraBrightness/main.swift` — CLI entrypoint.
- `Sources/ExtraBrightness/BrightnessController.swift` — selected implementation behind a small interface.
- `Sources/ExtraBrightness/StateStore.swift` — optional state handling.
- `raycast/toggle-extra-brightness.sh` — Raycast Script Command wrapper.
- `raycast/set-extra-brightness.sh` — Raycast Script Command wrapper with argument or presets.
- `raycast/reset-extra-brightness.sh` — Raycast Script Command wrapper.
- `raycast/extra-brightness-status.sh` — Raycast Script Command wrapper.
- `LICENSES/Lunar-MIT.txt` — only if Lunar code is copied/adapted.
- `LICENSES/BrightXDR-GPL-3.0.txt` — only if GPL-covered code is copied/derived and accepted.

If Codex finds an existing local repo/style for Sergey’s Raycast utilities, adapt the layout to that style while keeping the same minimal boundaries.

## 14. Test plan / manual verification

1. Build
   - Build the Swift helper from a clean checkout.
   - Run `extra-brightness status` successfully.

2. Environment detection
   - Confirm status reports built-in display and selected implementation mode.
   - Confirm unsupported environments fail with exit code `2` and no visual side effects.

3. Set levels
   - Run `extra-brightness set 100` and confirm normal mode.
   - Run `extra-brightness set 120` and confirm visible extra brightness or documented unsupported result.
   - Run higher presets only inside researched safe bounds.

4. Toggle
   - Run `toggle` from off state: extra brightness enabled.
   - Run `toggle` again: normal mode restored.
   - Run rapid repeated toggles: no duplicate overlays/processes/state corruption.

5. Reset
   - Run `reset` after extra brightness is enabled.
   - Run `reset` again when already normal.
   - Delete/corrupt state file and confirm `reset` still behaves safely.

6. Raycast
   - Import/add the script command directory.
   - Confirm commands appear in Raycast with correct titles/descriptions.
   - Trigger each command from Raycast and verify output is short and useful.
   - If using permissions-sensitive APIs, confirm prompts are granted to Raycast, not Terminal.

7. Rollback
   - Confirm the documented manual rollback works.
   - Confirm no launch agents, daemons, or login items were installed accidentally.

## 15. Risks / unknowns

- macOS may not expose a stable public API for full-range built-in XDR brightness control.
- Private display APIs may change between macOS versions and may break after updates.
- EDR overlay approaches can have artifacts in Mission Control, Spaces, screenshots, screen recording, HDR content, or full-screen apps.
- Extra brightness may increase heat, battery drain, and panel wear risk; keep max preset conservative unless research supports higher values.
- Raycast permission prompts may differ from Terminal because Raycast is the process executing scripts.
- BrightXDR’s GPL-3.0 license limits copy/paste reuse unless Sergey accepts GPL obligations.
- Lunar’s public repository may not contain all paid-feature implementation details; do not assume unavailable code can be reproduced exactly.

## 16. References

- Raycast Script Commands manual: https://manual.raycast.com/script-commands
  - Notes: script commands can run local scripts from Raycast, can be hotkeyed, should be idempotent, and macOS support includes Swift-backed scripts/interpreters.
- Raycast Extensions manual: https://manual.raycast.com/extensions
  - Notes: full extensions are command bundles with React/TypeScript/Node and richer UI; useful later, not necessary for MVP if Script Commands are enough.
- Lunar GitHub repository: https://github.com/alin23/Lunar
  - Notes: public Swift/macOS brightness-control reference; repository lists MIT license and XDR/HDR brightness features, but paid-feature source may be incomplete.
- Lunar site: https://lunar.fyi/
  - Notes: documents XDR Brightness as unlocking brightness above the normal macOS cap on supported XDR displays.
- BrightXDR GitHub repository: https://github.com/starkdmi/BrightXDR
  - Notes: open-source Swift PoC for Apple XDR extra brightness using an EDR/Metal/Core Image overlay approach; repository lists GPL-3.0 license and no-longer-maintained warning.
