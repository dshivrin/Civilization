# Goal: First Settlement & Exploration Onboarding — Stone Age

**Approved by owner:** 2026-11-20. This plan is the product/design handoff for a redesigned first-time player experience. Do not enable R2-07, overwrite the current gameplay branch, or replace approved runtime assets without the normal review gate. Coordinate with ongoing building art, geography and UI polish.

## Player experience goal
A new player should understand what to do immediately after New Game, without a long blocking tutorial: **permanent civic campfire → first hut → first expedition → forest discovery → woodcutter near forest → useful connection to settlement**. Player controls exact building placement. The tutorial should explain why each action matters.

## Current problem / screenshot evidence
Owner-provided landscape screenshot shows an almost empty campfire clearing, repeated white cloud tiles, narrow visible green corridors through fog, many resources and menus, and a generic bottom instruction (“Drag to explore · pinch to zoom · long-press a building to move it”). The game lacks a clear first objective. Do not treat the screenshot as a complete specification of current map internals; audit live rendering and progression before changes.

## Opening sequence — approved direction
1. **Start:** Campfire remains the permanent upgradeable civic center across eras; preserve current starting resources, save compatibility and civic mechanics. A compact contextual guide directs the player to **Build → Hut**.
2. **First hut:** Player places a hut at any valid nearby position. Guidance follows actual game events, not a scripted fake completion. Do not force a hardcoded tile or move existing structures. If already built, mark step complete idempotently.
3. **Introduce exploration immediately after first hut:** Show the expedition/explore control and highlight a nearby unexplored **area**, not a single corridor of tiles. Explain cost, duration and what exploration can reveal; use real gameplay values.
4. **Forest discovery:** The initial guided expedition must reveal a useful forest area within practical reach of the starting campfire. Guarantee this through deterministic valid map generation/area selection, not by secretly teleporting resources or changing an existing save. Preserve resource access and geography constraints.
5. **First wood production:** Guide the player to place the existing **woodcutter** adjacent/near the forest using the actual terrain-placement contract. Explain why forest proximity matters. If a mill is the correct production building in the final catalog, resolve naming and production semantics against live game data; do not introduce a new mill mechanic by assumption.
6. **Connect and continue:** Explain roads/path connectivity only where it is operational in the current reviewed rules; guide toward connecting the woodcutter to settlement if required. Hand off to existing first-era chapter goals without duplicate rewards or progression dead ends.

A wheat/fertile-land-first opening is a **future region-specific alternative**, not a change to the approved default temperate forest-first tutorial. Historical claims about first settlements should not be embedded as universal game facts.

## Fog-of-war redesign
- Replace obvious repeated white tile/cloud pattern with a **continuous, even, softly layered fog field**. Unexplored areas must be fully obscured; **no pre-revealed narrow paths or corridors** between fog regions.
- Divide unexplored map into meaningful **geographical discovery areas** (forest, hillside/stone deposit, fertile clearing, riverbank, sacred site). Use organic-looking boundaries consistent with terrain; do not use obvious rectangular chunks.
- Expedition reveals a coherent whole area with a short non-blocking receding-fog animation (~1–2 seconds target, tune on device). Do not create or move terrain/resources on reveal. Preserve exploration state across save/load.
- Distinguish unknown terrain, discovered terrain and currently accessible/usable terrain without leaking hidden resource details.
- Fog and reveal effects must work across camera pan/zoom, 64×48 map, rotation, river bends, mountains, bridges, road/placement overlays and all supported landscape devices.
- Audit current fog visibility, terrain generation, save format and expedition costs before proposing changes. Do not reset development saves or silently migrate discovered state.

## Expedition UI
- Select a discoverable region/area, with clear target, actual cost and duration, and confirmation/cancel where appropriate.
- Show a readable countdown and in-progress state. On completion, reveal the entire selected area, report discovered terrain/resource opportunities concisely, and offer a relevant next action (e.g. Build woodcutter).
- Avoid repeated popups or big completion banners. Reuse the approved compact icon-adjacent glow/check/unread dot notification pattern where appropriate.
- Handle cancellation, insufficient resources, overlapping/duplicate expeditions, reload mid-expedition, and out-of-order player actions without lost or duplicated costs.
- Area boundaries and reveal logic must be deterministic/testable; no invisible corridors or unreachable starting resource chain.

## Contextual first-time tutorial
- Use small, dismissible, non-modal prompts anchored to the actual relevant control: Build, Hut placement, Expedition, Forest discovery, Woodcutter, Roads when applicable.
- Explain one action at a time, show a concise next action, and allow skip/reopen from Goals. No forced screen takeover or repeated hints after completion.
- Tutorial state is event-driven, idempotent, save-compatible and resilient to experienced players completing steps out of order.
- Highlight only relevant UI controls; advanced controls remain available but should not compete visually with the opening action.
- Use accurate current catalog names, costs, prerequisites and navigation. Never display invented availability or timers.

## Menu guidance — later dependency
**Do not implement broad menu walkthroughs yet.** First complete/approve the HUD, Build catalog, Research screen, Expeditions interface and icon placement in the separate UI Themes & Animations milestone. Then add contextual guides for menu functions using stable control IDs. Keep icon meanings and layout consistent across era/region skins (Stone Age carved stone; future materials vary).

## Visual and animation contract
- First-era visual style: colorful historically inspired realism, readable mobile scale; natural soft fog without tiled repetition.
- Small, smooth, skippable fog reveal and subtle icon notifications; respect reduced-motion and accessibility.
- Do not obscure placement grid when in edit mode, block touch targets, or impose false loading delays.
- Existing civic center remains visually identifiable and upgradeable; avoid duplicate storytelling civic structures without reconciliation.

## Codex deliverables / gates
**Gate A — audit and prototype (may prepare now):**
- Audit existing New Game start, first-era goals, current expedition behavior, fog renderer, terrain areas, save schema, resource placement and HUD.
- Produce before/after screenshots on iPhone, iPad mini and iPad Pro showing continuous fog, no green corridor, initial campfire and first tutorial card.
- Demonstrate a deterministic forest-region reveal and woodcutter placement with actual placement constraints.
- Record proposed area data model, animation layering, save/migration policy and test plan. Owner review before production gameplay changes.

**Gate B — implement after review:**
- Integrate approved fog renderer, area-based expedition selection/reveal and opening tutorial with safe migration and rollback.
- Tests: first-game flow; out-of-order/skip tutorial; first forest reachable; no fog corridor; full-area reveal; reload during expedition; resource/cost idempotency; woodcutter valid placement; road/gate accessibility if applicable; old saves retain discovered terrain; screenshot/performance on phone/mini/Pro.
- No changes to R2-07 activation, unrelated economy, later eras, branding or original media without separate approval.

## Dependencies and coordination
- Building media plan: `plans/2026-11-20-stone-age-building-media-library.md`
- Roads/bridges/defenses plan: `plans/2026-11-20-stone-age-roads-palisade-towers-bridges.md`
- UI themes/animations plan: `plans/2026-11-20-ui-themes-animations-loading-branding.md`
- Living world plan: `plans/2026-11-20-living-world-environmental-animation.md`
- Canonical baseline, design decisions, current first-era review and save history remain authoritative; reconcile conflicts before code changes.

**Acceptance:** On New Game, the player has a clear immediate action, can place a hut freely, understands why to explore, reveals a complete forest region without corridor artifacts, can place a woodcutter in a valid spot, and proceeds naturally into the first-era game loop. No existing saves or player progress are lost.
