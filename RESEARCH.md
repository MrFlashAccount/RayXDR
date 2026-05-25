# Research Notes

## Local Machine Snapshot

- Date: 2026-05-25
- macOS: 26.3.1, build 25D2128
- Swift: Apple Swift 6.3.2, target `arm64-apple-macosx26.0`
- Mac: MacBook Pro, `MacBookPro18,4`, Apple M1 Max, 64 GB memory
- Built-in display: Liquid Retina XDR Display, 3024 x 1964 Retina, internal connection
- Raycast: `/Applications/Raycast.app`
- Raycast local config root: `/Users/sergeygarin/.config/raycast`

## Raycast Convention

MVP path is Raycast Script Commands. Raycast indexes scripts from a configured Script Directory, reads metadata headers, and supports compact output and arguments.

This repo provides scripts under:

```text
/Users/sergeygarin/Projects/RayCast Ultra Brightness/raycast
```

Official docs checked:

- https://manual.raycast.com/script-commands
- https://github.com/raycast/script-commands
- https://developers.raycast.com/information/file-structure
- https://developers.raycast.com/information/manifest

## Current Implementation Route

No brightness backend chosen yet. The scaffold intentionally fails closed:

- `status` reports unsupported backend.
- `reset` is a safe no-op that reports normal mode restored.
- `set` and `toggle` validate input shape, then return unsupported with exit code `2`.

## UltraBrightness Research Update

See `ULTRABRIGHTNESS_PLAN.md` for the implementation plan.

Findings:

- Lunar's public repo is MIT, but the repo states it cannot be built because paid/Pro source is hidden. The relevant Full Range XDR functions are referenced in open code but their bodies are not available; `required.swift.secret` is encrypted/binary.
- Lunar changelog says macOS `26.3+` blocked its native XDR algorithm and Lunar falls back to tone-mapping XDR logic.
- BrightXDR and BrightIntosh both use a macOS EDR/HDR overlay technique. BrightIntosh is closer to the target because it uses a tiny 1x1 HDR overlay and gamma shift instead of a full-screen user-facing app.
- BrightXDR and BrightIntosh are GPL-3.0, so copying code would make this project GPL-derived. For now, use them as behavioral references and write a minimal original implementation.
- Chosen MVP route: long-lived Swift helper process owns a 1x1 EDR overlay and gamma boost; Raycast calls a CLI that starts/stops the helper.

## Pending Research

- Locate local Lumen source or dependency and inspect UltraBrightness code.
- Check Lunar source/license before adapting any code.
- Check BrightXDR only as GPL-3.0 reference unless GPL obligations are accepted.
- Verify whether direct full-range control works on this exact macOS/hardware.
- If direct route is unsafe/unavailable, evaluate one-process EDR overlay fallback.
