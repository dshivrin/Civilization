# Gate 2 visual prototypes — 20 November 2026

Status: **review candidates prepared; no art, geometry or anchor acceptance implied**. Authority is the owner's direct Gate 2 brief after8e1c6fc, explicitly permitting visual prototypes while Gate 1 geometry remains unreviewed. R2-07 stays disabled. Defense gameplay and UI Themes & Animations remain separate.

Open [the interactive review gallery](index.html) directly from this checkout, or serve the repository root over loopback. It uses local PNGs and classic data scripts, no external service/build/package dependency. For example: `python3 -m http.server 8766 --bind 127.0.0.1 --directory .`, then `/docs/art/building-gate-2/index.html`. This is a standalone visual study, **not a running-game screenshot, physical-device test or integrated renderer**.

## Delivered review set

Thirteen individual PNGs in [assets](assets/), generated with built-in `image_gen`, copied unchanged from its saved outputs. No API/CLI fallback, background stripping or image-processing substitute was used. Native measurement confirms actual alpha, clear pixels and no alpha>32 pixels on canvas edges for all13.

| Family | Individual concepts | Role |
|---|---|---|
| Housing | hut-l1, hut-l2, hut-l3 | Blue family accent; vertical upgrade progression |
| Storage | storage-l1, storage-l2, storage-l3 | Gold/blue granary; higher chamber/structural detail |
| Fishing | fishing-l1, fishing-l2, fishing-l3 | Teal working bay; vertical upgrade progression, no baked water |
| Fishing direction | fishing-opposite-l1 | Additional opposite-facing proposal; not a certified cardinal master |
| Gathering | gathering-l1 | Open posts/baskets, purple accent; distinct from civic Gathering Place |
| Bridge | bridge-x, bridge-y | Two independently generated diagonal views; timber superstructure only |

This is the bounded Gate 2 prototype set from the approved staged plan, extended by the owner's explicit bridge comparison request. Remaining building families/full level-cardinal libraries belong to Gate 3, not falsely completed by these13concepts. Existing gameplay supportsL1–L3; these images add no floors/capacity/costs or other game mechanics.

## Gallery comparisons

- Four building families compare original shipped framing, proposed framing of **the same unchanged original**, and new generated concepts. The original is repositioned only in the gallery, not edited or replaced.
- Two/four-home neighborhoods and two/three/four-storehouse complexes remain separate sprites. All six unordered L1/L2/L3 pair combinations can be selected. Shared-edge yard joins are separate optional SVG overlays, not merged opaque ground squares, new roads or service connections. Roof and contact fitting are still review items.
- All seven Gate 1 fixtures show separate fishing and bridge panes against actual unchanged Riverbend tile rows. Fishing L1/L2/L3/opposite-L1 are selectable. No arbitrary blue water rectangle is part of an asset. Current radius-based fishing placement rules remain unchanged.
- Each fixture derives a terrain-only straight candidate crossing with real land ends and contiguous water in between. All seven chosen examples cross two water tiles, using the appropriate X/Y bridge view. This is not a bridge placement, pathfinding, defensive closure or pedestrian simulation test.

Bridge endpoint annotations are **hand-estimated source deck points**, not authored production sockets. A uniform scale and translation align their midpoint with real shore centers. No image warp/rotation/mirroring hides mismatch. Residual is about4.9world units for the X view and3.5for Y; these are diagnostics, not measured proof of exact contact or an acceptance threshold. Span width, true bank sockets, bends, ramps and final water/depth clipping remain prototype refinement work. At a bend the current study picks one actual straight crossing; it does not assert a bend-spanning bridge.

## Contact and geometry remain proposals

All ordinary building comparison hulls are the current2×2logical footprint. Gallery framing uses silhouette width116world units and a bottom offset16 to compare scale consistently; it is explicitly **not** a semantic contact calibration. PNG aspect ratios differ, especially hutL2/L3; source pixels and alpha are preserved, with display transforms in `manifest.json`. A normalized silhouette width does not prove all physical ground contacts are inside the hull. No ground mask was invented from roof alpha. Higher levels visibly gain height/detail, while game occupancy stays unchanged.

Each river card now identifies the waterward logical side and selected nominal pose: +X front/right or −X opposite are hand-assigned, uncertified studies; Y banks explicitly lack an authored quarter-turn and bends require a chosen edge/additional views. Mismatches remain visible rather than claimed compatible.

No full four-direction building set, editable3D model, accepted realism/color calibration, corrected SpriteKit anchor, final LOD export, certified source camera or production collision/hit mask is claimed. The opposite-facing fish concept needs direction/lighting review. Some source padding is narrow despite no measured edge clipping; final export padding and phone readability must be selected with prototypes. Housing and storage neighborhoods expose depth/roof relationships for review, not certified seamless production meshes.

## Provenance and verification

- [Exact prompt set](prompts/), [generation receipts](generation-receipts.json), [native measurements](measurements.jsonl), [manifest](manifest.json). Every asset has stable review ID, original generated filename, input-reference hash, prompt hash, PNG hash/dimensions/alpha, proposed frame and explicit unapproved status. New concepts reference preserved legacy or newly generated family assets. Bridge concepts are new generation without external reference images.
- `swift scripts/verify-art.swift --inspect-images ...` reuses native ImageIO/CoreGraphics measurement, with no optional Python imaging dependency. It reads only; original audit/no-argument modes remain supported.
- `python3 scripts/build-art-gallery.py` verifies pinned generation-output/prompt/reference digests from durable receipts, all20shipped-original hashes,13alpha images and seven actual-map fixtures; regenerates only review `manifest.json`/`gallery-data.js`. It fails if the seed hash has drifted from Gate 1.
- Browser QA used the available native CUA in-app browser (no separate Browser plugin skill or new Playwright package). Meaningful page content,13asset links, five cluster scenes, seven river cards and no relevant console errors were verified. L2/L3 pairing and opposite-bank selection updated the rendered scenes. Desktop and390×844phone override inspected; phone DOM content/client widths both375(no horizontal overflow). Temporary viewport reset afterward.
- Automated tool/fixture regression details and independent review are recorded in [execution evidence](../../testing/building-art-gate-2/progress.md).

Original game artwork/config/runtime and all player saves/history are untouched. Sibling media repository remains clean697b486 with no configured remote; **these review candidates are staged here, not promoted into its canonical production registry**. No unavailable ChatGPT ZIP bytes were imported. License/provenance is recorded as new built-in AI-generated review art; no new legal/commercial-use guarantee is inferred.

Next is owner selection/refinement of prototypes and proposed contact/anchor treatment. Accepted candidates can later be promoted into the separate media repository and exported in a distinct reviewed integration step. No mass production, runtime replacement, R2-07, defense gameplay or UI milestone is activated by this gallery.
