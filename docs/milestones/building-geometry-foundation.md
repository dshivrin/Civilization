# Building geometry foundation — delivery report

19 November 2026. Dima authorized the bounded next geometry task after the recovered ChatGPT reply. Baseline0b6b738; authorization/spec/plan committed1444ca6 before implementation. Current first-era-review branch retained; no merge or remote. This report covers the foundation, not activation of the proposed larger-building table.

## Delivered behavior

Pure Swift BuildingFootprint and BuildingOrientation now describe rectangles and four logical quarter turns. Catalogs may explicitly allow orientations; the default is the original north orientation. **Current bundled dimensions and all JSON remain unchanged:** campfire/palisade1×1, other18types2×2. No player-facing Rotate control, art rotation or new orientation assets are enabled.

Construction validates a chosen orientation and the entire occupied rectangle before charging, then captures the unrotated catalog dimensions and orientation on the new instance. Occupancy/hit lookup, relocation, save validation, previews and inspection use the same resolver. Relocation preserves captured dimensions and defaults to the saved orientation; explicit turns validate their full target, excluding only their own existing footprint. IDs, resources, timers, modes, priority, level, achievements and other state remain intact. Campfire stays unique, immovable1×1/north.

SpriteKit anchors use both logical axes; square anchors are unchanged. Depth uses the far footprint corner, overlay/hit fallback use occupied tiles, and render-cache signatures include size/orientation. Sprites remain upright, with current replaceable artwork. Scene gestures, map/projection and economy geographic/deposit distance semantics are unchanged.

## Save compatibility boundary

Optional per-instance fields keep the save envelope atv5. Legacy missing fields resolve to the current catalog with north orientation and are not eagerly rewritten; existing supportedv1–v5migration/reward/readiness tests remain intact. Snapshot-bearing new buildings retain their exact occupied dimensions through reload and relocation even if catalog dimensions later change.

**This is not a complete legacy-size conversion policy.** Nil-field buildings still derive size from their catalog. Before activating different catalog sizes, a separately reconciled migration must preserve those existing layouts. No auto-enlargement, auto-relocation, demolition or implicit conversion is implemented. A new catalog's optional orientation list controls new construction and changed orientations; preserving an established orientation is allowed. Captured sizes are checked for positive/map-bounded dimensions before tile enumeration; invalid origin/terrain/discovery/overlap fails validation. New client fields are additive; this is not a promise of future-era compatibility with old clients.

## Verification

The baseline126 Debug tests passed. First7new tests failed for the missing geometry API, then passed. Session-preview test failed for missing previewFootprint, then passed. Independent read-only review found no actionable correctness/save defect; it suggested a hidden-edge rotation case, now covered with an undiscovered tile present only in the rotated footprint. The regression verifies atomic rejection and successful rotation after revealing that tile.

Final135 Debug / 124 Release tests and5 Release developer-API exclusion probes pass, preserving historical regressions and the complete real-cost first-era routes. Current guided routes remain104.1/121.1simulated minutes,48actions, all20types/20technologies/7chapters/5pillars and650/768tiles. Tests are synthetic evidence, not human pacing acceptance.

Nine geometry-focused tests cover axis swaps/anchors, exact occupied tiles/costs, out-of-bounds/overlap/orientation rejection, relocation identity/atomicity, captured-size persistence across a changed catalog, unchanged legacy nil fields, corrupt saved dimensions/campfire geometry, catalog orientation validation, session preview/cancel and the newly covered hidden edge. The rectangular fixtures alter definitions only for tests; production dimensions are untouched.

All 9 existing UI cases pass on phone17ProMax/iOS26.5, miniA17Pro/iOS18.6 and Pro13M4/iOS18.6, including compact-card alignment/deficits, selected developer scenario, catalog→drag, long-press relocation/pan/pinch, fresh guided construction, navigation without purchase, earned completion and reserve→supplier→drag. No live Rotate button is claimed tested. Phone174.496s, mini163.115s and Pro163.469s, zero failures. Result bundles: /tmp/civilization-geometry-{phone,mini,pro}.xcresult. Native [placement capture](../screenshots/first-era-review/geometry-phone-guided-placement.png) was inspected: existing2×2anchor and controls remain aligned. [Next-step start](../screenshots/first-era-review/geometry-phone-fresh-next-step.png) and [first construction complete](../screenshots/first-era-review/geometry-phone-first-building-complete.png) are retained; the capture test passed48.284s.

Signed Debug iPhone and Release simulator builds succeed with unchanged signing/deployment settings; signature verification succeeds. Release excludes Debug test-save import keys and developer APIs. Catalog/art diff against baseline is empty. Physical iPhone again reports unavailable: no fresh backup/install or hardware performance claim. Earlier dense~48FPSsample/final-cache unmeasured limitation remains. No user saves were altered by these isolated checks.

Commands/logs:

```sh
swift test --package-path Packages/GameCore
swift test --package-path Packages/GameCore -c release
python3 scripts/verify-developer-release.py
xcodebuild -project Civilization.xcodeproj -scheme Civilization \
  -destination 'platform=iOS Simulator,id=<PROFILE-ID>' \
  -only-testing:CivilizationUITests/RelocationUITests CODE_SIGNING_ALLOWED=NO test
xcodebuild -project Civilization.xcodeproj -scheme Civilization -configuration Debug \
  -destination 'generic/platform=iOS' -derivedDataPath /tmp/civilization-first-era-device build
xcodebuild -project Civilization.xcodeproj -scheme Civilization -configuration Release \
  -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/civilization-first-era-release CODE_SIGNING_ALLOWED=NO build
```

Host logs: /tmp/civilization-geometry-{baseline,red,focused,preview-red,preview-green,edge,debug-final,release-final,release-probes,ui-build,phone,mini,pro,signed-build,release-build,devices}.log. One intermediate Release build overlapped creation of the not-yet-implemented preview API test and failed at compilation; the final complete Release run supersedes it. No failing product regression is omitted.

## Remaining staged work

Exact building sizes, legacy nil-field conversion policy, live Rotate UX and orientation art/anchors need the next bounded specification before activation. Decorative roads and NPCs are not implemented by this foundation; no new icons/images, media imports, audio, monuments, eras, cities, trade, warfare, monetization or backend. First-era human review and physical save-safe deployment retain priority. Q-PLAY-1historical insolvency recovery remains separate and unapproved. Media repository unchanged.

Implementation commits:1444ca6(authority/spec/plan),70418ea(core/session/tests),d0a3284(rendering/UI consumers), followed by the separately committed delivery documentation/screenshots. Working branch retained for Dima’s review; no merge/push.
