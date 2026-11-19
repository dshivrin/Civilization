# Building geometry foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Safe catalog-derived rectangular/oriented geometry without changing current first-era layouts.

**Architecture:** Pure footprint/orientation types resolve optional placed geometry; engine commands/validation and render consumers share them. New builds capture dimensions; legacy nil fields retain catalog fallback.

**Tech Stack:** Swift6, Swift Testing, Codable v5, SwiftUI/SpriteKit, iOS18.

**Spec:** docs/superpowers/specs/2026-11-19-building-geometry-design.md

## Global Constraints

Current catalog dimensions/costs/era/geography/art unchanged. Campfire1×1fixed. No new visible rotation controls, roads or NPCs. Preserve normal saves/rewards, old API default behavior and tested gestures. Inline continuation in existing non-main candidate branch; commit each step.

## Review Focus

Malformed dimensions must fail before range allocation; nil legacy geometry must keep old equality/layout. Saved non-square footprints must remain authoritative after catalog changes. In-place turning must validate occupied/discovered/terrain tiles atomically. Render/preview/hit/depth must share full oriented size. No rotated artwork is implied by logical orientation.

### Task 1: Geometry values and authoritative engine commands

Files: create GameCore/BuildingGeometry.swift, tests BuildingGeometryTests.swift; modify Types.swift, Configuration.swift, GameEngine.swift. Interfaces: BuildingOrientation(north/east/south/west), BuildingFootprint(width:height:), oriented(_:), tiles(at:), center(at:); BuildingDefinition.footprint, allowedOrientations/resolvedOrientations; PlacedBuilding.footprint/orientation/resolvedFootprint(in:)/resolvedOrientation/occupiedFootprint(in:)/tiles(in:). placementIssue/build orientation defaultnorth; relocationIssue/relocate orientation optionalnil (preserve).

- [x] Write tests for rectangle axis swapping/center, rotated placement/occupancy/rejection, relocation identity/atomicity, snapshots versus edited catalog, legacy nil reload, corrupt saved dimensions/orientation and invalid catalog orientations.
- [x] Run focused tests, observe missing API failures; implement minimal types/shared resolver and authoritative checks; run focused suite green.
- [x] Run complete Debug/Release regression suites and5Release probes. Commit.

### Task 2: Rendering and UI geometry consumers

Files: GameSession.swift previewFootprint; WorldView.swift; SettlementScene.swift; SettlementView.swift. Consume task1 geometry; session returns moving captured footprint or current selected definition. Preview/inspection tiles, fallback hit testing, anchor/depth and cache signature use shared resolved geometry. No gesture recognizer changes or rotation UI.

- [x] Add session preview regression: a stored rectangle remains the preview footprint during relocation despite catalog edits; verify failing missing API.
- [x] Implement shared geometry consumers. Build app and run all9UI cases on phone/mini/Pro; inspect native screenshot for unchanged square alignment.
- [x] Commit rendering/session changes.

### Task 3: Review and delivery

- [x] One fresh independent whole-change read-only review; fix important confirmed findings with regression tests, one pass.
- [x] Run final affected/full checks if fixes change behavior, signed Debug/Release builds, developer exclusion, compare seed/art untouched.
- [x] Update canonical status and milestone report with actual commands/results and pending physical/human review. Commit cleanly. No automatic secondary-system work.

Delivery:1444ca6 design authorization;70418ea core/session;d0a3284 render consumers. Baseline126Debug, focused missing APIs RED→GREEN; final135Debug/124Release and5Release probes pass. Full9UIcases pass on phone174.496s,mini163.115s,Pro163.469s. Independent review found no actionable defect; hidden-edge rotation coverage added. Native phone placement capture inspected and fresh-build flow passed48.284s. Signed/Release builds and signature pass, no seed/art diff. Physical unavailable; deployment/performance pending, no installation claim. See docs/milestones/building-geometry-foundation.md.
