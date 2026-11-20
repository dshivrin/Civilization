# Villager raster registration study

Two unchanged generated 1774×887 PNGs show one proposed adult villager in four nominal directions, with four walk and four carry frames per row. [Open comparison](index.html). Initial attempt and one padding correction are retained with exact prompts, reference hashes and native alpha measurements.

The proposed 8×4 partition has 32 nonempty cells per sheet. Covered gutter pixels fell from 4,008 to 41; **both candidates fail the 5% margin check**. No runtime export, semantic foot registration, seamless gait, direction/camera approval or complete character library is claimed. Alpha bounds are silhouettes, not planted feet. The viewer uses original UV rectangles and one fixed scale/origin for all frames; it never compensates for frame drift.

Browser checks cover eight direction/activity selections, stepping/playback, static mode, backgrounds and desktop/mobile layout. Gray/checker composites show clean edges at the reviewed sizes; misleading red fringes in the raw image preview are not an artwork finding. Lifecycle tests execute the actual viewer with simulated hidden/reduced-motion/page events; actual OS preference and tab-hiding behavior were not observed in IAB. See [verification](verification.json) and [browser evidence](evidence/browser-checks.json).

Reuse `swift scripts/verify-art.swift --inspect-atlas IMAGE.png 8 4` for read-only measurement, `python3 scripts/build-art-gallery.py --villager-atlas` for hash-validated data, and existing Python/Node test commands. Open locally, or serve only this self-contained directory over loopback. No server dependency, application integration or player save access.

This finishes the already-started study before the graphics checkpoint. The owner moved the realistic actual-scene proof into a separate fresh context; unfinished art does not hold up the fresh Economy Lab context. Existing 20 runtime building masters, ordinary gameplay, signing and R2-07 remain unchanged. Canonical media archive is additive and local-only, with no remote invented.
