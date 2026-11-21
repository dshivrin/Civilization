# Riverbend player verification

[Delivery and exact Xcode launch steps](../../milestones/2026-11-21-riverbend-player-review.md) · [Pinned handoff](../../milestones/2026-11-21-riverbend-player-handoff.md) · [Machine receipt](verification.json) · [Native gallery](index.html) · [Run index](run-index.json)

The player route is **ordinary New Game / Continue**, independent of Developer tools. Run from the preserved `riverbend-player-review` checkout. No owner save or physical device was read or modified.

## Reproduction

```sh
python3 scripts/dev.py doctor
python3 scripts/dev.py test --suite core --configuration both
python3 -m unittest discover -s scripts/tests -v
node --test scripts/tests/*.test.cjs
swift test --package-path Tools/SaveInspector
swift test --package-path Tools/SaveInspector -c release
python3 scripts/dev.py test --suite ui --configuration both --simulator PHONE_UDID --simulator IPAD_UDID --only-testing CivilizationUITests/NormalEntryUITests
```

Use `scripts/README.md` for the exact earned-checkpoint export and fresh UUID simulator preparation workflow. The checked-in `synthetic-earned/` files came from the Release public-engine route `riverbendPlayerCraftStorageEnclosureEarnedRoutePersists`, starting with GameLibrary New Game and reopening the same library. They are synthetic, contain no owner data, use no grants or Debug commands and record model seconds in `qa-earned.json`. A checkpoint is not a completed real-time native playthrough.

The route advances **5,880 simulated seconds**. Native survey and three Tool timers use real 1× elapsed time. Craft, enclosure and ending are distinct checkpoints from that earned route; each native run uses a separately prepared QA identity and ordinary Continue. Gate verification purchases the final enclosure, closes/opens its gate and earns readiness in that same game, then relaunches it. Capacity checks open the actual Food/Wood inspector after paid storage completion and connection.

## Evidence conventions

`runs/<id>/report.json` and `.md` are unmodified runner receipts. Original raw logs are losslessly stored as `.log.gz` (decompress with `gzip -dc FILE.log.gz`). Their absolute `/private/tmp/…` references identify the retained local result bundles; in this repository use the corresponding directory under `runs/`. Reports correctly identify a modified working tree at the resumed base; the pinned handoff ties the tested source files to the committed product. `verification.json` selects final passing gates separately from historical failures. Counts are executed test declarations, not expanded parameter combinations.

All failed/missing-selection/compile attempts remain in the run index; a later pass does not turn an earlier failure into a pass. Early app-cropped XCTest images had an orientation mismatch, found by visual inspection. Final gallery captures use original full-display XCTest screenshots; no crop, repaint, rotation or enhancement is applied. Wrong-orientation captures are excluded from the gallery, while their original run logs remain.

The independent review's critical/important findings were reproduced and fixed in one bounded pass. [Ledger](engineering-ledger.md) records the RED/GREEN evidence and decisions. Two minor performance findings are deferred: find pathfinding reconstructs boundary geometry per edge and scene feature nodes rebuild during updates. Physical frame cost, touch feel, art acceptance and a full real-time playthrough remain unmeasured.
