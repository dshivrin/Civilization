# Seed 0.2.5 completion report

Completed 18 November 2026 under the approved continuous roadmap. The latest rendered planning brief was retrieved after browser access resumed: no superseding design decisions, exact tree and thresholds delegated as experimental, and 0.2.5 is the final authorized gameplay milestone.

## Implementation

Twenty configurable Stone Age technologies span five pillars. Basic housing, gathering, wood, stone and storage remain accessible; fourteen advanced building types have explicit research unlocks. The original Oral Tradition, Stone Tools and Social Order IDs and existing benefits remain; Stone Tools additionally unlocks toolmakers. Five persistent pillar achievements establish era readiness without a reset. All-content completion is not mandatory. Original seven onboarding goals and their one-time rewards remain distinct.

Save v5 migrates versions 1–4, retaining resources, buildings, timers, research, priorities, geography, reserves and rewards. Previously established building kinds retain construction knowledge without free technologies or production buffs. Completed goals are sticky even when stocks or net rates later fall, but permanent research/building/population/discovery witnesses must remain valid. Original v4 files receive a byte-exact backup before replacement.

Research UI includes costs, prerequisites, effects, unlocks, five-pillar filtering and expandable goal requirements. Onboarding completion no longer claims era completion. **Stone Age Ready** appears only after all five pillar achievements, with sandbox play retained. Graphics remain original procedural placeholders.

## Verification

- `swift test --package-path Packages/GameCore`: **79 tests passed**, including all 70 previous regressions against their historical fixtures and nine progression/migration/review tests. Log: `/tmp/civilization-025-core.log`.
- The complete real-cost playthrough visits all twenty building types and technologies, completes five pillars, saves/reloads and builds afterward. Optional export run also passed. See `docs/design/stone-age-playthrough.md`; logs `/tmp/civilization-playthrough.log`.
- Review found three defects: transient stock-based achievements differed online/offline; completed achievements lacked permanent history checks; inherited building unlocks lacked existing-building witnesses. All were reproduced, fixed and covered by passing regressions. Catch-up now visits increasing goal-resource thresholds and evaluates valid commands before spending.
- XcodeBuildMCP `build_run_sim(extraArgs:["CODE_SIGNING_ALLOWED=NO"])` succeeded on iPhone 17 Pro Max / iOS 26.5 , iPad mini A17 Pro / iOS 18.6 and iPad Pro 13-inch M4 / iOS 18.6. Deployment target remains 18.0; signing unchanged. Build logs are under the XcodeBuildMCP workspace log directory.
- Phone research filtering/purchase was exercised; Oral Tradition deducted 20 food/10 wood and displayed completion. Migrated tablet showed five-pillar progress without prematurely claiming readiness. The legitimate automated completed save was previewed on the isolated phone simulator, showing **STONE AGE READY** and continued build controls. Screenshots: `docs/screenshots/seed-025`.

## Outstanding issues and boundary

No known failing tests or unresolved confirmed review defects. Physical-device FPS, battery/thermal behavior, signing and human enjoyment remain unverified. The all-optional-content strategy took 156 simulated minutes, so knowledge pacing needs playtesting; it is not an optimized readiness route. Broad extraction radii, shared placeholder building silhouettes and provisional security effects remain deliberate limitations. Second-age geographical adequacy is unverified because that content is undefined.

Original art, second-age content, further cities, trade, combat and monetization remain outside this implementation. Stop at the approved 0.2.5 boundary and coordinate original graphics/human playtesting next.

## Coordination handoff

Completion report sent to City Design Coordination and rendered acceptance retrieved on 18 November: **Seed 0.2.5 — Accepted**. The reply confirms the authorized gameplay foundation is complete and explicitly says to remain stopped at this boundary. Acceptance is based on the report, not independent repository inspection. Research content and numerical balance remain experimental; graphics and human playtesting remain pending.
