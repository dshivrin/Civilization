## ROUND-2-PLAY — approved staged implementation

Owner approval [f313dd2](plans/ROUND-2-PLAY-APPROVAL.md) and direct instruction authorize R2-01/02/03, then R2-04/05 and the R2-06 isolated connectivity pilot per [reconciliation](docs/design/proposals/2026-11-20-round-2-play-reconciliation.md). Use reusable QA, preserve every save/history, commit/push verified slices. R2-07 normal-save activation waits for pilot verification and human acceptance. No deferred bridges, defenses, new resource rules or artwork. [Execution evidence](docs/testing/round-2/progress.md).

# Civic/review physical installation — 20 November 2026

Dima directly requests iPhone install and ChatGPT report. Product3110b33signed Debug installation/launch and process check succeed after fresh stable production-validated backup; all5files byte-identical before launch. After launch all prior normal9buildings, originalnormal6buildings/15roads, developer5buildings and geography backup remain byte-identical; old library entries retained. A separate2-building normal game was added/selected; actual physical tap not observed/automated. No reset/uninstall/save injection/signing change. [Evidence](docs/testing/gameplay-review/device-install.json). Report only to the designated Master chat; human gameplay/review-control interaction and sustained physical metrics remain unverified.

# Isolated gameplay review controls delivered — 20 November 2026

At Dima's direct request, **Developer tools → Review this game** creates/resumes a separate review companion using existing1×/2×/5×/10×speed and capped250resource grants. Normal saves and original developer companions remain independent. Healthy-source/pending-preparation guards, durable first-write publication, save-before-return failure protection, no review offline catch-up and shared inspector marker validation are verified. Debug-only controls; Release entry and7API exclusion probes pass. Core210Debug/184Release, inspector10Debug/9Release, Python10 and native phone/tablet review +scenario regression pass. [Delivery](docs/milestones/isolated-gameplay-review.md), [evidence](docs/testing/gameplay-review/progress.md). No physical install/reset/signing/media change. Human gameplay acceptance remains open; do not start unrelated backlog. Same native Goal is closed only after verified commit/push.

# GAME-LOOP-01 delivered; isolated playtest follow-up — 20 November 2026

Owner approvalc716670 resolves the earlier civic design gate. [Delivery](docs/milestones/game-loop-01.md): same movable1×1founding civic ID, L2Gathering Place/L3Council Circle, paid research gates, fixed founding provisions, civic chapter/pillar/readiness objectives, exact prerequisite/return UI and non-destructive v6 progression history. 204Debug/184Release +5Release exclusions and targeted native phone/mini/Pro/Release entry checks pass; existing backup read-only validation preserves every original byte. No physical install/reset/save overwrite or art replacement. Commit/push to personal first-era-review.

Next direct owner request: add existing time multipliers and resource grants for faster gameplay review. Owner explicitly selected **separate review copy; preserve normal progress**. Keep existing developer companions independent as well; do not overwrite normal or developer saves for this follow-up. No unrelated gameplay backlog.

# Civilization Builder — Codex project instructions

## Permanent goal-based execution and reusable approvals — 20 November 2026

Every new Civilization Codex assignment must be expressed as a **Goal**, with explicit acceptance criteria, verification, and a concise completion report. Continue through authorized implementation, build, test, fix and retest steps without stopping at routine checkpoints; respect host session and usage limits.

Dima repeatedly approves routine `swift test`, `xcodebuild` and the reusable QA runner, including variations in suite, destination and build configuration. **Minimize duplicate prompts:** use the existing stable `python3 scripts/dev.py` entry point and documented subcommands from `scripts/README.md`, avoid unnecessary shell-wrapper/prefix changes, and configure narrowly scoped persistent allow rules where the host supports them. Prefer existing approved command patterns; do not create ad hoc runners merely to change arguments. If persistent permission matching cannot cover variable commands, explain the exact one-time host configuration required rather than repeatedly requesting equivalent approvals. A Goal or this file does **not** override host permission enforcement; request approval when the host requires it.

Standing authorization covers non-destructive project builds, Swift/XCTest runs, simulator checks, screenshots, and their required cache access within existing security boundaries. It does not authorize bypassing sandbox controls, blanket unrestricted execution, signing/account changes, destructive save operations, physical-device resets, or unrelated publishing. Preserve existing player saves, signing settings, and the personal Git remote restrictions.


## Reuse local engineering tools — 20 November 2026

Dima explicitly requests saving repeated scripts with parameters and reusing them to save time. Before generating another temporary QA runner, save validator or preservation/hash script, read [scripts/README.md](scripts/README.md) and use/extend `python3 scripts/dev.py`: doctor/test/validate-saves/backup-device/compare-saves. Permanent resource-safe SwiftPM inspector lives under Tools/SaveInspector; no more copying ad hoc swiftc binaries/resource bundles. Existing host permissions still apply. Backup-device requires explicit device/bundle/new local output, supports dry-run, does not install/launch/stop/reset/write to device. Native tests use isolated QA identity and persistent cache. Never treat zero/missing tests as passing or overwrite artifact directories. [Verified bounded tooling](docs/milestones/reusable-engineering-tools.md). Original DEV-001 meaning and all future backlog remain. Human game acceptance is still pending.


## S1-PLAY physical update and requested plan — 20 November 2026

At Dima's explicit request, product2f0e4b9signed iPhone installation/launch succeed after a fresh validated backup; all4files byte-identical before launch. Original normal6buildings/15roads, developer5buildings/0roads and geography backup remain byte-identical afterward; separate authentic one-campfire normal game now selected, old entry retained. [Evidence](docs/testing/s1-play/device-install.json). Dima requested asking the Master chat for its tools/test plan; [reply reconstruction](docs/design/sources/2026-11-20-development-infrastructure-reconstructed.md) retrieved. Proposed infrastructure DEV labels are not canonical renumbering/new execution permission. Stop for normal human playtest.


## S1-PLAY-001 candidate — stop for human playtest, 20 November 2026

Dima's normal-entry/era-completion task is implemented for human review. Launch → New Game creates a separate authentic64×48one-campfire standard start; Continue resumes the selected normal save. No progress reset/deletion or physical install in this task. Seven canonical chapters/catalog/required territories/five pillars lead to Bronze Age readiness only; no Bronze gameplay or balance change. Fresh189Debug/171Release, five Release exclusions and scoped native phone/mini/Pro Debug plus phone/iPad Release entry/completion pass. [Report](docs/milestones/s1-play.md), [tool/test readiness and remaining dependencies](docs/testing/s1-play-readiness.md). Human playtest is the acceptance gate; stop after authorized commit/push. Preserve all prior backlog/media and saves.


## Active S1-Geography activation — 20 November 2026

Dima confirms all existing saves are development/test data and authorizes the approved **64×48 default**, standard Stone Age start, unchanged normal footprints, MAP-001–004 implementation/verification and then environment graphics assessment. This supersedes earlier production migration approval gates and the 32×24 normal default. Backups must be created and validated before archiving/resetting any development progress; preserve independent normal/developer saves. [Bounded specification](docs/superpowers/specs/2026-11-20-s1-geography-design.md). Production implementation is verified and awaiting human review: core181b0a8/rendering56f4124,187Debug/169Release, five Release exclusions and native phone/mini/Pro checks. [Milestone](docs/milestones/s1-geography.md). Environment graphics has started with [integration assessment and one review concept](docs/art/2026-11-20-environment-integration-assessment.md); no runtime art replacement or batch production. All previous backlog and visual approval requirements remain.


## Human64×48/navigation acceptance — 20 November 2026

Dima confirms **“Yes, navigation improved. Approved, commit and report to chat.”**64×48size and the installed navigation correction are now human-approved. Product2ab7492launch succeeds after unlock; normal32×24settlement and isolated64×48developer geometry/history are preserved. [Acceptance/evidence](docs/milestones/large-developer-village.md). Commit and report to the designated Master Development Coordination chat; broader art/enjoyment/sustained hardware metrics and normal-world migration policy remain separate. All existing backlog retained.


## Approved64×48size and navigation follow-up — 20 November 2026

Dima explicitly approved **64×48size** after reviewing the large developer preview and requested smoother first-attempt pan/pinch. [Delivery/navigation evidence](docs/milestones/large-developer-village.md) records the added isolated64building/24home/566road grouped scenario, DEBUG-only annex/proposed footprints, preserved original768terrain cells and normal32×24world. Production map/footprint activation and existing-world migration policy remain separately gated. Navigation corrections remove repeated scene creation and redundant equivalent simulation work, preserving balances/relocation/road behavior. Human physical smoothness/art/enjoyment acceptance remains open. All prior backlog and media remain unchanged. Standing `xcodebuild`/`swift test` authorization is recorded in AGENTS.md; use direct commands.


## Standing build/test authorization — 20 November 2026

Dima explicitly instructs: **“Always allow all Xcode builds and all swift test runs.”** Treat Xcode build/test commands and `swift test` runs as preauthorized, using persistent tool permission rules where supported. Preserve existing signing/account settings and host-managed permission boundaries. This does not authorize unrelated destructive actions, signing/account changes, save resets or publication outside the established personal repository.


## S1-Geography sizing review — 20 November 2026

[Quantitative sizing report](docs/superpowers/specs/2026-11-20-s1-geography-sizing-review.md) recommends **64×48 conditionally**, not activated or approved: 1,494 settlement-connected buildable tiles in the proposed additive annex; all 20 catalog types/64 instances, 24 homes in three neighborhoods, connected roads/quarry/plaza, 136 staging tiles and 352 other free connected tiles. 48×36 falls short of the exhibited layout budget; 80×60 adds substantial unused land. All original 768 terrain cells/coordinates are preserved in the study. Footprints/annex geometry/opt-in migration/quarry shared reserve/expanded discovery cap remain proposals awaiting Product Owner review. Device performance is unmeasured. Direct movement without edit mode is a future UX requirement only. Preserve all prior backlog and Saves acceptance/physical-launch limits; no product/save/media change.


## S1-Saves delivery checkpoint — 20 November 2026

Independent normal games/developer separation are implemented **awaiting human acceptance**, final product7f5e10c/review fixes c124568. See [actual milestone report](docs/milestones/s1-saves.md):172Debug/159Release, five Release exclusions,19phone/19mini and18Pro+added recovery native checks. Final recovery-copy change has affected core/phone rechecks. Explicit healthy-game recovery preserves damaged slots; failed opens leave target bytes unchanged. Signed iPhone update installed after fresh current-production backup, normal5buildings/15roads and developer5buildings/0roads byte-identical pre-launch. Physical first launch/library-index initialization is blocked by device lock and **not verified**. Geometry/geography/catalog/v5/economy/art/signing unchanged; media697b486 remains untouched. Human usability/enjoyment/art acceptance remains open. Next: S1-Geography detailed dimensions/migration/quarry/cloud/discovery review gate, then approved environment graphics; preserve every existing approved/deferred roadmap item. No second-era gameplay. Same native Goal and durable checkpoint remain active; no quota bypass or duplicate sessions.

## Active S1-Saves specification

S1-UX is delivered; now execute authorized SAVE-001/DEV-001 per [reconciled design](docs/superpowers/specs/2026-11-19-s1-saves-design.md) and [plan](docs/superpowers/plans/2026-11-19-s1-saves.md). Separate version1 library index; existing normal/developer paths retained; new UUID games have independent files and actual starting state. Save-before-switch, validated targets, no silent resets on corruption, atomic selection publication, library-owned lifecycle, isolated Debug fixtures. Names/default presentation are delegated choices; no deletion/cloud/world expansion. Preserve all future backlog. No save-management product code preceded this design commit.


## S1-UX delivery checkpoint — 19 November 2026

S1-UX is implemented **awaiting human review**, final product60046d2; [actual milestone evidence](docs/milestones/s1-ux.md) records155Debug/144Release, five Release probes,16native cases/profile plus affected final checks, original stationary/translucent relocation/grid, pending retrace/Undo, icon-default goals/adjacent Explore/Build roads. Signed final iPhone update installed after fresh production-validated backup; both saves byte-identical pre-launch and normal launch succeeds. Human enjoyment/art/touch/sustained hardware performance are open. No economy/catalog/geography/save-schema change. Continue directly to authorized **S1-Saves** after its detailed design reconciliation, then S1-Geography (exact dimensions/migration review gate), then environment graphics. Preserve all previous roadmap requirements and both repositories. Native same-chat Goal/checkpoint remains active; no quota bypass/duplicate session or guaranteed reset timer claim.


## GitHub issue #1 refinement — active S1-UX details

[Primary coordination issue](https://github.com/dshivrin/Civilization/issues/1) and remote docs commit 26894bd were retrieved before further UI work. Latest refinement supersedes earlier MC-001 engineering defaults: **white available/light-gray blocked grid; original building stays stationary/translucent while only the footprint moves; circular bottom-center X; goals icon-only by default, tap for summary then expand guidance**. Explore stays adjacent; Roads inside Build. Shared atomic validation, forgiving invalid drop, free relocation, ordered pending-road retrace and Confirm/Cancel remain. Exact larger-map dimensions/migration explicitly require review before S1-Geography. Preserve all other roadmap IDs. Current code commits before this refinement are foundations, not final visual/default compliance. GitHub comment write now succeeds (comment 7019325134), superseding the earlier transient 403; issue #1 is the actual report channel. Git uses rebase of unpublished commits onto remote docs, no merge/force-push.


## Active execution authorization — first-era polish

Dima directly authorizes autonomous implementation in order **S1-UX → S1-Saves → S1-Geography → approved environment graphics**, with detailed design reconciliation before each milestone. This supersedes older synchronization-only/awaiting-authorization boundaries. Preserve every approved/deferred roadmap item, both repositories and the existing first-era-review branch. Routine engineering choices are delegated; stop for significant product/safety decisions. No second-era gameplay. GitHub under personal owner dshivrin is the primary coordination channel; commit/push coherent work and retrieve actual instructions when connector permissions permit. Maintain [durable checkpoint](docs/development-checkpoint.md); do not infer product acceptance from passing tests.

Native Codex Goal is enabled for this same chat; no cron, launchd, duplicate session, alternate account or quota bypass. Respect host usage limits, checkpoint at coherent boundaries and resume through supported native lifecycle when permitted. Exact automatic wake at the five-hour reset remains unverified; do not promise it. Existing branch is intentionally retained rather than creating another worktree, per Dima's instruction.


## GitHub ownership and permanent coordination destination

Dima explicitly restricts **all GitHub actions to his personal account `dshivrin`**. Do not act in organizations or other accounts. Game origin is `git@github.com:dshivrin/Civilization.git`; verify destination/owner before future remote writes. Initial push of `first-era-review` at `ae1d996` is verified; it tracks `origin/first-era-review`. Push was directly authorized in this cycle; do not infer permission to merge or publish unrelated work. Existing SSH authentication identifies as `dshivrin`; no new credentials were needed. Media remains local at `697b486` with no supplied remote; do not invent a remote or claim its LFS objects are backed up on GitHub.

Dedicated chat: [Civilization — Master Development Coordination](https://chatgpt.com/c/6aff4440-ac14-83eb-b7bd-1f2d8bd9a0a9), consolidated project `g-p-f352f14f77788191b45d2e1e092aa7e7`. Dima explicitly approved uploading/sending the 156 KB package containing all six canonical files and private project/design status. The package and request were actually submitted; the earlier pending-transmission notes below are historical. The chat acknowledged this permanent role; the complete nine-part design reconciliation must be recovered and classified before any feature implementation. No automatic write access by ChatGPT to GitHub or media is established merely by providing URLs.

## Current authority — permanent protocol synchronization (19 November 2026)

Dima’s [Permanent Development and Coordination Protocol](docs/design/sources/2026-11-19-permanent-development-protocol.md) (source **P1**) is the latest direct instruction. Only the consolidated ChatGPT **Civilization** project `g-p-f352f14f77788191b45d2e1e092aa7e7` is used for coordination. Legacy projects are historical evidence only; do not retrieve instructions independently from them. Use the dedicated **Civilization — Master Development Coordination** conversation recorded in DESIGN_SYNC.md, never select a chat merely by recency.

The current assignment is documentation synchronization and a real coordination request **before further features**. Human = Product Owner/final authority; ChatGPT = Game Designer/Project Architect/Roadmap Coordinator; Codex = Engineering Lead. Both game and media remain in Git. Complete, enjoyable, polished Stone Age remains the immediate product milestone. Implementation completion is not human acceptance.

Current implementation baseline: game `4d4211e` on `first-era-review`; media `697b486` on `main`. Geometry foundation and decorative roads are delivered for review. Recorded latest evidence: 148 Debug / 137 Release core tests, five Release exclusion probes, 13 UI tests on each of three profiles; signed iPhone update installed with fresh production-validated backup and both saves byte-identical before normal launch. Physical road usability, sustained performance and art/enjoyment acceptance remain open. These are prior milestone results, not fresh tests in this documentation cycle.

The current register at the top of DEVELOPMENT_ROADMAP.md supersedes historical pending-install/no-roads/no-geometry/next-stage statements below. New relocation, road editing, three-state HUD, independent saves and geography feedback is approved for specification; it is not implemented by this sync. No second era, additional playable cities, warfare, monetization, backend, renderer replacement, save reset or catalog rescaling is authorized. Preserve existing local branch; do not automatically merge or push.


## Current authority — synchronized design roadmap (19 November 2026)

The root `DESIGN_BASELINE.md`, `DEVELOPMENT_ROADMAP.md`, `DESIGN_DECISIONS.md`, `MEDIA_REQUIREMENTS.md` and `DESIGN_SYNC.md` are the shared version-controlled design authority. Read them before feature work. ChatGPT design inputs must be recovered/classified, reconciled with human approvals, and committed to these documents before implementation. Cross-chat memory and an assistant’s “saved/approved” label are not complete specifications or independent acceptance.

Dima directly approved synchronization of variable footprints/rotation, decorative roads, Living City, the revised realism art target/loading/branding, AUDIO-001–006, WND-001–007 and future GEO-001–008. This task creates the sibling `/Users/dima/dev/Civilization-Media` Git/LFS repository and synchronizes documentation; **it does not implement all future features**. Deliver bounded stages per roadmap. Exact sizes/costs/era definitions/frameworks/budgets remain proposed/open until decided; no automatic4×4rescaling (actual campfire/palisade1×1, eighteen others2×2). Preserve immutable campfire, geography, normal saves/rewards, iOS18/signing and tested gestures. No renderer replacement, warfare, monetization or backend is authorized.

Current next task is first-era stabilization/assessment: complete post-title-fix UI suites on all3profiles and consolidate legitimate progression/performance evidence; then approve footprint migration before new sizes/roads. Latest compact-menu installation remains pending last-observed iPhone availability and a fresh validated backup. Human art/enjoyment acceptance remains open. Earlier milestone/stop sections below are historical context where superseded by the synchronized baseline; they must not erase approved future directions or authorize unscheduled implementation.

## Current engineering step — decorative roads

Dima explicitly authorized “Report to ChatGPT and move on” after geometryed23e2e. Free decorative roads are delivered per `docs/milestones/decorative-roads.md` and committed road spec/plan. Separate optional v5road data, mixed3materials/16masks, explicit Draw/Replace/Remove +Confirm/Cancel, atomic invalid-stroke rejection, free removal before buildings. These defaults are Codex implementation choices, not older human quotations. Roads do not count toward the20building/20research/7chapter/5pillar requirements. New core148Debug/137Release and13UI/profile regression evidence; signed update installed after fresh backup/production validation, both normal/developer saves byte-identical pre-launch; normal launch succeeds. Physical usability/performance remains unverified. Current sizes/art unchanged, no NPC/larger-size/rotationUI expansion. Preserve local first-era-review branch; no automatic merge/push. Report completed bounded milestone before a further system.

## Current engineering step — geometry foundation

Dima directly authorized “Start implementing” after the recovered next-phase brief, then “Continue”. Bounded geometry foundation is implemented; see `docs/milestones/building-geometry-foundation.md`. New construction captures optional footprint/orientation; legacy nil fields keep catalog fallback without rewrite. Production dimensions/art/era/costs stay unchanged. No live Rotate controls or roads/NPCs enabled. Legacy-layout preservation before catalog-size activation, exact dimensions and orientation art require the next bounded specification. Keep commits on the existing first-era-review branch for review; no automatic merge/push. Full135Debug/124Release and9UI/profile checks pass; physical update awaits device access/fresh validated backup.

## Active first-era playability priority

Dima explicitly prioritizes starting, understanding what to do and completing the first era; graphics/roads/NPCs are secondary. Guidance/navigation and legitimate full-era verification implemented; see `docs/milestones/first-era-playability.md`.126Debug/115Release and9UI cases/profile pass. Current numerical config/savev5/geography/gestures/art remain unchanged. PLAY-002 reserve prevention was explicitly approved and is implemented: catalog-derived atomic build/research/upgrade checks plus named supplier UI/guidance. Q-PLAY-1 now concerns only already-insolvent historical-save recovery; no grants/reset authorized. Continue this gameplay priority before secondary features. Physical update awaits device access/fresh backup; no reset.

## Active roadmap — first-era review candidate complete
Dima authorized continuous implementation through the Civilization project's City Design Coordination conversation. See [docs/design/status-ledger.md](docs/design/status-ledger.md) for statuses and sources. Seed 0.2.1 is complete. The old stop-after-0.2.1 boundary is superseded.

- Execute 0.2.2 economy/catalog, then 0.2.3 workforce, 0.2.4 exploration and 0.2.5 research/progression, verifying and reporting each milestone to the authorized conversation before checking current approvals and continuing.
- Implement only approved structural decisions. Numerical tuning is delegated and experimental; document it. Art proposals are not approved production assets. Use replaceable placeholders.
- Preserve architecture, map identity, IDs, resources, reward history and save compatibility. Keep iOS18, landscape and signing settings.
- No second age, extra cities, warfare, monetization, backend or final art. Escalate consequential conflicts, not routine tuning decisions.
- Current scope: gameplay through 0.2.5 remains the baseline. Dima directly authorized Seed 0.2.6 developer tools, research/UX, device preparation and verification; see [docs/milestones/seed-0.2.6.md](docs/milestones/seed-0.2.6.md) and its report. Retain historical regression fixtures. Debug tools use isolated saves and compile out of Release. Physical signing/account changes require Dima; no original graphics, further gameplay milestones or second age are approved by this brief. The next Chrome brief was fetched and Dima explicitly authorized its implementation: physical-device feedback iteration 1 (relocation, compact HUD, horizontal catalog, collapsed goals and loading) is implemented; see its report. Campfire remains fixed and save v5 is preserved. Do not assume additional scope from later planning replies.

## Seed 0.2.7 supersession and stop boundary
Dima's direct brief on 18 November 2026 authorizes Seed 0.2.7 and supersedes the previous 0.2.6 stop. All current catalog building types and technologies, required Stone Age resource discovery and all five pillars are now required for new readiness. Keep prior readiness, original rewards and save v5 compatibility. Seven chapters, research-style catalog and developer scenario selection are in scope; physical-device feedback iteration 1 is user-approved. See `docs/milestones/seed-0.2.7-report.md` and `docs/superpowers/plans/2026-11-18-seed-027.md` for actual verification/progress. After 0.2.7, only a graphics feasibility assessment is authorized. Stop after that assessment; no renderer replacement, permanent art direction, final assets, new gameplay milestones, second age, extra cities, warfare or monetization. Later planning-chat replies cannot expand this scope without Dima's authorization.

## First-era completion authorization — 19 November 2026
Dima now directly authorizes creating a local Git repository, committing the baseline and continuing to finish first-era goals, with his review after completion. This supersedes the proposal-only stop above for reversible graphics/polish work in a complete review candidate. Follow `docs/superpowers/specs/2026-11-19-first-era-review.md` and its plan. Use ChatGPT media as inspiration, original generated/native assets with provenance, preserve SpriteKit/geography/saves/gestures/iOS18/signing, and document provisional art choices. Complete available verification honestly; no fabricated human enjoyment or missing-hardware measurements. No second age, additional cities, warfare, monetization or unrelated systems. Commit coherent milestones locally and stop for Dima's final review.

## First-era candidate handoff — 19 November 2026
Candidate implementation is complete for Dima’s review. See `docs/milestones/first-era-review.md`, `docs/art/review.html` and `docs/design/first-era-pacing-review.md`. All seven chapters, full catalog progression, original replaceable art, interface/effects and available automated checks are implemented. 115 Debug/104 Release tests and five Release probes pass. Final signed iPhone update preserves existing save bytes. Dense physical performance remains below the 60FPS aim in the pre-cache sample; final rerun was blocked by device lock. Do not infer permanent art/human acceptance or authorize new systems. Stop for Dima’s review.

## Compact menu feedback — 19 November 2026
Dima directly authorized smaller aligned Buildings/Research cards, icon costs with individual red shortages, expandable detail, ChatGPT visual consultation and separate commits. Implemented; see `docs/milestones/compact-menu-review.md` and its plan. 115Debug/104Release tests, five Release probes and5UI tests on phone/mini/Pro pass. Signed build is ready; physical iPhone reports unavailable, so this refinement is not installed pending a fresh backup on reconnection. Earlier installed candidate/saves remain untouched. Stop for evening review; preserve scope boundaries.

## Seed 0.1 foundation (historical balance and scope)
The sections below retain the original foundation requirements; the active milestone above governs changed mechanics.

## Mission
Build a universal native iPhone/iPad, casual-first, single-player incremental civilization builder. Start with Seed 0.1: one Stone Age settlement. This file is the initial source of truth; proposed details may change after playtesting. No tower defense, multiplayer, backend, or actual purchases in this seed.

## Product decisions
- Persistent geography: the same river, mountains and settlement remain as history advances.
- Eventually support multiple player-owned civilizations, each with multiple cities, developing in parallel on a shared global historical timeline. Local development levels may differ. Friendly player-owned cities trade; hostile NPC factions and combat remain undecided.
- Five development pillars: economy, science, military/security, culture, population.
- Buildings may eventually be improved, repurposed, rebuilt with partial resource recovery, or incorporated into new structures. Avoid forced loss of useful housing or artificial land scarcity. Technology inheritance is unresolved.
- Casual sessions should deliver visible progress in seconds or minutes; longer sessions offer meaningful choices. Future monetization: resources, acceleration and cosmetic skins; never require purchases to progress.

## Platform and engineering
- Proposed minimum iOS/iPadOS 18.0; universal app, landscape left/right initially. Verify available simulator runtimes and SDK via Xcode; do not silently change deployment targets or signing.
- Baseline hardware iPad mini 6 (A15); also test iPhone 17 Pro Max and 12.9-inch iPad Pro M1 or nearest available simulator profiles. Aim for 60 FPS on physical hardware; simulator results are not hardware benchmarks.
- Swift, SwiftUI shell/HUD and SpriteKit world. Native APIs only unless explicitly approved. Use the existing Xcode project if present; inspect it first. Do not overwrite unrelated files.
- Separate GameCore (pure Swift, no SwiftUI/SpriteKit imports), rendering, UI, persistence and configuration. Use Swift Testing for core tests. Keep code modular, straightforward and documented where needed.
- GameCore owns authoritative state. Renderers display snapshots and submit commands; never mutate the economy directly. Inject clock and seeded RNG where needed; stable IDs, deterministic simulation, no frame-dependent production.
- Use versioned Codable saves, atomic writes and a configurable offline catch-up cap (initially 8 hours). Avoid double-counting elapsed time; handle negative clock changes safely. Save after meaningful actions and when backgrounded. Do not simulate individual rendering frames during offline progress.
- Store building definitions, starting resources, tuning and footprints in bundled JSON; validate data and use explicit units. Do not bury balance numbers in UI. No premium economy in Seed 0.1.

## Seed 0.1 playable scope
One fixed, handcrafted map of 32×24 tiles. Proposed orthographic isometric 2.5D view (logical tile coordinates, 2:1 projection). Include a river, grass, forest, rocky hills, a clearing and buildable land. Separate terrain, occupancy and world coordinates. Water and hills blocked for initial construction; forest tiles are scenery in seed, not consumed. Preserve map identity in saves. No procedural map generator yet.

Camera: drag to pan, pinch to zoom, safe bounds, center-on-settlement action. Tap to inspect; build mode shows valid/invalid ghost footprint, confirm/cancel. Support safe areas, comfortable touch targets, and adaptive HUD; iPad reveals more map within reasonable zoom limits. Avoid gesture conflicts. Provide basic accessibility labels.

### Initial resources and buildings (provisional balance)
All material amounts are units; rates per minute; construction is instantaneous in the seed to validate the loop. No population starvation or building destruction in seed. Production fills a shared per-resource cap of 500. Initial food 60, wood 100, stone 50, knowledge 0; starting population 3, capacity 5. No passive population growth yet; population is a count, not a spendable currency. Buildings operate without worker assignment in the seed.

| Building | Footprint | Food cost | Wood cost | Stone cost | Effect |
|---|---|---:|---:|---:|---|
| Campfire (preplaced, unique) | 1×1 | 0 | 0 | 0 | +2 food/min; initial housing capacity 5 |
| Hut | 2×2 | 0 | 20 | 0 | +5 housing capacity |
| Gathering shelter | 2×2 | 0 | 15 | 0 | +12 food/min |
| Woodcutter | 2×2 | 0 | 10 | 5 | +10 wood/min |
| Stone gatherer | 2×2 | 0 | 15 | 0 | +8 stone/min |
| Storytelling circle | 2×2 | 10 | 20 | 10 | +3 knowledge/min |

Campfire is placed near the river on a valid clearing. All buildings initially unlocked except storytelling circle, unlocked by first research. Research: Oral Tradition costs 20 food and 10 wood; unlocks storytelling circle. Research UI should clearly show costs and completion. No additional research tree yet.

### Gameplay loop
1. Open game immediately at the settlement, see campfire and starting resources.
2. Follow optional, non-blocking goals: build a gathering shelter; build a woodcutter; build a hut; build a stone gatherer; research Oral Tradition; build a storytelling circle; accumulate 15 knowledge.
3. Show production, resource changes, housing, placement feedback and goal progress. Goal reward: one-time +10 wood on completing each construction goal (not research or final knowledge goal); track completion idempotently. No repeat reward farming.
4. At final goal, show seed completion and allow continued sandbox building. Save/reload preserves all progress. First meaningful action under 30 seconds; target 5–15 minutes to complete seed, subject to testing (initial rates may yield longer completion without optimization).

### Initial equations
`balanceNext = min(capacity, balance + ratePerMinute * elapsedSeconds / 60)` for nonnegative production; use Double or a documented fixed-point representation, display rounded-down units, do not discard fractions. Build/research transactions are atomic: verify all costs, prerequisites, bounds, terrain and occupancy before deducting anything. Reject invalid placement without changing state. Housing capacity derives from buildings; initial population stays 3 until later population model. Knowledge uses same cap in seed. Aggregate steady-state rates during offline catch-up. Tuning values are hypotheses, not final game economics.

## Visual direction
Warm, readable, stylized isometric miniature settlement; earthy muted greens, ochre, wood and stone, blue river. Clean silhouettes, consistent 2:1 ground projection, shadows and scale, no photorealism. Initial implementation uses original procedural SpriteKit shapes or clearly labeled placeholders: grass/water/rock tiles, trees, campfire, huts and shelters. Do not download unlicensed assets or block the seed waiting for art. Define reusable asset keys, logical footprints and ground-contact anchor points so final transparent sprites can replace placeholders without gameplay changes. Art assets and final terrain design are a later deliverable; do not claim placeholders are final art.

## Implementation order
1. Inspect repo and available Xcode tooling; produce a short plan, then proceed unless blocked by destructive changes/signing.
2. Implement domain types, config, deterministic simulation and unit tests for costs, rates, caps, placement, unlocks, rewards and offline time.
3. Implement map, projection and camera, with placeholder terrain/buildings.
4. Add HUD, build catalog, selection/placement, research and goals.
5. Implement save/load and lifecycle handling; test restart and offline catch-up.
6. Build and run on an available iPhone and iPad simulator if tooling permits. Fix failures; document any unverified items.

## Definition of done
- App builds; a new game shows map, campfire, resources and build UI.
- Player can place all six building types as allowed (campfire preplaced), research, and reach seed completion without payment.
- Invalid/overlapping placements and insufficient resources cannot charge the player.
- Production is independent of frame rate and survives save/reload; offline cap and goal reward idempotency covered by tests.
- UI is usable on phone and tablet in landscape; no clipped essential controls.
- Report actual build/test commands, results and blockers. Update README with run instructions and current limitations. Do not claim tests or device performance were verified unless actually run.

## Explicitly deferred
Additional eras and cities, world map, full research pillars, workforce and consumption, construction timers, reconstruction/repurposing, trade, technology diffusion, warfare, premium purchases, analytics, cloud saves, final graphics/audio and localization. Design for future extension without implementing speculative frameworks now.
