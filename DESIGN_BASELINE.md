# Design baseline

Synchronized 19 November 2026. This file and the four linked documents are the shared, version-controlled design baseline. Latest source: Dima’s direct **recover conversations / synchronize roadmap** instruction in the Codex implementation chat, after commit `fea9e16`. [Source/access record](DESIGN_SYNC.md). Historical milestone documents remain evidence, not competing current specifications.

## Authority and status

Approval and implementation are separate axes. **Approved** means a human-approved requirement or future direction; **proposed** means a candidate detail; **implemented** requires repository evidence; **deferred** describes scheduling, not rejection of an approved future feature; **open** requires a decision or feasibility check. An assistant’s “approved” heading alone is not human approval. Sync approved decisions into Git before implementation. The current task authorizes documentation, roadmap reconciliation and media-repository setup/imports; it does not authorize implementing all workstreams at once.

- [Development roadmap](DEVELOPMENT_ROADMAP.md): dependencies, bounded stages and acceptance gates.
- [Decision register](DESIGN_DECISIONS.md): decisions, supersessions, proposals and open questions.
- [Media requirements](MEDIA_REQUIREMENTS.md): asset coverage, provenance and media-repository contract.
- [Synchronization protocol](DESIGN_SYNC.md): source identity, access limitations and update procedure.

## Product and invariants — approved

Native universal iPhone/iPad, iOS/iPadOS18 minimum, landscape, SwiftUI interface, SpriteKit world and pure Swift GameCore. Preserve existing signing/account settings. Core gameplay is local and single-player. Current reference settlement is the fixed32×24 temperate river valley: geography, IDs, deposits, historical achievements and player investment persist. Do not replace the renderer or introduce a backend, warfare or monetization under this synchronization brief.

Five development pillars: economy, science, security, culture and population. New Stone Age readiness requires every active progression building type and technology, required Stone Age resource-territory discovery and all five pillars, retaining compatible manufacturing/civilization checks. Counts derive from catalogs; the current catalog has20types and20technologies. Full-map discovery/future-resource identification is not required. Earned readiness and rewards remain sticky; a changed future catalog must not revoke prior readiness. Seven journey chapters accept out-of-order achievements and expose measurable progress when expanded and compact progress when collapsed.

GameCore owns authoritative economy, construction, population, exploration and progression. Rendering submits commands; decorative systems must not mint resources, assign real workers or change simulation outcomes. Saves are currently version5, migrate older supported versions, write atomically and cap offline catch-up at8hours. Preserve map identity, original goal reward IDs/history and ordinary time handling. Debug tools use isolated saves and compile out of Release. Existing drag placement, relocation, camera pan/pinch and fixed campfire behavior remain regression boundaries.

## Current delivery priority — first-era playability

Dima directly instructs: prioritize a player starting, understanding what to do and completing the first era. Graphics/looks, roads and NPCs are secondary. This authorizes focused guidance/usability fixes and legitimate progression/recovery verification now; leave future feature workstreams staged. Keep existing chapter/readiness conditions and numerical balance. Contextual optional next-step explanations may expose prerequisite production/research and navigate to existing screens; no automatic transactions or new progression gates. See [execution plan](docs/superpowers/plans/2026-11-19-first-era-playability.md).

## Observed implementation at fea9e16

| Area | Observed state | Limits / next evidence |
|---|---|---|
| Stone Age gameplay |20building types,12resources,20technologies, production/maintenance/upgrades, workforce, growth, exploration,5pillars and7chapters |No actual second-age transition; experimental numerical balance|
| Legitimate full-era progression |Paid scripts finish all requirements;90minute investment route vs154minute serial route; recovery/reload tested |Simulated scripts, not human enjoyment or an optimal route|
| Building dimensions |Campfire **1×1**, palisade **1×1**, other18types **2×2** in bundled JSON |Not uniform4×4. Definitions already have width/height; placed buildings have no rotation or saved footprint snapshot|
| Placement |Rectangular enumeration exists in `BuildingDefinition.tiles(at:)`; placement/reload validation derives dimensions from current definitions |No authored rectangular catalog or rotation UI/persistence; changing dimensions directly can invalidate saved layouts|
| Menus |Compact categorized building/research cards, art/icons/costs, individual red deficits, expandable details, progress/locked/complete states |Phone/tablet captures and tested gestures retained|
| Candidate visuals |20original raster building masters/sprites/thumbnails, native20research/12resource/5pillar icon identities, native terrain and bounded effects |Earlier warm miniature candidate is not automatically compliant with the newly approved realism/saturation direction; no editable3Dmasters|
| Loading / branding |One panorama cropped adaptively; separate native text and indeterminate progress indicator |No2–3era illustrations/native-aspect master set, final logo/app icon or complete localization catalog|
| Roads |Absent from GameState, commands and renderer |All road placement/removal/upgrades/connectivity remain unimplemented|
| Living City |No NPC agents, markets, wildlife/domestic-animal actors or animal simulation |Static building imagery and water/fire effects do not count as agents|
| Monuments |No dedicated monument catalog, construction records or permanence system |Shrine/burialGround are ordinary existing types, not WND implementations|
| Audio |No playback/mixer, generative model, spatial/head tracking or advanced settings |All AUDIO workstreams remain future work|
| Regions / global systems |One map/settlement; no region selector, regional generator, global research or trade |Existing asset manifest has stable IDs but no implemented regional resolution|

Inspection sources: `Packages/GameCore/Sources/GameCore/{Types,Configuration,GameEngine}.swift`, `GamePersistence/SaveStore.swift`, bundled `seed.json`, GameApplication visual manifest, `Civilization/Rendering`, UI loading/menus and milestone evidence. Last recorded regression results are115Debug/104Release and5Release API probes. Full5UI suites passed on phone/mini/Pro before the last title-height-only fix; the final targeted alignment/affordability test passed on all3after it. Rerun complete post-fix suites as the next stabilization task; this documentation-only sync does not rerun or claim new gameplay tests.

The previous signed candidate is installed with preservation evidence. **The latest compact-menu update is built but not installed**: last physical inventory reported the iPhone unavailable and fresh backup failed. Hardware status is last observed, not a claim of present connectivity. Dense pre-cache physical sample was~48FPS vs60FPS aim; no sustained thermal/battery/A15/M1acceptance. See [candidate report](docs/milestones/first-era-review.md), [menu report](docs/milestones/compact-menu-review.md) and [pacing review](docs/design/first-era-pacing-review.md).

## Approved roadmap requirements — not yet implemented

### Building-specific footprints (FP)

Replace the current mostly uniform layout with individually balanced building dimensions, rectangular buildings and rotation. Original fireplace maps to the existing stable `campfire` ID: unique, immovable1×1. Exact dimensions, orientation increments, art variants, costs and migration representation are **open/proposed**, not approved by an example table. No map rescaling, auto-relocation, demolition or loss of saves is implied. Preserve existing buildings before introducing new dimensions.

### Decorative roads (RD)

Trodden footpaths, dirt roads and primitive stone roads. Each road is one logical tile wide; adjacent parallel strips permit wider routes. Automatic four-direction connections cover16bitmask combinations. Drag-to-build, persistence, removal and upgrades are required. Initially decorative and free to construct. Roads must not initially block era progression. Future transport, trade, NPC routing and building connectivity are approved directions, deferred beyond decorative roads. Bit ordering, eligible terrain, building/road overlap, mixed-tier connections, upgrade rules and gesture precedence need a bounded implementation brief.

### Living City (LC)

Decorative NPC population scales with settlement population within device-dependent budgets; not necessarily one actor per resident. Diverse appearances, ages and body types. Farming, crafting, trading, socializing and gathering use appropriate building activities. Markets show merchants/customers; a new economic market building is not implicitly approved. NPCs prefer roads and can traverse open terrain. Wildlife, domestic animals and environmental animation are included in the direction. Initial agents are decorative; economic integration is deferred. Movement must respect discovery and existing gameplay occupancy; exact navigation rules, caps and activity distribution are open.

### Media and loading (MED / LOAD)

Separate sibling local Git repo **Civilization-Media**, no remote required. Preserve high-resolution masters and provenance; derive optimized runtime copies separately. Approved target: **historically inspired realism, high saturation, sharp detail, realistic materials and warm natural lighting**. This supersedes the earlier muted/painterly candidate direction as the target, while existing candidate art remains preserved until a separate integration stage. No mass regeneration in this synchronization task. Support regional/era asset variants without duplicating mechanics.

Main logo, application icon,2–3loading illustrations per era and native landscape phone/tablet aspect compositions are required. Progress indicators, logo and localized text render separately. Import prior ChatGPT-generated concepts only when actual source files are accessible; search references or unavailable image metadata are not imports. See [media specification](MEDIA_REQUIREMENTS.md).

### Audio (AUDIO-001–006)

Offline production from commercially usable free sources, procedural generation and AI-generated assets; optional on-device generation with Apple acceleration where supported; native spatial audio; AirPods personalization/head tracking; physical acoustics; advanced settings. Standard audio fallback on every supported device. Generative audio modes **Off / Automatic / On**, cached output and thermal/battery/memory/game-performance limits are required. Master/music/nature/city/SFX/interface volumes are separate. Frameworks, models, hardware matrices, routing/permission behavior and exact generation policy require feasibility and license verification, not assumptions about a universal “AI chip.” No runtime model/framework was added by this sync.

### Historical monuments (WND-001–007)

Era-specific catalog, models/textures, multi-stage construction, permanent landmarks, celebrations and historical construction records; heritage/tourism mechanics are future/deferred. Monuments remain in their original geographical locations after later-era progression. Initial **candidates**: Temple of the Ancestors (Göbekli Tepe inspiration), Celestial Circle (Stonehenge), Ancestral Burial Mound (Newgrange). Exact catalog membership, footprints/costs/prerequisites, stages and completion rewards are not finalized. Do not silently add these candidates to the current all-building readiness requirement.

### Regional civilizations (GEO-001–008) — approved future expansion

Player-selected region per new civilization; regional landscape generation, architecture, resources/wildlife, monuments and soundscapes; global research inheritance and inter-civilization trade. Candidate regions: Egypt, Mesopotamia, Persia, China, Central Europe, Mediterranean, Indian Subcontinent, Mesoamerica. Shared scientific knowledge; independent economies, populations, geography and cultural identities. Existing temperate valley remains the reference development environment. Regional variants should reuse underlying mechanic IDs; eight names do not settle era-specific cultural/art differences or mandate an immediate eight-region release. Exact global/local research applicability and trade rules remain open.

## Boundary

Record and plan all approved workstreams now; implement them in separately scoped stages after stabilization and approved migration/design details. Subsequent eras and regional/global systems remain future delivery, not permission to add them during this sync. Human art/enjoyment acceptance remains open. “First-era candidate complete” in earlier reports describes the then-authorized core candidate, **not** completion of roads, NPCs, monuments, audio, regional variants or this expanded roadmap.

## First-era playability implementation update

The current priority iteration adds cached read-only next-step guidance, prerequisite production/research/mode/staffing/housing/exploration explanations and existing-screen navigation. Advice stays visible when goals are collapsed; earned completion and continued sandbox play are explicit. Ordinary recommendation-following routes complete all20types/20technologies/7chapters/5pillars/required discoveries in104–121simulated minutes without grants or tuning.120Debug/109Release and8UI cases per profile are verified; see [quality report](docs/milestones/first-era-playability.md).

The guided path is not proof all mistakes recover. Q-PLAY-1documents a confirmed pre-existing starter-wood overspending trap and a [reserve/recovery proposal](docs/design/bootstrap-reserve-proposal.md), pending Dima’s choice before changing spending rules. Latest signed build is available; physical installation remains pending iPhone access/fresh backup. Human comprehension/enjoyment and existing hardware limits remain open. Secondary visuals/roads/NPCs stay staged.

Dima explicitly approved PLAY-002starter-material reserve protection in response to the concrete proposal. Protect catalog-derived costs for still-missing basic construction suppliers across construction/research/upgrades, with a clear explanation. Actual costs/rates and earned resources remain unchanged; no covert grants or historical save resets. Implement/verify atomically before calling the prevention delivered.
