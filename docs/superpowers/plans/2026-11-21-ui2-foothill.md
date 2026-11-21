# UI2-4 Riverbend Foothill Implementation Plan

**Goal:** One integrated isolated Debug foothill founding and enclosure review.
**Architecture:** Explicit 64×48 Foothill profile reuses founding engine/view with a separate atomic envelope/filename. A bounded full-map cardinal collision graph recognizes explicit impassable cliffs and walkable slopes; the same graph drives review traversal and enclosure tests. Source-native procedural cliff/wall/gate overlays; no runtime raster replacement.
**Spec:** `4ec56dc37cb54a39d454412c2257f8f7fdb7f3c3:plans/2026-11-21-riverbend-interface-round-2.md`, referenced roads plan, and direct UI2-4 dispatch.

## Constraints and rulings
- Exact local/remote base verified 8f0146300e3efdca1a2b7cd87d36e7fcb3d9be5c before edits. Managed worktree only; branch riverbend-ui2-foothill-review only.
- Owner already authorizes execution with proposed defaults and no routine visual approval stop; no new approval gate.
- Original founding/default config and bytes remain separate. Normal/Release/Lab/economy/schema/art/signing unchanged.
- No combat, towers, bridges, general generator, device access or next goal.
- Cliff set is explicit map semantics over hill terrain, ordinary hill control remains traversable. Flood fills span all 3072 map cells, without cosmetic planner limits.
- Enclosure uses equal protected rectangle and one equal-price gate. Review-only provisional price 1 Wood per purchased cell (including gate); actual deducted cost and paid state are persisted in one Foothill envelope.

## Review focus
- Corrupt/wrong-identity saves fail without reset; stale concurrent windows reject writes.
- Every wall/cliff join, diagonal corner, map-edge detour and ordinary slope tested; no clipped search domain.
- Existing buildings/roads cannot overlap a purchased solid wall; intended gate road remains valid.
- Founding progress and exact file bytes survive Foothill open/reopen/relaunch.
- Temporary forest comparison cannot mutate retained Foothill transactions.

## Tasks
- [x] 1. Write failing profile, full-map collision/enclosure and save isolation tests. Implement explicit map identity, resources, traversal and comparison; run scoped core via dev.py.
- [x] 2. Parameterize founding review/store with separate Foothill envelope; preserve civic/footpath/hut and atomic mutation; test costs, collision, reload, stale/corrupt rejection.
- [x] 3. Integrate Developer entry, inherited founding menus, procedural cliff/wall/gate and actual traversal controls/animation. Add native phone/iPad route and save-isolation cases and Release exclusions.
- [x] 4. Full core Debug/Release/probes; phone/iPad Foothill, inherited founding/menu/fog-motion, Lab-through-craft, ordinary Release entry/save. Export original captures/receipts; inspect visually and review source independently. Fix verified blockers.
- [ ] 5. Record exact counts/failures/limitations/preservation, owner guide and gallery. Push only review branch, verify remote, add exact implementation ancestry/remote receipt handoff, push receipt and verify; stop.

Ruling: inherited5sMainActor setup guard repeatedly expired behind~20sof unrelated synchronous fixtures; test-only30sbound preserves race/byte assertions. Runtime RED receipts and final independent follow-up retained. Final full327/235/23pass,16unique Debug device/case passes plus2ordinary Release passes; failed aggregate bundles stay failed. UI-only fitted cost-column reruns pass1each.
