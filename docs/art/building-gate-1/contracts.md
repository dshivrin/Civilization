# Gate 1 proposed rendering contracts

Status: proposed for visual review. These contracts specify future media deliverables, not shipped schemas or activated gameplay. Read with the [audit](audit.md) and approved [building plan](../../../plans/2026-11-20-stone-age-building-media-library.md). Current runtime and saves remain authoritative.

## Coordinates, contact and depth

The current `MapGeometry` transform is `worldX = 32(x−y)`, `worldY = −16(x+y)`. Tile diamonds are 64×32 world units; the logical x axis points down-right and y down-left on screen. Do not infer camera compass directions from logical north/east labels. Ground elevation is currently zero; rocky hill silhouettes do not create a heightfield, cliff classification or new buildable land.

A w×h footprint centered at its actual occupied tile centers has a hull with world vertices:

```
(16(h−w),  8(w+h))
(16(w+h),  8(h−w))
(16(w−h), −8(w+h))
(−16(w+h), 8(w−h))
```

East/west quarter turns swap w/h before projection; north/south retain them. For current square footprints the hull is unchanged, while directional media must still differ. No 2D rotation/mirroring of fixed lit raster masters is a substitute for rendered cardinal views. Higher levels retain the same occupied ground and center; they may have taller roofs. Preserve legacy instances' captured footprint/orientation rather than rewriting saved geometry.

For a source pixel edge coordinate (u,v), with v measured down from the top, normalized anchor (ax,ay) measured from the bottom for SpriteKit, and W×H declared world size:

```
worldX = (u / pixelWidth − ax) W
worldY = (1 − v / pixelHeight − ay) H
```

Use pixel edges for polygons; inclusive alpha bounds use the outer edge `right+1,bottom+1`. Do not confuse image-pixel size with logical tiles or world size. In particular current palisade occupies 1×1 despite a 160×160 sprite canvas.

Proposed contact contract: author a semantic ground-contact polygon/mask separately from the total silhouette and optional soft shadow. Contact geometry must lie within the authoritative footprint hull; roofs/upper silhouettes may overhang. The anchor is the projected center of the actual occupied ground, not an arbitrary common fraction or the bottom of the canvas. Fit the authored contact geometry, then set per-export anchor and world size; do not resize ground occupancy to fit art. Exact anchor corrections remain a visual decision, not a blanket numerical change from this audit. Level/direction variants share a stable contact frame. Padding must avoid clipped roofs/props at exported resolution.

Current depth is `origin.x + origin.y + w + h − 2`, under a building layer above roads; silhouette picking uses alpha with logical footprint fallback. Future ground/roof/connector layering must preserve reachable selection of neighbors. Tall silhouettes and props require adjacent-row occlusion QA; do not claim a correct depth solution solely from an alpha mask. Keep the current fallback until accepted multi-layer exports and selection tests exist.

## Proposed per-export registry contract

Each future export must record these values before game integration:

| Field group | Required values |
|---|---|
| Identity | Stable semantic ID, building kind, era, actual level, logical orientation, variant, construction stage |
| Provenance | Master ID/path/hash, media commit, prompt/source, tool/version, license reference and direction-review status |
| Geometry | Logical base footprint, oriented footprint, world size, source/export pixel dimensions, bottom-origin anchor, ground elevation (zero for current game) |
| Semantic bounds | Ground polygon/mask, complete alpha bounds, roof/props/soft-shadow layers, overhang limits and hit-test policy |
| Sockets | Local coordinates/side/tangent, layer, compatibility family, level-independent contact frame; absence explicit |
| Export mapping | Runtime/thumbnail paths, alpha mode, color profile, hashes, selected LOD, approved fallback ID, visual-review receipt |

Use distinct IDs such as `stoneAge.hut.l2.east.base` and `stoneAge.housing.join.east.yard`, preserving existing IDs as fallbacks. These are proposed media names, not an `ArtCatalog` schema change. Current IDs `building.<kind>.master` remain intact. Civic IDs must distinguish the same campfire entity's Campfire/Gathering Place/Council Circle stages from the separate Gathering Shelter/Storytelling Circle kinds.

Retain transparent PNG masters at original resolution, create exports separately, keep editable source/prompt provenance. Do not treat a concept-sheet crop as an accepted transparent master. Do not bake a brown square, placement grid, bank or water rectangle into the object. Color families follow the approved brief: housing blue; gathering/cultural purple; storage gold/blue; hunting forest-green/rust; fishing teal/blue; healing green; pottery terracotta; tannery orange; tools blue. Color alone must not carry identity. Camera, lighting and saturation are assessed against the prototype set at real phone scale; do not certify them from metadata.

## River-band contract and actual fixtures

`WorldDetails.waterEdge` draws the bank on each water tile side with a non-water cardinal neighbor, provided that neighbor is revealed. Endpoint coordinates relative to the water-tile center are:

| Logical neighbor | Bank segment endpoints in world units |
|---|---|
| x−1 | (−32,0) → (0,16) |
| y−1 | (0,16) → (32,0) |
| x+1 | (32,0) → (0,−16) |
| y+1 | (0,−16) → (−32,0) |

The current bank is a 5-unit rounded stroke, with a 1.2-unit shallow-water line and optional reeds. Future joins align to these exact tile edges rather than to a hand-painted horizontal river. Coordinate records use logical N=(0,−1), E=(1,0), S=(0,1), W=(−1,0); bank segment names above are deliberately explicit.

Current fishing legality is a revealed water tile within a square radius of 3 **around the building origin**, plus ordinary clear 2×2 footprint checks. It does not enforce touching a bank, a socket, a bank-facing orientation or a full river crossing. No placement rule changes in this task. For a visually adjacent site, select an actual shared land/water edge; for a currently legal inland site, retain the existing fallback rather than drawing water over land or silently moving the building. Requiring edge attachment for all placements is a separate gameplay/save decision.

Proposed sprite layers: land-only shelter/contact; independently selectable bank-join/deck at an actual edge; optional transparent water interaction/shadow clipped to existing water tiles. Bank sides and tangent determine art variant. Support multiple candidate edges at a bend deterministically (explicit chosen edge or stable order), and do not leak hidden river geometry through fog. No water tile becomes occupied by a building merely to make a deck look correct. Any new water/deck collision policy needs separate approval.

[Fixtures](evidence/river-fixtures.json) pin the config hash and list real contact edges. [Projected map](evidence/river-fixtures.svg) is a diagnostic, not an in-game screenshot. All named origins have clear 2×2 land and at least one cardinal water contact when fully revealed; no live occupancy/resources/research are assumed.

| Fixture | Origin | Purpose |
|---|---|---|
| west-bank / east-bank | (19,8) / (23,8) | Opposite sides of the original two-tile river band |
| bend | (21,1) | Two logical bank directions at a real turn |
| annex-west / annex-east | (50,28) / (54,28) | Opposite sides in the additive geography |
| horizontal-north / horizontal-south | (35,22) / (35,26) | Opposite banks of the horizontal annex band |

Prototype QA uses each orientation on these sites, plus inland-but-radius-legal and unrevealed-edge fallback cases. Bridges are absent: visual bridge joins may later reference the same edge coordinate contract, but no bridge, crossing route, pedestrian or pathfinding behavior is implemented or certified here.

## Housing and storage modular connections

Proposed adjacency is visual-only and derived from existing occupied tiles, not serialized as a new building or prerequisite. Buildings remain individually selectable/movable and upgrades retain footprint. Candidate socket is at the midpoint of a **full shared cardinal tile edge** on compatible housing/housing or storage/storage footprints; no corner-only, gap-spanning, building-through-building or across-road connector. If several full edges meet, choose a deterministic compatible pair and do not duplicate a connector (stable building IDs). Level pairs L1–L1, L1–L2, L1–L3, L2–L2, L2–L3 and L3–L3 share the same ground socket. Never connect floating upper roofs just because heights differ.

For Gate 2, prototype removable ground-yard/path and fence/roof join overlays separately. A connector must stay in already available shared contact space; it cannot occupy another building's tiles, erase a road or block the footprint-side path used by the connectivity pilot. Overlay depth and alpha must preserve neighboring touch targets. Connector choice never changes housing capacity, storage, workers, cost, service connectivity, rewards or save state. The prototype must show disconnected/free-standing variants so players keep decoration space.

Required visual matrix: 2 and 4 homes; 2,3,4 storehouses; each mixed-level pair; four orientations; shared edge versus corner/gap; neighboring road; remove/move one member; construction; overlapping roof depth; phone framing. No current runtime adjacency API or modular export exists; the above is a proposed integration contract for later approval, not delivered renderer behavior.

## Future palisade, gate, tower and cliff interfaces

Current palisade is a standalone 1×1 catalog building with one curved-enclosure image; watchtower is a standalone 2×2 building. Neither a segment perimeter nor tower socket/gate/bridge system exists. There is no separate impassable-cliff terrain: `.hill` is blocked for normal building placement but is not certified as a defensive cliff. Do not reinterpret ordinary hills as free walls.

Future media-only interface slots: straight/corner/end/closed-gate/open-gate/cliff-end; wall-road joint; tower attachment frame common to L1/L2/L3; separate bridge superstructure/span/bank joins. Natural-barrier contact requires an explicit approved cliff/collision edge from a future model. Reuse bank-edge tangent/coordinate conventions where appropriate, not arbitrary 4×1 walls or 3×3 towers. Render transparent layers with no baked water/ground squares.

The later owner plan asks for one initial gate, paid extra gates/expansion, tower-only-on-wall placement, defensive closure and pedestrian bridges. Those need a separately reconciled gameplay specification (lengths, costs, terrain semantics, crossing placement, save migration and tests); none is invented or activated by these visual contracts. Preserve current saves, road styles/masks, standalone buildings and all deferred roadmap items.

## Visual gate

Review the measured atlas and these **proposed** contracts before Gate 2. Review must select/approve semantic ground contacts, per-kind scale/anchor corrections, source camera/lighting/color identity, modular joins and bank-facing prototype treatment. Missing level/direction assets, masks and accepted exports are documented deliverables for later work, not reasons to rewrite catalog footprints or silently start production now.
