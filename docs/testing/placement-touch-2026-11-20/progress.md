# Placement touch investigation — 20 November 2026

Owner supplied three physical screenshots: candidate at invalid19,-11, later valid10,8, then dismissed. Owner later could not reproduce the jump and confirmed rotation letters DO change while the building image does not. Do not claim the original physical sequence or unsafe placement reproduced. Animation work paused for this investigation.

## Findings and correction

Logical facing/persistence works; production sprites have one fixed view. R2-04 explicitly permits logical rotation with provisional indicator, and excludes rotating flat raster art or replacing masters. Actual directional building rendering remains missing and requires the separate directional-asset review/integration work. This patch does not deliver visually turning buildings.

A separate concrete input bug reproduced: roof tap moves gathering candidate18,12→16,10; roof drag pans camera because only footprint owns drag. Correction: existing opaque-sprite mask recognizes new candidate body; tap preserves its origin, drag ownership captured at touch-down and original grab offset retained. Transparent pixels remain passthrough; relocation keeps its stationary source/footprint semantics; outside drag still pans. No economy, schema, art, signing or R2-07 change.

Debug-only diagnostics retain at most200lines in Library/Caches/civilization-placement-debug.log: timestamp, event, building kind, candidate tile, facing, validity, world touch and camera geometry. Rotation/map tap/pan release/confirmation logged. No resource amounts, save bodies or identity; not game state or automatic upload; cache may be purged and current process session replaces prior lines. Release excludes this code. If original jump recurs, copy that file via devicectl appDataContainer read-only copy, without changing saves.

## Verification ledger

- First reproduction harness used wrong category Production; failed selector, corrected to Food and water. Retained33d7330b... report, not product regression evidence.
- Footprint/control baseline46b729ae... passed1case, all four logical orientations with stable origin.
- RED roof drag8f11a4af...: tile18,12 unchanged while camera pans.
- RED roof tap82518f50...: expected18,12, actual16,10.
- GREEN phone dcc021fc...:3cases pass (roof tap/drag/rotation, persisted logical rotation/cancel, candidate confirmation after camera gestures). [Inspected fresh native image](phone-roof-drag.png).
- Full reusable core9fc1e31f...:239Debug/207Release and8ReleaseAPI exclusions pass. Existing core regression exercises invalid rotated relocation confirmation and byte-preserved save.
- Independent read-only review: no Critical/Important findings. No native gameplay or asset acceptance inferred.

Tablet/Release and physical installation evidence follow below. Private backups remain outside Git. These tests do not certify the user's unreproduced original jump or visible sprite rotation.

- Tablet matrix0a6a0d4a...: Pro3/3pass; mini ran only2existing cases and omitted the new regression. Runner correctly failed the matrix despite xcodebuild success; explicit mini rerun required.
- Release65324489...: ordinary entry1pass, requested roof test absent because RelocationUITests is wholly DEBUG-only. Runner correctly failed the mixed selection; corrected entry-only rerun required. These are harness scope/discovery failures, not passing matrices.

- Corrected mini aa53e6a4...: roof regression1/1pass. Corrected Release entry b12fc53a...:1/1pass. Total scoped Debug executions9 acrossphone/mini/Pro; Release entry1. Original failed/scope reports retained. Device signed build and host-trust strict signature check pass; fresh stable double-copy/production validation at /tmp/civilization-placement-touch-device-before-20261120.
