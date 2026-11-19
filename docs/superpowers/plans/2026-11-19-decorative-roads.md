# Decorative roads Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans inline task-by-task.

**Goal:** Optional free persistent road editing with safe drag previews and16neighbor masks.
**Architecture:** Core road values/atomic commands and pure geometry; session draft never mutates state; renderer updates only changed tiles/neighbors. Optional additive v5 roads preserve nil old saves.
**Tech Stack:** Swift6/Swift Testing/Codablev5, SwiftUI/SpriteKit/iOS18.
**Spec:** docs/superpowers/specs/2026-11-19-decorative-roads-design.md

## Global Constraints

Current costs/rates/era/building catalog/art/map/signing/gestures preserved. Campfire fixed. No roads required for progression. No larger buildings, NPCs or media production. Follow spec operational defaults and report them as implementation choices. Baselineed23e2e; branch remains local first-era-review.

## Review Focus

Mixed invalid strokes reject atomically; out-of-map gestures bounded; hidden tile does not leak visuals. Editing/upgrading road styles updates neighbors after reload without mutating buildings. Road mode cannot steal ordinary placement/long-press gestures. Draft never leaks through background/save/scenario switch. Era and bootstrap material rules unchanged; full route still reachable.

### Task1 — Domain and persistent editing
Files: new GameCore/Roads.swift, tests RoadTests.swift; Types.GameState optional roads; GameEngine.siteIssue/validateState.
Interfaces: RoadStyle, RoadTile(tile:style:); RoadGeometry.neighbors/connectionMask/path/affectedTiles; GameEngine.roadIssue(at:),editRoads(at:style:),roadMask(at:). Nil style erases; nil saved roads empty. Keep commands atomic/idempotent.
- [ ] Tests first for16masks, continuous bounded path, atomic valid/invalid edits and unchanged economy/history, mixed styles/removal/reload, old nil saves, corrupt/overlap saves/build conflict. Observe missing API RED.
- [ ] Implement domain/validation; focused then full Debug/Release green; commit.

### Task2 — Draft session and native tools/rendering
Files: new GameApplication road extension if access allows (otherwise focused methods in GameSession), new RoadSceneLayer.swift registered in Xcode, WorldView, SettlementScene, SettlementView; tests RoadSessionTests.swift, UI RoadUITests or existing RelocationUITests.
Interfaces: RoadTool.draw/replace/erase; session roadTool/roadDraft/roadPreviewIssue/chooseRoadTool/extendRoadStroke/clearRoadStroke/confirmRoadStroke/exitRoadMode. Cancel/default navigation resets road mode; pinch clears draft; background discards draft. Pure changed-cell set feeds incremental rendering.
- [ ] Session tests RED for draft isolation, confirmed persistence/idempotency, cancel/mode/navigation/lifecycle and map bounds. Implement GREEN; render cached committed+draft layers; add compact controls and deliberate gesture branch.
- [ ] Add UI road lifecycle test RED missing Roads control; implement tools/drag/confirm/erase, verify no existing gesture regression. Native captures + all UI cases on3profiles. Commit.

### Task3 — Review/verification/report
- [ ] One fresh read-only whole-change reviewer, fix important confirmed issues with regressions, one fix pass.
- [ ] Final full core/Release probes, signed/Release builds; full paid first-era route and changed-cell/node/performance evidence. Physical availability check; no install without fresh backup.
- [ ] Archive ChatGPT response with limitations, synchronize canonical docs/ledger/README/report, native proof and clean separate commit. No next system expansion.
