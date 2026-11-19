# Design decisions and unresolved details

Synchronized19November2026. Status vocabulary and precedence: [baseline](DESIGN_BASELINE.md), [source record](DESIGN_SYNC.md). Source IDs: **S1** current direct Codex synchronization instruction; **S2** City Design Coordination; **S3** Plan iOS GameWinvalid (exact returned title also in archive); **S4** Stage 2 Testing Status; **R1** repository atfea9e16; **E1** checked-in test/milestone reports. Approval is independent of implementation.

## Decision register

| ID | Decision / authority | Design status | Implementation / scheduling |
|---|---|---|---|
| SYNC-001 |Versioned five-document baseline before code; conversation memory is not a complete spec (S1)|Approved, effective now|This documentation sync|
| CORE-001 |SwiftUI/SpriteKit/pure Swift, iOS18universal landscape, deterministic core and protected normal saves (S1/prior direct instructions)|Approved|Implemented; preserve|
| CORE-002 |Persistent geography, IDs, rewards/readiness; no silent revocation (S1/prior0.2.7)|Approved|v5implemented; future migrations must preserve|
| ERA-001 |All active progression catalog buildings/technologies, required resource discovery, five pillars (direct0.2.7)|Approved|Implemented20/20current counts; historical partial-pillar rule superseded|
| GOAL-001 |Seven measurable chapters and out-of-order credit, no duplicate historical rewards (direct0.2.7)|Approved|Implemented; four-chapter proposals superseded|
| PLAY-001 |Dima prioritizes start/understand/complete first era over looks/roads/NPCs; contextual optional dependency guidance and existing-screen navigation |Approved current work|Implementation/verification next; no tuning or requirement change|
| UI-001 |Compact expandable aligned Building/Research cards, icon costs, individual red deficits (direct feedback)|Approved|Implemented through60e3268; current code unchanged by sync|
| FP-001 |Individually balanced dimensions, rectangles and rotation (S1)|Approved requirement|Unimplemented beyond existing width/height enumeration|
| FP-002 |Unique immovable1×1fireplace, existing `campfire` identity (S1/R1)|Approved invariant|Implemented; current palisade also1×1but not required to remain so forever|
| FP-003 |Uniform4×4reported design starting point (S1)|Source discrepancy, not an implementation fact|Actual18types2×2pluscampfire/palisade1×1; no automatic scale conversion|
| FP-004 |Rotation uses90degree steps; saved dimensions/orientation per instance (planning suggestion)|Proposed approach, not finalized|Choose/migrate before catalog dimension changes|
| RD-001 |Footpath/dirt/primitive stone,1tile strips,4-way16masks, drag, save/remove/upgrade (S1)|Approved requirements|Not implemented|
| RD-002 |Initially decorative/free; must not gate era progression (S1)|Approved constraint|Keep outside required-building counts unless a later explicit decision changes it|
| RD-003 |Transport/trade/NPC path preference/building connectivity (S1)|Approved future direction|Functional economics/network delivery deferred|
| RD-004 |N=1/E=2/S=4/W=8; no diagonals; road command batching/tier borders (planning)|Only four-direction16states are approved; exact bit order/transaction details proposed|Document protocol in implementation brief before save format/art mapping|
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
| Q-FP-1 |What footprint/rotation/anchor does each actual type use, and how are legacy instances preserved without overlap or land loss?|Before footprint JSON/save changes; individual table is proposed until approved|
| Q-FP-2 |Are rotations90degree-only, which types may rotate, and do visuals need direction variants rather than image mirroring?|Before interaction/save/art protocol|
| Q-RD-1 |Which terrain/discovery/occupancy allows roads? Can buildings replace roads, share entrance tiles or require removal? How do gestures select roads vs buildings/pan?|Before road commands/UI; do not infer bridges or bulldozing|
| Q-RD-2 |Are all road tiers available initially? Upgrade/downgrade/removal rules, mixed-tier connections and free-upgrade treatment?|Before tier catalog; initial free construction and no progression gate stay fixed|
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
