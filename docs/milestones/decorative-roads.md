# Decorative roads — milestone report

19 November 2026. Dima authorized reporting geometry and moving on. Geometry baselineed23e2e remains preserved; road scope/choices were committed2bd4997 before implementation. ChatGPT agrees roads can proceed without activating larger buildings; its [brief](../design/sources/2026-11-19-decorative-road-brief.md) was reconciled in6659754. Core/session implementation is4ed64ac. This is a bounded decorative-road delivery, not NPC or economy implementation.

## Player behavior

A dedicated Roads entry sits outside the twenty-building catalog. Trodden path, dirt road and primitive stone surfaces are free, have no maintenance/research requirement and never contribute to era objectives. Draw adds missing tiles; Replace changes existing surfaces only; Remove erases roads. Materials stay per tile and connect across material boundaries. Adjacent strokes form wider joined surfaces. Drafts show their tile count, validity and an explicit Confirm/Cancel workflow; the panel can collapse to expose more map. No resource is charged for roads; ordinary production/consumption continues while editing.

One-finger drag in road mode previews a deterministic four-connected path between samples; normal map pan returns on closing Roads. Tap also previews. A recognized pinch clears pending tiles and zooms without applying them. Existing building catalog drag, grab offsets, relocation hold, map pan and pinch remain supported. Opening Build/Research/journey, changing tools, backgrounding or switching developer scenarios discards the nonpersistent draft. Clear discards the draft while keeping the selected tool. Confirm clears the draft and leaves the tool ready for another stroke.

Roads need discovered open grass or clearing. Water, forest, hills, buildings and hidden land are protected; no bridges. Construction and relocation require explicit road removal first. **Any invalid tile rejects the entire preview stroke**, with an explanation; no partial hidden edits. Draw/Replace/Remove filtering applies only to whether valid tiles already contain roads.

These operational defaults are documented Codex choices under Dima's stage authorization. ChatGPT proposed skipping invalid tiles and committing on release; those interaction suggestions were not adopted. Its headings do not become independent human approval. First-era player understanding/completion remains the priority; roads are optional.

## Core, saves and rendering

RoadTile/RoadStyle are separate from building/catalog/reward IDs. Optional GameState.roads preserves missing fields asnil and thev5envelope. Old saves load without roads and are not eagerly normalized. Commands validate a complete bounded stroke before changing sorted tile/style data; repeated same-style draws and empty erases are idempotent. Malformed, duplicate, hidden, out-of-map or overlapping road saves are rejected. No goal evaluation, production, workforce, consumption, research, readiness or resource mutation occurs inside the road command.

Masks derive from cardinal occupancy: north(y−1)=1,east=2,south=4,west=8; no diagonal connection or persisted masks. Mixed materials use the same topology. Dirty rendering covers changed tiles plus four neighbors, rather than rebuilding terrain/buildings. Empty updates do nothing. A bounded pointer sample is separate from the deduplicated draft so backtracking cannot invent cells outside the sampled route.

Original replaceable procedural surfaces use sixteen cached compound paths and three fill materials (48logical combinations), one shape node per committed tile. Broad central ground with full shared-edge joins makes parallel tiles visually contiguous. Preview nodes are separate, cached and hidden outside known/map-bounded tiles. No external texture/image has been imported and no final asset acceptance is claimed. [Procedural provenance](../art/roads-provenance.json) records source hash/projection/anchor/status; the separate media repository is unchanged.

## Verification evidence

Final core:148 Debug / 137 Release tests, preserving all 135 Debug / 124 Release geometry baseline regressions;5 Release API exclusion probes pass. Thirteen new core/session tests cover16masks, bounded gap-free traversal, atomic rejection and idempotency, protected/fog terrain, mixed styles/remove/reload, nil legacy saves/corrupt data, road/building conflicts, local renderer invalidation, draft/save/background isolation, independent editing modes, bounded cancellation, reviewed backtracking and a complete ordinary-cost era with roads.

The paid recommendation-following route with two persistent mixed-style roads still completes in7263seconds, all building/research/chapter/pillar/discovery requirements; no grants or balance changes. Existing no-road routes stay6243.5/7263seconds. Scripts prove reachability, not human enjoyment or optimal strategy. No catalog/config JSON, numerical balance, existing raster assets or geography changed.

Final post-footer full13UI suites pass on phone17ProMax/iOS26.5 (220.142s), miniA17Pro/iOS18.6 (206.723s) and Pro13M4/iOS18.6 (207.684s), zero failures. These include all nine prior scenarios/catalog/dense-art/placement/guidance/completion/regression cases plus road draw→replace→remove/cancel→building placement, real pinch draft cancellation, chapter-navigation cancellation and dense mixed-surface rendering. The first dense fixture had221legal tiles/masks1–15; the final targeted capture fixture additionally removes a legal neighboring ring to assert/render all16masks, including an isolated tile. The refined217-tile fixture asserts masks0–15and passed targeted checks/capture on all three profiles. Subsequent native phone inspection reproduced a partially clipped Confirm button: hittability alone passed, but a full-target-in-screen assertion failed. Header and action footer are now fixed outside scrolling details; final post-fix suites include the complete target-frame assertion and all-mask fixture.

A fresh independent read-only review found two P2issues: using the last deduplicated cell rather than the last pointer sample, and retaining a road draft through the full journey. Both were reproduced by failing tests, fixed and verified. No additional blocking domain/save/render defect was reported. Only one final review/fix pass was used.

Early phone pinch automation at1.1scale did not deliver recognizer callbacks; native capture confirmed the collapsed panel/map and no road commit. The iPad runtime delivered that gesture. A clear1.8scale gesture in supported landscapeRight delivered the callback and passed on phone. Temporary recognizer diagnostics and failed-path screenshot were removed. This is an automation threshold/delivery finding, not a claim that tiny physical pinches were manually verified. Physical touch comfort/multitouch still needs device testing.

Signed Debug iPhone and Release simulator builds succeed with unchanged signing/iOS18/landscape settings; signature verification succeeds. The phone reconnected during final verification. Fresh ApplicationSupport backup at /tmp/civilization-iphone-before-roads-20261119-1835 was production-validated before installing: normal save4buildings, developer save28buildings, both mapriver-clearing-v1,0roads. Signed update installed successfully. Post-install copy /tmp/civilization-iphone-after-roads-20261119-1835 was revalidated; both files are byte-identical **before launch**. Normal SHA256f179f4d20531ce4dc59f5d0d169f8cb5db1f604414ac6872c57f4acd51a06cc8, developer3e68799f3b06d4798dbc99c13676cdf3fe6edf67d53681f0cbc5003402a066b5. [Comparison metadata](../testing/decorative-roads/device-save-preservation.json) retains the preservation result without save contents. Normal launch succeeded and the game process remained running. Ordinary offline catch-up after launch may legitimately update balances/time; no post-launch byte-identity claim. No physical road usability, FPS, battery or thermal benchmark is claimed.

## Rendering assessment

An opt-in simulator mini sample of the221-road fixture recorded263scene nodes,64.8MiBphysical footprint,57.7FPSand17.29ms95thpercentile frame interval over275samples. Three simulator suites were running concurrently; this is not a controlled device benchmark. The final217-road/all16mask mini fixture recorded259scene nodes,62.0–66.0MiB,58.0–59.4FPS and16.82–17.90ms95thpercentile intervals over three276–297-frame windows. Capture/profile tests were concurrent; no paired physical comparison is implied.

Raw [simulator rendering samples](../testing/decorative-roads/rendering-simulator.json) retain fixture/environment/concurrency limits.

The theoretical scene bound is one committed shape per map tile (768maximum) plus at most769draft samples, filtered to map bounds/discovery before drawing. Only16path shapes are cached; no unbounded per-frame path generation. There is no new actor simulation. The simulator sample is an absolute fixture measurement, not a paired hardware benchmark or proof of60FPS/battery/thermal behavior. Earlier dense~48FPSphysical sample and final-cache unmeasured limitation remain documented.

## Reproducible checks and artifacts

```sh
swift test --package-path Packages/GameCore
swift test --package-path Packages/GameCore -c release
python3 scripts/verify-developer-release.py
xcodebuild -project Civilization.xcodeproj -scheme Civilization \
  -destination 'platform=iOS Simulator,id=<PROFILE-ID>' \
  -only-testing:CivilizationUITests/RelocationUITests CODE_SIGNING_ALLOWED=NO test
```

Core logs:/tmp/civilization-roads-{red,core-green,session-red,session-green,debug-final,release-final,backtrack-red,release-probes}.log. Final UI:/tmp/civilization-roads-pinned-{phone,mini,pro}.{log,xcresult}. Device/Release builds:/tmp/civilization-roads-{signed-build,release-build,devices}.log. Intermediate red UI and gesture-diagnosis result bundles are retained under/tmp; only successful native captures enter the review gallery. Core tests first failed for missing APIs; a fixture initially disabled exploration while retaining its dependent progression configuration, corrected only in the test fixture. One Swift lazy closure needed explicitself; the final complete suites supersede those intermediate compile attempts.

Successful final native captures: [phone preview](../screenshots/first-era-review/roads-pinned-phone-road-preview.png), [trodden road](../screenshots/first-era-review/roads-pinned-phone-road-trodden.png), [mixed stone](../screenshots/first-era-review/roads-pinned-phone-road-mixed-stone.png), [all three surfaces with visible actions](../screenshots/first-era-review/roads-pinned-phone-road-three-styles.png), and [tablet all16mask fixture](../screenshots/first-era-review/roads-pinned-mini-road-dense.png). Both final capture tests pass; native views were inspected. Superseded pre-footer images were discarded.

## Staged boundaries

No NPCs, larger footprint activation, live rotation controls, new building/research/goal type, final art, audio, monuments, subsequent ages/cities, trade, warfare, monetization, backend or renderer rewrite. Exact building sizes/legacy nil-field conversion and historical insolvency recoveryQ-PLAY-1remain separate decisions. Human first-era acceptance and physical gesture/performance review remain pending; save-safe deployment is complete. Next Living City/media/performance stage needs its own bounded brief and measured device budget; this report does not automatically launch it.

Implementation commits:2bd4997(scope),6659754(returned-brief reconciliation),4ed64ac(core/session/tests),24fd575(native rendering/tools/UI). Documentation/provenance/captures committed separately; branch retained for review.
