# Civilization durable development checkpoint

Updated19November2026. Branch first-era-review. Product18c758f, metadata c0de0b5, reconciled design4e5b60a. Remote coordination0a4ce8e/50653fd/254fc8f inspected and integrated by rebasing unpublished work; documentation-only conflict retained BOTH new CLU notice and active Saves specification. Product diff against pre-rebase cc996c7 is empty. Media697b486/main unchanged/local-only. GitHub actions only under personal dshivrin; primary issue https://github.com/dshivrin/Civilization/issues/1 . Native Goal active in chat01a1f50b-a549-7010-9931-1e625005c041; no duplicate session.

## Current task and exact next action

S1-Saves Tasks1–2 core is committed; native app is NOT wired to GameLibrary yet. Spec docs/superpowers/specs/2026-11-19-s1-saves-design.md; plan docs/superpowers/plans/2026-11-19-s1-saves.md. Exact next action: retrieve latest issue1/remote instructions, inspect existing native UI test helpers, add failing isolated Games create/switch/relaunch/developer-isolation UI tests, then wire CivilizationApp to GameLibrary, keyed SettlementView and SavedGamesView. Add new view to pbxproj without signing changes. Build phone and run relevant native tests, then tablet/full regressions/review/device/report per plan. Do not begin Geography before Saves delivery and its explicit dimensions/migration review gate.

## Completed work and actual evidence

S1-UX delivered and pushed: product60046d2/report0b4a8b4/research6f5195c.155Debug/144Release, five Release exclusion probes,16native cases/profile plus affected final checks. Signed final iPhone update with fresh production-validated backup, both saves byte-identical pre-launch; normal launch succeeds. Normal4buildings/15roads, developer5buildings/0roads. Actual report docs/milestones/s1-ux.md; GitHub handover7020189361. Human enjoyment/art/touch/sustained physical performance remain open.

S1-Saves design start reported GitHub7020373582. Metadata RED missing API then160Debug GREEN. Async library RED missing API then166Debug initial GREEN. Final added metadata failure/concurrent guard tests:168Debug and156Release PASS (/tmp/civilization-s1saves-library-final-{debug,release}.log). One initial metadata-failure assertion incorrectly compared normal JSON bytes despite valid key reordering; corrected to compare production-loaded GameState. Corrupt files retain byte comparisons. No product fix was hidden by this correction. All five Release developer API exclusion probes PASS (scripts/verify-developer-release.py). No native Saves tests or installation claimed yet.

## Implemented core behavior

GamePersistence GameLibraryStore: version1 games-index.json separate from v5; legacy normal/developer paths untouched; UUID games/<ID>/settlement-v1.json; canonical IDs, names/map/version/selection validation; corrupt metadata and symlink alias rejection. No paths from metadata. Test bootstrap never mutates legacy bytes.

GameApplication GameLibrary.load(rootURL:clock:configuration:), session/index/games/activeGameID/isBusy, setActive, async createGame(name:) and openGame(id:). Serial MainActor operations save/suspend old, restore candidate off-main, require existing registered files, publish selection only after atomic index save. Current scene activity is retained during awaits. Missing/corrupt targets never create fresh replacements; current-save failure blocks switch; index failure leaves old selection/session. Unique unindexed candidate may remain after failed index commit. Existing corrupt legacy may use protected temporary mode and can be left without overwrite. Developer mode blocks library operations until explicit normal return. GameSession.load adds default-false requireExistingSave; suspendForGameSwitch cancels editors/inspection and throws regular save failures.

## Native UI integration guidance

App should own one GameLibrary and root scenePhase; SettlementView gets optional Games callback and lifecycle-managed flag defaulting to existing direct-session behavior. In library mode ONLY root forwards lifecycle; key SettlementView by activeGameID to replace scene/tasks. Keep benchmark direct isolated GameSession. Debug fresh/earned fixtures use unique temporary library ROOT, with earned bytes at settlement-v1.json before library load; never production. Games sheet current marker/list, optional name/default, New/Resume/busy/error/44targets, no delete/reset/scenarios. Keep UI shell state outside keyed world if needed. Scene activity after async publication must win over prior active state. Existing16UI regressions must survive.

## Remaining authorized sequence and constraints

Saves native UI→verification/review/handover; then Geography detailed dimensions/migration review gate; then approved environment graphics with media masters/provenance. Preserve all FP/RD/LC/AUDIO/WND/GEO/UX/CLU backlog. Remote CLU diagrams are schematic proposals; no bonuses/courtyard/catalog/economy activation. No second-era gameplay, extra playable cities, warfare, monetization/backend/renderer replacement. Existing immutable campfire/map/saves/rewards/IDs/iOS18/signing stay protected.

## Continuation and quota

Same native Goal stays active; respect host quota stops and resume through supported lifecycle when available. Last read90% five-hour usage. No reset credits, paid capacity, alternate account, cron/launchd, duplicate session or bypass. Native continuation at safe idle boundaries supported; exact unattended wake at quota reset remains unverified. On recovery read active canonical notices, checkpoint, git status/log and latest issue1. SHA18c758f is current verified core product; this documentation checkpoint follows it. Do not mark full Goal complete while Saves/UI/Geography/environment remain.
