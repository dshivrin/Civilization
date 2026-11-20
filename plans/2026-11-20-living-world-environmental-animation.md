# Goal: Living World & Environmental Animation — Stone Age

**Owner approval:** 2026-11-20. Prototype a lively first-era settlement. **Do not interrupt the active gameplay run, enable R2-07, merge branches, replace accepted art, or change economy/save semantics.** Coordinate with the separate building-art Gate 2 and roads/defenses work. This is a visual-production plan, not an authorization for autonomous gameplay changes.

## Visual reference and direction
- Owner-approved direction: historically inspired realism, colorful readable silhouettes, warm natural lighting, coherent isometric camera, anchors and materials. The concept-board in the coordinating ChatGPT discussion shows NPCs, wildlife, construction, production, day/night, weather, idle buildings, sound and camera; it is **not automatically available to Codex**.
- Use actual game screenshots, 64×48 Riverbend geometry, building catalog and existing media registry for measured contracts; do not use speculative dimensions from concept sheets.
- Preserve the player-designed layout: connected houses/storage, roads, bridge crossings, cliff-boundary palisades, and decoration space. Avoid brown square ground seams.
- First era only. Regional and future-era extensibility may be designed, but do not implement later-era gameplay.

## Phase A — living settlement (first review gate)

### NPCs and daily life
- Distinct but coherent small villager sprites: varying age/body/clothing, appropriate Stone Age tools, baskets, logs, water vessels.
- Reusable animation states: idle, walk, carry, gather, work, sit/rest, socialize, turn; directional views matching the isometric camera.
- Give villagers meaningful **visual destinations** (home, faucet worksite, storage, storytelling circle, paths, gate and bridge) rather than aimless random movement.
- Respect the actual traversable road/path graph, occupancy, river crossing and palisade gate; no teleporting across water or walking through structures.
- Visual agents must not imply a simulated worker economy. Cap population on-screen by device tier and ensure background/offscreen throttling.
- Prototype: a villager carries wood from forest worksite through gate to storage, another visits a gathering area, and a pedestrian crosses a wooden bridge to a resource location.

### Wildlife
- Deer near forest edges, rabbits in clearings, birds near river/trees, fish as occasional subtle water movement. Choose region-appropriate species and document provenance.
- Short, varied idle/move loops, low density, no path through occupied structures; no gameplay harvest changes.
- Prototype one forest edge and one riverbank vignette with movement.

### Construction and upgrades
- Construction visuals reflect **actual progress**: ground preparation, timber frame, walls, roof, completion. Avoid fake completion timing.
- Small workers can carry/assemble materials where the game has a real build state; when unavailable, use a truthful minimal visual stage rather than inventing construction gameplay.
- Completed building clears temporary scaffolding/dust, starts its idle loop and remains interactable.
- Upgrades: **all building types keep identical logical footprints across levels**. Height and ornament may increase; adjacency to lower-level buildings and storage/housing connection overlays remain valid.
- Prototype hut L1→L2→L3 and one mixed-level storage cluster; coordinate with building-art Gate 2.

### Resource production and idle buildings
- Prefer physical visual activity over floating +N spam. Examples: woodcutting, quarry extraction, harvesting, leather drying, pottery kiln glow, toolmaking movement, livestock shifting, mill mechanism, hearth fire and chimney smoke.
- Effects indicate existing real activity; do not invent production transactions, resources or workers.
- Use subtle low-frequency loops, no continuous reward banners. Ordinary research/goal/achievement completions retain **small icon-adjacent glow/check/dot**, not large popups.

## Phase B — atmosphere (second review gate)

### Day/night
- Introduce a continuous, **visual-only** lighting cycle: warm day, golden dusk, cool night, dawn. Campfires, windows and kilns become visible light sources at night.
- Keep resource rates, construction, research, NPC economy, progression and saves unchanged. No gameplay penalty or new time-of-day mechanic.
- Do not require storing new authoritative time state; if visual phase is persisted, do so safely without affecting existing saves. Define pause/resume, background/foreground and low-power behavior.
- Provide an accessible brightness/contrast floor so nighttime remains playable and all icons/roads/buildings can be distinguished.
- Prototype same settlement composition in day, dusk and night, with no HUD layout changes.

### Weather
- Lightweight rain, clouds, breeze, occasional fog; wind moves foliage and smoke subtly. No penalties or terrain/economy effects.
- Weather overlays must not hide selection, placement footprints, building progress, or path/gate cues. Seasons and snow are **deferred**.
- Provide reduced effects / reduced motion and device-specific budgets.

### Spatial audio
- Match audible events to visible actions: tools, construction, fire, water, birds, footsteps, mill/kiln, UI notifications. Honor sound settings and muted mode.
- Reuse the approved audio baseline/fallback architecture; do not make on-device generative audio a dependency or first-era blocker.
- Limit simultaneous emitters and test spatial transitions on headphones and speakers.

## Phase C — polish (deferred until A/B accepted)
- Smooth optional camera focus after meaningful construction/upgrade; never steal camera during active placement or player pan/zoom.
- Extended weather, seasons, deeper individual NPC schedules, crowds, complex wildlife and cinematic flyovers are later backlog, not initial deliverables.

## Media library and production contract
- Use the canonical separate `/Users/dima/dev/Civilization-Media` repository and its LFS, registry and license conventions. Determine actual configured remote; do not invent one.
- Proposed families: `characters/stone-age`, `wildlife/reference-temperate`, `animations/construction`, `animations/building-idles`, `effects/atmosphere`, `audio/...`.
- Each individual asset needs stable ID, region/era, state, direction, source and license/provenance, editable master where available, alpha, anchor, dimensions, frame count/rate, export mapping, device budget and validation status.
- Choose sprite sheets vs layered/procedural effects after benchmarking SpriteKit on actual target devices. No renderer replacement. Maintain static fallbacks and reduced-motion variants.
- Preserve originals and keep art commits separate from gameplay integration commits.

## Deliverables and acceptance tests
1. **Audit:** existing character/scene animation hooks, asset inventory, SpriteKit z-order and movement/path APIs, animation memory/performance on iPhone/iPad mini/iPad Pro.
2. **Visual design board:** consistent NPC character sheet, wildlife sheet, four construction stages, building idle examples, day/dusk/night comparison and rain/fog examples.
3. **Prototype A:** short captured clips/screenshots showing wood delivery along roads through a gate, bridge crossing, wildlife, real-progress construction and two building-specific idles.
4. **Prototype B:** same saved settlement in day/dusk/night plus gentle rain/fog; show HUD readability and reduced-motion/static variants.
5. **Verification:** no NPC clipping or illegal routes; no effect over UI; no change to economy, building footprints, save history, R2-07 or existing game art without owner acceptance; no duplicated events after reload; bounded CPU/GPU/memory/battery impact and offscreen throttling.
6. Report actual media commit SHA, branch and remote/push status, prototype gallery path and test evidence. **Owner review required before runtime asset replacement or Phase C.**

## Execution sequence
- Begin with asset/renderer audit and **review-only prototypes**, independently of gameplay review where feasible.
- Coordinate building animation anchors with Building Gate 2 and bridge/gate paths with the road/defense design plan; use placeholders or mocks if systems are not yet implemented, labeled as such.
- Owner reviews A and B separately. Only accepted pieces may be exported into the running game.
