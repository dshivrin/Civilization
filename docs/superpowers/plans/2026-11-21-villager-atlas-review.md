# Villager Raster Registration Review Implementation Plan

> **For agentic workers:** Use superpowers:executing-plans inline with one final independent review; retain owner-selected first-era-review branch.

**Goal:** Produce and honestly inspect a regular32-frame realistic villager walk/carry candidate before further atlas production.
**Architecture:** Original transparent raster plus immutable generation/native measurement receipts feed an offline review gallery. No application/resource export.
**Tech Stack:** Built-in image_gen, existing native Swift/CoreGraphics inspector, Python art gallery tooling, browser JavaScript and canonical Git/LFS media archive.
**Spec:** docs/superpowers/specs/2026-11-21-villager-atlas-review-design.md; plans/2026-11-20-living-world-environmental-animation.md.

## Global Constraints
- Four nominal directions;8columns×4rows; one adult per cell. One initial generation + at most one targeted correction.
- Original PNGs/prompts/references retained, no pixel editing, no alpha-bounds-as-semantic-contact claim.
- Preserve all game/media originals, gameplay/save/economy/footprints/signing and R2-07 disabled. No normal visual/ONGateB/new-roadmap/audio activation.
- Exact data provenance; no renderer/build dependency on sibling media; actual local media commit/no remote status.

## Review Focus
- Integer partition and top-left row order on odd dimensions; empty/opaque/clipped cells remain explicit failures.
- Viewports must never hide badly registered feet/props with per-frame transforms or silently fabricate directions/frames.
- Wrong hashes, missing/duplicate cells, path aliases and optimized execution must fail before changing generated data.
- Playback stops for Static/reduced motion/hidden page, controls remain usable on390px mobile and desktop.
- Canonical archive is additive and byte-exact; source/runtime20masters and all previous registry entries unchanged.

### Task 1: Candidate, read-only measurement and review viewer

**Files:** extend scripts/verify-art.swift and scripts/build-art-gallery.py; tests scripts/tests/test_villager_atlas.py; new docs/art/villager-atlas-review/{assets,prompts,measurements,README.md,index.html,review.js,generation-receipts.json,gallery-data.js,verification.json}; additive canonical media concept archive/registry.
**Interfaces:** native --inspect-atlas PNG COLUMNS ROWS → JSON with actual dimensions/hash/alpha32/top-left cells; build_villager_atlas(review=None) → validated data/window.VILLAGER_ATLAS; browser consumes immutable raw UV rectangles and proposals, never processed PNGs.

- [ ] Generate initial32-frame study from inspected references using saved exact prompt; inspect/copy unchanged output. Preserve failures; at most one targeted correction.
- [ ] Write native fixture tests for6×6RGBA(top-left/empty/gutter) and odd-cell boundaries; run RED using existing unittest CLI, expected missing --inspect-atlas. Implement inspector mode; GREEN, run on actual candidates and pin exact reports.
- [ ] Write gallery tests for32cells/8loop selections, honest failed registration, asset/prompt/reference/report drift, output alias/optimized execution; RED missing build_villager_atlas. Implement validated single-output atomic data publication. GREEN.
- [ ] Build original-cell playback/raw comparison UI with proposed anchor/gutter overlay, frame stepping and suspension. Verify through actual browser desktop/mobile interactions and record unchanged screenshot evidence. Do not claim generated layout/loop quality from green integrity tests.
- [ ] Archive canonical media additively under existing license/source/registry conventions; validate registry/LFS and every original file/record. Report media local-only commit.
- [ ] Run scoped/full tooling checks, existing art validation, source invariants; independent whole-slice review once, reproduce/fix Important findings in one pass, ledger minors/rulings. Commit/push verified game slice and concise report; parent Goal active.

Pre-flight: prompt layout→native integer cell bounds→pinned gallery data→raw UV playback. Layout metadata is a proposal consumed by diagnostics, not accepted production registration. Existing native renderer and source-native8-state comparison are unaffected. Ruling: use offline raster review before runtime replacement, as owner requested refinement before integration; cost if rejected is revising this candidate only.
