# Stone Age progression

Seed 0.2.7 supersedes the earlier partial-pillar readiness rule. New readiness requires every building type and technology in the active Stone Age catalogs, one discovered and identified territory source for each extraction resource used by catalog recipes, and all five achievements below. Current totals are 20 building types, 20 technologies and six natural resources (wood, water, stone, flint, clay and animal hides); totals are derived, not hardcoded. Future copper and full-map discovery are excluded. Existing readiness is a sticky historical achievement and is never revoked by the expanded checklist. Exact pillar thresholds below remain EXPERIMENTAL tuning.

| Pillar | Achievement | Requirements |
|---|---|---|
| Economy | A self-sufficient craft economy | Operational gathering shelter, woodcutter, stone gatherer, storehouse, toolmaker, tannery and pottery workshop; at least 5 stone tools, 5 leather and 5 pottery |
| Science | Stone Age understanding | Oral Tradition, Stone Tools, Construction, Natural Knowledge, Pottery, Social Order, Rituals and Exploration researched |
| Population | A growing community | Operational hut; population at least 10; current net food and water rates each at least +1 unit/minute |
| Culture | Shared stories and traditions | Operational storytelling circle and shrine; at least 30 culture |
| Military & Security | A known and protected valley | Operational scout camp, watchtower and palisade; at least 600 discovered tiles |

Achievements are sticky historical records. Resource spending, recipe changes, worker priorities or later shortages do not erase a completed achievement. Each achievement activates once, without a material reward. When all five and the expanded catalog/discovery checklist are complete, Stone Age completion becomes a permanent record. The player keeps the same map, buildings, research, stocks and population and may continue exploring, researching, upgrading and building.

The original seven onboarding records remain internally distinct and preserve their earned +10 wood construction rewards. Finishing onboarding demonstrates the original tutorial loop; it does not automatically mark the expanded Stone Age complete. Research and progression UI should show unmet requirements clearly so players can choose which pillar to advance next.

The economy goal encourages all three crafting chains, which share labor and inputs; production modes and priorities remain meaningful. The science pillar retains its selected core; the era checklist additionally requires every research branch. Population asks for sustainable present income at ten inhabitants, not merely spare housing. Culture connects storytelling to pottery-supported shrines. Security combines exploration coverage and non-combat infrastructure. Farms, animal pens, healers, burial grounds, basketry and preservation are now required catalog content.

Version-5 saves record completed pillar IDs, Stone Age completion and grandfathered construction knowledge. Versions 1–4 start with no recorded pillar achievements or Stone Age completion; normal goal evaluation can recognize requirements after play resumes. Existing buildings, timers, priorities, resources, research, discovery, deposit depletion and original goal history survive migration. Existing building kinds preserve construction knowledge without free technologies or buffs. A version-4 original receives a byte-for-byte `.seed-0.2.4.bak` before replacement. Current saves missing progression history are rejected rather than silently repaired.

Full completion must be tested from a fresh game using actual costs and simulation time, alongside migration and idempotency regressions. Balance may require further playtesting, especially when a broad production catalog competes for a small automatic workforce. Extra eras, prestige resets, chapter rewards, trade, warfare and monetization remain deferred.

## Seven journey chapters

Founding a settlement; Mastering nature; Establishing agriculture; Developing craftsmanship; Building a society; Exploring and protecting; Completing the Stone Age. Individual building/research objectives credit permanent witnesses immediately, even before earlier chapters finish. The society chapter uses the original sticky 15-knowledge achievement. The final chapter displays the catalog/discovery/pillar checklist. No new rewards or stock thresholds are added; the original five +10 wood construction awards remain capped and idempotent in completedGoals. Chapters are derived from existing history, so no new normal-save schema or duplicate migration ledger is needed. Goals begin collapsed with chapter/progress counts, expand to the next objective and open a full-screen checklist for detail. Final chapter/pillar details are also available from Research.

Chapter grouping and copy are provisional implementation decisions under Dima's brief. No second-age transition is exposed. A historically ready save may show unfinished expanded chapters while retaining its readiness badge.
