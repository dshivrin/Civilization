# Riverbend Economy Lab Implementation Plan

> **For agentic workers:** Use superpowers:executing-plans for the owner-authorized autonomous inline execution. Stop after delivery for Lab review.

**Goal:** Play the isolated, persistent waterless hut → forest → Woodcutter loop and recover from depletion.

**Architecture:** A Debug-only versioned configuration reuses GameEngine transactions/integration, unchanged seed terrain/art/footprints and the existing whole-forest proposal adapter. A separate validated envelope stores engine state and survey status atomically outside the game library. Only two Debug-guarded engine policy hooks differ: no Water growth gate and at least two field workers. The lab permits one hut and one of each producer, keeping two workers sufficient without assignment reallocation.

**Tech Stack:** Swift/GameCore, GameApplication, SwiftUI/SpriteKit, XCTest and existing Python QA runner.

**Spec:** plans/2026-11-20-stone-age-economy-foundation.md, bounded by owner Goal 1 prompt.

## Global Constraints

Base a598da71c5315eb021d77c44e8d6bc4ec290e7c5; branch economy-lab-review. Main read at 3e1faa1; do not merge. Seed SHA256 5c812367c320b1060fd93f3b07af64b942b20d8c679a73b5b62bc6d4b5b9f25d. No device access, ordinary save/mode/economy changes, production activation, media changes, signing changes or later goal. Initial3people/32Food/32Wood, campfire2Food/3housing; hut12Wood/+3housing, gatherer8Wood/+8Food, cutter4Wood/+6Wood; upkeep1Food/person; caps60; growth240eligible seconds/20Food/positive flow. Survey8Food/+6Knowledge exactly once, independent of workers. Recovery floors Food12, Wood12 before hut/8after. Existing footprint and construction times retained. Survey duration60seconds is a lab choice, shown before payment. No offline catch-up in this first slice; time pauses on dismissal/relaunch, explicit review advances remain available.

## Review Focus

Corrupt/wrong-profile saves must not reset. Failed save must not publish debits/reveals. Repeated survey/reload must not debit/grant twice. Delayed/empty starts must recover without knowledge/crafts. Occupied first forest site must leave a reachable fallback.

### Task 1: Deterministic profile and loop

- [x] Add failing tests in EconomyLabTests.swift covering exact numbers, forest contiguity/fallback, delays/depletion, growth/caps, cost/reveal idempotency and ordinary isolation. Run scoped QA RED.
- [x] Implement RiverbendEconomyProfile.swift (GameCore) and RiverbendEconomyLab.swift (GameApplication). Use GameEngine for placement, construction, growth and rates; adapter supplies forest only.
- [x] Run scoped QA GREEN; record full baseline/result.

### Task 2: Atomic independent persistence and playable entry

- [x] Test failed publication, invalid envelopes, reload mid-survey and byte preservation of normal/developer/round2/library fixtures.
- [x] Implement lab store candidate-write-before-publication. Use an independent fixed namespace; no GameSession or game library mutations.
- [x] Add Debug Developer tools entry and focused lab UI/map, player site selection and explicit confirmation, optional gatherer/recovery, pause and small time advances, visible costs/timers/staff/net rates.
- [x] Native test completes route, reloads paid survey, confirms positive rates and normal return; add specific Release API and entry absence checks.

### Task 3: Verification and delivery

- [x] Full python3 scripts/dev.py test, Python toolkit tests, native iPhone/iPad Debug route and ordinary Release entry. Read all outputs, preserve failures.
- [x] Export two actual screenshots; inspect readability. Record ten-minute trace, exact test counts and limitations in docs/milestones/2026-11-21-economy-lab.md.
- [x] Fresh whole-branch review, fix important findings, verify affected tests. Commit/push only economy-lab-review to dshivrin/Civilization; report exact pushed SHA and stop for Lab review. Goal2 remains gated.

## Execution ledger

- Worktree verified clean/detached at exact base, personal remote verified; requested branch created without overwriting.
- Ruling: Existing main specification plus direct autonomous implementation instruction supplies design authorization; routine lab choices recorded here, no duplicate approval gate.
- Ruling: Reuse existing region adapter; ordinary area exploration remains unapproved. Lab is labeled deterministic fixture. Terrain is never moved or generated.
- Baseline /tmp/civilization-qa-c409b379596c4011aa6b64238f64c32a: interrupted helper after process sample identified existing unbounded Task.yield polling in cancelledLargePreviewPreparationDoesNotPublishOrWriteNormalSave. Preserved failed result; deterministic pre-start cancellation replaces transient flag polling; scoped cancellation test passed.
- First sandbox-scoped attempts failed Swift cache access (7f66c7/ad9299); authorized QA now uses host escalation, unchanged runner.
- RED b157b8: missing RiverbendEconomyLab API confirmed. First implementation aa92ce: six lab tests rejected inherited Campfire rotation after civic levels removed. Profile pins the existing stationary Campfire to north.
- Task1: complete. Core profile/loop tests GREEN 0be3057; full285Debug/235Release+13APIexclusions GREEN 1b616c6. Additional authentic save/library byte isolation and ten-minute trace:8Lab tests GREEN cc8d379.
- Native eeb734f: phone zero executed (failed correctly), mini1 actual route/reload passed. Release7b91aa9:1 ordinary entry/persistence test passed with explicit Lab absence.
- Independent review: important camera refit per timer/drag, and preview roof tap relocates origin. Phone465d8e reproduces camera snap RED (1 executed failure). Fix fit only at initialization/explicit selection; add roof/drag regression next. Minor map accessibility wording will be corrected with shared surface parameter.
- Toolkit sandbox run failed three native image cache checks; escalated rerun42passed/3art-audit skipped (local media not at this worktree's expected sibling path). Skips are not passes and art is unchanged.
- Full core9cbe932:288Debug/235Release+13Release exclusion probes passed. Nine lab tests include failed survey cost/reveal publication; authentic Normal/Developer/connected Round2/library fixtures are byte-identical.
- Phone5c04b7 route passed, but logs show earlier test body (no roof assertion); do not attribute new gesture coverage to it. Use renamed gesture test in independent persistent Lab cache. Phone834634 runner launch Busy preserved; alternate available iOS18.6phone used without resets.
- Phone39df5c: actual new roof regression RED (origin18,12→17,11). Add existing preview-body/footprint guard and retained-offset surface; camera refit corrected at explicit initialization/selection only. Original cropped mini capture discarded as readability evidence; use full-screen XCTest capture and fixed counters above scroll controls.

- Final: phone+mini e1eb457 each1actual gesture/route/relaunch test passed. Both review findings verified RED→GREEN. Map accessibility wording corrected; final full-screen captures inspected with both Food/Wood fixed above scroll. Additional9Lab tests cc6a7d pass after discovered-open-terrain fallback assertion. No required check skipped. Stop for Lab review.
