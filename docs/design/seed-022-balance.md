# Seed 0.2.2 experimental balance

Status: EXPERIMENTAL numerical tuning within the APPROVED twenty-building economy. These values are starting hypotheses for playtesting, not final historical or economic claims. The original map identity, campfire, six original building IDs, legacy costs/rates and existing goal rewards remain intact. Final art and wider progression remain separate design work.

All amounts are units, rates are units/minute and construction times are seconds. All twelve resources begin with capacity 500. Starting stocks remain food 60, wood 100 and stone 50; water starts at 60 and other new stocks start at zero. Population still consumes one food per person per minute under the foundation rules. Water consumption by population is deferred to the workforce/population milestone.

## Extraction and survival

The campfire produces 2 food and 3 water/minute. Gathering shelters produce 12 food/minute. These survival routes require neither tools nor maintenance, so a manufacturing shortage cannot permanently disable recovery.

| Building / mode | Output per minute | Maintenance | Terrain bonus |
|---|---|---|---|
| Hunting lodge | 10 food, 4 hides | None | +20% near forest |
| Fishing shelter | 10 food, 12 water | None | +20% near river |
| Woodcutter | 10 wood | None | +20% near forest |
| Stone gatherer: stone | 8 stone | None | +20% near hills |
| Stone gatherer: flint | 6 flint | None | +20% near hills |
| Stone gatherer: clay | 6 clay | None | +20% near hills |
| Farm | 16 food | 3 water/minute | +20% near river |
| Animal pen | 8 food, 5 hides | 2 water/minute | None |

Forest radius is 5 logical tiles; river radius is 3 and hill radius is 4. Bonuses reward location without making survival depend on a scarce buildable river edge. This stage does not impose a hard adjacency placement restriction. Forest, river water and wildlife are renewable.

Finite shared pools contain 12,000 stone, 6,000 flint and 8,000 clay. Their extraction radii are provisionally 40 logical tiles so existing settlements and regression placements retain access. The pool origins correspond to hills and river bank. Depletion pauses extraction; it never damages a building. Copper is recorded only as a future natural deposit, without an associated current resource or recipe. These generous ranges and reserves are deliberately provisional until geography/exploration design is implemented.

## Crafting and community

| Building | Recipe per minute | Maintenance per minute |
|---|---|---|
| Toolmaker | 2 wood + 2 flint → 2 stone tools | 1 water |
| Tannery | 2 hides → 2 leather | 1 water |
| Pottery workshop | 3 clay + 2 wood → 2 pottery | 1 water |
| Storytelling circle | 3 knowledge + 2 culture | None |
| Healer's hut | 0.5 leather → 2 knowledge + 1 culture | 2 water |
| Shrine | 0.5 pottery → 5 culture | None |
| Burial ground | 1 knowledge + 3 culture | None |
| Scout camp | 0.5 stone tools → 2 knowledge | None |
| Watchtower | 0.25 stone tools → 2 culture | None |

Raw production has allocation tier 0. Toolmaking, pottery, farms and animal pens use tier 1. Tanning uses tier 2 because hides can also come from the tier-1 animal pen. Healers use tier 3 for leather; other community consumers use tier 2. Same-tier consumers share shortages fairly; no recipe relies on output of another recipe in the same or a higher tier. Storage caps can halt accumulation without removing fractional balances.

Security buildings provide only the listed provisional knowledge/culture effects in this milestone; there is no combat. Palisades are a permanent decorative/security foundation with no speculative battle mechanic. Healers and burial grounds do not imply illness or death simulation.

## Construction, storage and upgrades

Original construction times are unchanged: hut 15, gathering/wood/stone 20, storytelling 30. New buildings take 20–45 seconds, with exact costs and footprints in bundled `seed.json`. All buildings are available immediately except the storytelling circle, which retains the Oral Tradition unlock.

A storehouse adds 250 capacity to every resource per operational level. Permanent upgrades have a maximum level of 3 and a provisional output bonus of 25% per added level. The configured base upgrade cost is 10 wood and 5 stone for every non-campfire building; level-based cost scaling and throughput input scaling are engine policies. Upgrades preserve building IDs. Campfire upgrades are disabled. Hut housing and storehouse capacity are level effects; palisade upgrades currently have no productive benefit and should be considered cosmetic tuning pending later security design.

Fresh games can obtain all recipe inputs without consuming a manufactured item to unlock its own source: gather food, cut wood, collect stone/flint/clay using stone-gatherer modes, hunt for hides, and collect water through the campfire or fishing shelter. This avoids circular bootstrap dependencies. Research remains the three foundation technologies until the approved research milestone replaces its provisional content.
