# Media requirements

## Current authority — permanent protocol synchronization (19 November 2026)

Dima’s [Permanent Development and Coordination Protocol](docs/design/sources/2026-11-19-permanent-development-protocol.md) (source **P1**) is the latest direct instruction. Only the consolidated ChatGPT **Civilization** project `g-p-f352f14f77788191b45d2e1e092aa7e7` is used for coordination. Legacy projects are historical evidence only; do not retrieve instructions independently from them. Use the dedicated **Civilization — Master Development Coordination** conversation recorded in DESIGN_SYNC.md, never select a chat merely by recency.

The current assignment is documentation synchronization and a real coordination request **before further features**. Human = Product Owner/final authority; ChatGPT = Game Designer/Project Architect/Roadmap Coordinator; Codex = Engineering Lead. Both game and media remain in Git. Complete, enjoyable, polished Stone Age remains the immediate product milestone. Implementation completion is not human acceptance.

Current implementation baseline: game `4d4211e` on `first-era-review`; media `697b486` on `main`. Geometry foundation and decorative roads are delivered for review. Recorded latest evidence: 148 Debug / 137 Release core tests, five Release exclusion probes, 13 UI tests on each of three profiles; signed iPhone update installed with fresh production-validated backup and both saves byte-identical before normal launch. Physical road usability, sustained performance and art/enjoyment acceptance remain open. These are prior milestone results, not fresh tests in this documentation cycle.

The current register at the top of DEVELOPMENT_ROADMAP.md supersedes historical pending-install/no-roads/no-geometry/next-stage statements below. New relocation, road editing, three-state HUD, independent saves and geography feedback is approved for specification; it is not implemented by this sync. No second era, additional playable cities, warfare, monetization, backend, renderer replacement, save reset or catalog rescaling is authorized. Preserve existing local branch; do not automatically merge or push.


Approved requirements and production inventory synchronized19November2026. Source authority/status: [baseline](DESIGN_BASELINE.md), [decisions](DESIGN_DECISIONS.md), [sync record](DESIGN_SYNC.md). Separate media repository: [Civilization-Media](../Civilization-Media/README.md), `/Users/dima/dev/Civilization-Media`, local `main`, initial commit **697b486**; no remote configured. The game continues to bundle its own runtime assets and does not depend on a sibling path at build/runtime.

## Art direction and production contract

**Approved target:** historically inspired realism, high saturation, sharp detail, realistic materials and warm natural lighting. Preserve appropriate historical materials, coherent perspective/scale/anchors and readable mobile silhouettes. Earlier muted/painterly warm-miniature concepts and shipped candidates remain preserved references; they are not silently relabeled as final approved realism. This sync produces no new art and replaces no shipped media.

Preserve high-resolution masters, editable source where it exists, exact prompts/source references and license evidence. Downsample/compress/export runtime assets separately. Current512pxsprites/144pxthumbnails are historical export choices, not permanent production constraints. Current building originals are **rasters, not editable3Dmodels**. A future modeling/render workflow needs its own selected formats, camera/lighting/material contract and measured export budgets; no renderer replacement is implied.

Every accepted asset needs a stable ID, family, logical mechanic ID (where relevant), era, region, visual variant, orientation, construction stage, resolution role/LOD, source/provenance, master/export relationship, actual dimensions/format/alpha, checksum, rights/attribution status, review status and game integration reference. Proposed metadata region key `reference-temperate` is not an implemented game region ID. Reuse underlying mechanics; variants select appearance rather than clone economy definitions.

Runtime integration records the media commit and asset IDs/transform parameters in the game repo, exports only required files and retains fallbacks. Update game art manifest/anchor/alpha validation and visual screenshots with each changed export. Do not pull unavailable LFSassets dynamically at app launch. Do not relocate/remove original game assets during this setup. New work in either repo is committed separately and cross-referenced.

## Media repository contents and current inventory

[Asset registry](../Civilization-Media/registry/asset-registry.json), [license registry](../Civilization-Media/registry/license-registry.json), [backlog](../Civilization-Media/MEDIA_BACKLOG.md), [art direction](../Civilization-Media/art-direction/ART_DIRECTION.md).

| Family / directory | Required coverage | Current imported / missing state |
|---|---|---|
| `art-direction` |Approved palette/material/light/style rules, references, guides|Target documented; prior contact sheet copied as candidate evidence|
| `concept-art/masters` |Original concept masters and traceable prompts|3existing game concepts copied byte-identically; missing design-chat binaries **not imported**|
| `environments` / `textures` / `meshes` |Reference terrain/river/forest/hills/deposits/fog; future regional environments|Native WorldDetails source snapshot copied; no standalone3Dmesh/texture pack claimed|
| `buildings/masters` |All20current types, effective rectangular/rotation variants and thumbnails; later era/region variants|20existing master rasters copied; future dimensions/rotation/regional views absent|
| `runtime-exports/{buildings,thumbnails}` |Derived compact exports with source IDs/anchors|20world+20thumbnail copies; app runtime unchanged|
| `roads` |Trodden/dirt/primitive stone surfaces,1tile,16four-way joins/tier, wider parallel strips, previews/edit states|Empty/backlog; mask bit order and mixed-tier art protocol not finalized|
| `characters` |Diverse age/body/appearance NPCs and building-specific activities, merchants/customers|Empty/backlog; no individual agents hidden in “completed effects” claims|
| `wildlife` |Reference wildlife and domestic animals; future region-specific sets|Empty/backlog; animals painted into building sprites are not separate actors|
| `icons/{resources,research,pillars}` |12resource,20research,5pillar identities and variants|Native EraIcon source and exact mappings copied; not37separate raster files|
| `icons/{achievements,ui}` |Achievement/journey/status/action identities and accessibility semantics|Dedicated full art sets absent; existing native text/system controls retained in game|
| `branding/{logo,app-icon}` |Main logo and application icon|Empty/backlog; current text “CIVILIZATION” is not a finished logo|
| `loading-screens/masters` |2–3distinct illustrations per era, phone/tablet native landscape framing|No dedicated new master set; conceptA exists and one historical panorama runtime export is copied|
| `animations` / `effects` |Construction, placement, fire/smoke/water/production; NPC/animal/celebration loops later|SettlementScene source snapshot retained; standalone future animation sets absent|
| `audio/{music,nature,city,sfx,ui,generated}` |All playback/generation categories and rights records|Empty/backlog; no audio/model file imported|

There are68imported records:60building files (20masters+40exports),3concepts,1loading export,1contact sheet and3native-source reference snapshots. All checksums match the source game snapshotfea9e16. Swift snapshots are references, not independently buildable media modules; authoritative game source remains in the game repo. No new ChatGPT source binary was available in the recovered chat windows. Search-image queries are inspiration, not licensed assets.

## Storage, licenses and verification

Git LFS3.8.1installed; configured with `git lfs install --local`, with repository-local hooks/filters. Raster/source/model/audio/video/archive formats in `.gitattributes` use LFS; Markdown/JSON/SVG/source code remain normal Git. No game history rewrite or global Git LFSconfiguration. No remote. Back up local LFSobject storage with this repo; Git pointers alone are not master-file backups.

`python3 scripts/validate_registry.py` in the media repo validates68IDs/files, hashes, bytes, PNG dimensions, source hashes, derived relationships and license references; it passed. `git lfs fsck` passed. License registry records provenance **without asserting unverified commercial clearance**. Existing generated originals and project-native code have provenance entries; external source assets/models/audio must supply creator/source URL, license/terms version and evidence, commercial/modification/redistribution permissions, restrictions and attribution before adoption. “Free,” a search thumbnail or “AI-generated” is not a substitute for the rights record. No downloaded reference art/audio is integrated by this sync.

## Loading screens and branding

Main logo/app icon,2–3illustrations **per delivered era**, distinct native landscape phone/tablet framing. Future era list remains undefined; no all-era mass-production order. Images contain only illustration; render progress, logos and localized text independently. Existing native overlay/spinner already follows separation in part, but artwork count, branded assets and localization coverage remain incomplete. Keep safe areas/readability, no invented percentage or artificial loading delay, and loading readiness tied to actual restore/renderer state. Import accessible prior generated source concepts at original resolution with provenance; unavailable sources stay marked missing.

## Roads and Living City media constraints

Road art is single-tile, four-direction16states including isolated0; no diagonal/bridge functionality inferred. Parallel placement may widen a path, but exact seam/tier/edge variants need the road brief. Art must never dictate a changed map or building collision rule. Road functionality starts decorative/free, with no era gate.

NPC/media activity must map to actual building/activity anchors and respect discovery, occupancy, population and bounded device quality. Farming/crafting/trading/social/gathering, diverse people, market merchants/customers, wildlife/domestic animals are future sets. Establish path/update/texture/animation budgets on available devices before batch generation. Decoration is not a second workforce/economic engine. Pause/background/reduce-motion behavior and fallback silhouettes matter as much as detail.

## Audio requirements and feasibility gates

| ID | Approved requirement | Required gate / delivery status |
|---|---|---|
| AUDIO-001 |Offline production using commercially usable free assets, procedural generation and AI-generated assets|Per-asset rights evidence/master/export record; no assets implemented|
| AUDIO-002 |Optional on-device generation with Apple acceleration where supported, cached output|Verify distributable model/license/framework/device feasibility; no guaranteed universal Neural Engine support|
| AUDIO-003 |Native spatial audio|Standard supported-device fallback, world emitter/listener policy, route/interruption handling|
| AUDIO-004 |AirPods personalization/head tracking|Verify current supported APIs/devices/permissions; no direct H-series chip programming assumed|
| AUDIO-005 |Physical acoustic simulation|Measured optional advanced feature; avoid mandatory cost on unsupported devices|
| AUDIO-006 |Advanced settings, master/music/nature/city/SFX/interface volumes; generation Off/Automatic/On|Persist controls; define Automatic policy, safety throttles, cache limits and graceful downgrade|

Standard playback works on every supported device. Generative audio is optional; Off means no generation workload, Automatic uses a documented thermal/battery/memory/frame policy, and On must still honor protective limits. Cache outputs rather than regenerate unnecessarily. Exact models, sample rates, channel counts, defaults, cache budgets, update rates and platform APIs are **not finalized** by this document. Verify official Apple support and actual measurements before a technical implementation brief.

## Monuments and regions

WND-001catalog,002models/textures,003construction stages,004permanent landmarks,005celebrations,006historical records;007heritage/tourism deferred. Candidates: Temple of the Ancestors, Celestial Circle, Ancestral Burial Mound. Preserve original locations and recognizable era identity after advancement. Recovered6×6/5×5/5×4examples,25/50/75percent stages and broader21monument lists are assistant proposals, not approved configuration. No dedicated monument assets exist yet.

GEO-001starting regions,002regional landscapes,003architecture,004resources/wildlife,005monuments,006soundscapes,007global research inheritance,008trade are approved future directions. Region candidates: Egypt, Mesopotamia, Persia, China, Central Europe, Mediterranean, Indian Subcontinent, Mesoamerica. Reference valley stays fixed for development. Variant metadata may prepare for region/era/culture without duplicating mechanic definitions or claiming a region selector/generator exists. Exact release subset, regional catalogs, heritage/era interpretation and global/local research semantics remain design questions.

Geometry foundation note: runtime occupied-footprint centers now use both logical axes (2:1projection); current square anchors/art are unchanged. Logical orientation is not permission to rotate finished sprites. Orientation-specific art/overhang/anchors remain a later asset brief; no media generated or imported for this foundation.

Decorative-road candidate surfaces are now original procedural code:16cached compound paths ×3material fills, per-tile terrain-center anchors under existing2:1projection, broad shared-edge joins. [Provenance](docs/art/roads-provenance.json) includes source hash and replaceable status. No external road raster/texture or permanent asset imported; media repository unchanged. Dedicated final road master/runtime textures remain a separate art brief.

## P1 first-era geography and interaction coverage

Preserve ART-001: realistic highly saturated environments with sharp material detail and warm natural lighting. MAP-001–004 require a later terrain/quarry/cloud pilot tied to approved logical geometry and save policy. Cover cloud fog edges/reveal transitions, a readable accessible near-side stone quarry, larger-map terrain continuity and expedition feedback; no second-era asset batch. MOVE/HUD/RD feedback needs clear per-tile availability, cancel/goals/Explore/Build-road controls and erase/reversal feedback. Native controls/procedural previews may satisfy usability without new raster files. No new assets, imports or media-repo edits occurred in this sync. Existing 68-record media baseline stays 697b486; new art needs a bounded production brief, provenance and human visual review before acceptance.
