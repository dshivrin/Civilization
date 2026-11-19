# Seed 0.2.1 completion report

Implemented the approved simulation foundation; stopped before 0.2.2.

## Functionality and architecture

Kept GameCore / GamePersistence / GameApplication and SwiftUI / SpriteKit boundaries, original 32×24 map and identity, six building types, stable IDs and reward history. Added per-resource capacities, gross/net production, population food consumption, paused eligible-time growth, persistent timed construction with benefits/rewards at completion, data-driven technology graph/unlocks/effects with multiple pillar labels, and chronological elapsed-time integration. Resource arithmetic iterates Resource cases over keyed Codable amounts. No generic future framework or dependency added.

Minimal UI exposes resource breakdown, growth requirements/countdown, research examples and construction countdowns. Placeholder rendering distinguishes unfinished structures. Inspection resolves by ID to avoid stale timer data.

Provisional JSON rules: food consumption 1/person/min; growth 120 eligible seconds, minimum 20 reserves and positive net food/free housing; Social Order 90 s. Hut 15 s, gathering/wood/stone 20 s, storytelling 30 s. Oral Tradition bootstraps knowledge; Stone Tools +20% wood/stone and Social Order are foundation examples, not final first-era content.

## Compatibility and simulation edge cases

Version 1 -> 2 migration preserves resources, buildings/IDs/map, research and rewards, treating old buildings as operational and initializing growth progress. Original file is unchanged by load; first upgraded atomic save preserves a version-1 backup. Filename stays settlement-v1.json for discovery. Version 2 stores growth progress, technology set and construction duration/remaining time. Invalid/unsupported saves still preserve the original and show a warning.

Events split at construction completion, food reserve thresholds and birth times. Same-time construction resolves before growth, then goals. Positive/negative food clamps at cap/zero; growth pauses without deaths. Changed growth intervals preserve already-earned eligible seconds. New construction captures its duration when started, so later research does not retroactively rescale it. Eight-hour offline cap discards excess time for ALL mechanics and advances the clock watermark; negative/repeated time adds no progress.

## Actual verification

`swift test --package-path Packages/GameCore --scratch-path /tmp/civilization-swift-build`: **37 passed, 0 failures**. Includes 19 original regression cases against frozen Seed 0.1 configuration and 18 new foundation/migration/review cases. Tests cover complete seed progression, partial timer/growth reloads, real v1 JSON bytes and backup, partition-equivalent online/offline time, caps, modifier/prerequisite rejection and idempotency.

`xcodebuild -project Civilization.xcodeproj -scheme Civilization -destination 'platform=iOS Simulator,id=EC995F2A-534A-4E57-A59C-0DE408729150' -derivedDataPath /tmp/civilization-derived CODE_SIGNING_ALLOWED=NO build`: **BUILD SUCCEEDED**.

XcodeBuildMCP build/run succeeded for iPhone 17 Pro Max (iOS 26.5), mini A17 Pro and Pro 13-inch M4 (iOS 18.6). Installed phone save verified live envelope v2 + original backup v1 with identical IDs [0,1,2,3,4], original research/goals. Phone population grew 3→4 and net food updated +11→+10 with gross +14. Hut countdown persisted across stop/relaunch with 12 s left, without duplicate charges. Mini research purchases showed wood +12/min, stone +9.6/min and 90-second interval, with housing-full growth pause.

Screenshots: ../screenshots/seed-021/iphone-resources.jpg, iphone-construction.jpg, iphone-completed.jpg, ipad-mini-migrated.jpg, ipad-mini-research.jpg, ipad-mini-population.jpg, ipad-pro.jpg. These are local artifacts, not uploaded to ChatGPT.

Independent review findings fixed with failing-then-passing regression tests: capacity validation used old scalar cap; opposite multipliers hid overflowing partial research subsets; paused progress from a prior longer growth interval could be rejected on reload. No findings deferred.

## Limits and decisions

No physical-device FPS/memory/battery/signing verification, no complete VoiceOver/Dynamic Type or exhaustive gesture testing. Simulator results are not A15 hardware benchmarks. Balance and final art/catalog/tree/chapters remain open. Available mini A17/13-inch M4 profiles substitute for unavailable mini 6/M1 profiles. No target/signing change. No Git repository existed; no initialization, commits, worktrees or pushes created.

Original requirements/README and original config are preserved as history/fixtures. AGENTS.md now states active-stage precedence; docs/milestones/seed-0.2.md records both approved stage and proposed larger scope. Seed 0.2.2 needs explicit approval.

Completion handoff sent to City Design Coordination in the Civilization ChatGPT project on 17 November 2026. No next-stage implementation started.
