# Design synchronization record and operating procedure

Effective19November2026. Version-controlled documents are the shared source of truth. ChatGPT supplies new design inputs; approved decisions must be explicitly reconciled and committed **before** implementation. Do not rely on cross-chat memory, an assistant’s claim that something was “saved,” or the newest visible chat alone.

## Canonical documents and precedence

1. Latest direct human instruction resolves conflicts, followed by explicit human approvals with traceable source text.
2. Synchronize into [DESIGN_BASELINE](DESIGN_BASELINE.md), [DEVELOPMENT_ROADMAP](DEVELOPMENT_ROADMAP.md), [DESIGN_DECISIONS](DESIGN_DECISIONS.md), [MEDIA_REQUIREMENTS](MEDIA_REQUIREMENTS.md) and this record; keep approval distinct from implementation and scheduling.
3. Bounded stage specs/plans implement that baseline. Catalog numbers, framework selections and balancing guesses are proposed/experimental unless specifically approved or delegated.
4. Historical `docs/design/*`, milestone reports, archived chats and AGENTS history preserve evidence. Add supersession notices to stale entry points instead of pretending old decisions never existed. A source excerpt is not automatically a current requirement.
5. Game source/tests/art manifests prove implementation; a planning reply accepting a report is not an independent code/art/human audit.

## Source registry and actual recovery

Tools used: `list_projects`, ChatGPT `list_threads` history, `read_thread` and local Git/source inspection. Only relevant game-chat excerpts are archived; unrelated conversation contents were not exported.

| Source | Identity and retrieval | Coverage / limitation |
|---|---|---|
| S1 |Dima’s current direct Codex synchronization instruction,19November2026, afterfea9e16|Authoritative approval for listed requirements/future directions and media setup; exact dimensions/costs/era details stay provisional|
| S2 |[City Design Coordination](https://chatgpt.com/c/6afcb607-afec-83eb-9ba1-a4393b41348a), project **Civilization** `g-p-6afcb5df21608191a15193d9a56c4a4d`|5connector-exposed turns recovered; earlier replies already in local design records; not a full chat export|
| S3 |[Plan iOS GameWinvalid](https://chatgpt.com/c/6afca01d-56e0-83eb-b5d1-9cf417b87e22), same **Civilization** project; exact connector-returned title retained in archive|5turns recovered: initial seed/future ideas; tentative tower-defense/prices/era list are not approvals|
| S4 |[Stage 2 Testing Status](https://chatgpt.com/c/6afe06b8-152c-83ed-8108-8acc56721deb), project **Civilazation** `g-p-f352f14f77788191b45d2e1e092aa7e7`|Latest media/game-design chat found.5turns recovered: synchronization prompt, human“Approved path” for regional direction, monuments and audio/AirPods discussion. Earlier road/footprint/loading discussion not separately exposed|
| R1 |Game repo `/Users/dima/dev/Civilazation`, branch `first-era-review`, snapshotfea9e16(code through60e3268)|Clean before sync; inspected catalog/types/placement/save/UI/rendering/tests/history; source assets remain unchanged|
| M1 |Media repo `/Users/dima/dev/Civilization-Media`, branchmain, initial697b486|Separate local Git/LFSrepo,68checksummed imports from R1, no remote|

Readable Markdown archives normalize trailing whitespace; message identities and text content remain traceable. They are not byte-for-byte full exports.

Archive paths:

- [City excerpt](docs/design/sources/2026-11-19-city-design-coordination.md).
- [Plan excerpt](docs/design/sources/2026-11-19-plan-ios-game.md), retaining its exact returned title and message IDs.
- [Latest design excerpt](docs/design/sources/2026-11-19-stage-2-testing-status.md).

**Access is partial, not wholly unavailable.** The connector returned5turns per target. Requesting10turns for S4still returned5with `hasMore:false`/no older cursor; this does not prove the original conversation contains only5turns. The broader roads/footprints/NPC/loading/audio specifications therefore derive from S1where original discussion was unavailable. Project names differ: the newer S4is under **Civilazation**, while the older coordination/planning chats are under **Civilization**. Search both during future syncs.

A native Chrome fallback was attempted; CUA reported **the Mac is locked and automatic unlock failed**. No older browser transcript or generated-media binary was recovered. This optional recovery limitation does not prevent synchronizing S1. Connector attachment metadata was empty and text contains image-search groups/SVG/interactive fragments; it does not supply original generated raster files. **No design-chat concept binary import is claimed.** Existing20masters/3concepts imported into M1came from the game repo’s previous original-image workflow, not newly recovered ChatGPT files. Cross-conversation memory is not used as substitute evidence.

## Synchronization outcome and conflicts resolved

| Topic | Before / discrepancy | Current synchronized ruling |
|---|---|---|
| Roads |Absent despite “complete first-era visuals” language|Approved roadmap requirements recorded; implementation explicitly absent. No progression gate|
| Footprints |Design prompt refers to uniform4×4|Actualcampfire/palisade1×1and18types2×2recorded. Change to individually balanced rectangles/rotation requires legacy-layout migration first|
| Art target |Earlier muted warm-miniature/painterly candidate|S1realism/high saturation/sharp materials/warm lighting is current approved target; old sources preserved as candidates, not silently regenerated or accepted|
| Global research |Earlier foundation left inheritance unresolved|Approved future shared knowledge/independent local civilizations; exact application/transfer semantics still open|
| Era / monument lists |Early assistant proposals give exact dimensions/era examples|Candidate names retained; sizes/costs/prerequisites/era definitions not promoted into final requirements|
| Scope boundaries |Prior first-era review stop and later future approvals mixed|Current task authorizes sync/media setup, not immediate mass implementation. Future directions approved for roadmap; deliver bounded stages|
| Media “imported” |Search queries/attachment absence can be mistaken for source files|Only verified existing binaries copied; missing ChatGPT sources remain missing|
| Acceptance |ChatGPT reports5of7accepted stages|Human permanent art/enjoyment/hardware acceptance remains open;7in-game chapters are a different implemented measure|

## Current implementation and evidence checkpoint

Code/assets unchanged by this synchronization. Actual catalog counts and footprint shapes verified from `seed.json`; GameState/PlacedBuilding has no road/rotation/NPC/audio/regional/monument system. Existing GameApplication visual manifest is replaceable but not a regional runtime resolver. Current v5validation derives occupied tiles from active definitions, so dimension edits need explicit legacy handling. Loading uses1panorama and native English overlays/spinner, not a completed logo/icon/native-aspect illustrated set.

Last recorded evidence:115Debug/104Release core tests,5Release compile probes, full5UI suites on phone/mini/Pro **before** the final title-height correction and targeted final alignment/affordability tests on all3after. Reports and actual local log tails were inspected; no fresh full-suite run is claimed during this documentation-only task. Ordinary-cost90minute/154minute full-era scripts and recovery evidence exist; human pacing/idle-action quality assessment remains the next task. Signed latest menu build succeeds but newest installation is pending last-observed physical device availability. No present device connectivity or save-byte claim was invented.

M1verification: `python3 scripts/validate_registry.py` passed68records/20masters/20–12–5native mappings; master/export hashes match R1; local `git lfs fsck` passed. Git LFS3.8.1installed and local filters/hooks/patterns configured. No remote/global Git config/game history rewrite; game build does not require M1. License registry contains provenance and pending commercial-clearance status, not a fabricated license grant.

## Persistent synchronization procedure

1. **Discover:** list both relevant ChatGPT projects and identify chats by ID/title. Read actual accessible turns, not just list summaries. Record retrieval date, source project/chat/message IDs, pagination/truncation and attachment/source-file availability. Try a supported fallback if the connector lacks needed content; report any lock/sign-in/access failure plainly.
2. **Classify:** separate human approvals, assistant proposals, implemented evidence, deferred delivery and open questions. If a direct instruction supplies missing specs, cite it; do not claim an inaccessible conversation was fully recovered.
3. **Reconcile:** compare source/code/catalog/save/tests and current documents. Record conflicts/supersessions with stable IDs; do not silently choose dimensions/costs/era definitions or treat every “next task” suggestion as approval for unrelated scope.
4. **Update:** change the five root docs as needed and add relevant source excerpts/specs. Update AGENTS/README/ledger entry points. Media requirements update M1backlog/registry; unavailable files remain absent entries, not false imports.
5. **Commit design first:** make a documentation-only game commit. Media-repo source imports/registry changes have their own commit; record its hash here. Do not mix unrelated gameplay patches into the synchronization commit. Existing uncommitted user work must be preserved and excluded.
6. **Plan a bounded stage:** resolve required open questions or document explicitly delegated routine tuning. Use an effective source commit and specific acceptance criteria. Assessment-only stages can reuse current evidence; do not turn proposed tuning into final requirements. Feature implementation is a later separate commit sequence.
7. **Implement/verify/report:** preserve normal saves/geography/history and required regression fixtures. Update each item’s implementation status with source commit/test/artifact evidence. Native media exports record media commit, master IDs and transforms. Never treat a generated concept as accepted production art without the appropriate review.
8. **Return updates:** when Dima explicitly authorizes reporting to ChatGPT, send a concise real-results summary and limitations, record the reply. Do not depend on ChatGPT “remembering” it or silently broadcast private saves/device data. No automatic messaging/polling service is created by this protocol.

### Change record template

```text
SYNC-ID / date / authorizing human instruction:
Source project/chat/message IDs and recovered text paths:
Access, truncation and unavailable source files:
Approved requirement IDs vs proposed details:
Superseded decisions and preserved history:
Actual implementation baseline and unchanged invariants:
Game documentation commit / media source commit:
Implementation task, dependencies and acceptance criteria:
Actual verification artifacts / unverified items:
Next action and required design decisions:
```

## Synchronization verification

All five canonical documents and updated entry-point relative links resolve. AllAUDIO-001–006/WND-001–007/GEO-001–008IDs are present in the decision register. Catalog audit confirms20buildings/20technologies, with campfire/palisade1×1and18other2×2types. All68media record hashes still match the unchanged game source files. Media repo has65LFS-tracked binary paths; `git show HEAD:buildings/masters/hut.png` is an LFS pointer and `git lfs fsck` passes. Game implementation/config/runtime assets/project/test sources compare unchanged againstfea9e16. Game sync changes are Markdown only; media setup/import has its own separate commit. No fresh gameplay test, missing concept import, road/NPC/audio delivery or hardware installation is claimed.

## Next action

Execute S1final candidate quality assessment: full post-correction UI suites on3profiles, consolidate current legitimate progression/idle gaps, retain real hardware limits and install safely after reconnection. Then S2footprint/rotation brief and migration decision precede S3decorative roads. This task stops after synchronized docs/media foundation and commits; no roads, resized building catalog, agents, audio, monuments or new-era content was implemented.
