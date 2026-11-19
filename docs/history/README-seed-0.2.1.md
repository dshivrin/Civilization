# Riverbend — Civilization Builder, Seed 0.2.1

A native, single-player Stone Age settlement for iPhone and iPad. SwiftUI HUD, SpriteKit isometric world, and original procedural **placeholder graphics**. No external dependencies, account, network, purchases, or final assets.

## Current milestone

Seed 0.2.1 extends the functional seed with timed construction, food consumption, conditional population growth, configurable capacities, production/duration modifiers, data-driven research prerequisites and v1→v2 save migration. The six original buildings, geography, identities and seven seed goals remain. Placeholder graphics are retained. Full first-era catalog, chapter progression and production art await later approval.

The accepted scope and provisional larger plan are in [docs/milestones/seed-0.2.md](docs/milestones/seed-0.2.md). Original Seed 0.1 requirements, README and configuration are preserved under `docs/history` and the regression fixtures.

## Run

Open `Civilization.xcodeproj` in Xcode, choose the **Civilization** scheme, select an iPhone or iPad simulator, and Run. The deployment target is **iOS/iPadOS 18.0**, universal, landscape left/right. No development team is set; configure your own team only if running on a physical device. Simulator verification used unsigned builds; signing settings were not changed.

```sh
open Civilization.xcodeproj
swift test --package-path Packages/GameCore --scratch-path /tmp/civilization-swift-build
xcodebuild -project Civilization.xcodeproj -scheme Civilization \
  -destination 'platform=iOS Simulator,id=EC995F2A-534A-4E57-A59C-0DE408729150' \
  -derivedDataPath /tmp/civilization-derived CODE_SIGNING_ALLOWED=NO build
```

The device ID above belongs to this development machine. Use `xcrun simctl list devices available` to select a local simulator. There is no package installation or project generation step.

## Play

- Choose **Build**, choose a building, then **Confirm** its green footprint. A valid initial location near the campfire is offered automatically. Tap the map to reposition; the four 44-point arrow controls also move the footprint one logical tile at a time. Red footprints cannot be confirmed. **Cancel** leaves resources untouched.
- Drag the map to pan; pinch to zoom; use the scope button to center on the settlement. Tap an existing building to inspect its footprint and effects.
- Resource HUD shows rounded-down material units and **net** rates per minute. Tap a resource for gross production, consumption and storage. Fractions remain in the simulation. Tap population for growth status and remaining eligible seconds. No worker assignment or starvation deaths.
- Buildings now reserve their footprint and deduct costs immediately, then become operational after a configured countdown. Hut: 15 seconds; gathering shelter, woodcutter and stone gatherer: 20 seconds; storytelling circle: 30 seconds. Benefits and one-time construction rewards activate at completion.
- Population starts at 3, consumes one food/person/minute and grows after 120 eligible seconds (90 with Social Order). Growth needs free housing, 20 food reserves and positive net food. Earned progress pauses when blocked.
- Follow optional goals in the lower left, in any order. Each construction goal grants +10 wood once. Research **Oral Tradition** in the Research panel to unlock the storytelling circle. Provisional foundation research also includes Stone Tools (+20% gross wood/stone, 15 knowledge) and Social Order (90-second growth interval, 50 knowledge); both require Oral Tradition.
- Accumulate 15 knowledge to complete the seed, then continue sandbox building. One circle takes five minutes to produce 15 knowledge; additional circles can shorten this. No payments are involved.

## Architecture

`Packages/GameCore` is a local Swift package with three modules:

- **GameCore**: pure Swift domain values, validated bundled JSON, a fixed 32×24 map, chronological event-based elapsed-time simulation, population/consumption, validated research graph/effects, atomic placement/research transactions, stable incremental IDs, goal/reward history, and framework-independent map geometry. No SwiftUI/SpriteKit imports and no rendering-frame production. No RNG is needed: both geography and simulation are deterministic.
- **GamePersistence**: version-2 Codable envelope, validated v1 migration and v2 load, original v1 backup, and Foundation atomic writes.
- **GameApplication**: observable main-actor `GameSession`, injected clock, command adapter, lifecycle transitions, and save error reporting. Exposing this separately allows testing real application save/reload and inactive/foreground transitions without UIKit.

`Civilization/UI` contains the adaptive HUD and presentation controls. `Civilization/Rendering` converts snapshots to a SpriteKit scene, with UIKit gesture recognizers confined to the map view. Rendering submits tile selections and never changes resource balances. Static terrain is rasterized; buildings refresh when their snapshot changes, including construction countdowns. Inspection resolves the latest building snapshot by stable ID. Camera center stays inside the map diamond at all zoom levels; tablets reveal more map.

All initial resources, costs, rates, capacities, rewards, footprints, asset keys, research costs, and terrain rows live in `Packages/GameCore/Sources/GameCore/Resources/seed.json`. The map has a stable identity, `river-clearing-v1`. Water, hills and forests block initial construction; forests remain scenery. Terrain, occupancy and world projection are separate.

### Replacing art

Each definition has a reusable `placeholder.*` asset key and logical footprint. `SettlementScene.drawBuilding` uses the footprint's projected center as the ground-contact anchor. Replace the placeholder node there with a transparent sprite using that asset key and anchor, preserving logical occupancy. Tree/rock/grass/water drawings are placeholders too. No downloaded assets are used.

## Saves and time

The app saves to its sandbox's `Library/Application Support/Civilization/settlement-v1.json` after meaningful actions, every 15 seconds while active, and when leaving the active scene. It loads before showing the playable settlement and applies chronological catch-up once, capped at 28,800 seconds (8 hours). It never simulates offline rendering frames. Integration jumps to the next construction completion, reserve threshold or eligible population event. Completed buildings produce only for the remainder of the interval; growth changes consumption immediately. Exact ties resolve construction before population, then goals. Food is clamped to zero and each resource to its effective capacity. Technology production bonuses add; duration multipliers multiply and affect new construction only.

The saved timestamp is a high-water mark: backwards clock changes produce zero progress and do not lower it. Time beyond the offline cap is discarded while advancing that watermark, so restarting cannot repeatedly claim it. Timers store simulated seconds remaining, so discarded offline time cannot complete construction or grant population. Inactive callbacks and timer ticks cannot bypass foreground catch-up. Severe clock rollback pauses production until wall time reaches the watermark.

Unreadable, invalid, or unsupported saves are preserved. The app shows a warning and permits a temporary settlement without overwriting the original. Filesystem write failures remain visible and are retried on later saves. Version 1 migrates existing buildings as operational, translates Oral Tradition into the technology set, and initializes growth progress without regranting rewards. The first upgrade write creates `settlement-v1.json.seed-0.1.bak` before atomically replacing the live file; the backup is not overwritten on later saves. Version 2 persists researched IDs, earned growth seconds, and construction duration/remaining seconds. There is no cloud sync or in-app recovery interface.

## Verification — 17 November 2026

Toolchain: **Xcode 27.2 (27B52), iOS SDK 27.2**. Installed runtimes include iOS 18.6, 26.5 and 27.2. Tests use Swift Testing on macOS; iOS compilation and runtime are checked through the app builds.

Actual test command:

```sh
swift test --package-path Packages/GameCore --scratch-path /tmp/civilization-swift-build
```

**Seed 0.1 baseline: 19 tests passed, 0 failures.** The original assertions are retained against the frozen original configuration; the current ruleset has additional tests described below.

Coverage includes starting resources, fractional/frame-independent production, all resource caps, costs and rates, housing, map/terrain/occupancy/whole-footprint rejection, insufficient funds, unlocks and research uniqueness, out-of-order and repeated construction rewards, save roundtrips, invalid versions/maps/corrupt data, repeated resume, negative clock changes, offline cap, complete seed progression, camera bounds and every map tile's projection roundtrip. Application tests exercise injected time, background → inactive → foreground, save preservation, and reward idempotency after real save/reload.

Actual simulator build/run calls used XcodeBuildMCP `session_set_defaults` with this project, scheme `Civilization`, `/tmp/civilization-derived`, and `preferXcodebuild: true`, then `build_run_sim(extraArgs: ["CODE_SIGNING_ALLOWED=NO"])`:

| Simulator | Runtime | Verification |
|---|---|---|
| iPhone 17 Pro Max | iOS 26.5 | Final build/run and documented shell build succeeded; landscape HUD/placement/inspection; catalog scrolling, placement arrows, invalid river footprint with disabled Confirm, pan and recenter exercised |
| iPad mini (A17 Pro) | iOS 18.6 | Build/run; landscape screenshot and inspection; nearest installed mini profile |
| iPad Pro 13-inch (M4) | iOS 18.6 | Build/run; new-game screenshot; all five constructible types placed through UI; Oral Tradition researched; production/housing/6-of-7 goals verified; process stopped/relaunched with buildings, research, rates, and progress preserved |

The original iPad mini 6 and 12.9-inch M1 profiles were unavailable, so the nearest installed profiles were used. See `docs/screenshots` for captured phone/tablet evidence. Core tests reach seed completion using injected elapsed time; the five-minute knowledge wait is not accelerated in the shipping app.

The final shell build succeeded with one informational Xcode warning: App Intents metadata extraction was skipped because this app has no AppIntents dependency.

Initial build problems were resolved: the sandbox blocked compiler caches (tests ran with approved cache access), and Debug initially built two simulator architectures while the local package built only the active one (`ONLY_ACTIVE_ARCH=YES` corrected this). A fresh review identified unsafe rectangular camera bounds; map-space clamping and regression coverage replaced them. Lifecycle review also led to explicit active-state tracking.

## Current limits

- Final graphics, audio, localization, additional eras/cities, warfare, worker assignment, the final research tree/catalog and chapters, cloud saves, analytics and monetization remain deferred as specified in AGENTS.md.
- Physical-device 60 FPS, memory, battery, baseline A15 performance, signing and distribution have **not** been verified. Simulator builds are not hardware benchmarks.
- Basic accessibility labels and placement nudge controls are present; full VoiceOver navigation, large Dynamic Type, and all display/gesture combinations need device QA.
- Balance is provisional. Completion is covered by deterministic tests; broader human playtesting is needed to validate the 5–15 minute pacing target.
- This folder started with only AGENTS.md and no Git repository. No existing app was overwritten; no commits, remote pushes or worktrees were created.

## Seed 0.2.1 verification

The same `swift test` command exercises the original regression fixture and the new foundation rules. New coverage includes event partition equivalence, reserve crossing and food exhaustion, paused eligible growth, construction benefits/rewards at completion, capacity/efficiency/duration effects, cyclic/missing prerequisites, partial modifier overflow, real v1 save bytes and backup preservation, current timer/growth reloads, and complete seed progression under consumption/timers.

Phone simulator upgrade was inspected: live envelope v2 and preserved backup v1 have identical original building IDs [0,1,2,3,4], original goals and Oral Tradition. Live phone UI verified population growing from 3 to 4; net food changed from +11 to +10/min while gross stayed +14. A new hut's 15-second countdown persisted through process termination/relaunch (12 seconds remaining afterward); housing remained unchanged until completion. Resource breakdown and construction screenshots are in `docs/screenshots/seed-021`.

Review fixes cover effective capacity checks, modifier subsets that could overflow before all research is purchased, and retaining paused growth accumulated under an earlier longer interval. No new assets/dependencies, deployment-target changes or signing changes.

Final 0.2.1 result: **37 Swift Testing tests passed, 0 failures** (19 original regressions plus 18 foundation/migration/review cases). Final documented iPhone `xcodebuild` command returned `BUILD SUCCEEDED`; XcodeBuildMCP build/run succeeded on mini A17 Pro and Pro 13-inch M4 with iOS 18.6. Physical-device performance/signing are still unverified. On mini, Stone Tools was purchased through UI (wood +12.0/min, stone +9.6/min), Social Order was purchased and population detail showed the 90-second interval and housing-full pause. No final catalog/tree/art or Seed 0.2.2 work was started.
