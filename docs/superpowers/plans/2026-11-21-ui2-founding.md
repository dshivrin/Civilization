# UI2-1 Riverbend Founding Implementation Plan

**Goal:** Deliver isolated Debug founding and mandatory opening roads, then push only `riverbend-ui2-founding-review`.
**Architecture:** A dedicated map-ID profile and atomic separate save wrap the existing civic upgrade, road edits and R2-06 service graph. A native map review uses existing scene/gesture surfaces with a narrow founding inspector. Normal and Economy Lab profiles remain unchanged.
**Spec:** `4ec56dc37cb54a39d454412c2257f8f7fdb7f3c3:plans/2026-11-21-riverbend-interface-round-2.md`, UI2-1 only; direct dispatched brief.
**Base:** remote confirmed `94c3e6934f39250ad4e073b5b9b6581099f85a52`; clean managed worktree. Main is not merged.
**Execution:** Native inline; owner explicitly requests continuous execution with no cosmetic/design sign-off.

## Constraints and decisions
- Debug-only profile, model, entry and tests. No device, production save or signing access. No UI2-2.
- Same civic entity/1×1 footprint; first upgrade costs 12 Wood + 4 Stone, available without research. No legacy +10 Wood or storytelling objective credit.
- Existing full-edge cardinal graph and civic exemption. Entrance is a visual teaching cue, never a new graph constraint.
- Starter path free after founding. Building sites and roads use existing terrain validation. Default camera includes two legal hut sites and civic clear space.
- Separate file; no offline catch-up. Atomic candidate write before publishing mutations; damaged saves preserved.

## Review focus
Failed writes/reload, stock conservation across founding, completed and partly paid work on disconnect, alternate legal hut placement, Release isolation.

### Task 1: Profile and transaction model
- [x] Add failing core tests for identity/cost/history, no prerequisites, free road, hut connection/disconnection and reload, invalid terrain and failed publication.
- [x] Run via `python3 scripts/dev.py test --suite core --configuration debug --filter foundingReview`; confirm RED.
- [x] Implement Debug profile and separate atomic store; narrow civic compatibility seams, preserving default behavior.
- [x] Repeat filtered test then full Debug/Release and exclusions; expect all selected cases pass.

### Task 2: Native founding map
- [x] Add native phone/iPad flow test with fresh identities and screenshots; assert stocks, objective/history and civic identity before/after/relaunch.
- [x] Implement Debug entry, stone/timber Lodge with visible door, clear civic focus, recommended and fallback hut, free starter and drawn route controls; use existing gesture/map surface.
- [x] Run native flow on phone/iPad plus ordinary entry and Economy Lab regression using existing runner. Inspect original captures.

### Task 3: Review and delivery
- [x] Fresh whole-branch review; reproduce/fix blockers; rerun necessary checks.
- [x] Archive exact commands/counts/failed attempts and captures; verify protected profile/asset bytes and branch/base.
- [x] Commit and push only requested branch, confirm remote SHA; write bounded milestone/handoff and end context.
