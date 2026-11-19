# Riverbend — Civilization Builder, Seed 0.2.7

A native iPhone/iPad Stone Age settlement using SwiftUI, SpriteKit and a pure Swift simulation. The approved gameplay roadmap through 0.2.5 is implemented: twenty buildings, twelve resources, production chains, maintenance, upgrades, workforce, exploration, twenty technologies and five-pillar era readiness. **Graphics are procedural placeholders.** No account, backend, purchases or external dependencies.

See the [status ledger](docs/design/status-ledger.md) for approved mechanics, experimental tuning and deferred work. Seed 0.2.7 completes the Stone Age checklist, seven development chapters and a research-style building catalog, with isolated Debug developer scenarios. No second age is implemented. See the [0.2.7 report](docs/milestones/seed-0.2.7-report.md), [graphics feasibility proposal](docs/design/graphics-feasibility-03.md) and [0.2.6 report](docs/milestones/seed-0.2.6-report.md), [physical-device setup](docs/design/device-testing.md) and [approved-feature audit](docs/design/approved-feature-audit-026.md).

## Run

Open `Civilization.xcodeproj`, choose **Civilization**, select an iPhone/iPad simulator and Run. The app is universal, landscape, with deployment target **iOS/iPadOS 18.0**. The existing user-configured development team and signing settings are preserved.

```sh
swift test --package-path Packages/GameCore
xcodebuild -project Civilization.xcodeproj -scheme Civilization \
  -destination 'platform=iOS Simulator,id=EC995F2A-534A-4E57-A59C-0DE408729150' \
  -derivedDataPath /tmp/civilization-derived CODE_SIGNING_ALLOWED=NO build
```

Simulator IDs are machine-specific. This machine has Xcode 27.2 and SDK 27.2. Verified profiles include iPhone 17 Pro Max / iOS 26.5, iPad mini A17 Pro / iOS 18.6 and iPad Pro M4 / iOS 18.6. Simulator results do not establish physical-device performance.

## Play

- Choose a building from the categorized catalog, drag its preview and release on valid land to place it; the hand icon indicates drag mode. Tap positioning and Confirm/Cancel are also available. Construction reserves occupancy and costs immediately; effects and one-time onboarding rewards begin on completion.
- Long-press an existing building to drag it to valid land, or use Move building from inspection. Movement is free and preserves upgrades/timers; the campfire remains fixed. Invalid drops cancel.
- Drag/pinch the map; scope centers the settlement. Tap buildings or use the building-picker button to inspect recipes, staffing, priorities, maintenance and permanent upgrades.
- The compact toolbar shows resource icons/quantities. Tap for gross production, consumption, net rate, capacity, sources and operating-producer count. Swipe the toolbar on smaller screens. Tap population for food/water conditions, housing, growth and workforce.
- Gather food, cut wood and collect stone/flint/clay through stone-gatherer modes. Research hunting for hides, fishing for food/water, then tools, leather and pottery chains. Manufacturing and maintenance shortages reduce productivity without negative stocks or deaths.
- Workers are assigned automatically. Half the available labor is provisionally protected for basic food/water buildings; remaining labor follows player priorities. Campfire production and household construction/expeditions preserve recovery routes.
- Explore expands known territory through timed food-cost expeditions. Farther journeys require a scout camp. Unknown footprints cannot be built upon; extraction requires discovered, identified deposits. Fishing needs nearby revealed water. Copper remains unidentified and unavailable this age.
- Research opens a full-screen adaptive interface with five category progress indicators, costs versus stocks, prerequisites, effects and a separate Stone Age readiness view. Follow seven independently evaluated development chapters. Readiness now requires every catalog building type and technology, required resource territories and all five pillars. The original five +10 wood construction rewards and previously earned readiness remain recorded. Continue building, researching and exploring afterward without a reset.

All exact values are experimental. Read the [economy](docs/design/seed-022-balance.md), [population](docs/design/population.md), [landscape](docs/design/landscape.md), [research](docs/design/research.md) and [progression](docs/design/progression.md) notes.

## Architecture

`Packages/GameCore` contains three modules:

- **GameCore:** framework-independent authoritative state, validated bundled JSON, commands, chronological simulation, transactions and achievements. No SwiftUI/SpriteKit imports.
- **GamePersistence:** versioned Codable saves, strict validation, compatibility migration, original-file backups and atomic writes.
- **GameApplication:** observable session, injected clock, command/lifecycle adapter and persistence warnings.

`Civilization/UI` presents adaptive controls. `Civilization/Rendering` displays snapshots and submits commands, preserving logical tiles, footprints and ground anchors. Placeholder asset identifiers can be replaced without economy changes. The handcrafted 32×24 river valley and deposit identities persist.

The engine jumps to construction, growth, exploration, resource/deposit depletion and achievement-threshold events. It never simulates rendering frames offline. Deterministic max-min input sharing operates within validated production tiers; upstream flow is immediately available at empty stocks. Worker allocation is deterministic and separate from input scarcity. Fractional balances are retained; presentation rounds down.

## Saves and time

Version **5**, at `Library/Application Support/Civilization/settlement-v1.json` in the app sandbox. Versions 1–4 migrate without resetting buildings, stocks, IDs, timers, research, priorities, discovery, reserves or earned rewards. Existing advanced building kinds retain construction knowledge without free technologies. Backups use `.seed-0.1.bak`, `.seed-0.2.1.bak`, `.seed-0.2.3.bak` and `.seed-0.2.4.bak` according to the original version; backups are not overwritten.

Saves follow meaningful actions, every 15 active seconds and backgrounding. Catch-up is capped at eight hours for production and timers. A high-water timestamp prevents duplicate claims and negative-clock progress. Invalid/unsupported saves are preserved; the warning disables overwriting them. Earlier clients displayed the whole map, so those saves retain full discovery.

## Verification and known limits

**106 Debug Swift Testing tests pass**, including frozen historical regressions, transactions, all migrations, growth/construction, production/maintenance sharing, finite depletion, priorities, exploration, research and sticky achievement boundaries. A complete real-cost playthrough reaches all five pillars, saves/reloads and builds afterward. See the [0.2.5 report](docs/milestones/seed-0.2.5-report.md) and [documented playthrough](docs/design/stone-age-playthrough.md).

Release tests: **96 pass**. Three simulator XCTest UI regressions verify immediate catalog drag mode, the mode indicator, long-press relocation, pan/pinch and stable identity; run it with `xcodebuild -project Civilization.xcodeproj -scheme Civilization -destination 'platform=iOS Simulator,id=<SIMULATOR-ID>' CODE_SIGNING_ALLOWED=NO test`. `python3 scripts/verify-developer-release.py` checks that four debug APIs compile only in Debug, after building both package configurations.

In Debug, tap the wrench to load Early/Developed/Late test settlements or resume the separate developer save. Pause/speed/time advance, grants, reveal and three-second construction are available there. Normal saves stay isolated; relaunch always opens normal play. See the device guide for controls, reset and save recovery.

Phone and tablet builds/runs and relevant UI interactions were verified. The completed automated save was previewed on an isolated simulator; screenshots are in `docs/screenshots/seed-025`. This is not a manual full-era playtest.

Physical iPhone 17 Pro Max is connected; signed and unsigned device builds pass using the existing user-configured team. Device installation is handled separately from compilation. Physical FPS, battery/thermal behavior and enjoyment remain unverified. Signed 0.2.7 device installation preserves validated normal/developer save bytes. The serial complete-era playthrough takes 154 simulated minutes, exposing knowledge pacing for human testing. Deposit reach is generous and provisional; buildings share placeholder silhouettes. Security effects are foundations rather than combat. No final art/audio, additional ages/cities, trade, warfare, analytics, monetization or cloud saves.

## Physical-device feedback iteration 1

Implemented building relocation, a horizontal building carousel, compact resource controls, collapsed-by-default goals and native/asynchronous startup loading. No artificial delay. See the [iteration report](docs/milestones/seed-0.2.6-feedback-1-report.md) and screenshots in `docs/screenshots/seed-026-feedback`.
