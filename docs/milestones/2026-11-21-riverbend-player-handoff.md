# Pinned Riverbend player handoff — 21 November 2026

**Product source:** `623b9adfc0c74a59210c1fb77c701dd5f3c15bb0` on `riverbend-player-review`.
**Checkout:** `/Users/dima/dev/Civilazation-riverbend-player-review`.
**Personal destination:** `git@github.com:dshivrin/Civilization.git`, branch `riverbend-player-review` only. The following evidence commit changes documentation and captures; its product source is this pinned revision. No main merge, deployment or physical install is authorized by this delivery.

[Complete delivery and exact normal launch instructions](2026-11-21-riverbend-player-review.md) · [Verification receipt](../testing/riverbend-player/verification.json) · [24 original native captures](../testing/riverbend-player/index.html) · [Exact source blob identities](../testing/riverbend-player/tested-source-blobs.txt)

**Launch:** open this checkout's `Civilization.xcodeproj`, choose **Civilization** and an iPhone/iPad simulator, Cmd-R, then **New Game**. Use the ordinary **Goals**, **Build**, **Explore**, **Research** and **Games** controls; **Continue** resumes the selected game. No Developer tools, QA environment, checkpoint import, grant or speedup is required. The endpoint is **Goals 7/7 → Stone Age journey → Bronze readiness**; Stone Age building continues afterward.

**Passed:** 348 core Debug / 255 Release + 23 Release exclusion probes; SaveInspector 14 Debug / 13 Release; 47 Python and 9 Node. Final ordinary/earned native gates: 20 cases, zero failures/skips across phone and iPad, Debug/Release normal entry, contextual return, real survey, three real Tool waits per workshop, specialized storage, paid gate and same-game ending Continue. Five isolated-mode regression cases pass; their earlier aggregate selection/root errors are explicitly retained and explained in the machine receipt. Historical archive: 109 run receipts (57 failed attempts, 52 passing runs); earlier failures are not described as passes.

**Timing:** the full paid public-engine path starts with GameLibrary New Game and reopens the same game after **5,880 simulated seconds**. Native later stages use separately prepared synthetic earned checkpoints, ordinary Continue and real 1× actions. This is not a full 98-minute real-time native playthrough. Exact measured native waits and checkpoint hashes are in the receipt.

**Preservation:** no owner saves or hardware were accessed. The primary checkout remains unchanged. Existing large/review games retain their rules/stores; positively identified original small primaries use recoverable archives, with unknown/corrupt/migrated-primary negatives covered by synthetic fixtures. Original artwork/media/signing remain unchanged.

**Owner review remains open:** gameplay enjoyment, artwork acceptance and physical performance. Minor deferred review findings: find BFS rebuilds boundary geometry per edge and scene feature nodes rebuild during updates. No additional engineering work is required for this bounded delivery; future refinement remains separate.
