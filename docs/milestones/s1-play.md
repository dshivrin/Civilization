# S1-PLAY-001 — normal game entry and era completion

20 November 2026. Reconciled against pushed first-era-review `3c72d88` and [S1-Geography](s1-geography.md); authorization/specification committed `4f1f255` before product code. Implementation is a human-playtest candidate, not milestone acceptance.

## Player start and persistence

Launch **Civilization → New Game**. This starts an authentic64×48 river valley with one campfire, 3 inhabitants, food 60 / wood 100 / stone 50 / water 60, all other stocks 0, no roads/research/grants. Campfire/palisade remain 1×1 and the other 18 catalog types 2×2. Standard construction, production, costs and workforce apply. **Launch → Continue** resumes the selected normal game. **Settlement → Games** switches independent games or starts another. First tap of the chapter icon shows the next action; another expands guidance; **All seven chapters** shows the full checklist.

Launch reads availability metadata only; it does not restore/simulate/migrate an unopened game. New Game creates a separate slot, even if the previous selection is damaged. First install uses the original slot. Existing normal/developer companion files remain independent and untouched by launch-level creation. No reset/delete/overwrite UI exists, so creating a game cannot replace old progress. Ordinary play continues atomic autosaves; existing geography conversion retains validated backup-before-conversion. No physical device/container operation was performed in this task.

Developer scenarios remain inside separate Debug tools after normal entry, compile out of Release, and are never launch choices. No automatic developer resume or grants. New Game does not require opening a damaged old save.

## Completion audit

Operational buildings and completed technologies trigger objective credit; starting construction alone does not. Prerequisites and costs are validated atomically by the existing engine. Chapters accept out-of-order work; original construction rewards and earned pillar/readiness history remain sticky and idempotent. No seed configuration, economy, timers, costs, recipes, map or save schema was changed.

| Chapter | Existing objectives / prerequisite concern | Guided completion minutes (15s / 60s decision cadence) |
|---|---|---|
|1 Founding a settlement|Gathering shelter, woodcutter, hut, Oral Tradition|1.2/4.0|
|2 Mastering nature|Stone gatherer, hunting lodge, fishing shelter; Hunting/Fishing/Natural Knowledge. Knowledge needs a storytelling circle ahead of chapter 5; existing guidance supplies this.|20.0/27.7|
|3 Establishing agriculture|Farm/animal pen; Cultivation → Animal Domestication, Pottery → Food Preservation|44.3/51.4|
|4 Developing craftsmanship|Toolmaker/tannery/pottery/storehouse; Stone Tools, Leatherworking, Pottery, Construction, Basketry. Flint/clay recipes, inputs and staffing matter.|56.1/66.6|
|5 Building a society|Circle/shrine/healer/burial; Social Order/Rituals/Permanent Settlement/Herbal Medicine/Burial Traditions; original15knowledge milestone|80.9/95.8|
|6 Exploring and protecting|Scout/watchtower/palisade; Exploration → Surveillance(with Stone Tools) → Fortification|90.9/106.4|
|7 Completing the Stone Age|All20 building types,20 technologies,6 required resource territories and5 pillars|104.1/121.1|

Required identified territories are **wood, stone, water, animal hides, flint and clay**. Full-map discovery/future-resource identification is optional. Pillars retain these thresholds:

- Economy: gathering/wood/stone/storehouse/toolmaker/tannery/pottery buildings and5 each stone tools/leather/pottery.
- Science: Oral Tradition, Stone Tools, Construction, Natural Knowledge, Pottery, Social Order, Rituals, Exploration.
- Population: hut, 10 inhabitants and net food/water at least +1 each/minute.
- Culture: storytelling circle, shrine and 30 culture.
- Security: scout camp, watchtower, palisade and 600 discovered tiles.

The journey now shows actual unmet pillar thresholds and missing territory names. Completion says **Stone Age complete / Bronze Age unlocked · readiness earned**, explains that Bronze Age gameplay is unavailable and allows continued settlement building. This is existing readiness presented as a clear destination, without an age transition/new economy or playable Bronze content. Previously earned readiness is preserved if future catalogs expand.

## Fresh verification

| Check | Observed result |
|---|---|
|Full core Debug|189 tests passed; final16.038s|
|Full core Release|171 tests passed;1.623s|
|Release developer exclusion probes|All 5 passed|
|Debug iPhone 17 Pro Max / iOS 26.5|Menu/new/continue, independent switch/relaunch, missing-selected recovery (MCP 3 cases); additional ordinary-entry persistence, completion/sandbox and developer isolation (3 cases)|
|Debug iPad mini A17 Pro / iOS 18.6|4 cases: menu/new/continue, independent switch/relaunch, developer isolation, earned completion/sandbox|
|Debug iPad Pro 13 M4 / iOS 18.6|3 cases: menu/new/continue, independent switch/relaunch, final earned completion/sandbox with Bronze readiness assertion|
|Release iPhone17Pro Max|Ordinary menu/new/continue, paid building persistence, second-game preservation; separately earned completion/7-of-7/sandbox across two launches|
|Release iPad|Pro ordinary menu/new/continue and paid-building persistence; mini earned completion/7-of-7/sandbox across two launches|
|Independent review|No blocking findings; recovery/coverage limits below|

Release UI uses alternate app identities `com.civilization.seed.playcheck` and `.playcomplete`, with no product setting/signing change. Completion harness installs a save earned by ordinary public commands into a **previously empty, separate** test-app slot, guarded against replacement. It does not modify balances, use developer APIs or add a Release import hook. Debug fixtures use UUID temporary libraries. Standard simulator production progress and physical saves are preserved.

Core commands: `swift test --package-path Packages/GameCore`, same with `-c release`; `python3 scripts/verify-developer-release.py`. Native commands: `xcodebuild test -project Civilization.xcodeproj -scheme Civilization -configuration <Debug|Release> -destination 'platform=iOS Simulator,id=<profile>' -derivedDataPath /tmp/civilization-play-<configuration>-<profile> CODE_SIGNING_ALLOWED=NO PRODUCT_BUNDLE_IDENTIFIER=com.civilization.seed.playcheck -only-testing:CivilizationUITests/<suite>/<case>`. Release completion uses `build-for-testing` with `.playcomplete`, followed by guarded fixture installation and `test-without-building -xctestrun ... -only-testing:CivilizationUITests/NormalCompletionUITests`. Logs/result bundles retained under `/tmp/civilization-play-*`; first 3 phone results under XcodeBuildMCP workspace. These are scoped native suites, not reruns of every historical gesture/UI case.

Test development observed missing entry APIs fail before implementation, then preservation tests pass; the paid-route test failed on missing Bronze wording before the wording change, then full Debug/Release passed. Initial sandbox-only compiler/simulator failures were resolved with approved host access. One initially requested native completion case name matched no test; discovery reported only3 cases, and the correct named completion cases were explicitly run afterward. No hidden failure or skipped-case success claim.

## Gaps and acceptance

**Blocking bugs:** none reproduced on valid normal-save/new-game/full-era paths. A corrupt library index remains fail-closed and blocks entry until repaired; this is a pre-existing recovery limitation, with original bytes preserved. No repair/reset tool is added here.

**UX friction:** failed Continue has saved-game recovery but no back-to-launch-menu button; relaunch restores New Game access. Seven-chapter order can suggest waiting until chapter 5 for science although chapter 2 needs knowledge; existing next-step guidance correctly recommends the circle early. No dedicated new rapid-double-tap UI regression; MainActor entry guard prevents overlapping operations and existing core concurrency tests pass. Some old developer labels after geography conversion remain a prior minor issue.

**Pacing:** guided ordinary-cost routes finish 104.1–121.1 simulated minutes, 48 actions, 3 expeditions and 704/3072 tiles. Longest scripted uninterrupted cost/construction wait 580–625 seconds. Population 15, workers 9 against 19 demand; science bottlenecks and staffing tradeoffs remain visible tuning/playtest questions. Alternative strategies retain 90–154 minute historical spread. No artificial timer or balance adjustment. [Detailed 15s](../testing/s1-play/guided-15.json) and [60s](../testing/s1-play/guided-60.json) traces include stocks/rates/population/workers, chapter timing and wait reasons. These scripts prove reachability, not natural-player comprehension, duration or enjoyment.

**Future enhancements:** index repair/backup recovery UI, back-to-menu navigation, richer pacing observation and sustained physical performance evidence. Optional exploration/geography and every existing FP/RD/LC/AUDIO/WND/GEO/UX/CLU/MAP backlog remain. Bronze gameplay remains deferred. [Readiness/tool/test dependency register](../testing/s1-play-readiness.md).

Stop for Dima's normal human playtest. No new physical install, final art acceptance, hardware benchmark, merge or second-era work is claimed.
