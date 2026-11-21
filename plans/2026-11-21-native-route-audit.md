# Ordinary Riverbend Native Route Evidence Plan

**Goal:** Test installed review baseline `ca1426b4613697ee0b5fc7558c2d0a1c38565821` from ordinary New Game continuously through Chapter 3 and prove Chapter 4 reachable, or preserve the exact block.

**Scope:** Tests and evidence only on `codex/riverbend-native-route-audit`. No gameplay/UI/core/project/signing changes, owner data, shared simulator access, physical installation, merge or Bronze work. Parent request is the specification. Ten screenshot placeholders do not establish the owner’s exact sequence.

**Architecture:** Extend existing XCTest helpers in `CivilizationUITests/RelocationUITests.swift`; reuse `scripts/dev.py` with a unique UUID app identity, independent derived data and a new compact iPhone simulator. Normal New Game, standard resources and real time only; no earned container, fixtures, grants, clock control or protected hooks.

## Acceptance and verification

- [ ] Verify pinned source and read AGENTS.md and scripts/README.md.
- [ ] Continuous native New Game → Lodge → Hut → Gathering Shelter → whole forest survey → operating Woodcutter → operating Stone Gatherer → Oral Tradition → Natural Knowledge → Chapter 4.
- [ ] Assert exact objective/building/technology and action hit area; record before scrolling. Separate explicitly named baseline behavior test from strict discoverability test.
- [ ] Observe missing-road reason and recover using ordinary suggested path controls.
- [ ] Continue across suspect transition without replacing earned progress.
- [ ] Capture milestone/block screens, actual profile, timings, logs/result bundles; distinguish reproduced defects, deliberate REDs and unknown human readability.
- [ ] Prioritize compact iPhone; add dedicated iPad if feasible without concurrent resource conflict.
- [ ] Commit tests, receipts and concise handoff; verify protected source unchanged and normal-push only isolated personal branch.

## Test steps

1. Run inherited ordinary opening/Continue as baseline on dedicated simulator.
2. Add strict third-action visibility case and a continuous baseline route that logs and captures every scrolling workaround before applying it.
3. Run native cases via `python3 scripts/dev.py test --suite ui --configuration release --qa-identity UUID --simulator UDID --derived-data /tmp/civilization-route-audit-builds --only-testing CivilizationUITests/NormalEntryUITests/CASE`.
4. Diagnose test-driver failures against accessibility tree/screenshots; change tests only. Retain all failures, and do not treat an incomplete route as complete.
5. Export actual XCTest attachments with xcresulttool; inspect representative screenshots and exact block. Publish evidence with source/profile/receipt hashes.
