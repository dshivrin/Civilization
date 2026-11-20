# S1-Geography Implementation Plan

> **For agentic workers:** Use superpowers:executing-plans inline, then one whole-change review.

**Goal:** Production 64×48 geography with concealed exploration and safe development save transition.
**Architecture:** Bundled additive map, bounded SpriteKit caches, existing authoritative exploration and independent library ownership.
**Tech Stack:** Swift, Swift Testing, SwiftUI, SpriteKit, Xcode XCTest.
**Spec:** docs/superpowers/specs/2026-11-20-s1-geography-design.md

## Global Constraints

Preserve iOS18/signing, original terrain/IDs/reserves/history, normal footprints/economy, separate developer companions, existing first-era-review branch and all backlog. No new renderer/backend/era.

## Review Focus

- Backup failure must never overwrite old test progress.
- Failed library selection must leave target bytes intact.
- Legacy fully explored maps must not reveal annex prematurely or lose known cells.
- Unknown terrain, deposits, footprints and interactions must remain concealed.
- Release must support the full map without developer APIs or unbounded texture allocation.

### Task 1: Production map and development preservation

Files: Configuration.swift, Resources/seed.json, private legacy resource, SaveStore.swift, GameLibrary.swift, ProductionGeographyTests.swift.
Interfaces: bundled() returns normal 64×48; SaveStore.load(configuration:) returns validated converted state after byte-verified backup; library prepares mapped metadata before publication.
- [x] Add tests proving default/start/core terrain/footprints, backed-up legacy progress and independent games; run RED.
- [x] Promote rows, map-derived radius and bounded old-save conversion; run focused GREEN and full core suite.
- [x] Commit coherent core/application changes.

### Task 2: Quarry/clouds/expeditions

Files: SettlementScene.swift, GameSession.swift, visibility policy/core tests, RelocationUITests.swift.
Interfaces: known-footprint predicate shared by renderer/session; existing startExploration/advance retain economics.
- [x] Prove near-side quarry reachable/extractable; pin pending/duplicate/capped-offline/reload/full optional discovery behavior.
- [x] Add native regression for cloud/reveal/default dimensions and Release cache path; observe failures.
- [x] Implement opaque bounded cloud presentation and visibility/interaction filtering; run GREEN.
- [x] Run full Debug/Release, Release exclusions and native phone/mini/Pro; inspect captures and performance evidence.
- [x] Commit production rendering and native verification.

### Task 3: Review, publication and environment assessment

- [x] One independent whole-change review; correct consequential findings with regression evidence.
- [x] Update milestone/checkpoint/canonical status with actual results and limitations.
- [ ] Fetch and push coherent commits to verified personal origin first-era-review; report issue #1 and exact Master chat.
- [x] Assess realistic saturated environment integration and define bounded visual approval pilot; do not batch-generate art.
