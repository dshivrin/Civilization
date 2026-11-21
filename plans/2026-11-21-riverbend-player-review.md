# Riverbend player review integration

**Goal:** One ordinary New Game/Continue Riverbend branch, playable from Campfire through earned Bronze readiness in Debug and Release.
**Authority:** Dima's current consolidation instruction and delegated acceptance criteria supersede historical review-only activation gates. No main push, physical installation, actual-save inspection or permanent deletion.
**Architecture:** Adapt GameEngine and the normal session/library rather than ship review stores as a second game. New map/rule identity isolates new rules from supported large saves. Optional state metadata preserves existing decoding. Use existing connectivity, simulation, persistence and rendering seams.

## Reconciliation

Verified origin: git@github.com:dshivrin/Civilization.git. Local origin/main is 4ec56dc37cb54a39d454412c2257f8f7fdb7f3c3; local main differs and is not a base. Base 47e351f6599971d595bb5a04864cc0f807fd4794 already inherits economy 94c3e6934f39250ad4e073b5b9b6581099f85a52 and graphics a598da71c5315eb021d77c44e8d6bc4ec290e7c5. No duplicate merges or source-checkout changes.

Reuse the authored 64×48 cliff map, in-place civic identity, free entrance, connected services, menu behavior, continuous fog and approved procedural motion/variant. Reconcile the opening price with the new 32 Food/32 Wood/zero Stone economy: founding cannot require Stone before its contextual discovery. Preserve legitimate later costs. Reuse survey, find, specialized-storage, single craft and improvement rules; integrate them with ordinary area exploration and chapter/research progression. Existing Water stock and progress in supported old large games remain under their original configuration. Review envelopes retain separate identities.

Exclude abandoned UI mockups, failed raster atlas/art candidates, diagnostic comparisons/probes, time controls, grants, unrelated backlog and playable Bronze. Keep equal-price wall comparison in regression tests, with ordinary enclosure/gate actions in the player UI.

## Tasks and acceptance gates

- [x] Add failing normal-game regression tests before behavior changes: distinct new rules, Campfire/Lodge/road/hut opening, whole forest exploration, food/wood recovery, contextual materials/finds/storage/craft, permanent spend, enclosure collision and earned readiness/persistence without grants.
- [x] Implement shared normal profile/state/commands, then adapt normal session, navigation, inspectors and renderer. Keep Debug tools excluded from Release.
- [x] Verify historical small map IDs/dimensions from committed configuration. Fixture-only recoverable retirement must preserve unknown/corrupt/current/review files, backups and atomic recovery; no actual device saves are accessed.
- [x] Run checked-in python3 scripts/dev.py core Debug/Release/exclusions and meaningful fixture/tool regressions. Record exact counts/failures/skips and CI requirements.
- [x] Run native normal phone/iPad flow with real gestures and real waits, independent games, relaunch, forest/material/tool/gate checkpoints and earned ending persistence. No fixture/grant/time-jump player UI.
- [x] Record milestone, owner Xcode instructions and direct evidence; review final diff; push only riverbend-player-review to verified origin and verify exact remote SHA. A failed required gate leaves delivery explicitly incomplete.

## Review focus

Old large saves must not be reinterpreted, rewarded or reset; unknown small-save identity stays preserved. Failed disk writes must not publish new progression. Hidden territory cannot leak through terrain, markers or motion. Interrupted/timed construction/craft and resource capacity must remain deterministic. Mandatory roads/worker/research gates must leave a reachable first-era endpoint.

## Completion receipt

Product `623b9adfc0c74a59210c1fb77c701dd5f3c15bb0`; [pinned handoff](../docs/milestones/2026-11-21-riverbend-player-handoff.md). All required software/native gates pass. Exact timing, prior failures and minor deferrals are preserved. Final delivery verifies only the consolidated remote branch; no main merge or device action.
