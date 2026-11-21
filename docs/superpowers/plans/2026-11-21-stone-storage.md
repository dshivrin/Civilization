# Riverbend Stone and Storage Implementation Plan

**Goal:** Debug-only revealed Stone collection and useful storage, preserving E0/E1 and ordinary games.
**Base:** fb068aba76ee4cc5104dbb9c696173d8b94bf75b, economy-stone-storage-review.
**Spec:** origin/main:plans/2026-11-20-riverbend-next-codex-goals.md E2 and approved economy foundation; direct autonomous overnight execution.
**Architecture:** Extend the existing isolated v1 envelope additively. Existing storehouse kind has per-instance Granary/Stockyard specialization metadata. Derive caps from completed specialized buildings in a lab-only configuration; no generic warehouse bonus. Stone uses an explicitly labeled deterministic revealed-land outcrop fixture and existing Stone gatherer, workforce and simulation. No craft inventory is unlocked.
**Tech Stack:** Swift GameCore/GameApplication, SwiftUI/SpriteKit, Swift Testing/XCTest, checked-in Python QA runner.

## Constraints and choices

No normal engine/schema/seed/art/signing/device edits, main merge or production activation. Preserve pause-on-close and exactly-once finds/survey. Use all candidate costs/caps/rates unchanged. One each storage specialization; no removal/disconnect/upgrade UI in this slice. Outcrop appears only after E0 checkpoint through an explicit free reveal action on reachable already-revealed land (no new production exploration). Fixture collection has no depletion in this bounded review; no finite reserve claim. Stone gathering needs a third field slot: expose worker shortage and wait for population5, preserving prior assignments. Storage capacity starts on completion. Cap recalculation occurs at construction event boundaries, with old-envelope compatibility. Craft caps remain dormant24; Stockyard's future +24 contract is documented, no craft chain enabled.

## Review focus

- Unaffordable selection must explain missing resources and preserve state.
- Full Stone must stop intake; retry after spending resumes.
- Specialization metadata must match actual storehouses, unique roles, and no hidden cap grants.
- Failed disk writes cannot publish source/build/spend/time changes.
- Native compact layout must keep amount/cap/contribution readable.

## Tasks (inline execution authorized)

- [x] Add focused failing Stone/storage tests: hidden-source rejection, exact costs, separate caps, construction/reload, failed writes/retry, cap stop/resume, malformed metadata and old envelopes.
- [x] Extend Debug profile and Lab model only: source reveal, gatherer placement, storage role costs/validation/configuration. Reuse atomic store.
- [x] Extend Lab controls/readouts and native route for source → gather → storage → relaunch; retain E0/E1 native tests unchanged.
- [x] Run full Debug/Release and Release exclusions, phone+iPad three Debug cases and ordinary native Release. Preserve every report and failure.
- [x] Review final diff, archive actual captures/reports with hashes, write delivery and Goal4 handoff; commit/push only designated branch and verify remote SHA.

## Review findings

Independent review caught free reveal using an affordability-inclusive placement check. Regression `stoneStorageFreeRevealDoesNotRequireGathererFunds` reproduced the failure in d342fa30; reveal now uses a zero-cost geometry configuration, while construction retains10Wood. Follow-up review found no further important issue. Labels now name each specialization during placement/completion and retain the growth-status explanation. First native failed Granary hit testing after full-page test scrolling; subsequent test uses bounded smaller steps and the UI omits disabled completed opening buttons. All unsuccessful attempts remain separate evidence.
