# Goal: Stone Age Economy Foundation — Riverbend Economy Lab

**Owner direction, 20 November 2026:** Proceed with the economy direction and publish this Codex plan. This handoff covers the isolated pilot below. Production adoption, save migration, the remaining economy phases, and monetization remain separate review decisions.

## Codex Goal: prove the first ten minutes

Deliver a Debug-only **Riverbend Economy Lab** in which a player starts with Food and Wood, builds a hut, scouts a contiguous forest region, places the existing Woodcutter at a valid site, and sees sustainable Food and Wood flows. The pilot must work from a fresh isolated fixture with no ads, payments, Water stock, manual save edits, or legacy-save changes. Stop for owner review after verified delivery. Keep the original experiment and art/UI work undisturbed.

### Execution order

1. **Pin a baseline.** Read `AGENTS.md`, `scripts/README.md`, the [first-settlement plan](2026-11-20-first-settlement-exploration-onboarding.md), and the latest source diffs on `first-era-review`. Record the exact game commit, seed hash and configuration identity. Inventory Food/Water consumers, forestry placement and visible warehouse variants versus actual catalog IDs. Use the established review branch/worktree procedure; read this main-only plan without merging main or touching another active checkout. Reuse the current test runner and inspector.
2. **Isolate the profile.** Reuse the existing GameCore configuration and Debug scenario seams where possible (`Configuration.swift`, `GameEngine.swift`, `Economy.swift`, `Exploration.swift`, and the seed catalog). Create a named versioned lab profile with no Water production, debit, HUD entry or growth gate. Existing enum/decoding and production logic remain compatible; do not globally remove Water. Store the lab’s new save in an independent Debug-only namespace, absent from Games and Release; never load or migrate an existing real save into it. Fail safely if initialization or publication fails. Normal New Game/Continue, original Developer and Round 2 review copies, and R2-07 status stay unchanged.
3. **Build the short loop.** In the lab, start with 3 residents, 32 Food and 32 Wood; zero Stone and Water. Campfire provides +2 Food/min and 3 housing; residents consume 1 Food/min each. Hut costs 12 Wood and adds 3 places. The hut immediately introduces the forest survey (8 Food), with a Gathering Shelter (8 Wood, +8 Food/min) as an available parallel choice, not a prerequisite to scouting. Start with two available field workers, keep the first survey from consuming them, and show staffing and net rates. Grow only when under housing cap with at least 20 Food and a positive flow, initially one resident per four eligible minutes. Food/Wood cap at 60. A Woodcutter costs 4 Wood and makes +6 Wood/min. Recovery actions top Wood up to 12 before the first hut or 8 afterward, and Food up to 12, only as needed; never grant above those floors. Ordinary builds, discovery, staffing and save/reload must remain deterministic.
4. **Reuse the onboarding contract.** If the approved area-expedition API is available, use it. Otherwise use a lab-scoped deterministic region fixture behind an adapter and label it as such; do not ship a second live exploration system or change ordinary fog. Validate contiguous reveal, legal terrain/placement, and at least one reachable fallback site if the first is blocked. Do not create a hidden corridor or teleport a forest. Survey grant of +6 Knowledge is once-only bootstrap evidence, not a new research or currency system in this pilot. No production warehouse, crafts or readiness changes in this first slice; those are follow-up milestones.
5. **Verify and report.** Add deterministic tests using existing GameCore and native UITest targets. Cover normal and delayed starts, zero Food/Wood before and after the Hut, invalid/occupied candidate, retry and insufficient cost, reload during an expedition, exact-once cost/reveal, capacity/overflow, and ordinary/other-mode isolation. Run `python3 scripts/dev.py test` for Debug/Release core and existing exclusions; add a Release absence check specific to the lab and run its native Debug flow on iPhone and at least one iPad profile plus ordinary Release entry. Use the approved runner; no extra package, signing change, physical install or device reset. Compare original save and library bytes before/after with existing tooling or isolated fixtures. Produce a concise report with commit, profile ID, actual test counts, stock/net-rate trace, two screenshots and caveats. Publish authorized pilot work on its review branch only; no merge, Release enablement or R2-07 activation. The report should distinguish a lab fixture from real production exploration and human playtest.

**Done for owner review:** No existing-save writes; normal behavior unchanged; lab absent in Release; the real lab UI can complete the route with Food and Wood visible, a valid whole-region forest reveal and net-positive Food and Wood at the end. The four numerical examples below are planning checks, not a substitute for the game tests.

| Model-only checkpoint at minute 10 | Food | Wood | Residents |
|---|---:|---:|---:|
| Guided | 60 | 20 | 4 |
| Delayed | 46 | 14 | 4 |
| Empty stock after Hut | 57 | 16 | 4 |
| Empty stock before Hut | 46 | 16 | 4 |

## Economy design reference

The following records the agreed direction and candidate numbers for later reviews. Its broader milestone gates are **not** authorization to implement them alongside the ten-minute lab.


## The decision

Make Riverbend about turning nearby natural resources into a settlement that can support itself, then choosing where to expand. The interesting scarcity is **workers, placement, and what to build next**, not five simultaneously depleting meters. Start with Food and Wood; unlock Stone on discovery, then teach one craft chain at a time. Make good logistics useful, not mandatory during the tutorial. Do not make waiting, recovering, or starting a new city a paid privilege.

## What is actually in the build

I audited the GitHub `first-era-review` seed and economic code, not an unpushed Codex worktree. [Seed catalog](https://github.com/dshivrin/Civilization/blob/first-era-review/Packages/GameCore/Sources/GameCore/Resources/seed.json) · [Economy](https://github.com/dshivrin/Civilization/blob/first-era-review/Packages/GameCore/Sources/GameCore/Economy.swift) · [Game engine](https://github.com/dshivrin/Civilization/blob/first-era-review/Packages/GameCore/Sources/GameCore/GameEngine.swift)

- **Water isn't unused.** The seed starts with 60; the Campfire supplies 3/min, Fishing Shelter produces 12/min alongside fish, and each resident consumes 0.5/min. Farms, animal pens and several workshops consume it as maintenance, and it gates population growth. The problem is that the player rarely makes a distinct water decision: the building they want for food solves both meters, and the sink is mostly overhead.
- **There is storage for water, but not a meaningful storage identity.** The audited seed has one buildable `storehouse` definition, adding 250 units per level **to each of the 12 resources**, even Water, Knowledge and Culture. The general base storage is 500 per resource. Basketry and Food Preservation also raise selected caps. If two warehouse looks or variants are visible elsewhere, reconcile their asset/catalog IDs before changing anything. Don't assume they're two active economic types or delete either from existing cities.
- The three craft lines are already present: Wood + Flint → Stone Tools; Hides → Leather; Clay + Wood → Pottery. The current economy pillar asks for the three buildings and five of each output. Other buildings also burn crafted materials continuously. Food is both subsistence and expedition fuel. The shape of a good economy is here; its priorities and feedback aren't.
- A distinct operational versus structural capacity already exists in the connectivity pilot. Use that precedent: **an interrupted road can stop new intake, but it must not erase stock.** R2-07 stays off; this proposal does not approve enabling it.

## Benchmark decisions

| Game / source | What works there | What to do here |
|---|---|---|
| [Anno 117: official starting guide](https://www.anno-union.com/getting-started-in-anno-117-pax-romana/) | Woodcutter and sawmill start with matching cycle times; roads, workforce, and a nearby warehouse have clear jobs. | Copy readable rates and a visible placement preview. Don't copy mandatory road coverage from minute one, or introduce planks just to add a step. |
| [Against the Storm: resources](https://wiki.hoodedhorse.com/Against_the_Storm/Resources), [warehouse](https://wiki.hoodedhorse.com/Against_the_Storm/Warehouse), [developer update archive](https://wiki.hoodedhorse.com/Against_the_Storm/Updates_and_Devlog) | Warehouses expose unified storage; proximity can matter to hauling. Water powers selectable engine boosts and comes with a cost. | Use pooled inventory and useful storage placement once logistics lands. Cut water as general maintenance; only bring it back as a stock if there is a real choice. |
| [Clash of Clans: Magic Items](https://support.supercell.com/clash-of-clans/en/articles/magic-items-and-the-trader.html) | Explicit upgrades, research accelerators and stocked-resource items make reward value legible. | Borrow clarity, **not** multipliers: our cities may trade, so a paid speed-up can become a transferable advantage. |
| [Fortnite: store model](https://www.fortnite.com/news/changes-to-save-the-world-store-and-llama-shop) | Monetization can sell identity without competitive power. | Sell distinct settlement looks. Keep the free version's art, economy and progression complete. |

## Player loop: the first 90 minutes

Timing is a playtest hypothesis, not a countdown players must sit through.

1. **Founding, 0–10 min.** Existing Campfire stays permanent. The guide asks for a Hut first. Build a Gathering Shelter when ready; food shows net flow and how many residents it supports. The first expedition targets a **whole adjacent forest area**, not a cleared tunnel or another concentric radius. It reveals a legal Woodcutter site and a fallback if the primary site can't be used. Player places the Woodcutter and sees Wood reach the shared stock.
2. **Expansion, 10–35 min.** Scout once the player wants more space or Stone. Choose a nearby stone-rich or food-rich region after the tutorial forest. The Food route can be foraging/fishing early or a farm when available; both feed the same pool. An eventual Farm/Mill chain should exist only if it has a role such as feeding more people per worker. Don't introduce wheat as another stock simply because farming exists.
3. **Specialization, 35–75 min.** Upgrade the Campfire to Gathering Place. Choose which to pursue first: tools for construction, pottery for food storage, or leather for expeditions. The guide highlights missing inputs and legal sites; it doesn't dictate all three chains at once. Add a stockyard because it lets you stage larger projects, or a granary because you need a food buffer.
4. **Bronze readiness, roughly 75–105 min.** Demonstrate viable Food, Housing, production, exploration, and civic growth. Use one completed craft project rather than hoarding five of everything. Keep sandbox open. There is no shop or ad in this flow. The dedicated guide to menus follows the redesigned menus, not the other way around.

## Resource contract

Every stock needs a producer, a use the player understands, and a reason to care about the next unit. Reveal rows as unlocked; display only the top four pinned counters, configurable later. Use explicit groups, not one undifferentiated wallet.

| Seed resource | New role / when shown | Source → sink |
|---|---|---|
| Food | **Keep, at start.** One common supply, regardless of producer. | Campfire safety floor, gatherers, fishing, farming → upkeep and expedition rations. Never required to buy food to recover. |
| Wood | **Keep, at start.** Core build material. | Forest Woodcutter → huts, buildings, upgrades, fuel for one craft chain. |
| Stone | **Keep, first expansion.** Heavy construction. | Revealed outcrop → civic upgrades, storage, larger builds. No Stone requirement for the first Woodcutter or first forage. |
| Water | **Remove from active Stone Age inventory.** | River remains geography for fishing and eligible Farm sites. No water production, upkeep, growth check or purchase in this profile. No new Well/Cistern UI until a future irrigation/service design is justified. |
| Flint | **Keep, reveal with Toolmaking opportunity.** | Flint seam → Tools. Let the stone gathering job switch modes; don't make a separate production building just for Flint. |
| Stone Tools | **Keep, project material, not upkeep.** | Wood + Flint → targeted civic/construction upgrades. No passive tool drain at a watchtower. |
| Clay | **Keep, reveal with Pottery opportunity.** | Riverbank clay seam → Pottery. The bank matters; no water stock required. |
| Pottery | **Keep, project material.** | Clay + Wood → Granary upgrade; secondary optional civic use, not required just to finish. |
| Animal Hides | **Keep late, hidden until the Leather chain.** | Hunt or livestock → Leather. Track prerequisites together; do not put the raw/intermediate pair on the default HUD. |
| Leather | **Keep late, optional route investment.** | Hides → a one-time Scout Camp expedition package; e.g. unlock an alternate scouting route (not faster Bronze completion by paying). |
| Knowledge | **Keep, non-physical research points.** | First survey discovery and staffed Gathering Place → technology unlocks. No storage building, no transfer, no paid points. |
| Culture | **Reclassify, not a spendable stock.** | Visible civic achievements → permanent readiness record. Credit each event once. Shrines and storytelling can confer milestones or a distinct civic benefit; no arbitrary passive spend or warehouse cap. |

No currency for Stone Age. No grain, plank, ration-item, logistics-credit or premium-currency inventory at launch. Expedition cost is Food directly. Take an additional commodity only if removing it would erase an actual decision. After Stone Age telemetry, if Hides/Leather still feels like an extra mandatory production line without a meaningful payoff, defer both in new games instead of adding busywork to justify them.

## Storage, workforce and recovery

- **Campfire cache:** seed capacity without requiring construction: Food 60, Wood 60, Stone 40; each unlocked craft material 24. Capacity is per named resource, not a shared weight puzzle. Never applies to Knowledge/Culture.
- **One buildable storage family, two explicit specializations.** Stockyard: materials and crafted goods only (L1 +60 Wood, +60 Stone, +24 per unlocked craft material). Granary: Food only (L1 +60 Food). Buildable variants can share a shell, menu category and art family. Prototype them as selectable specializations under one catalog entry; no duplicate generic warehouses. First upgrades extend only the chosen specialization. Placement can gain relevance in a later logistical pass, canopy/skins never change traits.
- Show output held, specific input shortage, worker shortage, and storage full as separate reasons. Block a recipe on full output **before** consuming ingredients. Move/replace/disconnect never destroys inventory: show retained overflow, allow spending/consuming it, stop filling above the operational cap. Do not introduce spoilage in the first era.
- Use a small shared workforce with one slot per basic producer. Start with two field slots for three residents; prototype slots = max(2, floor(0.7 × population)). Priority: survival food first, then explicit player workers, then default production. Never silently steal assigned workers; warn before reallocation and expose restoring defaults. Early UI may use automatic assignments. Keep the first expedition independent of the only Food or Wood worker.
- Population grows when there is room and a stable food surplus plus reserve. No death spiral: shortage pauses growth and nonessential demands before survival; a persistent free **Forage for recovery** action credits only missing Food up to 12, and **Gather fallen branches** credits only missing Wood up to 12 before the first Hut, or 8 afterward. Keep recovery nonrepeatable above the floor, with no export/reward loop. Never sell the rescue. Ensure the allowed starter area always fits Campfire, Hut, Gathering Shelter and required access. Survey fallback is deterministic and never requires an optional craft.
- During absence, apply the same rules using elapsed simulation time, never a rendering-frame loop. Prototype a **60-minute first-era offline cap** for the new economy, with a plain return summary. Freeze at the cap; no loss beyond it. Cancelled timers or reconnects must not double-charge or double-grant. Test the cap before choosing it over the current behavior.

## First balancing sheet

Numbers are provisional. Rates are **per simulation minute** at level 1 with one staffed producer and valid placement. Explicit starter gifts are legacy-neutral and not eligible for eventual export.

| Item / action | Candidate cost | Candidate output / outcome |
|---|---:|---|
| New settlement | — | 3 residents, 32 Food, 32 Wood, 0 Stone; Campfire +2 Food/min; consumption 1 Food/resident/min |
| Hut | 12 Wood | +3 housing, starts tutorial sequence; Campfire housing = 3 |
| Gathering Shelter | 8 Wood | +8 Food/min; first route's baseline |
| First forest survey | 8 Food | Region discovery +6 Knowledge, one legal Woodcutter site |
| Woodcutter | 4 Wood | +6 Wood/min |
| Stone gatherer | 10 Wood | +5 Stone/min; Flint or Clay variant +4/min, mutually exclusive per building |
| Fishery | 16 Wood + 6 Stone | +10 Food/min; Food only |
| Farm | 22 Wood + 8 Stone | +13 Food/min; fertile site, no water stock debit |
| Stockyard / Granary | 18 Wood + 6 Stone / 14 Wood + 4 Stone | Capacity only; no extra workers initially |
| Oral Tradition / civic L2 | 6 Knowledge / 12 Wood + 6 Stone | Staffed L2 +2 Knowledge/min; no circular start dependency |
| Toolmaker batch | 2 Wood + 2 Flint | +1 Tool; one batch per minute |
| Pottery batch | 3 Clay + 1 Wood | +1 Pottery; one batch per minute |
| Leather batch | 2 Hides | +1 Leather; one batch per minute |
| Example craft projects | 3 Tools / 3 Pottery / 3 Leather | Civic L3 upgrade component / Granary upgrade component / scout-route unlock. These are components, not the full project price. |

At population 3, one gatherer plus Campfire gives +7 Food/min; with the first Hut full (6 residents), +4. At 10, the gatherer alone merely breaks even. Fishery alone plus Campfire yields +2; farm alone yields +5. These are different investments, not pay gates. With 32 starting Wood, a player can build Hut, Gatherer and Woodcutter and still have 8 Wood. One source feeds one crafter without immediately forcing multiple copies. Start growth at one resident every four minutes only when housing, reserve (20 Food) and positive flow all hold. The ten-minute model summarized above checks four scripted routes (guided, delayed, empty stock after Hut, and empty stock before Hut). It assumes scheduled construction completes at the listed minute and does not implement the engine. It verifies arithmetic and the recovery floor, **not** placement, actual pacing, UI or player enjoyment.

Suggested readiness prototype, as replacements for the existing checklist **only in a new profile**: permanent completion records for (1) stabilize Food surplus across 3 simulation minutes, (2) reach 8 residents, (3) staff civic L2 and complete two non-tutorial technologies, (4) complete one actual craft project, (5) discover forest + two other regions and place a Lookout after it is available. Confirm conditions can be satisfied through both river and inland development. Preserve existing first-era pillars/chapter/reward IDs in legacy saves; do not silently reset, rerun or double grant them.

## Monetization: design boundaries now, code the store later

**Three separate ledgers.** (A) World stock and gameplay unlocks scoped per settlement, playable offline. (B) Account entitlements and earned cosmetic unlocks. (C) Trade or seasonal scoring ledger only if those features actually ship, server validated. No conversion paths B→A/C; no ad or paid item can transfer to another account, enter trade, alter score, or generate more resources. Same rule applies to indirect advantages such as extra production slots, better warehouse capacity, or a paid city slot that could supply other cities.

- **First products:** transparent direct purchases of decorative building styles, civic plaza visual packs, banner/soundscape bundles. Same footprint, stats, visual legibility and category cues. Free base looks and earned decoration route. No loot boxes or obscure premium exchange rates; start with direct purchases.
- **First reward test, after player completes Stone Age:** optional opt-in ad from a dedicated décor panel grants one specified nontradeable decoration stamp toward a visible cosmetic, also earnable through play. Trial cap: two per day; no autoplay, no ad in tutorial or starvation/storage dialogs, no ad refresh on app restart. Dismissal/no fill/denied tracking has zero progression impact. Don't grant a marketable resource, generic speed boost, or points that can flow into competitive or intercity systems. Measure annoyance and retention alongside revenue; turn off the format if the benefit depends on creating frustration.
- **Later seasons/multiple civilizations:** begin with authored local production and voluntary orders, not a live global market. Test at least three regional surpluses without adding daily chores: explicit export reserve below which sales pause, one low-touch trade order, symmetric access to imports via play, and no self-trading loops that multiply goods or progression. Prove two settlements don't funnel free starter stock to a third. Only then add server-authoritative trading, auditable order fills, and non-client clocks; do not promote old or offline unverifiable stock into that economy.
- **Implementation boundary:** no login, ads SDK, payment code or live backend needed to test the economy. Later verify the applicable [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) and use [StoreKit](https://developer.apple.com/storekit/) as the baseline for digital goods. Store signed transaction IDs and reconcile refunds/restores for durable cosmetic entitlements. For rewarded ads, review [Google's opt-in/disclosure and non-transferability policy](https://support.google.com/admanager/answer/7496282?hl=en) and verify [server-side reward callbacks](https://developers.google.com/admob/ios/ssv) before minting entitlements. Idempotency by provider/event ID; a delayed verified reward stays pending visibly, not silently lost.

## Follow-up milestones after the lab

**Goal for the first implementation, after review:** deliver a separate, Debug-only Riverbend Economy Lab. A fresh fixture can build a Hut, feed residents, discover a contiguous forest area, start production and run one craft chain without Water, payment, ads, or modifying an existing save.

1. **Snapshot and measure:** map every consumer, producer, cap, entitlement, goal and tutorial hint; reconcile the visible warehouse UI with catalog IDs; record exact baseline ref and seed hash. Run the existing regression suite before touching normal play.
2. **Versioned profile:** separate economy rules from balance config, pin the config version per save, use deterministic simulation and existing transaction boundaries. Preserve legacy as default. Labs start clean in isolated copies; no implicit migration. Keep legacy Water and Culture balances intact; don't convert to Food, points or tradeable rewards. Start with no migration path until the new route is accepted. Any later migration must be explicitly approved, backed up, idempotent, and able to reconcile goal history, in-flight paid expeditions, old storehouse capacities, and offline time without silently losing assets.
3. **First slice:** Food/Wood → forest → Woodcutter; clear inventory and depth controls; add recovery actions and guarded staffing. Leave global placement/connectivity behavior and current visual assets untouched. Coordinate area discovery with the tutorial plan rather than create two competing expedition models.
4. **Second slice:** Stone, one storage specialization of each type, and Tools; only then test the other crafts and readiness conditions. In the absence of implemented logistics, capacity is the only economic storage effect. No fictional hauling bonus; no R2-07 activation.
5. **Human review:** capture a fresh iPhone and iPad route with counters and shortage explanations. For the first five novice sessions, require at least four players to build the Hut and start a first expedition without coaching; record time-to-first-wood and cause of each stall. Target **zero unrecoverable states**, at least two no-payment routes to Bronze readiness, and a normal route in about 75–105 minutes before tuning. Spread deliberate building/scouting choices across waits; never lengthen a timer for monetization. These are acceptance *targets*, not measured results.
6. **Regression list:** no ads/backend/SDK in the prototype; source and sink conservation including offline catch-up; full capacity no input destruction; duplicate reward IDs inert; remove/disconnect storage retains stock; reload matches uninterrupted sim; old saves not written and R2-07 stays off; empty Food/Wood, occupied site, no worker, full storage, bad forest candidate and replay all have predictable outcomes. Record exact commits; don't merge in-flight art/UI work.

**Review before rollout:** accept the isolated pilot and review subsequent milestone scope before making any change to the normal game.
