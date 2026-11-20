# First settlement onboarding — Gate A audit and independent model

Goal: prepare the owner-requested first-settlement/forest exploration review without changing production expeditions, terrain, saves, costs or progression. Authority: [20 November onboarding plan](../../../plans/2026-11-20-first-settlement-exploration-onboarding.md), fetched at `ccf33c6`. Gate B remains subject to owner review. This document covers the source audit and pure model; native screenshots and visual verification belong to the enclosing delivery report and are not inferred from source inspection.

## Actual opening and sources

| Contract | Current behavior |
| --- | --- |
| New game | `GameLibrary.startNewGame` creates an independent authentic game. `GameEngine.init` uses map `river-clearing-64x48-v1`, 64×48, campfire at (17,12), one 1×1 civic building, population 3, food 60 / wood 100 / stone 50 / water 60. No initial roads. |
| Civic identity | Campfire remains the same civic identity through Gathering Place and Council Circle. Current civic mechanics permit relocation; the onboarding does not move or duplicate it. “Permanent” describes identity, not a new immovability rule. |
| Existing guidance | `SettlementGuidance` and `StoneAgeJourney` support the existing seven chapters and five pillars. Founding currently includes gathering shelter, woodcutter, hut and Oral Tradition/civic progress. The new proposed hut-first guide must hand off without rewriting these objectives/rewards. |
| Hut | Catalog name **Hut**, 2×2, 20 wood, 15 seconds construction, no research prerequisite, 5 housing. A placed, unfinished hut is not a completed onboarding event. |
| Wood producer | Catalog name **Woodcutter**, 2×2, 10 wood + 5 stone, 20 seconds, one worker, no research prerequisite. Recipe produces 10 wood/minute before productivity/bonuses. No new mill mechanic. |
| Forest semantics | Woodcutter has **no mandatory `requiredNearbyTerrain`**. Forest within radius 5 gives +20% geographical output. Its wood recipe uses renewable `western-forest` deposit (2,12), extraction radius 40; deposit knowledge and staffing affect operation. The guide must not claim mandatory adjacency or guaranteed output before completion/staffing. |
| Actual placement | Entire footprint must be inside map, discovered grass/clearing, unoccupied, without roads; costs/bootstrap reserves and unlocks must pass `GameEngine.placementIssue`. Forest, water and hills cannot hold the building. |
| Initial exploration | `initialRadius=7`, Chebyshev square around original campfire. Six known-deposit IDs additionally reveal handcrafted Manhattan routes, x first then y. The visible green corridors are intentional discovery data, not merely gaps in fog shading. |
| Expeditions | `startExploration`: 10 food, 45 seconds, one concurrent expedition; payment happens once. Completion unions the square with radius +2 into existing knowledge. Scout camp required beyond radius 11. Maximum radius for this map is 46. The live UI reports these rules and the real remaining timer. |
| Forest geography | Two cardinal forest components exist in current terrain: western 232 tiles, eastern 512. Nearest western forest tile by squared distance from campfire is (11,4). Revealing the entire western component at the first expedition would expose a long map-edge tract; Gate A proposes a smaller local geographical lobe. |
| Connectivity | Normal legacy operating rules do not require roads. Only explicit `connectedPathsV1` v7 review rules require service connectivity. No R2-07 activation is performed. |

Audited sources: `Packages/GameCore/Sources/GameCore/{GameEngine,Exploration,Economy,SettlementConnectivity,StoneAgeJourney,SettlementGuidance,Configuration,Types}.swift`, bundled `Resources/seed.json`, `GameApplication/GameLibrary.swift`, `Civilization/UI/SettlementView.swift`.

## Fog and concealment

Current `SettlementScene.drawTerrain` creates an opaque diamond plus two cloud ellipses for each unknown cell. It skips hidden terrain/scenery below that cell. This hides terrain but produces a repeated white tile pattern. SpriteKit terrain is chunk-cached for the 64×48 map. Road/deposit/building visibility uses discovered tiles; buildings require their complete footprint to be discovered. This concealment boundary must remain when a continuous visual fog field is reviewed.

A continuous fog layer alone cannot remove the green routes: production `initialDiscoveredTiles` explicitly contains those routes. Removing existing saved discoveries would be a destructive gameplay/migration change. Gate A instead supplies a separate initial discovery set to an isolated preview renderer. The actual session and existing files retain every original discovered tile.

Proposed visual layering: render known terrain and fully known buildings only; keep unknown cells covered by an opaque ground-independent field; add low-frequency soft boundary/scenery layers above it. Recede only the reviewed region over approximately 1–2 seconds, with a static reduced-motion reveal. Fog must not mask placement/grid controls or disclose resource silhouettes. Native screenshot/zoom/rotation/concealment evidence is still required for a renderer implementation; this audit does not claim it.

## Pure review model and API

`OnboardingReviewSnapshot.make(configuration:state:)` validates a value copy through the production engine and returns an optional independent snapshot:

- `sourceDiscoveredTiles`: unchanged source knowledge, retained for preservation assertions.
- `initialDiscoveredTiles`: the real initial-radius square without the six legacy routes, for the isolated first-card preview only.
- `region.forestTiles`: cardinal flood fill of actual forest within a circular local radius of five cells from a deterministically ranked seed. Ranking is squared distance to the founding anchor, then y/x; no random choice or resource generation.
- `region.woodcutterOrigins`: actual 2×2 footprint candidates, cardinally adjacent to this forest lobe, on reachable open terrain, within current first-expedition practical radius. Candidates are sorted deterministically and must pass authoritative `placementIssue` using current resources, occupancy, roads, unlocks and bootstrap protection.
- `region.tiles`: the connected forest lobe plus the valid candidate footprints. `revealedDiscoveredTiles` unions this area with the initial preview clearing. It never draws a narrow discovery route or rectangular replacement map.

Reachability is checked against existing open terrain from the actual civic position. The model never creates a bridge or crosses protected water/hills/forest. Its temporary engine copy retains original discovery plus the proposed cells solely for transaction validation. It never calls build, startExploration, advance, grant, save or session mutation. If no candidate validates, the API returns `nil`; no forest is invented. Five-cell lobe extent and the current first-expedition reach are review choices, not accepted gameplay balance.

`OnboardingReviewGuide` derives completed civic/hut/woodcutter facts, actual pending/completed expedition evidence and forest visibility from a read-only engine snapshot. Events are a set, so duplicates do not replay actions. Ordered steps are campfire → hut → expedition → forest → woodcutter → optional connection → handoff. Out-of-order facts remain remembered without fabricating preceding completions. The connection step appears only for explicit connected operating rules. `skip()` and `reopen()` alter presentation only; no encoded tutorial field or reward ID is added.

The review UI can also feed explicit preview events to demonstrate the proposed area sequence. Such a demonstration must be labeled as a review; the current live square expedition does not reveal this proposed area in one journey.

## Save policy, remaining design decisions and Gate B

`SaveStore` supports legacy versions 1–5, civic v6 and explicitly marked connected-rules v7. Current saved expedition state is remaining seconds + completed radius + discovered set. Legacy conversions preserve original bytes through existing backups. There is no current region ID, selected region or paid expedition transaction identity. This change adds no persisted fields and no migration.

Before Gate B, reconcile how a new-area expedition identifies target and cost transaction durably, resumes a paid in-progress expedition, and avoids duplicate payment/reveal after cancellation/reload. Preserve old discovered sets and pending paid square expeditions; never infer fresh starts from an assistant label or re-fog existing games. Choose whether old games retain legacy square exploration or opt into additive area exploration. Reject missing/corrupt target metadata rather than silently charging or restarting.

The existing wood deposit origin/radius contract requires an explicit decision if the first revealed forest lobe does not expose a deposit origin/access site. Gate A demonstrates terrain proximity and valid placement; it does **not** claim that hiding legacy deposit routes already provides an operational early wood economy. No deposit is moved, revealed in the session, or duplicated to conceal that design dependency.

Tests prepared in `OnboardingReviewTests.swift` cover deterministic real-terrain cardinal regions; authoritative woodcutter placement and source-state preservation; absent forest; out-of-order/deduplicated events; skip/reopen; explicit connectivity gating; and real hut construction/paid-expedition evidence. Loading model tests separately cover indeterminate/valid measurements, decorative-only skip and motion suppression. Exact test results and phone/mini/Pro screenshots must be recorded by the enclosing verification run before a completion claim. Physical performance, gameplay acceptance and Gate B remain open.

## Whole-forest alternative after audit (review recommendation)

The optional `includeWholeForest: true` proposal reveals the full actual connected western forest(232cells) plus valid adjacent building sites. It includes the unchanged renewable wood source at(2,12). Native GateA now previews this alternative, while the original local-lobe model remains available for comparison. A new production-engine test builds a woodcutter in a value copy, completes construction and proves wood increases; source state is unchanged. This avoids inventing resource access semantics or secretly adding deposits.

Tradeoff: the first reviewed expedition exposes a larger geographical area than the local lobe. Adopting its area, timing/cost, existing-save rollout and tutorial persistence remains GateB review; current production expeditions stay radius-based. Current10food/45s values are shown as existing rules, not a claim that this preview has charged/earned/rebalanced them.


## Owner feedback and visible walkthrough correction

The owner saw only changed clouds and could not find onboarding guides; visual integration was explicitly declined pending refinement. This is not GateB acceptance. The first native lab exposed only a static initial card/manual reveal despite the model-tested state machine. A separate **Developer tools → Onboarding walkthrough — start here** now connects those steps to a fresh in-memory production engine: actual Hut construction, one paid expedition/countdown, additive proposed whole-area reveal, Woodcutter construction/production and existing chapter advice. It has no GameSession, library or store. Free map selection, confirmation/cancel, skip/reopen and clearly labeled review time advance are native interactions. Production New Game, saved discoveries, paid expeditions and rules remain unchanged. Exact test/capture/installation status belongs to the native visual-program ledger; this description does not imply acceptance.
