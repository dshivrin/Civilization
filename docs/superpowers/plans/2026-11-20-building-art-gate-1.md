# Building Art Gate 1 implementation plan

**Goal:** Deliver the approved audit, inventory and rendering contracts for the existing 20 masters, ready for visual review.
**Spec:** `plans/2026-11-20-stone-age-building-media-library.md`; designated Master reply 34783060-ac9e-4dc0-9c8d-792ae091dbcc; direct owner “Implement”.
**Architecture:** Extend the existing offline art validator to produce reproducible measurements and an atlas. Keep runtime code, catalog, images, saves and the sibling media repository read-only. Store audit evidence and proposed contracts in the game repository.
**Tools:** Swift ImageIO/CoreGraphics/CryptoKit, Python standard library for documentation, existing media registry validator. No new dependencies.

## Constraints and review focus

Preserve current 1×1 civic/palisade and eighteen 2×2 footprints, all saves and art bytes. No Gate 2 generation/integration, normal connectivity activation or new defense/resource gameplay. Ground contact is semantic: silhouette bounds/alpha are measurable, but cannot certify contact masks, lighting or perspective. Label estimates and absent assets explicitly. Registry hashes must match real files; outputs must not overwrite earlier evidence. River fixtures must come from the actual map and distinguish current near-water legality from proposed visual edge attachment.

- [x] Extend `scripts/verify-art.swift` with optional `--audit-output DIR --media-root DIR`: preserve default validation; audit exact master/runtime/thumbnail hashes, alpha bounds, dimensions and existing catalog placement; write JSON and an HTML/SVG diagnostic atlas to a new directory.
- [x] Run existing media validation and the extended art validator. Verify 20 unique IDs, exact source/export mappings, PNG alpha, source/config hashes and no source changes. Inspect the atlas and representative sources.
- [x] Write `docs/art/building-gate-1/audit.md` and `contracts.md`: all20 kinds, level/research mechanics, missing directions/levels/semantic masks, actual river edges and modular sockets, defense-only future interfaces. Add map-derived bank/bend/opposite-bank fixtures to the report.
- [x] Review artifacts independently, fix substantive issues, rerun affected verification. No product test suite rerun is required for documentation/offline-tool changes.
- [x] Commit/push verified audit and checkpoint on existing first-era-review. Stop for visual review before Gate 2.
