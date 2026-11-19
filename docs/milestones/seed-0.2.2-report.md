# Seed 0.2.2 completion report

Implemented approved twenty-building/twelve-resource catalog; configurable recipes, continuous maintenance, permanent upgrades, per-resource storage, geographic bonuses, renewable/finite deposits. Copper is future-only. Retains map/building IDs, original rewards and historical ruleset fixtures. UI categories, horizontal resources, breakdowns and inspection mode/status/upgrade controls. Placeholder graphics retained.

Simulation uses analytical depletion boundaries and deterministic max-min fair sharing in dependency tiers. Tanning tier2 and healing tier3 preserve the production DAG. Survival gathering and water production remain independent of manufactured maintenance. All numerical tuning is experimental; see ../design/seed-022-balance.md.

Verification: `swift test --package-path Packages/GameCore` passes53tests; log /tmp/civilization-022-core.log. Original19tests retained, foundation18tests frozen,16new economy/migration/review tests. Reviewer found unsupported-save lookup crash and recipe research overflow; both fixed and regression-tested. Fresh-game real-cost traversal obtains all20types and all manufacturing outputs.

Build: `xcodebuild -project Civilization.xcodeproj -scheme Civilization -destination 'platform=iOS Simulator,id=EC995F2A-534A-4E57-A59C-0DE408729150' -derivedDataPath /tmp/civilization-derived CODE_SIGNING_ALLOWED=NO build` succeeded. XcodeBuildMCP build_run_sim with same args also succeeded for phone17ProMax26.5 and miniA17Pro18.6. Actual interactions: crafting category, toolmaker placement/charge/countdown/completion, horizontally scrolling to knowledge/culture, existing progress migrated on phone/tablet. Screenshots ../screenshots/seed-022.

Saves v3 preserve original v1/v2 backups before atomic replacement. Three dedicated migration tests verify byte-exact backup idempotency, four-resource v2 decoding, progress preservation, modes/levels/reserves roundtrip and corrupted-v3 rejection.

Limits: physical hardware/performance/signing unverified. Full manual inspection-mode/upgrade walkthrough unverified (core commands tested). Provisional placeholder silhouettes remain shared; no final art claim. Workforce, discovery and complete research/progression remain next approved milestones.
