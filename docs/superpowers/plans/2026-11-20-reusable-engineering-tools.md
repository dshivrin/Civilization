# Reusable engineering tools implementation plan

> Use superpowers:executing-plans inline on the human-required first-era-review branch.

**Goal:** Replace repeated temporary scripts with reusable safe local commands.
**Architecture:** Python stdlib CLI orchestrates existing tools; local SwiftPM inspector uses real save validation and bundled resources.
**Spec:** docs/superpowers/specs/2026-11-20-reusable-engineering-tools-design.md

## Constraints / review focus

No resets, overwrite of backups, signing changes, implicit device actions, false zero-test passes or new gameplay. Preserve paths with spaces and exact filtered suite identity. No shell interpolation or sensitive save contents in reports.

### Task 1 — reusable commands and reporting
- [x] Write failing Python tests for zero/failure classification, no-clobber output, strict/additive comparisons and symlink preservation.
- [x] Implement scripts/dev.py with doctor, test, validate-saves, backup-device and compare-saves commands.
- [x] Run Python unit tests.

### Task 2 — resource-safe production save inspector
- [x] Write failing Swift tests for normal/legacy/grouped saves, corruption, missing indexed slot and source immutability.
- [x] Implement Tools/SaveInspector with GameCore/GamePersistence/GameApplication local package dependency and no external libraries.
- [x] Run inspector tests and validate actual private backup copies without mutation.

### Task 3 — integration and handoff
- [x] Run CLI full core Debug/Release/exclusion workflow and one scoped native Release entry case; check generated reports and failure exit behavior.
- [x] Review safety/report truthfulness; fix consequential findings.
- [x] Document commands and deferred proposal items, update checkpoint/agent guidance, commit/push, leave human playtest open.
