# Design decisions and unresolved details

## S1-UX delivery checkpoint — 19 November 2026

S1-UX is implemented **awaiting human review**, final product60046d2; [actual milestone evidence](docs/milestones/s1-ux.md) records155Debug/144Release, five Release probes,16native cases/profile plus affected final checks, original stationary/translucent relocation/grid, pending retrace/Undo, icon-default goals/adjacent Explore/Build roads. Signed final iPhone update installed after fresh production-validated backup; both saves byte-identical pre-launch and normal launch succeeds. Human enjoyment/art/touch/sustained hardware performance are open. No economy/catalog/geography/save-schema change. Continue directly to authorized **S1-Saves** after its detailed design reconciliation, then S1-Geography (exact dimensions/migration review gate), then environment graphics. Preserve all previous roadmap requirements and both repositories. Native same-chat Goal/checkpoint remains active; no quota bypass/duplicate session or guaranteed reset timer claim.


## GitHub issue #1 refinement — active S1-UX details

[Primary coordination issue](https://github.com/dshivrin/Civilization/issues/1) and remote docs commit 26894bd were retrieved before further UI work. Latest refinement supersedes earlier MC-001 engineering defaults: **white available/light-gray blocked grid; original building stays stationary/translucent while only the footprint moves; circular bottom-center X; goals icon-only by default, tap for summary then expand guidance**. Explore stays adjacent; Roads inside Build. Shared atomic validation, forgiving invalid drop, free relocation, ordered pending-road retrace and Confirm/Cancel remain. Exact larger-map dimensions/migration explicitly require review before S1-Geography. Preserve all other roadmap IDs. Current code commits before this refinement are foundations, not final visual/default compliance. GitHub comment write now succeeds (comment 7019325134), superseding the earlier transient 403; issue #1 is the actual report channel. Git uses rebase of unpublished commits onto remote docs, no merge/force-push.


## Active execution authorization — first-era polish

Dima directly authorizes autonomous implementation in order **S1-UX → S1-Saves → S1-Geography → approved environment graphics**, with detailed design reconciliation before each milestone. This supersedes older synchronization-only/awaiting-authorization boundaries. Preserve every approved/deferred roadmap item, both repositories and the existing first-era-review branch. Routine engineering choices are delegated; stop for significant product/safety decisions. No second-era gameplay. GitHub under personal owner dshivrin is the primary coordination channel; commit/push coherent work and retrieve actual instructions when connector permissions permit. Maintain [durable checkpoint](docs/development-checkpoint.md); do not infer product acceptance from passing tests.

Native Codex Goal is enabled for this same chat; no cron, launchd, duplicate session, alternate account or quota bypass. Respect host usage limits, checkpoint at coherent boundaries and resume through supported native lifecycle when permitted. Exact automatic wake at the five-hour reset remains unverified; do not promise it. Existing branch is intentionally retained rather than creating another worktree, per Dima's instruction.


## Current authority — permanent protocol synchronization (19 November 2026)

Dima’s [Permanent Development and Coordination Protocol](docs/design/sources/2026-11-19-permanent-development-protocol.md) (source **P1**) is the latest direct instruction. Only the consolidated ChatGPT **Civilization** project `g-p-f352f14f77788191b45d2e1e092aa7e7` is used for coordination. Legacy projects are historical evidence only; do not retrieve instructions independently from them. Use the dedicated **Civilization — Master Development Coordination** conversation recorded in DESIGN_SYNC.md, never select a chat merely by recency.

The current assignment is documentation synchronization and a real coordination request **before further features**. Human = Product Owner/final authority; ChatGPT = Game Designer/Project Architect/Roadmap Coordinator; Codex = Engineering Lead. Both game and media remain in Git. Complete, enjoyable, polished Stone Age remains the immediate product milestone. Implementation completion is not human acceptance.

Current implementation baseline: game `4d4211e` on `first-era-review`; media `697b486` on `main`. Geometry foundation and decorative roads are delivered for review. Recorded latest evidence: 148 Debug / 137 Release core tests, five Release exclusion probes, 13 UI tests on each of three profiles; signed iPhone update installed with fresh production-validated backup and both saves byte-identical before normal launch. Physical road usability, sustained performance and art/enjoyment acceptance remain open. These are prior milestone results, not fresh tests in this documentation cycle.

The current register at the top of DEVELOPMENT_ROADMAP.md supersedes historical pending-install/no-roads/no-geometry/next-stage statements below. New relocation, road editing, three-state HUD, independent saves and geography feedback is approved for specification; it is not implemented by this sync. No second era, additional playable cities, warfare, monetization, backend, renderer replacement, save reset or catalog rescaling is authorized. Preserve existing local branch; do not automatically merge or push.


Synchronized19November2026. Status vocabulary and precedence: [baseline](DESIGN_BASELINE.md), [source record](DESIGN_SYNC.md). Source IDs: **S1** current direct Codex synchronization instruction; **S2** City Design Coordination; **S3** Plan iOS GameWinvalid (exact returned title also in archive); **S4** Stage 2 Testing Status; **R1** repository atfea9e16; **E1** checked-in test/milestone reports. Approval is independent of implementation.

## Decision register

| ID | Decision / authority | Design status | Implementation / scheduling |
|---|---|---|---|
| SYNC-001 |Versioned five-document baseline before code; conversation memory is not a complete spec (S1)|Approved, effective now|This documentation sync|
| CORE-001 |SwiftUI/SpriteKit/pure Swift, iOS18universal landscape, deterministic core and protected normal saves (S1/prior direct instructions)|Approved|Implemented; preserve|
| CORE-002 |Persistent geography, IDs, rewards/readiness; no silent revocation (S1/prior0.2.7)|Approved|v5implemented; future migrations must preserve|
| ERA-001 |All active progression catalog buildings/technologies, required resource discovery, five pillars (direct0.2.7)|Approved|Implemented20/20current counts; historical partial-pillar rule superseded|
| GOAL-001 |Seven measurable chapters and out-of-order credit, no duplicate historical rewards (direct0.2.7)|Approved|Implemented; four-chapter proposals superseded|
| PLAY-002 |Dima explicitly approves catalog-derived starter-material reserve protection: reject only spending that strands missing basic suppliers; actual costs/rates unchanged |Approved current correction|Implemented/tested; existing insolvent saves get no covert grants/reset|
| PLAY-001 |Dima prioritizes start/understand/complete first era over looks/roads/NPCs; contextual optional dependency guidance and existing-screen navigation |Approved current work|Implementation/verification next; no tuning or requirement change|
| UI-001 |Compact expandable aligned Building/Research cards, icon costs, individual red deficits (direct feedback)|Approved|Implemented through60e3268; current code unchanged by sync|
| FP-001 |Individually balanced dimensions, rectangles and rotation (S1)|Approved requirement|Unimplemented beyond existing width/height enumeration|
| FP-002 |Unique immovable1×1fireplace, existing `campfire` identity (S1/R1)|Approved invariant|Implemented; current palisade also1×1but not required to remain so forever|
| FP-003 |Uniform4×4reported design starting point (S1)|Source discrepancy, not an implementation fact|Actual18types2×2pluscampfire/palisade1×1; no automatic scale conversion|
| FP-004 |Rotation uses90degree steps; saved dimensions/orientation per instance (planning suggestion)|Proposed approach, not finalized|Choose/migrate before catalog dimension changes|
| RD-001 |Footpath/dirt/primitive stone,1tile strips,4-way16masks, drag, save/remove/upgrade (S1)|Approved requirements|Decorative implementation delivered; see road milestone|
| RD-002 |Initially decorative/free; must not gate era progression (S1)|Approved constraint|Keep outside required-building counts unless a later explicit decision changes it|
| RD-003 |Transport/trade/NPC path preference/building connectivity (S1)|Approved future direction|Functional economics/network delivery deferred|
| RD-004 |N=1/E=2/S=4/W=8; no diagonals; road command batching/tier borders (planning)|Documented implementation protocol in2bd4997, not a recovered human bit-order requirement|Masks derived from tiles; no stored mask migration|
| LC-001 |Decorative population-proportional diverse agents; building activities, road preference/open land; markets/animals (S1)|Approved direction|Unimplemented; economic agents deferred|
| LC-002 |Exact NPC caps, update rates, demographic proportions, wildlife collisions (planning)|Open technical/tuning choices|Measure on target devices; do not conflate with actual workers|
| MED-001 |Separate local Civilization-Media Git repo, master/runtime separation, provenance/license/backlog (S1)|Approved, setup authorized now|Created/imported separately; see media repo and SYNC manifest|
| ART-001 |Historically inspired realism, high saturation/sharp detail/materials/warm light (S1)|Approved current target|Old miniature assets remain legacy candidates; fidelity gap documented|
| ART-002 |Keep SpriteKit; choose raster or modeling sources per approved future pipeline (S1)|Approved renderer boundary; exact production pipeline open|Current sources are raster/native code, not3Dmodels|
| LOAD-001 |Logo/app icon,2–3era illustrations, phone/tablet native framing, separate progress/logo/localized text (S1)|Approved|One adaptive panorama/native spinner/text exists; remainder backlog|
| AUDIO-001 |Offline audio production with commercial-use source/license evidence, procedural/AI assets (S1)|Approved roadmap|Not implemented|
| AUDIO-002 |Optional on-device generative audio / supported Apple acceleration, caching, Off/Automatic/On and resource limits (S1)|Approved behavior, technical feasibility open|Not implemented; hardware/model assumptions unverified|
| AUDIO-003 |Native spatial audio with standard fallback (S1)|Approved roadmap|Not implemented|
| AUDIO-004 |AirPods personalization/head tracking where supported (S1)|Approved roadmap|Not implemented; permissions/routes/API capability matrix required|
| AUDIO-005 |Physical acoustic simulation (S1)|Approved roadmap|Deferred advanced stage; no mandatory unsupported-device cost|
| AUDIO-006 |Master/music/nature/city/SFX/interface levels and advanced settings (S1)|Approved|Not implemented|
| WND-001 |Era-specific monument catalog (S1)|Approved workstream|Membership and relation to progression open|
| WND-002 |Monument models/textures (S1)|Approved workstream|No monument assets imported or created|
| WND-003 |Visible multi-stage construction (S1)|Approved workstream|Stage fractions/resources/durations not final|
| WND-004 |Permanent landmarks at original locations across eras (S1/S4human)|Approved|No dedicated implementation|
| WND-005 |Completion celebrations (S1)|Approved workstream|Effect/audio/NPC scope and reduce-motion behavior to specify|
| WND-006 |Historical construction records (S1)|Approved workstream|Schema, dates and event IDs open|
| WND-007 |Heritage/tourism mechanics (S1)|Approved future direction|Explicitly deferred|
| WND-CAND |Temple of Ancestors / Celestial Circle / Ancestral Burial Mound (S1/S4)|Candidate list; exact inclusion not final|Recovered assistant6×6/5×5/5×4dimensions are **proposals**, not config values|
| GEO-001 |Region choice per new civilization (S1, S4“Approved path”)|Approved future expansion|Deferred|
| GEO-002 |Regional landscape generation (same)|Approved future expansion|Deferred; do not replace reference map now|
| GEO-003 |Regional architecture packs, shared mechanics/variant lookup (same)|Approved direction|Registry supports metadata; runtime regional lookup absent|
| GEO-004 |Regional resources/wildlife (same)|Approved future expansion|Deferred; no candidate-region resource tables finalized|
| GEO-005 |Regional monuments (same)|Approved future expansion|Deferred; depends on WND/geography preservation|
| GEO-006 |Regional music/soundscapes (same)|Approved future expansion|Deferred; depends on AUDIO/media licensing|
| GEO-007 |Shared global scientific knowledge/research inheritance (same)|Approved future direction|Supersedes earlier “inheritance unresolved” only at concept level; exact sharing rules open|
| GEO-008 |Inter-civilization trade (same)|Approved future direction|Deferred; independent local economies preserved|
| ERA-002 |Later historical eras preserve geography/landmarks (S1/S3/S4)|Approved long-term direction|No current next-era content/transition; exact era list and durations remain proposals|
| BOUND-001 |No warfare, monetization, backend or renderer replacement under current work (S1/prior scope)|Preserved boundary|Early S3brainstorming prices/tower defense are not approvals|

## Open design questions (do not block this documentation sync)

| ID | Question / decision needed | Gate before implementation |
|---|---|---|
| Q-PLAY-1 |Reserve protection approved (PLAY-002). How should already-insolvent historical saves recover? [Approved prevention scope](docs/design/bootstrap-reserve-proposal.md)|Prevention does not authorize an emergency grant/refund/reset; legacy recovery remains separate|
| Q-FP-1 |What footprint/rotation/anchor does each actual type use, and how are legacy instances preserved without overlap or land loss?|Before footprint JSON/save changes; individual table is proposed until approved|
| Q-FP-2 |Are rotations90degree-only, which types may rotate, and do visuals need direction variants rather than image mirroring?|Before interaction/save/art protocol|
| Q-RD-1 |Resolved for current road stage: discovered open grass/clearing, no overlap, explicit removal before buildings; explicit road mode/Confirm/Cancel|Codex defaults documented before implementation; no bridges/bulldozing|
| Q-RD-2 |Resolved for current road stage: all3free styles, Draw missing tiles, Replace existing surfaces, Remove roads, mixed-style joins|No research/economy/progression effect; documented stage defaults|
| Q-LC-1 |What are the measured per-device caps and LOD/update budgets? Are market stalls decorative anchors or new functional buildings?|Before NPC pilot; no invented economic market|
| Q-MED-1 |Can missing earlier ChatGPT concepts be recovered as actual high-res files, with provenance and usable rights? Which current candidates need replacement under the realism target?|Before import/replacement acceptance; keep absent entries absent|
| Q-AUD-1 |Which distributable models/licenses/frameworks/device profiles actually satisfy local generation and spatial/head-tracked audio on supported hardware?|Before advanced audio implementation; no guaranteed Neural Engine execution|
| Q-AUD-2 |Automatic-mode policy/default, generation cache budget/eviction, route/interruption/mute behavior, safety throttles for On?|Before settings/runtime audio; normal fallback always available|
| Q-WND-1 |Which monuments ship first, where can they fit the32×24valley, and are they optional vs part of era readiness?|Before catalog expansion; do not silently increase all-building goal requirements|
| Q-WND-2 |How do original-location permanence, restoration/repurposing, construction stages and historical dates interact?|Before monument save/era transition protocol|
| Q-ERA-1 |What is the next era’s approved content/criteria, and how do useful old buildings evolve without forced demolition?|Before any actual advancement|
| Q-GEO-1 |What is shared knowledge vs local researched application? Are global discoveries inherited instantly or gated locally?|Before multi-civilization save/research migration|
| Q-GEO-2 |Region/culture/time-specific variants, generated map identity/seed rules and first shipping subset of eight candidates?|Before regional generation/art production|
| Q-TRADE-1 |Local-only player-owned civilizations, trade rates/routes/capacity and atomic transfer/offline accounting?|Before transfers; no multiplayer/backend inference|

## Supersession rules

The latest direct sync instruction approves broader **future planning**, the revised art target, footprint/road/Living City requirements and the media repository. Earlier first-era stop boundaries still protect against unscoped implementation; they no longer mean those future directions were never approved. Existing code/catalog/save schema are not changed by a document approval alone. Exact costs, dimensions, era lists, numeric targets, bit assignments and framework selections remain provisional until explicitly decided in a bounded stage brief. Preserve historical records with a superseded notice rather than rewriting their original claims.

## Geometry foundation authorization

Dima directly said “Start implementing” after the recovered next-step summary. This authorizes the bounded geometry foundation described in docs/superpowers/specs/2026-11-19-building-geometry-design.md. Exact larger dimensions, legacy-size conversion, visible rotation/art variants and roads/NPC implementation remain staged. Optional captured geometry for new builds and zero-orientation legacy fallback are engineering choices; no eager save rewrite or implicit relocation conversion.

Geometry foundation implementation:70418ea(core/session/tests),d0a3284(render consumers);135Debug/124Release,5Release API probes and9UIcases per profile pass. Optional legacy fields remain nil unless already present; no assumption that this settles legacy conversion before larger-size activation.

## Current authorization — decorative roads

Dima directly instructs “Report to ChatGPT and move on” after geometryed23e2e. Implement the bounded approved decorative-road direction on existing dimensions, per docs/superpowers/specs/2026-11-19-decorative-roads-design.md and plan. Default terrain/no-overlap/mixed-material/free explicit paint/erase rules are documented Codex implementation choices, not recovered human quotations. Geometry stability is sufficient; unapproved larger dimensions remain deferred. No NPC, era or economy expansion. Commit this scope before product changes.

Road delivery: core/session4ed64ac, with native controls/rendering and separate report commits. Reviewer backtracking and journey-preview leaks reproduced/fixed;148Debug/137Release and13UI/profile verification. Current approval does not activate NPCs or larger building dimensions.

## P1 decisions — current feedback and supersessions

The new requirements below are human-approved directions to reconcile/specify, not authorization for simultaneous implementation. Delivery metadata and acceptance live in the canonical roadmap register.

| ID | Decision | Authority / delivery |
|---|---|---|
| COORD-001 | Permanent canonical cycle and dedicated master coordination chat | P1; Ready, S0 |
| MOVE-001 | Individual availability indicators for every relocation footprint tile | P1; Approved, S1-UX |
| MOVE-002 | Footprint-only dragging for relocation | P1; Approved, S1-UX |
| MOVE-003 | Automatic valid relocation and remain in mode on invalid release | P1; Approved, S1-UX |
| MOVE-004 | Bottom-center relocation cancellation | P1; Approved, S1-UX |
| RD-005 | Road stroke reversal and individual tile removal | P1; Approved, S1-UX |
| HUD-001 | Compact goals HUD with three display states | P1; Approved, S1-UX |
| HUD-002 | Explore icon beside goals icon | P1; Approved, S1-UX |
| HUD-003 | Move Roads into Build menu | P1; Approved, S1-UX |
| SAVE-001 | New game and independent saves | P1; Approved, S1-Saves |
| DEV-001 | Separate developer and regular player experiences | P1; Approved, S1-Saves |
| MAP-001 | Larger persistent geographical maps | P1; Approved, S1-Geography |
| MAP-002 | Accessible stone quarry on settlement side of river | P1; Approved, S1-Geography |
| MAP-003 | Cloud-covered unexplored territory | P1; Approved, S1-Geography |
| MAP-004 | Expedition-based territory discovery | P1; existing exploration milestones; Awaiting Human Review, S1-Geography |
| MAP-005 | Geographical expansion across historical eras | P1; Deferred, S8 |

P1 supersedes invalid-drop cancellation and unrestricted relocation drag behavior where these conflict with MOVE-001–004; changing interaction is intentional only in a later bounded approved stage. Existing road Confirm/Cancel and atomic rejection stay active; the phrase “stroke reversal” alone does not select release-to-commit or partial-invalid filtering. Automatic placement refers to the relocation feedback, not implicit road commits. Three HUD states are required, but their exact contents/transitions are open. New independent game saves do not authorize additional simultaneously playable cities. MAP-001–005 complement GEO-001–008 rather than replace the regional backlog. ART-001 remains the realistic saturated target; no human art acceptance is inferred.

Open P1 gates: Q-MOVE-1 exact footprint hit region and per-tile failure display; Q-RD-3 retrace reversal vs explicit undo and committed-tile removal UX; Q-HUD-1 exact three states; Q-SAVE-1 slot count/naming/selection/deletion/recovery and migration; Q-MAP-1 new vs existing world expansion, size/budget/quarry accessibility policy. ChatGPT should return a bounded first-era polish brief and identify decisions requiring Dima. No automatic reset, resource grants or destructive migration.

## S1-UX reconciled engineering choices

Human execution authorization above plus [MC-001 detailed reply](docs/design/sources/2026-11-19-master-coordination-detail.md) settle the bounded S1-UX spec. MOVE-001–004 use shared per-tile core checks, projected logical footprint hit regions, free valid release, retained invalid preview, and bottom-center cancellation. RD-005 uses ordered retrace-to-truncate (returning to a previous draft cell removes its suffix); Confirm/Cancel and whole-stroke validation remain explicit. Individual committed removal is already supported, now retained and verified. HUD-001 adopts Minimal/Compact/Expanded, Compact default, cycle through accessible states; explicit controls permit direct collapse/expand for compatibility. HUD-002 keeps Explore adjacent to Goals in every state. HUD-003 adds a distinct Roads category to Build, no separate top-level Roads entry and no progression count changes. These exact defaults are delegated engineering rulings, not invented historical human quotations. Future sizes/rotation UI, NPCs, audio and monuments remain outside this stage. Q-MOVE-1/Q-RD-3/Q-HUD-1 are resolved for this bounded implementation; save-slot and larger-map policy are resolved only in their later specs.

MC-001 mentions CIV-001 friendly player-owned civilizations and CIV-002 common timeline with different local progress. Existing historical prose retains those concepts. The source supplies no original message IDs for a newly stricter prohibition, so record that attribution for future reconciliation; do not implement warfare or multi-civilization systems.

RD-005 pending correction: individual endpoint Undo removes one preview cell without changing committed roads; Clear remains discard-all, retrace removes suffix, Remove+Confirm erases a committed chosen tile. Build-selected road surface must initialize editing controls, preventing silent switch to trodden during Replace. Delegated bounded interaction detail under current authorized work.
