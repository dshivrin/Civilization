# Goal: Stone Age modular roads, palisade, towers, and pedestrian bridges

**Execution order:** Run only after the current Codex rotation/dedicated-placement/geography milestone is completed and reconciled. Do not overwrite existing road implementation or interrupt the current run.

## Inputs
- Approved concepts from owner discussion, 2026-11-20.
- Interim downloadable archive `Civilization-Roads-Defenses-Media.zip` generated in ChatGPT, with 19 separately named concept crops, 3 reference sheets, README, registry. **The ZIP is not uploaded to GitHub and is not automatically available on the Mac.** It is review material, not production art; source sheets include opaque backgrounds. Request/import the archive when accessible, or recreate compliant assets from the approved description. Do not claim import without verification.
- Canonical game repo `dshivrin/Civilization`; canonical local media repo `/Users/dima/dev/Civilization-Media` with its own Git/LFS registry. Existing runtime road styles and terrain masks are authoritative for geometry and gameplay; do not silently replace or expand road tiers.

## Approved rules
1. Roads connect through straight, end, corner, T, cross and gate/bridge transitions. Preserve the existing road styles, drag/edit UX and per-tile storage. Render continuous surfaces without a brown square or hard rectangular seams. Road-to-gate-to-bridge should remain a traversable path.
2. Palisade is player-drawn as a connected perimeter. Initial construction includes **one gate**. Extra gates and later perimeter expansion cost resources. Gate placement must be valid and preserve access from town to outside. Gates have correct road connections. Set initial allowed palisade length and costs from verified first-era geography/economy, not from concept sheet labels.
3. A **steep impassable mountain cliff can form part of the defensive boundary**, allowing players to omit that stretch of palisade and save segments. Ordinary hills do not count. Draw correct cliff-to-wall endpoints and validate enclosed boundary using terrain collision semantics.
4. Defense towers **attach only to palisade**, at valid wall segments or corners. No standalone towers. L1/L2/L3 tower visuals become taller/more detailed but keep **exactly the same logical footprint and wall sockets**. This fixed-footprint rule applies to **all** upgraded buildings; upgrading never moves roads, walls or neighbors. No tower included for free in initial palisade.
5. Wooden bridge: Stone Age pedestrian bridge, player placed across valid river crossing, connected to roads on both banks, usable by pedestrian agents gathering on opposite bank, not large carriages. Align ends with riverbank and actual river bands; support orientations/bends as geometry permits. **Never bake a blue rectangle of water into bridge art**; render transparent bridge superstructure and bank join layers against existing river tiles. If upgrades are introduced later, same footprint and crossing.
6. Asset style: historically inspired, colorful and readable at mobile scale; coherent isometric camera, lighting, material, alpha, anchors, rotation and z-order. Use warm wood/stone, modest blue banners, no anachronistic large stone fortification for first era.

## Required production library
Create or update the **separate** canonical `Civilization-Media` repository with:
- `roads/stone-age/{style}/{mask-or-connection}/{orientation}` assets and edge masks;
- `defenses/stone-age/palisade/{straight,corner,end,cliff-end,gate}` and `towers/{l1,l2,l3}` masters/exports;
- `bridges/stone-age/wood-footbridge/{orientation,bank-join,span}` masters/exports;
- stable asset IDs, logical footprint, anchor/socket points, layer ordering, source/prompt, license/provenance, alpha, dimensions, hashes, LOD, orientation, registry and thumbnails;
- individual high-resolution **transparent** PNG masters, not crops of a composite or sprites with baked water/ground squares;
- documented media commit ID and explicit game-side export mapping.

## Deliverables and QA
1. Audit existing road/bridge/terrain APIs and actual grid sizes; reconcile planned variants with current runtime. No speculative 4x1 wall or 3x3 tower footprints.
2. Produce separate visual pieces and reference examples; verify seams for all 16 four-neighbor road masks and turns, mixed styles, gate connections, riverbank orientations and natural-cliff boundary ends.
3. Add pathfinding/placement/defensive enclosure tests and screenshots for palisade segments, extra gate purchase, tower socket/upgrade, cliff saving, bridges and mixed river bands. Test rotation and elevation.
4. Validate no opaque backgrounds, no false water tiles, no overhang blocking interactions, no changing logical footprint on upgrades, and preserved save compatibility.
5. Present prototype screenshots to owner for approval **before** replacing runtime assets; keep old fallbacks.
6. Commit media changes in media repo and game integration separately. Push only to actual configured remotes; report SHA and whether media repo has remote. Put accepted plans in game repo `plans/`.

## Acceptance criteria
- A palisade can close a defensive perimeter against an impassable mountain face with fewer purchased segments than an equivalent freestanding enclosure.
- Initial gate exists, paid additional gates work, at least one traversable entrance remains.
- All tower levels occupy the same palisade socket and footprint.
- Roads visibly connect through gates and across wooden bridges; pedestrians can traverse the crossing.
- Bridge ends match actual river bands without hard-edged water artifacts.
- Individual assets are traceable, validated and integrated only after approval.
