# UI2-3 Fog and Motion Implementation Plan

**Goal:** Deliver the approved UI2-3 native review with opaque organic fog and reusable alternate villager styling.
**Architecture:** Opt-in Debug rendering flags on the existing scene; retained VillagerFigure joints and VisualAgentJourney. Founding/menu save and all authoritative algorithms remain unchanged. Reuse the existing whole-forest temporary walkthrough, subject to the requested integration boundary.
**Spec:** 4ec56dc37cb54a39d454412c2257f8f7fdb7f3c3:plans/2026-11-21-riverbend-interface-round-2.md and direct UI2-3 dispatch.
**Execution:** Native execution already authorized; no routine sign-off pause. Work ledger: docs/testing/ui2-fog-motion/progress.md.

- [x] Task 1: Add deterministic boundary geometry in GameApplication, tests in GameCoreTests. Verify missing API RED then focused GREEN. Unknown cover remains solid; no unknown ground lookup; fade only newly known cells. New flag scopes appearance to this review.
- [x] Task 2: Add Explore controls and alternate retained styling in FoundingReviewView, SettlementScene, LivingWorldLayer, VillagerFigure. Preserve normal appearance, eight poses, four facings, timing and route anchors. Native tests compare moving/static identity and joints.
- [x] Task 3: Native phone/iPad genuine captures and sequence, matched camera and zoom before/after, hidden terrain/markers, pan/pinch, Static/Reduce Motion; retained founding/menu/Lab/ordinary entry/save. Full core Debug/Release/exclusions. Reject zero selections.
- [ ] Task 4: Review source and captures; record counts/failures/limits, preservation and exact base/tip. Push only riverbend-ui2-fog-motion-review; verify remote; end for coordinator UI2-4.

Review focus: disconnected known one-cell corridors, interior unknown holes, map edges during zoom, transition interrupted by Static/Reduce Motion, outfit changes without journey rebuild.
