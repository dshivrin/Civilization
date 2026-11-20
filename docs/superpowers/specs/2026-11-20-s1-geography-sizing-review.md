# S1-Geography — settlement-derived sizing and migration review

**Decision update:** Dima has now explicitly approved64×48size after reviewing the authorized isolated developer preview. The original assessment's approval-pending language below is historical for the size decision; existing-normal-world migration, production catalog activation and broader Geography delivery remain gated. [Direct source](../../design/sources/2026-11-20-large-preview-approval-navigation.md), [preview/navigation delivery](../../milestones/large-developer-village.md).


20 November 2026. **Recommendation: 64×48, conditional spatial pass; awaiting Product Owner approval. No activation.** This is a quantitative design assessment, not an implemented map/migration or a hardware benchmark.

## Authority and scope

The Product Owner requests comparison of 48×36, 64×48 and 80×60 using the actual 20-type catalog, proposed variable footprints, 2×2 residences, neighborhoods/courtyards, pedestrian roads, public space, rearrangement reserves and persistent natural territory. Preserve every saved coordinate and existing geography. Direct movement without entering edit mode is a **future UX requirement**, excluded from implementation here. All FP/RD/LC/AUDIO/WND/GEO/UX/CLU and MAP-005 future work remains preserved; no second-era gameplay.

Retrieved [MC-002 / issue #1](../../design/sources/2026-11-20-mc-002-geography-gate.md) before this assessment. Its 48×36 suggestion was a proposal; this human request supersedes it with a requirements-based comparison, not approval of 64×48. MAP-001–004 remain the bounded geography requirements. Existing S1-Saves human acceptance and locked-device first-launch verification remain open.

## Method, assumptions and reproducibility

Run `python3 docs/analysis/s1-geography/evaluate.py` from the repository root. Standard library only. [Source](../../analysis/s1-geography/evaluate.py), [machine-readable areas, all 64 coordinates and district bounds](../../analysis/s1-geography/results.json), and [64×48 layout](../../analysis/s1-geography/layout-64x48.svg) are committed review artifacts. The script reads bundled `seed.json`, never player saves. Its JSON records the input SHA-256.

Footprints use the **unapproved illustrative table** in [the recovered design](../../design/sources/2026-11-19-recovered-design-next-phase.md). Housing remains 2×2; campfire remains 1×1 at (17,12). This analysis does not approve a footprint table, rotate controls, residential bonuses, decorations as gameplay objects, or any economics change.

The terrain prototype copies the entire original rectangle x=0…31, y=0…23 exactly. New land extends only toward positive axes. The river exits its existing two-tile outlet at (24,23)/(25,23), turns east along added rows 24–25, then south at x=width−12/width−11. A western wooded edge and eastern forest/hills remain. This angular tile-level bend is a **proposed annex**, not existing geography or accepted final river art. No bridge or clearing of existing forest is assumed.

Count grass/clearing as buildable, water/hill/forest as blocked. Four-neighbor flood fill from campfire measures the connected settlement-side component **before construction**, excluding the far bank. Roads are a separate four-neighbor connected network after construction. Building frontage, plaza approach, quarry approach, all extraction-recipe Manhattan deposit ranges and required nearby terrain (assuming discovery), non-overlap, total footprint area and every original terrain cell are checked. All counts are exact **for this proposed terrain and authored layout**, not a guarantee for arbitrary annex geography or arbitrary player layouts.

An earlier gradual southeast river continuation left only 1,192 connected tiles at 64×48 and the initial district packing failed. The reviewed eastward bend deliberately preserves a broad south-bank plain and yields 1,494. Thus **dimensions alone do not pass**: approval must include a contiguous-land requirement and annex shape. The failed packing was not proof that no compact layout could fit.

## Complete settlement inventory

| Actual catalog kind | Proposed footprint | Count | Occupied tiles |
|---|---:|---:|---:|
| campfire | 1×1 | 1 | 1 |
| hut | 2×2 | 24 | 96 |
| gatheringShelter | 2×1 | 2 | 4 |
| huntingLodge | 2×2 | 2 | 8 |
| fishingShelter | 2×1 | 2 | 4 |
| woodcutter | 3×2 | 3 | 18 |
| stoneGatherer | 3×2 | 2 | 12 |
| farm | 4×3 | 4 | 48 |
| animalPen | 3×3 | 2 | 18 |
| storehouse | 3×2 | 3 | 18 |
| toolmaker | 2×2 | 2 | 8 |
| tannery | 3×2 | 1 | 6 |
| potteryWorkshop | 3×2 | 1 | 6 |
| storytellingCircle | 3×3 | 1 | 9 |
| healersHut | 2×2 | 1 | 4 |
| shrine | 2×2 | 1 | 4 |
| burialGround | 3×3 | 1 | 9 |
| scoutCamp | 3×2 | 1 | 6 |
| watchtower | 1×1 | 2 | 2 |
| palisade | 1×1 | 8 | 8 |
| **Total** | **20 types** | **64** | **289** |

This represents a mature village with redundant food, wood, stone, tools and storage, rather than one specimen of each building. Eight palisades are illustrative boundary segments, not a complete enclosing wall or new defense mechanic. With current housing values it offers 125 capacity and 28 base worker slots; it does **not** imply 125 actual residents, a balanced full-occupancy economy or simultaneous operation. Population/maintenance/paid progression remain unchanged. This is a spatial completion scenario, not a new legitimate-progression test or an optimal economic recommendation.

Three 10×10 residential districts contain eight houses each:

- Pairs at district (10,14): four touching pairs with pedestrian lanes.
- Squares at (31,37): two groups of four touching 2×2 homes, with space outside the groups for communal use.
- Courtyard at (41,37): eight homes in a 3×3 pattern around a free central 2×2 courtyard, with one-tile lanes between homes. The center remains reserved for decoration; it is not occupied by a house or awarded a bonus.

Food/agriculture district: (3,26), 16×16; industry: (19,26), 14×10; civic: (19,36), 12×9; logistics/storage/scouting: (33,26), 12×11. Two fishing shelters move from the generic food block to near-bank (21,24)/(21,25). A third woodcutter sits near the western forest at (4,24), within its original deposit range. One stone gatherer sits on a near-side worksite at (7,24), 3×2, with approach at (10,24). These are authored **example placements**, never relocations of existing player buildings. See JSON for every instance.

The connected road network reaches **64/64 structures**, including every production building, the quarry approach and the plaza. Maximum shortest road distance from the campfire approach to a road cell is **80 tiles**. Roads remain decorative; this study creates no access requirement, transport costs or NPC logic.

Public/decoration space is **151 tiles**, including a separate **6×6 plaza at (4,5)** with road access, courtyard centers and district pockets. Rearrangement reserves are **12×6 at (3,42)** and **8×8 at (12,0)**: **136 tiles**, large enough to stage multiple largest 4×3 farms or residences without demolishing a neighbor. Another **352 unassigned connected tiles** remain, but their sum is not a promise of another single rectangular district.

## Land and size comparison

| Terrain / capacity | 48×36 | 64×48 | 80×60 |
|---|---:|---:|---:|
| Total tiles | 1,728 | 3,072 | 4,800 |
| Forest (blocked) | 388 | 744 | 1,228 |
| Water (blocked) | 96 | 152 | 208 |
| Hills (blocked) | 179 | 227 | 275 |
| Buildable grass + clearing, both banks | 1,065 | 1,949 | 3,089 |
| **Connected settlement-side buildable land** | **746** | **1,494** | **2,626** |
| Other-bank buildable land, excluded from settlement budget | 319 | 455 | 463 |
| Added territory outside unchanged 32×24 | 960 | 2,304 | 4,032 |
| Complete authored village fits | No | **Yes** | Yes |

For 64×48, the connected land budget is disjoint and reconciles exactly:

`289 buildings + 566 roads/access + 151 public/decor + 136 reserved rearrangement + 352 unassigned = 1,494 tiles`.

Buildings occupy 19.3% of usable connected land, buildings plus roads 57.2%, public/decor 10.1%, and reserved plus unassigned free land **32.7%**. Dense clusters sit within a much greener world; comparing 289 only with 3,072 would conceal the actual space constraint.

The seven district envelopes total **936 tiles** (including their internal roads/pockets); add 136 staging tiles, 36 separate plaza tiles and 16 outlying fishing/quarry/woodcutting building tiles for a **1,124-tile floor** before external links. This alone exceeds the 48×36 prototype's 746 connected tiles by **378**. Its greedy diagnostic only places 28 structures and is explicitly an incomplete attempt; it is not used to claim mathematical impossibility of a different, much tighter village. This candidate requires fewer duplicates, smaller neighborhoods/reserves, less natural territory or bridge access to satisfy this brief. [48×36 attempt](../../analysis/s1-geography/layout-48x36.svg).

80×60 uses the **same authored settlement at the same coordinates**, avoiding an artificially spread layout. All 64 buildings have access. It leaves **1,484 unassigned connected tiles**, versus 352 at 64×48; built/road coverage falls to 32.6% of connected land. It offers no demonstrated Stone Age requirement advantage for its extra 1,728 tiles and increases navigation/render/discovery exposure. [80×60 layout](../../analysis/s1-geography/layout-80x60.svg).

**Recommendation:** 64×48 with this preserved core and an annex delivering **at least 1,450 connected buildable tiles**, the exhibited district fit and **at least 130 tiles of explicitly rectangular rearrangement reserves**. The 1,450 floor is a proposed acceptance threshold, not permission to substitute arbitrary terrain that merely meets an area sum. Require the actual coordinate layout/access checks too. Footprint changes, larger decoration objects, realistic artwork overhang and touch readability may require renewed review; unused land is not approval of later-era gameplay.

## Pacing, discovery and navigation

Keep first-era required discoveries, paid research/construction, rewards and starting resources unchanged. Initial radius 7 and existing explored tiles remain; do not expose the annex or require whole-map exploration for Stone Age readiness. Future-resource territory can remain permanently discoverable without becoming a new era requirement. Clouds conceal all undiscovered cells/landmarks and interaction; revealed sets only grow and persist independently per normal/developer world. No cloud service is proposed.

Under the current Chebyshev radius mechanism (step 2, 45 seconds, 10 food), full-map coverage from a new game requires the following **analytical expedition totals**, excluding food accumulation, camp construction and gameplay time:

| Candidate | Farthest radius | Expeditions from radius 7 | Expedition timer total | Food spent |
|---|---:|---:|---:|---:|
| 48×36 | 30 | 12 | 9 min | 120 |
| 64×48 | 46 | 20 | 15 min | 200 |
| 80×60 | 62 | 28 | 21 min | 280 |

The existing 32×24 reaches its farthest radius 17 after five expeditions (3.75 min/50 food). Current code clamps radius to 32, which would strand part of 64×48 and 80×60. **Propose** a per-map farthest-radius cap while retaining current cost/time/step and scout requirement after 11. This makes more expeditions available; it does not retroactively complete old expeditions or charge for old discovery. Old radius 32 must not reveal added territory merely because a global radius predicate becomes larger. Existing explicit discovered sets are authoritative; pending expeditions retain their paid cost and timer and reveal once under their original target/domain policy. Material pacing changes require approval here before implementation.

Quarry approach (10,24) is radius 12, ordinarily reachable on the third expedition (radius 13), after legitimate scout access. Keep original stone/flint IDs, locations and remaining reserves. **Propose an added visual/worksite access landmark linked to existing `valley-stone` reserve**, not a duplicate resource grant or relocation of its original deposit at (27,4). The example near-side stone gatherer remains within that deposit's existing Manhattan radius 40: |7−27| + |24−4| = 40. Do not alter existing cells to draw a quarry; author the landmark solely on new land. Landmark art, exact access semantics and shared reserve identity require approval. This avoids silently replenishing stone or duplicating discovery rewards.

Keep existing center-on-settlement and pan/pinch. Camera bounds must use each world's dimensions; initial view stays on campfire rather than zooming out fourfold. Full-world view may aid orientation, but essential phone touch targets must retain usable scale. The 80-tile road extent is a layout measure, not an estimate of swipes or human navigation time. Test at existing phone/mini/Pro zooms; no new minimap, planner or direct movement implementation is authorized by this study.

## Device performance — analytical risks, not measured passes

World tile counts are 2.25×/4×/6.25× the current 768. The current `SettlementScene` builds visible ground/scenery nodes, flattens them into a texture and rebuilds on discovery. Cached water activity is bounded, but larger worlds can increase rebuild work and peak texture memory substantially. Approximate complete diamond bounds are (width+height)×32 by (width+height)×16 at the existing 64×32 tile projection, without art overhang, texture padding, retina scaling or mipmaps:

| Map | Approximate texture bounds | One RGBA8 image |
|---|---:|---:|
| 32×24 | 1,792×896 | 6.1 MiB |
| 48×36 | 2,688×1,344 | 13.8 MiB |
| 64×48 | 3,584×1,792 | 24.5 MiB |
| 80×60 | 4,480×2,240 | 38.3 MiB |

These are estimates, **not measured GPU/RSS or proof of texture support**. A transient old/new image pair at 64×48 already represents ~49 MiB before other allocations; 2× raster scale would quadruple these memory estimates, and actual device texture limits/scaling must be checked. Avoid approving performance on tile count alone. Chunked static terrain/cloud caching within SpriteKit is a candidate mitigation, subject to a bounded implementation plan; no renderer replacement.

Before activation: compare current/expanded matched scenes on phone, A15 mini and M1 Pro target hardware where available; simulator checks separately. Measure cold load, resident/peak memory, pan/pinch frame times, full-reveal and single-expedition rebuild stalls, roads/buildings/fog, reduced-motion fallback, sustained thermal/battery behavior and library switch/reload. Retain 60 FPS aim (16.7 ms frame budget). Report unsupported hardware and regressions explicitly; do not substitute simulator FPS or analytical estimates for physical acceptance. Hardware/performance gate remains open.

## Expansion and migration recommendation

Three policies considered: new games only is lowest migration risk but strands existing investment on a small map; mandatory expansion maximizes consistency but forces an unreviewed change; **recommend new games at the approved size plus opt-in, additive expansion per existing normal world**, with an exact legacy mode available until consent. This is the engineering recommendation for approval, not an inferred human selection. Developer companions remain independent; never expand every file just because a global config changes.

1. Maintain immutable map-definition versions for the legacy core and reviewed annex. Preserve `river-clearing-v1` world identity; store an additive per-world geometry revision/bounds or equivalent explicit compatible metadata. Missing metadata means exact legacy geometry, never 'use latest'. Select configuration by world before loading/validation/rendering. Current hardcoded 32×24 validation must be deliberately replaced with supported-version validation. Save v5 compatibility must be maintained; settle the additive field representation and old-binary behavior in the approved implementation design. Never assume an older app can read the expanded world.
2. Expand positive x/y only: old tile (x,y) stays (x,y); no translation, scaling, recentering, terrain regeneration or map-ID substitution. Hash/compare all 768 old cells and every original deposit definition. Roads, occupied footprints/orientations, stable IDs, construction, research, population/workforce, resources, depleted reserves, rewards/readiness, timers and last-updated state are preserved. Do not create the example settlement in player saves.
3. Snapshot and production-validate each affected save plus its world/library metadata before consented conversion. Preserve an immutable pre-expansion backup with hashes and original geometry identity. Stage deterministic expanded state in memory/temporary storage; validate supported map version, old-core equality, all geometry/roads, discovery, deposits and library isolation before publication. Ordinary clock catch-up is a separate operation, never a migration reward or replay.
4. Make the revision part of the world's atomic save envelope where feasible, so the library index continues pointing to the same world/path. If multiple files are unavoidable, use a recoverable transaction/journal with explicit commit marker. Keep the library selection stable; no index switch to a partially converted file. Disk-full, corrupt source, failed validation or process interruption must leave the original usable or recover it deterministically from the preserved backup. No silent reset or best-effort auto-repair.
5. Discovery migration copies the explicit tile set exactly, bounds old pending reveals to their legacy target/domain, and starts all added cells hidden. A previously fully explored old map remains fully explored **only within its old bounds**. Preserve cost/timer/no duplicate charge; revealing the annex happens through later ordinary expeditions. Do not interpret saved radius 32 as automatic permission to reveal new cells on load.
6. Legacy nil footprint snapshots must resolve against the **original catalog**. If larger footprints are separately approved later, explicitly capture old effective sizes atomically before changing fallback definitions. Never enlarge on load, movement or upgrade implicitly. Moving a legacy building retains its captured footprint; an optional resize/conversion needs its own safe placement transaction and product approval. Map approval does not activate variable footprints.
7. Add the quarry access landmark only inside guaranteed-new terrain after checking occupancy/discovery and shared reserve linkage. No original deposit or reward changes. The retained legacy mode keeps its original rules until separately approved remediation; do not fake a quarry on occupied or blocked existing land.
8. Validate each normal UUID/legacy world and each developer companion independently, across switch/background/relaunch. Migration is idempotent; a second open makes no further terrain/discovery/resource changes. Rollback returns to the exact backed-up pre-expansion world and explicitly excludes annex progress; never silently discard post-expansion construction or down-save it into 32×24. Preserve private save contents locally.

## Approval and delivery gates

**Spatial gate:** passed for the proposed 64×48 annex, provisional footprints and 64-instance layout. Script confirms all 20 types, no overlap, all building/road cells in the connected component, 64 accessible buildings, connected road/quarry/plaza approaches, disjoint area accounting and original core equality. It also checks all deposit-dependent recipe ranges and required nearby terrain under full discovery. It does not run the game or exercise economic progression; depleted deposits and undiscovered/technology-locked sources remain unavailable during actual play.

**Product decision requested:** approve 64×48 plus the annex/contiguous-land requirement, new-world default and per-world opt-in policy, positive-axis coordinate preservation, existing-reserve quarry access, and extended radius cap with unchanged expedition economics. These are concrete recommendations; approval can amend any of them. Direct movement outside edit mode stays future-only.

After explicit Product Owner approval, reconcile the final S1-Geography implementation design/plan before product code. Then require migration corruption/interruption/retry and no-write-on-failure tests, normal/developer/library isolation, pending expedition/offline/idempotency and no-hidden-interaction regressions, core Debug/Release and Release exclusions, phone/mini/Pro native checks and measured performance. Physical backup/install/launch remains subject to actual device access; no reset/uninstall. Human usability/art/enjoyment acceptance remains separate. No map, footprint, save schema, renderer or installed app changes are included in this report.

## Assessment verification record

Fresh offline evaluation completed on 20 November 2026. Both 64×48 and 80×60 pass the authored spatial/access/terrain/deposit-range assertions; 48×36 is explicitly incomplete. Three SVGs parse as XML and all local report/source links resolve; area accounts reconcile. Independent builder review corrected the quarry and third woodcutter to remain inside the original Manhattan deposit radii and corrected projection memory estimates. The final model includes assertions for every deposit-dependent recipe and required terrain. Product source/config/assets/project files and private saves are untouched; no app or hardware tests were run for this documentation-only assessment.
