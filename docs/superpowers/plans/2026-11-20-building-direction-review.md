# Gathering Shelter Direction Review Implementation Plan

> **For agentic workers:** use superpowers:executing-plans for the gallery/tooling work, with native built-in image generation for raster edits. Retain owner-selected first-era-review branch.

**Goal:** Prepare a truthful four-view single-family rotation comparison before runtime asset selection.
**Architecture:** Preserved original plus three separately generated alternate views, immutable receipts and existing native image inspection; local HTML/SVG gallery consumes exact PNGs. No game renderer integration.
**Tech Stack:** Built-in image_gen, native ImageIO measurement, existing Python gallery tooling, local browser.
**Spec:** docs/art/building-direction-review/README.md; owner rotation feedback and visual-refinement instruction; building Gate2/Living World plans.

## Global Constraints

- Fixed2×2footprint and original art/player saves/economy/signing unchanged; R2-07 disabled.
- No normal asset replacement, Gate3 mass production, bridges/defenses, audio/new roadmap or onboarding Gate B.
- Every generation/edit copied unchanged, exact prompts/references/hashes retained. Nominal azimuths and display anchors are proposals.

## Review Focus

- Source-specific baskets/posts/roof identity can drift during generation; inspect, report and retain failures.
- A mirrored/flat-rotated image does not prove a3Dquarter-turn; require changed visible roof sides and prop occlusion.
- Alpha bounds do not prove ground contact; label framing and keep raw view accessible.
- No missing view or unsupported family should masquerade as a complete direction library.
- Verify links/responsive layout/controls on desktop/phone; no new artwork in runtime bundle.

### Task 1: Alternate-view candidates and comparison

- [x] Preserve reference and exact prompts; generate B/C/D with true alpha via built-in imagegen; inspect each and apply at most one targeted correction when necessary.
- [x] Reuse `swift scripts/verify-art.swift --inspect-images` for measured alpha/bounds/hash records; create immutable receipts with observed limitations.
- [x] Extend existing `scripts/build-art-gallery.py` with a separate direction mode that verifies all raw/prompt/reference digests and source seed/art invariants, creates manifest/data/HTML; no image transformations. Add a focused failing tooling test for missing/tampered view before implementation.
- [x] Run focused and existing tooling regressions, validate actual gallery and inspect native-alpha/browser composition/controls/layout. No core tests or device install for docs/art-only slice.
- [x] Independent read-only review once for tooling and evidence claims; correct Important findings via RED→GREEN. Commit/push actual scope and update checkpoint.

Pre-flight: image receipts→native measurements→gallery share immutable filenames/digests. Keep new family out of the canonical media/runtime registry until owner art review; cost of rejection is revising this bounded proposal, not migrating a player game.

Task1 evidence: three built-in edits plus exact sourceA, native4alpha measurements, focused3RED→GREEN then independent review3Important findings reproduced in8test/6failure RED and8GREEN; full28tooling tests pass. Desktop/mobile controls/compositing/width proof and JPEGs retained; all links now resolve. Source-master/shadow-label minors remain recorded. No game/app/media/device/save change; personal branch commit/push tracked in Git history.
