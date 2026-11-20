# Building Art Gate 1 audit — 20 November 2026

Status: **engineering audit complete; proposed contracts awaiting visual review**. Gate 2 generation/integration has not begun.

Authority: [owner-approved plan](../../../plans/2026-11-20-stone-age-building-media-library.md), direct “Implement”, Master reply `34783060-ac9e-4dc0-9c8d-792ae091dbcc` in the [designated chat](https://chatgpt.com/c/6aff4440-ac14-83eb-b7bd-1f2d8bd9a0a9). The later roads/defenses plan on origin/main cbc0363 is future scope, not permission to add gameplay in this audit.

## Verified sources and outputs

Game baseline `a0cd0e7`; media repository `697b486`, clean and local-only (no configured remote). All20 high-resolution masters exist in `/Users/dima/dev/Civilization-Media/buildings/masters`. All are1254×1254 PNGs and byte-identical to the retained game source copies and registry hashes. All20 world exports512×512 and thumbnails144×144 also match their media export copies exactly. Registry validation passes68records with license references; that is provenance consistency, not a new legal/commercial-license judgment. Media state remains untouched.

- [Measured inventory](evidence/inventory.json): exact per-file SHA-256, dimensions, bytes, alpha fractions/bounds, edge-clipping count, current footprint, orientation and manifest anchors. Config/art/registry input hashes pin the snapshot.
- [Diagnostic atlas](evidence/atlas.html): all20 sprites at the **actual same world scale**, overlaid on the real footprint hull/center. This is a static reconstruction of current projection, not an in-game screenshot or accepted art.
- [Actual river geometry](evidence/river-fixtures.svg), [fixture coordinates and bank edges](evidence/river-fixtures.json).
- [Proposed export/ground/river/modular contracts](contracts.md).

## Measured inventory and visual findings

Bounds below are runtime512×512 raster coordinates `[left,top,right,bottom]`, inclusive, alpha>32. They measure the **whole silhouette**, including roof/props/shadow; they do not claim exact semantic ground contact. All source images have real transparency and0covered edge pixels. No current image is certified against the newer realism/color/modularity target merely because alpha passes.

Current logical footprint is campfire/palisade1×1 and eighteen others2×2. All20 support logical north/east/south/west; **one sprite is reused for every level and direction**. Runtime dimensions are80×80/anchor(.5,.35) for campfire,160×160/anchor(.5,.18) for every other kind, including palisade. All gameplay levels are1–3. Ordinary upgrades require completed construction, payment and bootstrap reserve safety; no additional per-level research gate. Initial research unlocks are below. Civic L2 requires Oral Tradition and L3 Social Order, with their existing paid costs. Level changes retain IDs, footprint and orientation; renderer currently does not select level art.

| Kind | Tiles | Initial research | Alpha coverage | Runtime silhouette bounds | Observed gap |
|---|---|---|---:|---|---|
| campfire | 1×1 | None (ordinary start) | 19.4% | `[50, 204, 469, 423]` | Fire/log arrangement; no distinct Gathering Place/Council Circle art. |
| hut | 2×2 | None (ordinary start) | 52.6% | `[31, 27, 480, 477]` | Roof overhang and front pots need separate contact mask; housing blue identity absent. |
| gatheringShelter | 2×2 | None (ordinary start) | 34.4% | `[36, 91, 478, 443]` | Open posts/baskets; distinguish from civic Gathering Place; purple accent absent. |
| huntingLodge | 2×2 | Hunting | 31.4% | `[23, 150, 487, 451]` | Hides and tent profile; preserve distinction from fishing shelter. |
| fishingShelter | 2×2 | Fishing | 42.6% | `[30, 60, 473, 442]` | No baked water rectangle visible; no bank socket/overlay or direction variants. |
| woodcutter | 2×2 | None (ordinary start) | 49.3% | `[13, 42, 498, 457]` | Wide log/stump spread; check contact against neighboring tile access. |
| stoneGatherer | 2×2 | None (ordinary start) | 35.6% | `[41, 91, 472, 427]` | Loose stone piles and posts need contact segmentation. |
| farm | 2×2 | Cultivation | 22.9% | `[54, 213, 458, 458]` | Soil/crop bed is baked into sprite; remove square-seam risk in prototype. |
| animalPen | 2×2 | Animal Domestication | 29.7% | `[64, 130, 454, 442]` | Fenced yard is baked in; define true contact perimeter separately. |
| storehouse | 2×2 | None (ordinary start) | 42.8% | `[57, 36, 451, 464]` | Raised granary; gold/blue identity and mixed-level connectors missing. |
| toolmaker | 2×2 | Stone Tools | 38.2% | `[37, 91, 477, 423]` | Tools/bench silhouette; blue identity missing. |
| tannery | 2×2 | Leatherworking | 37.1% | `[25, 103, 488, 426]` | Rack hides silhouette; orange identity missing. |
| potteryWorkshop | 2×2 | Pottery | 37.8% | `[27, 74, 485, 420]` | Kiln/fire/pots extend around hut; terracotta identity to strengthen. |
| storytellingCircle | 2×2 | Oral Tradition | 47.1% | `[23, 54, 489, 442]` | Baked earthen disc; optional building, not founding civic entity. |
| healersHut | 2×2 | Herbal Medicine | 43.9% | `[33, 55, 484, 451]` | Herb pots; green family accent needs review. |
| shrine | 2×2 | Rituals | 42.4% | `[44, 44, 466, 452]` | Stone group and offerings; no sacred-site gameplay currently enforced. |
| burialGround | 2×2 | Burial Traditions | 24.3% | `[35, 156, 472, 381]` | All measured visible pixels above anchor by ≥11.8 world units; apparent floating base. |
| scoutCamp | 2×2 | Exploration | 31.2% | `[26, 73, 486, 431]` | Tent/rolled supplies; no direction/upgrade variants. |
| watchtower | 2×2 | Surveillance | 32.9% | `[87, 23, 423, 480]` | Tall four-post structure; currently standalone 2×2, no wall sockets. |
| palisade | 1×1 | Fortification | 25.8% | `[34, 149, 484, 399]` | Curved enclosure in one sprite; 160-wide canvas versus 1×1 footprint; lowest pixel above anchor. Not modular wall pieces. |

## Ground contact, perspective and missing deliverables

The atlas shows a repeatable mismatch: one generic(.5,.18)anchor places different ground bases at different apparent elevations. Burial ground's lowest covered pixel is11.8world units **above** its ground-center anchor; palisade's is6.2above, and its silhouette width is roughly141world units across a64-wide1×1diamond. These are diagnostics, not proof that every overhanging pixel is ground. Hut/industrial roofs legitimately overhang. Do not fix these by enlarging occupancy or scaling every object into a square.

Existing inputs lack authored contact polygons, ground-only alpha masks, level/direction selectors, roof/ground layers, sockets, elevation metadata, geometry-aware bank overlays and per-level master/export registry entries. Their exact contact bounds/perspective cannot be recovered reliably from alpha alone. Gate 2 must supply and visually approve semantic masks/anchors; the proposed contract defines how. No editable3D models are present/claimed. The legacy camera looks broadly isometric in the board, but no source-camera calibration exists, so exact camera/perspective/lighting compliance remains unverified. Lighting is broadly warm from upper-left; saturation/color identity remains a visual review decision.

The downloaded interim ChatGPT ZIPs and their four new review concepts are not imported or assumed available. The local20existing masters originate from the earlier Codex-generated candidate set; they are not falsely labeled newly received ChatGPT originals. There are no verified L2/L3/directional game-ready exports or approved modular pieces. No source master is missing; the **new production deliverables** are missing.

## Verification and preservation

`python3 /Users/dima/dev/Civilization-Media/scripts/validate_registry.py` passes68records/20masters. Existing `swift scripts/verify-art.swift` validation passes20sprite/thumbnail pairs, genuine alpha and21MiB theoretical decoded pixels (not full process/GPU memory). Extended audit verifies20master/source/registry hashes and40media/runtime export matches plus seven actual-map bank fixtures. The2×2PNG coordinate fixture first failed with an unnecessary vertical transform, then passed after removing it; initial wrong-coordinate artifacts were retained outside Git under `/tmp/civilization-art-gate1-initial-flipped-evidence`. Final JSON uses top-left row order. A loopback browser inspection verified all20atlas cards and the river layout. The board/source PNGs were also inspected.

Independent review confirmed the current measurements and identified three verifier issues; all were reproduced and fixed with isolated integration tests. Final tooling suite13/13passes, and the corrected native generator reproduces all four inspected artifacts byte-for-byte. Export checks now pin per-kind registry IDs, master linkage, paths and digests; output reservation is exclusive and rejects the resolved media root, including symlinked parents. [Verification metadata](../../testing/building-art-gate-1/verification.json).

No runtime source, seed configuration, artwork, media registry, signing, player save or progression file is changed. No Swift/GameCore/UI suite rerun is claimed for this documentation/offline-tool delivery. R2-07 remains absent and tonight's gameplay acceptance remains open. Existing physical installation is not updated by this audit.

## Next gate

Owner reviews this atlas and the proposed contracts before Gate 2. The prototype set is HutL1–L3, Gathering Shelter, housing clusters, mixed-level storage clusters and FishingL1–L3 using actual bank fixtures. Civic L2/L3 art needs its own identity slots. Defense/bridge pieces remain visual interface proposals with gameplay separately gated. No mass generation, runtime export replacement or footprint migration is authorized by passing Gate 1 measurements.
