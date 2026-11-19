# First-era pacing review — 19 November 2026

Recommendation: retain the current bundled balance for Dima's first-era review. Real-cost investment in a second storytelling circle and earlier Natural Knowledge reaches full readiness in 90 simulated minutes, versus 154 minutes for the preserved serial route. Adding still more science or keeping science at high worker priority can finish research sooner while delaying material recovery and total completion. These are meaningful choices already supported by the economy; a global research-cost reduction is not justified by the serial route alone.

This is deterministic GameCore reachability, recovery and strategy evidence. It does not establish human enjoyment, natural discovery of the strategy, an optimal route, physical performance, or a promised session duration. The historical experimental 45–90-minute target is context, not a new acceptance gate.

## Method

`FirstEraPacingTests.swift` starts each route from bundled configuration, three inhabitants and ordinary starting resources. Every technology, building, resource, construction timer and exploration is paid for through public commands. There are no debug grants, configuration changes, save-state edits, worker overrides or accelerated construction. All routes must finish all twenty operational building types, twenty technologies, all seven chapters and five pillar records. Polling and one-minute construction waits match the historical playthrough; the listed times include that deliberate quantization.

The comparison holds the original bootstrap (gathering, wood, stone, hut, Oral Tradition, circle, Fishing, fishing shelter, second hut), craft sequence and later catalog order constant. After the bootstrap, routes 2–4 add circles and all four buy Natural Knowledge early. The later catalog loop researches every remaining technology before constructing missing types, so this is intentionally a simple comparison rather than optimized parallel play. Route 4 raises circle priority only while a required knowledge cost is missing and restores default priority afterward. It uses two circles; the other worker priorities stay at their defaults.

## Measurements

All times below are simulated minutes from a fresh settlement, before the separate post-completion idle/reload check.

| Route | Circles | Knowledge investment ready | Craft economy built | All research | Full readiness | Longest uninterrupted cost wait |
|---|---:|---:|---:|---:|---:|---:|
| Historical serial route | 1 | Later catalog order | 38 | 143 | 154 | Not instrumented |
| 1: Early Natural Knowledge | 1 | 19 | 38 | 125 | 136 | 16 |
| 2: Second circle + early Natural Knowledge | 2 | 18 | 31 | 79 | 90 | 8 |
| 3: Third circle + early Natural Knowledge | 3 | 17 | 39 | 63 | 104 | 13 |
| 4: Second circle + temporary research priority | 2 | 14 | 36 | 62 | 100 | 11 |

Route 2 has population 9 at the 18-minute knowledge investment checkpoint, 15 by its 31-minute craft checkpoint, and 15 at readiness. At the craft checkpoint its knowledge rate is 4.80/minute, net food +21.00/minute, net water +7.90/minute, with 9 available workers against 12 demanded. At readiness it has 9 workers against 19 demanded and knowledge +4.95/minute; food and water remain positive. The two circles do not simply double useful throughput: workforce sharing limits output.

Route 2's first observed chapter completions are:

| Chapter | Minute |
|---|---:|
| 1: Founding a settlement | 5 |
| 2: Mastering nature | 21 |
| 3: Establishing agriculture | 81 |
| 4: Developing craftsmanship | 57 |
| 5: Building a society | 84 |
| 6: Exploring and protecting | 87 |
| 7: Completing the Stone Age | 90 |

Chapters can complete out of order. The large chapter-2-to-next-completion gap reflects this scripted catalog order and a major Social Order knowledge purchase, not a requirement to stop taking actions. It remains a useful human-review concern: players should understand knowledge capacity, worker sharing, net inputs and chapter choices. Additional extraction, upgrades, earlier missing buildings and earlier exploration are available options not optimized in these comparisons.

## Recovery and persistence

A fork of route 2's earned 31-minute craft state gives high priority to science and crafting/extraction buildings while leaving wood at default priority. This exhausts the worker pool before wood extraction and leaves net wood nonpositive. Twenty offline minutes drain wood to zero, while all resources remain nonnegative and population stays 15. Returning buildings to default priorities, encoding/reloading that actual state and advancing another ten offline minutes restores wood from 0.00 to 53.33; food and water rates are positive. No resource grant, demolition, external state edit or restart is needed. This checks recovery from an ordinary poor staffing choice, not every possible scarcity scenario or deposit exhaustion.

Each completed route also runs ten unattended minutes, encodes/reloads its normal state and pays for an additional hut. Readiness and the original pillar completion records remain preserved. The pre-existing historical route independently retains its SaveStore v5 validation and completed-save export path. No fixtures or bundled values were changed.

## Verification

Command (Debug, macOS host, Xcode Swift toolchain):

```sh
swift test --package-path Packages/GameCore \
  --filter 'firstEraAlternativeNormalCostStrategies|freshStoneAgeCompletesThroughRealResearchAndProduction'
```

Final result: two tests, including four parameterized strategy cases, passed. The original serial route still completed at 9,240 seconds. Detailed console output: `/tmp/civilization-first-era-pacing.log` (temporary local artifact). Compiler cache access required the approved sandbox escalation; the initial sandbox-only command could not write the Swift module cache. During test authoring, a key-path assertion macro and chapter-ID type were corrected before execution; the recovery assertion was corrected to include ongoing crafting consumption, then the complete targeted command was rerun.

No balance tuning, GameCore implementation changes, save migration, UI changes or Git operations are part of this review. Broader regression and device/UI verification belong to the main review candidate's verification report.
