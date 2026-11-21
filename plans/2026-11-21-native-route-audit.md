# Ordinary Riverbend Native Route Evidence Plan

**Goal:** Test installed review baseline `ca1426b4613697ee0b5fc7558c2d0a1c38565821` from ordinary New Game continuously through Chapter 3 and prove Chapter 4 reachable, or preserve the exact block.

**Scope:** Tests and evidence only on `codex/riverbend-native-route-audit`. No gameplay/UI/core/project/signing changes, owner data, shared simulator access, physical installation, merge or Bronze work. Parent request is the specification. Ten screenshot placeholders do not establish the owner’s exact sequence.

**Architecture:** Extend existing XCTest helpers in `CivilizationUITests/RelocationUITests.swift`; reuse `scripts/dev.py` with a unique UUID app identity, independent derived data and a new compact iPhone simulator. Normal New Game, standard resources and real time only; no earned container, fixtures, grants, clock control or protected hooks.

## Acceptance and verification

- [x] Verify pinned source and read AGENTS.md and scripts/README.md.
- [x] Continuous native New Game → Lodge → Hut → Gathering Shelter → whole forest survey → operating Woodcutter → operating Stone Gatherer → Oral Tradition → Natural Knowledge → Chapter 4.
- [x] Assert exact objective/building/technology and action hit area; record before scrolling. Separate explicitly named baseline behavior test from strict discoverability test.
- [x] Observe missing-road reason and recover using ordinary suggested path controls.
- [x] Continue across suspect transition without replacing earned progress.
- [x] Capture milestone/block screens, actual profile, timings, logs/result bundles; distinguish reproduced defects, deliberate REDs and unknown human readability.
- [x] Prioritize compact iPhone; add dedicated iPad if feasible without concurrent resource conflict.
- [x] Commit tests, receipts and concise handoff; verify protected source unchanged and normal-push only isolated personal branch.

## Test steps

1. Run inherited ordinary opening/Continue as baseline on dedicated simulator.
2. Add strict third-action visibility case and a continuous baseline route that logs and captures every scrolling workaround before applying it.
3. Run native cases via `python3 scripts/dev.py test --suite ui --configuration release --qa-identity UUID --simulator UDID --derived-data /tmp/civilization-route-audit-builds --only-testing CivilizationUITests/NormalEntryUITests/CASE`.
4. Diagnose test-driver failures against accessibility tree/screenshots; change tests only. Retain all failures, and do not treat an incomplete route as complete.
5. Export actual XCTest attachments with xcresulttool; inspect representative screenshots and exact block. Publish evidence with source/profile/receipt hashes.

## Execution results

See `docs/testing/native-route-audit/README.md` and original per-run receipts. The phone continuous route passes (618.570 s), the compact opening-visibility case is intentionally RED (39.292 s), and two earlier driver errors remain preserved. Use per-case results: run 3 aggregate is correctly failed. All three selected iPad comparisons pass (strict connection 39.483 s, opening/Continue 101.660 s, immediate third action 24.838 s). No implementation method/approval pause applies because the owner explicitly requested test execution through report without intermediate stop.
