# Construction Visual Review Implementation Plan

> **For agentic workers:** use superpowers:executing-plans inline; retained first-era-review branch per owner.

**Goal:** Complete a five-stage native construction comparison driven by actual onboarding build progress.
**Architecture:** Debug-only presentation phase + opt-in procedural SpriteKit nodes; existing disposable walkthrough owns review clock controls. No normal renderer promotion.
**Tech Stack:** Swift/GameApplication, SpriteKit, SwiftUI, XCTest, existing scripts/dev.py.
**Spec:** docs/superpowers/specs/2026-11-20-construction-visual-review-design.md; plans/2026-11-20-living-world-environmental-animation.md.

## Global Constraints

- Existing normal construction appearance, all saves/history/costs/time, fixed footprints, original media and signing preserved.
- R2-07 disabled; no new roadmap, normal onboarding Gate B or runtime art acceptance.
- Native source additions remain Debug-only and opt-in to the disposable walkthrough.

## Review Focus

- Boundary stages must derive from remaining work; invalid values must not report completion.
- Paused review must not advance its engine while XCTest/readers inspect stages.
- Temporary nodes must be removed at completion; original art becomes visible and remains selectable.
- Existing candidate drag/grab offsets and empty-map navigation remain functional.
- Small phone guide must retain civic/touch clearance, visible controls and wrapped labels.

### Task 1: Real construction comparison

**Files:** modify ConstructionPresentation.swift/tests, SettlementScene.swift, WorldDetails.swift, NativeVisualReviewView.swift, RelocationUITests.swift; extend existing gallery builder for construction archive.
**Interfaces:** `ConstructionPresentation.reviewStage` Debug-only enum with foundation/frame/walls/roof/finished; `SettlementScene.reviewConstructionEnabled` defaultfalse; summary reports actual visible nodes/art and source fraction; walkthrough consumes phase and renders remaining work.

- [x] Write boundary tests for review phases0/.15/.40/.75/1 and invalid work; native `testOnboardingConstructionStagesUseActualWork` pauses review, builds Hut and observes actual foundation/frame/walls/roof/finished with repeated3second advances, captures each; normal map preserved afterward.
- [x] Run reusable focused core/native tests; expected RED missing phase/clock control.
- [x] Implement Debug-only phased footprint-derived source geometry and actual-node diagnostics. Keep normal code path unchanged. Add review clock pause/resume and3second advance controls, no persistence API.
- [x] Run focused tests then existing full core and scoped native phone/mini/Pro walkthrough/drag/suggestion regressions plus Release entry. Expected nonzero passing counts, no failed suites.
- [x] Archive15unchanged screenshots with new gallery mode and hashes; inspect layouts. Run independent review once, correct Important findings with RED→GREEN; preserve historical artifacts.
- [x] Commit/push coherent verified slice; update ledger/checkpoint with actual SHA/evidence/limits. Parent Goal remains open for remaining art/audio and acceptance gates.

Pre-flight: phase→renderer→walkthrough/native share actual remaining work. Ruling: keep legacy stage separate so normal Release construction cannot change from a review-stage refinement; cost is one small Debug-only phase enum.

Task1 complete evidence: focused model/native REDs and review correction RED→GREEN are recorded in progress.md; final core94d39ab1 is273Debug/235Release+10exclusions; final native3136edaa is4cases each phone/mini/Pro; Releasec72c21b5 is1case.15source PNGs archived, phone/mini/Pro stages inspected, all gallery links/hashes validated. Independent review once, two Important findings corrected, one Minor label ambiguity deferred. No player data/device/art/migration/normal activation. Commit/push recorded in Git history.
