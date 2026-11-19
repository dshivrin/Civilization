# Seed 0.2.6 report

18 November 2026. Implemented Dima's direct developer-tools/UX brief. Seed 0.2.5 gameplay and bundled production balance remain the baseline; placeholders remain. The later user message says the UI is sufficient for this stage and asks to fetch the next ChatGPT instructions after finishing.

## Submilestone A — isolated developer tools

Debug-only wrench opens three deterministic valid settlements: Early (3 inhabitants/basic buildings/no research), Developed (24, partial research/discovery, producing manufacturing chains and staffing priorities), Late (60, positive food/water, 19 technologies/full discovery/four completed pillars). Late's remaining objective is Fortification plus Palisade. Real engine placements/upgrades construct the fixtures; normal validation and save/load checks verify references, occupancy, research closure, capacities and achievement witnesses.

Separate `.developer` sibling save uses v5 state with debug-only scenario metadata for reliable reset after relaunch. Normal saves remain on their original path/schema; corrupt normal files stay protected across mode switches. Explicit scenario reset archives damaged developer bytes before replacing them. Relaunch starts normal; debug resume is explicit and has no offline catch-up. Normal play resumes with ordinary capped elapsed time after leaving debug.

Controls include load/reset/resume/return, capped resource grants, housing-limited population, dependency-complete individual/all research grants, reveal, +1 minute/+1 hour, pause and 1×/2×/5×/10× speed. Fast construction is exactly three simulated seconds for future debug buildings, unaffected by research modifiers. The catalog displays the engine's actual duration. Settings are transient, never production balance. At 1× three simulated seconds equal three wall seconds; faster simulation scales all mechanics. All controls and commands compile out of Release.

## Submilestone B — research and usability

Dedicated full-screen research on phone and tablet. Phones use horizontal category navigation; tablets use a category rail and adaptive multi-column cards. Each category shows completed/total research; cards display descriptions, cost versus stored resources, prerequisites, building unlocks, numerical effects, and distinct researched/available/unaffordable/prerequisite-locked status. Category and per-category scroll context are retained during navigation. Research completion and Stone Age readiness are separate; readiness opens all five goal requirements.

Map opens unobstructed by the catalog. Added catalog search, explicit close actions, readable negative resource rates and scroll cue, compact goal detail on phone, scrollable placement and top-of-inspection dismissal. Existing recipe/worker/upgrade/exploration details remain. Current gesture model is preserved: map drag/pinch, tap footprint/inspection and precision arrows. There was no building-object drag/drop/relocation implementation to redesign.

Before/after evidence is in `docs/screenshots/seed-026`. Phone/tablet research “before” files were copied from verified Seed 0.2.5 baseline screenshots; tablet HUD-before was freshly captured before implementation. After images cover phone research/developer controls/invalid placement and both tablet research layouts.

## Submilestone C — verification and handoff

- `swift test --package-path Packages/GameCore`: **88 passed**: all 79 historical regressions plus nine developer tests. Final log `/tmp/civilization-026-tests.log`. Includes scenario round trips, actual late final objective, dependencies, cap/housing limits, exact construction boundary, normal-byte isolation, corrupt normal/developer preservation, speed/pause/background and resumed reset identity.
- `swift test --package-path Packages/GameCore -c release`: **80 passed**: all 79 plus normal construction verification. Log `/tmp/civilization-026-release-tests.log`.
- `python3 scripts/verify-developer-release.py`: four compiler probes pass. Scenario factory, construction override, session scenario loader and resource-grant APIs exist in Debug and fail to compile in Release. Log `/tmp/civilization-026-release-api.log`.
- XcodeBuildMCP Debug build/run succeeds on iPhone 17 Pro Max / iOS 26.5, mini A17 Pro and Pro 13-inch M4 / iOS 18.6. Release simulator compilation succeeds. Logs under `~/Library/Developer/XcodeBuildMCP/workspaces/Civilazation-42670ca08da1/logs/`.
- Unsigned physical-device build succeeds: `xcodebuild -project Civilization.xcodeproj -scheme Civilization -configuration Debug -sdk iphoneos -destination 'generic/platform=iOS' -derivedDataPath /tmp/civilization-026-device CODE_SIGNING_ALLOWED=NO build`. Log `/tmp/civilization-026-device-build.log`. iOS target remains 18.0; landscape, universal and signing/account settings retained.
- Simulator interactions: research open/dismiss/category navigation, iPad Natural Knowledge purchase (overall count 3→4), debug Developed fixture (24 population), fast toggle, hut preview, nudge into occupied land/disabled confirmation, valid placement and observed 2-second countdown then completion. Simulator tap helper failed to deliver taps; explicit touch-down/up worked. Pinch/multitouch not claimed verified.
- Independent read-only review found resumed scenario reset incorrectly selected Early. Reproduced with failing regression and external probe, fixed by debug metadata. Recheck confirms Late → resume → reset retains 60 inhabitants/28 buildings. Fixture water deficit was corrected with a third debug fishing shelter; net water +10.82/min, food +55.2/min at 60. Normal JSON balance untouched. A raw-byte isolation regression also eliminated unnecessary normal writes at a repeated timestamp.

Physical iPhone 17 Pro Max is connected. No project development team is configured; physical installation remains pending Dima's signing selection/device confirmations. Requested physical iPads were not connected. See `docs/design/device-testing.md` for concrete Xcode steps and touch checklist, and `docs/design/approved-feature-audit-026.md` for approved gaps separated from proposed/deferred work. Physical FPS, thermals/battery, gestures and enjoyment remain unverified. No original art, extra age/city, warfare or monetization was added. No Git metadata exists in this workspace; no commits/worktrees/pushes were created.

## Next ChatGPT brief
Retrieval attempted after implementation/verification. In-app ChatGPT is signed out; native Chrome access timed out. Next instructions remain unread, and external coordination acceptance is not claimed. Login handoff is open.
