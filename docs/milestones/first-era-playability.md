# First-era playability and quality assessment

19November2026. Dima prioritizes a player starting, understanding what to do and completing the first era. Graphics, roads and NPCs remain secondary. This iteration adds optional, actionable guidance and verifies an ordinary-cost journey; it changes no economy values, geography, dimensions, era requirements, reward history or save schema.

## What changed for the player

Collapsed goals now show the named next useful step, not just chapter counts. Expansion explains why/how and offers an explicit route to Buildings, Research, a producer/mode/priority inspector, resource help, Population or Explore. The full journey retains every measurable chapter and out-of-order credit, with the named recommendation and full explanation. Navigation spends nothing; the player still chooses a real purchase/placement.

The original journey listed the storytelling circle in chapter5while chapter2needed knowledge for research. Guidance now resolves that prerequisite when it is needed. It handles unlocked sources, recipe inputs, dedicated stone/flint/clay gatherers, construction timers, resources/estimates, staffing/housing, discoveries and pillar checks. A second knowledge source and additional housing are optional capacity recommendations during long waits, not new completion requirements. Current300second recommendation heuristic is an implementation choice, not a final economic target.

Read-only core guidance is bounded and cached per actual session state. No frame-driven simulation or persistent tutorial/reward fields. Advice collapses during placement to leave the map usable. The existing preview grab offset and drag gestures are preserved. A test initially dragged from inside the ghost and therefore landed at a different blocked origin; native captures established the test-path error and the test now starts outside it. No gesture behavior was changed.

Full-journey navigation waits for dismissal before opening another cover. Actual accessibility inspection showed the parent goalProgress identifier overriding its visible action; explicit child containment now preserves the action ID. Independent review also caught the missing next-step title in the full journey; it is now shown. Completed readiness displays “Stone Age complete,” explains continued sandbox play and does not imply next-age advancement.

## Legitimate progression evidence

[15second cadence data](../testing/first-era-playability/guided-15.json) and [60second cadence data](../testing/first-era-playability/guided-60.json) retain all48actions, construction durations, first chapter completions, full per-resource gross/used/net/stored/capacity snapshots, population/housing/workforce and discovery. Tests start from ordinary bundled stocks and use real build/research/recipe/priority/exploration commands. No developer scenario, grant, free research, fast construction or balance alteration. They save/load through production persistence and preserve earned history/readiness.

| Chapter | 15second decision/check cadence | 60second casual-script cadence |
|---|---:|---:|
| 1Founding |1.2min|4.0min|
| 2Nature |20.0min|27.7min|
| 3Agriculture |44.3min|51.4min|
| 4Craftsmanship |56.1min|66.6min|
| 5Society |80.9min|95.8min|
| 6Exploration/protection |90.9min|106.4min|
| 7StoneAgecompletion |104.1min|121.1min|

Both follow only the visible recommendation rather than a developer-written tech/catalog order:23paid constructions,20research purchases,2recipe selections and3expeditions. Including the preplaced campfire,24instances cover all20types; all20technologies,7chapters and5pillars complete. Both finish with15inhabitants,9available workers against19demanded and650/768tiles. End net food~39–41.4/min, water+7.89/min and knowledge+4.95/min. Partial staffing remains intentional; no need to fully staff every building or discover the whole map.

The earlier resource-efficient two-circle/early NaturalKnowledge route remains90minutes; preserved serial route154minutes. These are strategy comparisons, not promised session durations. The new recommendation-following route without capacity advice took221–226minutes; recommending existing capacity investments reduced that to104–121without tuning. The60second cadence is an explicitly defined **casual script**, not observed human behavior; human comprehension/enjoyment still needs Dima’s review.

## Waiting and bottlenecks

Research purchases are instantaneous once costs/prerequisites are met. “Research waits” are knowledge/material accumulation, not a hidden research timer. Current construction durations total~611–613seconds across the23starts, but work proceeds concurrently with the script’s decision intervals.

| Wait reason | 15second cadence | 60second cadence |
|---|---:|---:|
| Knowledge accumulation |4202s|3536s|
| Stone tools accumulation |625s|580s|
| Pottery accumulation |240s|210s|
| Clay accumulation |102s|57s|
| Explicit construction timer checks |264.5s|0s|
| Explicit expedition checks |90s|0s|
| Total explicit scripted waits |5523.5s|4383s|

The60second cadence absorbs short construction/45second expeditions into its48ordinary decision intervals; zero explicit timer waits does **not** mean zero construction/exploration duration. Total scripted time = action cadence + explicit waits. Longest continuous scripted wait is625seconds (15second route) or580seconds (60second route), mainly accumulating tools for retained manufacturing requirements. Knowledge remains the largest cumulative bottleneck. During these waits the player may act in other chapters, manage resources, inspect priorities or leave for ordinary capped offline progress. These values do not prove there were no other meaningful actions or that every wait is enjoyable. No broad rate/cost cut is applied on this evidence alone.

Resource/population detail: the60second route reaches chapter4at10inhabitants/6workers against13demand; advice then supports housing/growth to15/9by chapter5. The15second route reaches15/9by chapter4. Per-chapter JSON snapshots expose consumption and staffing tradeoffs. Extraction uses discovered/identified existing sources; separate recipe producers preserve stone while making flint/clay. Exploration reaches the security threshold through3paidexpeditions, including a built/researched scout camp before the farther ring. No future copper identification or whole-map discovery is required.

## Recovery and approved starter-material protection

A fork of the legitimately earned craft state assigns high priorities elsewhere and Low to wood, then advances4ordinary offline hours (within the8hourcap). Wood reaches0. Following the priority/resource explanation restores hut affordability at20wood, then normal encoding/reload preserves it. No grants, restart, forced population edits or demolition. Earlier [pacing review](../design/first-era-pacing-review.md) independently tests another poor-priority recovery.

**Approved prevention is implemented (PLAY-002).** Dima explicitly answered Yes to the catalog-derived reserve proposal, committed before code in9ccbd3f. Construction, research and upgrades reject a payment atomically only if it destroys every remaining basic-supplier funding route. Supplier costs, maintenance-free outputs and selectable modes come from the catalog. Existing/pending sources count, and safe supplier order is flexible: no fixed25wood reserve or forced tutorial sequence. Buildings/Research show an amber supplier instruction and Reserved action; actual missing resources alone remain red. Expanded details explain why, and Buildings offers Show supplier. Advice can switch an existing gatherer mode when a duplicate cannot be funded safely.

The historical seven-shelter trap (5wood/no source) is retained as a regression; current rules block the sixth-to-seventh repeat before insolvency and allow building the Woodcutter. Tests cover research/upgrade bypasses, atomic rejection, changed catalog costs, both supplier orders, pending/selectable sources and save/reload. The optional current-seed policy flag leaves frozen legacy configuration rules intact. No new resource grants, refunds, reset, costs, rates or rewards. **Already-insolvent historical saves are preserved unchanged**; their recovery policy remains Q-PLAY-1, outside this prevention approval. See the [approved decision](../design/bootstrap-reserve-proposal.md).

## Verification and UI evidence

126Debug/115Release Swift Testing tests pass, preserving all prior regressions;5Release API probes pass. New tests cover read-only advice, first action, the cross-chapter knowledge dependency, capacity advice, complete ordinary recommendation-following routes, poor-priority recovery/reload and cache refresh after actual construction. All numerical seed values remain unchanged; the only JSON difference is the explicitly approved protectBootstrapMaterials policy flag.

Final UI suite now contains9cases: five existing menu/scenario/chapter/dense-art/gesture tests plus fresh normal first construction, nonpurchasing guided research navigation an earned completion/sandbox test, and reserved-spending explanation→supplier→drag placement. The completion fixture itself uses ordinary public commands, then passes its validatedv5envelope through a **Debug-only unique temporary save**. It never overwrites normal/developer user files; no scenario/grants are counted as era achievement. All9cases pass on iPhone17ProMax/iOS26.5, miniA17Pro/iOS18.6 and Pro13M4/iOS18.6. Phone172.969s, mini160.601s and Pro163.383s; zero failures. Final result bundles use `/tmp/civilization-reserve-final-{phone,mini,pro}.xcresult`; earlier full runs used the corresponding non-final names.

Native successful captures: [fresh phone next step](../screenshots/first-era-review/playability-phone-fresh-next-step.png), [placement](../screenshots/first-era-review/playability-phone-guided-placement.png), [first construction/next objective](../screenshots/first-era-review/playability-phone-first-building-complete.png), [earned tablet completion](../screenshots/first-era-review/playability-complete-mini-earned-completion.png) [completed journey](../screenshots/first-era-review/playability-complete-mini-completed-journey.png), and [reserve explanation](../screenshots/first-era-review/reserve-phone-v2-reserve-explanation.png). The capture tests pass. Failed-path diagnostic captures were discarded; no screenshot of a developer-granted scenario is used as proof of earned completion.

Signed Debug device and Release simulator builds pass. Physical inventory again reports Dima’s iPhone unavailable; no fresh backup or installation is claimed, and the previously installed candidate/saves remain untouched. Physical launch/performance/thermal/battery work awaits access. Previous dense~48FPSsample and final-cache unmeasured limitation remain from the [earlier report](first-era-review.md); these UI changes are not a claimed hardware improvement.

Reproducible checks:

```sh
swift test --package-path Packages/GameCore
swift test --package-path Packages/GameCore -c release
python3 scripts/verify-developer-release.py
CIVILIZATION_GUIDANCE_REPORT_DIR="$PWD/docs/testing/first-era-playability" \
  swift test --package-path Packages/GameCore -c release --filter ordinaryPlayerCanFollow
xcodebuild -project Civilization.xcodeproj -scheme Civilization \
  -destination 'platform=iOS Simulator,id=<PROFILE-ID>' \
  -only-testing:CivilizationUITests/RelocationUITests CODE_SIGNING_ALLOWED=NO test
```

Local logs: `/tmp/civilization-reserve-{debug,release,release-probes,final-phone,final-mini,final-pro,signed-build,release-build,devices}.log`; guided data generation `/tmp/civilization-reserve-evidence.log`. Simulator measurements are not hardware benchmarks. All routes are synthetic tests, not human acceptance.

## Delivery and scope

Commits: f403401(priority/design),62767da(core/session guidance),7047d38(UI/accessibility/recovery), 9ccbd3f(explicit reserve approval),3ecc846(reserve validation/guidance),ec36baf(reserve/earned-completion UI), followed by this evidence/report commit. Source-of-truth design updates precede implementation. No graphics generation, roads, NPCs, new footprints, monuments, audio, subsequent ages/cities, warfare or monetization. Media repo unchanged. Current priority remains first-era understanding/completion, then physical save-safe deployment and review of pacing/any historical recovery policy; secondary systems stay staged.
