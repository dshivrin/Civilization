# Goal: Stone Age building art library, levels, and modular combinations

**Status:** Approved art direction; implementation deferred until the current rotation, dedicated placement, and geography run is complete. Do not interrupt or merge into that run.

## Owner-approved design
- Existing 20 building masters are in local `/Users/dima/dev/Civilization-Media/buildings/masters` (the supplied ZIP is the reference). Keep original files and the canonical media repo intact.
- Fix the mismatch between rendered ground contact and catalog footprint. Not every building is 4×4. Use verified per-building logical footprints from the current game catalog, not illustrative concept-sheet dimensions. Do not change occupied tiles or saves without separate approval/migration.
- Make L1/L2/L3 concepts for **each applicable first-era building**; confirm actual supported levels and unlocks against canonical gameplay. A taller upper silhouette at higher levels must not enlarge its ground occupancy without explicit approval. Retain consistent isometric camera, scale, anchor, lighting, perspective and mobile readability.
- Color identity: housing blue, gathering/cultural purple, storage gold/blue, hunting forest green/rust, fishing teal/blue, healing green, pottery terracotta, tannery orange, tools blue. Avoid visually indistinguishable silhouettes (especially hunting/fishing and housing/gathering).
- Modular **housing neighborhoods** and **storage complexes**, including L1 next to L3, use adjacency-aware connection pieces/overlays (paths, shared yards, roofs, fences, connectors), with no overlaps or brown square seams. Keep player freedom and decoration space.
- Fishery/fishing shelter must attach to a *valid river bank*. **Do not bake a square or arbitrary water patch into the base sprite.** Render separate land/bank and optional transparent water overlay; match the runtime river-band geometry, masks, bends, orientation and both banks. Visual QA against actual Riverbend map.
- Palisade is player drawn; steep impassable mountain cliff may complete part of defensive boundary and save fence length. Initial palisade includes one gate; extra gates cost resources; towers attach only to palisade; expansion costs resources. Art must include straight/corner/end/gate/tower/cliff transitions, including wall-to-natural-barrier ends.
- Faucet buildings are continuously resource-producing buildings and have terrain-based placement constraints (forest, stone/hill, fertile soil, etc.); shrine at sacred site. Guide first home/storage; other districts are player-composed.
- Keep the brown placement grid visible only in editing/placement, not as permanent baked sprite ground.

## Deliverable
1. Audit 20 original masters and catalog logical footprints; create a measured atlas of contact bounds, anchor, rotation, elevation, alpha, and existing level mechanics.
2. Produce **individual transparent master assets** for every approved building/level/orientation (not just composite illustrations), with editable source/prompt/provenance and asset IDs.
3. Produce reusable adjacency overlays and example configurations: 2/4 homes, 2/3/4 storage buildings with mixed levels, and relevant industrial/cultural groupings.
4. Create a **canonical media library in the new project** under `Civilization-Media` (separate local repo), following its registry/license/LFS/export conventions; if a remote is needed, coordinate configuration rather than inventing a URL. Preserve old assets and build fallbacks.
5. Add riverside fishing alignment fixtures and screenshots for straight bands, bends, opposite banks and bridges; forbid water-band mismatch.
6. Produce in-game screenshot tests on the 64×48 map: isolated, adjacent, rotated, upgraded, mixed-level, terrain boundary, palisade cliff closure and iPhone framing.
7. Export only accepted art into the game; preserve save compatibility and keep current gameplay build functional. Commit/push game-side plan and later accepted changes separately; report actual commit IDs and media remote status.

## Execution order / gates
- **Gate 0:** Wait for current Codex run to finish and reconcile its footprint/rotation/placement decisions.
- **Gate 1:** Audit + dimension contract + river geometry contract for owner review.
- **Gate 2:** Prototype hut L1–L3, gathering shelter, housing cluster, storage mixed-level cluster, fishing L1–L3 on actual river bands. Review before mass production.
- **Gate 3:** Complete remaining families/levels and modular pieces; validate.
- **Gate 4:** Integrate accepted exports, tests, screenshots, and registry provenance.

## Source availability
ChatGPT prepared a downloadable interim ZIP named `Civilization-Stone-Age-Media-Staging.zip` with the 20 user-provided originals and four **review-only** cropped concepts (hut L1–L3 and gathering L1). This ZIP is **not on GitHub** and is **not** a complete game-ready asset library. Codex should use the canonical local media repo and should not assume ChatGPT attachment bytes are available in its environment.

## Acceptance criteria
- No visual tile-base bleed, clipped roofs, wrong z-order, or opaque white background.
- All occupied ground stays inside verified logical footprint; taller roof silhouette can overhang visually without obscuring neighboring interactions.
- Mixed-level adjacency is seamless, including rotations.
- Fishing water edges conform to real river bands; no rectangular blue-water tiles.
- Every delivered sprite has stable ID, level, footprint, orientation, anchor, source/provenance, alpha validation, preview, and master/export linkage.
- The current milestone is not interrupted; the owner reviews prototypes before final integration.
