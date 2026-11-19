# Population and workforce

Seed 0.2.3 status: APPROVED mechanics, EXPERIMENTAL numerical tuning. Population supplies automatically allocated labor. Food and water influence growth; no shortages cause deaths, building damage or population loss. No individual worker assignment or demographic simulation is introduced.

## Configured starting rules

The working population is `floor(population × 0.6)`. A productive building requires one worker; campfires, huts, storehouses and palisades require none. Construction remains a household task with the existing timer and does not reserve workers. Only operational buildings request labor or provide housing, storage and production.

The starting three inhabitants provide one worker. A gathering shelter can use that worker to produce enough food for recovery and growth; the campfire supplies food and water without workers. Additional housing unlocks further growth and eventually more available workers. All productive buildings stay available to build even when labor is insufficient; their inspection shows reduced productivity and allocation.

## Automatic allocation and priorities

Half the available labor is reserved first for gathering shelters, hunting lodges and fishing shelters. This reserve is distributed equally up to each building's requirement. These three survival producers require no manufactured inputs or ongoing maintenance. Farms and animal pens are advanced producers and do not receive the protected reserve.

Remaining labor is allocated to high-priority buildings, then normal, then low. Buildings at the same priority share proportionally to unmet demand. The reserve is retained even when survival buildings have low priority, so a high-priority workshop cannot claim all recovery labor. Unused reserve returns to the general pool. Allocation depends on requirements and priorities, not building-array order. Priorities are persisted per building; omitted priorities in older saves mean normal.

Fractional labor produces proportional output and input/maintenance demand. Resource shortages can reduce that productive fraction further. Upgrades improve output but do not multiply a building's configured worker requirement. This is a provisional balance choice, allowing upgrades to remain useful under limited population without creating an extra assignment interface.

## Consumption and growth

Each inhabitant consumes 1 food and 0.5 water per minute. The existing food rules remain: at least 20 food, positive net food, spare housing and 120 eligible seconds for one new inhabitant; Social Order reduces the interval to 90 seconds. Growth additionally needs at least 10 water and positive net water. The water stock starts at 60 in new games; migrated settlements retain their existing stock, with missing water interpreted as zero.

At population three, the passive campfire produces 3 water/minute against consumption of 1.5, so even a migrated zero-water settlement can recover. Food needs an active survival building. At population six, the campfire's 3 water/minute exactly balances consumption; a fishing shelter is needed to restore positive net water for further growth. This creates an early food/water choice without a fatal shortage or manufacturing dependency.

Growth progress pauses when any condition fails and resumes from earned eligible time. Resource depletion, reserve crossings, construction and growth are chronological simulation events. Offline progress uses the same rules with the existing eight-hour catch-up cap. No rendering frames or individual worker objects drive production.

## Playtesting questions

The 60% working share, half-labor reserve, one-worker requirements and water values are configurable hypotheses. Check that first growth is reachable, priorities have visible effects, too many workshops do not permanently stall survival, and expanded settlements can support food and water together. Large catalogs may make one-worker buildings compete sharply at low population; partial productivity is deliberate, but completion pacing needs live playtesting. Population decline, worker specialties, consumption of manufactured goods and additional demographic systems remain deferred.
