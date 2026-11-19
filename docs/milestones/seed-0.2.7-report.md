# Seed 0.2.7 — complete Stone Age progression

Implemented 18–19 November 2026 under Dima's direct 0.2.7 authorization. Physical iPhone feedback iteration 1 is user-approved. The new completion decision supersedes the earlier partial-development rule. No balance values, terrain identity, gameplay IDs, signing/account settings, iOS18 deployment floor or landscape support were changed.

## Original seven goals — inventory before redesign

Retrieved from `Types.swift` (`Goal`), `GameEngine.evaluateGoals`, and the bundled `seed.json`; reported in implementation chat before chapter/UI replacement. All seven were implemented and evaluated independently, including out-of-order completion.

| Saved ID | Existing title | Condition | Reward |
|---|---|---|---|
| gatheringShelter | Build a gathering shelter | At least one operational gathering shelter | +10 wood once |
| woodcutter | Build a woodcutter | At least one operational woodcutter | +10 wood once |
| hut | Build a hut | At least one operational hut | +10 wood once |
| stoneGatherer | Build a stone gatherer | At least one operational stone gatherer | +10 wood once |
| oralTradition | Research Oral Tradition | researchedOralTradition true | None |
| storytellingCircle | Build a storytelling circle | At least one operational storytelling circle | +10 wood once |
| knowledge | Accumulate knowledge | At least 15 knowledge currently stored | None |

Construction rewards use configurable `constructionGoalWoodReward`, capped by wood storage. The knowledge threshold uses `knowledgeGoalUnits`. Completion is stored in `completedGoals`; completed records are never awarded again. Construction sites do not count. These enums, evaluator, amounts and saved history remain intact beneath the redesigned journey.

## Implementation

### Complete era requirements

`StoneAgeJourney.swift` derives building kinds and technology IDs from the active catalogs, requiring every type operational and every technology researched. Current totals are 20/20, not hardcoded requirements. Discovery requires at least one revealed, identified source of each `depositResource` used by catalog extraction recipes: wood, water, stone, flint, clay and animal hides. Future copper has no current catalog resource and is excluded; no full-map discovery or future identification is needed.

All five existing pillar achievements remain required, including tools/leather/pottery stocks, ten inhabitants with sustainable food/water, culture and the 600-tile security threshold. Pillars remain sticky. New readiness is set only when every checklist item passes. Previously true `stoneAgeCompleted` is retained even if the expanded checklist is incomplete; Research and journey screens explain the historical record. Save v5 and its normal state schema remain unchanged. An optional configuration switch enables the strict rule in current seed JSON while preserving older rulesets. The full 0.2.6 config is frozen under test Fixtures; historical fixtures remain unchanged. Two historical completion tests explicitly exercise their original five-pillar contract.

### Seven journey chapters

1. Founding a settlement: gathering shelter, woodcutter, hut, Oral Tradition.
2. Mastering nature: stone gatherer, hunting lodge, fishing shelter, Hunting, Fishing, Natural Knowledge.
3. Establishing agriculture: farm, animal pen, Cultivation, Animal Domestication, Food Preservation.
4. Developing craftsmanship: toolmaker, tannery, pottery workshop, storehouse, Stone Tools, Leatherworking, Pottery, Construction, Basketry.
5. Building a society: storytelling circle, shrine, healer's hut, burial ground, Social Order, Rituals, Permanent Settlement, Herbal Medicine, Burial Traditions and the original 15-knowledge achievement.
6. Exploring and protecting: scout camp, watchtower, palisade, Exploration, Surveillance, Fortification.
7. Completing the Stone Age: complete catalog buildings/research, required resources and all five pillars.

Names/groupings are provisional implementation choices. All chapters evaluate existing permanent history, so objectives done ahead of time count immediately. No new transient stock thresholds or rewards were introduced; the original knowledge and pillar ledgers supply sticky credit. This avoids another save migration or duplicate reward ledger. Goals start collapsed with chapter and active-objective counts; expansion shows the next objective and opens a full-screen scrollable chapter checklist. No second-age transition exists.

### Developer interface

The selected source scenario shows a checkmark and accessibility selection trait. A top-of-form source label and Original scenario / Modified developer state distinguish the disposable fixture from its ongoing simulation. Debug-only envelope metadata preserves the original state for comparison across resume; wall-clock rebasing alone is excluded. Simulation/resource/population changes count as modifications. Older developer saves without original metadata display comparison unavailable rather than inventing an original state. Normal and developer files remain isolated; all developer APIs and UI compile out of Release.

### Building catalog

Full-screen adaptive menu follows Research with shared `DevelopmentCategoryButton` and `DevelopmentCardStyle`. Tablet uses a category sidebar; phone uses horizontal categories. Cards show replaceable SF Symbol icons, descriptions from JSON, costs, prerequisites, recipe outputs and inputs per minute, housing/storage, footprint, workers, duration, lock/availability and constructed counts. Category and overall type progress count operational buildings. Search and explicit dismissal remain available. Campfire is a visible fixed/preplaced entry and cannot be constructed. Choosing another unlocked type dismisses the catalog and calls the unchanged `session.choose` drag-placement path. No renderer or gesture production code changed.

## Verification

- `swift test --package-path Packages/GameCore`: **106 passed** (all original 100 regressions retained plus six new tests). Final log `/tmp/civilization-027-debug-final.log`.
- `swift test --package-path Packages/GameCore -c release`: **96 passed** (all original 92 retained plus four new non-Debug tests). Final log `/tmp/civilization-027-release-final.log`.
- `python3 scripts/verify-developer-release.py`: four probes pass, confirming developer APIs exist in Debug and fail to typecheck in Release. Log `/tmp/civilization-027-release-api-final.log`.
- New coverage: complete real-cost era, operational rather than under-construction catalog types, independent rejection of missing research/building/discovery, catalog-derived totals, future-deposit exclusion, all twenty research objectives grouped, out-of-order hut credit, original reward persistence/idempotency, old readiness under the new rule, and developer source/mutation/resume/normal-mode selection.
- Updated real-cost playthrough completes at **9240 simulated seconds (154 minutes)** with 15 inhabitants, 23 instances covering all twenty types, all twenty technologies, all seven chapters and five pillars, and **650/768 discovered tiles**. Save/reload plus a subsequent hut preserves history. No debug grants. Export `/tmp/civilization-027-playthrough.json`; see `docs/design/stone-age-playthrough.md`. Serial strategy demonstrates reachability; human pacing remains unverified.
- Debug builds/runs succeed on iPhone 17 Pro Max / iOS26.5, iPad mini A17 Pro / iOS18.6 and iPad Pro 13-inch M4 / iOS18.6. Release simulator app builds successfully; log `/tmp/civilization-027-release-build.log`.
- Three UI tests cover immediate catalog selection/dismissal/drag placement, long-press relocation followed by pan/pinch with stable position, scenario selection, collapsed/expanded goals, full-screen chapter entry, category filtering and locked/available states. Final per-device results are below.
- Independent read-only review found no concrete correctness defects in completion/history, reward handling, developer isolation or catalog/placement integration. Live visual QA additionally prompted moving developer summary above the fold, full-screen chapter detail, readable search colors and dark text on yellow actions. An iOS18 inherited accessibility identifier was reproduced and fixed with an explicit child-containing accessibility group.

## Physical device and visual proof

First signed update installed successfully. Pre-update normal/developer directory backed up to `/tmp/civilization-iphone-before-027-20261119`, normal save validated through production SaveStore/GameEngine as v5, four buildings, map `river-clearing-v1`. Post-install copy at `/tmp/civilization-iphone-after-027-20261119`: both files byte-identical. Normal SHA-256 `28a6259eab9a3882f2a01d5de6c86f3034fdcffc5e74d543a2abc119a98f983b`.

Final chapter-detail and readiness UI changes are included in the signed refresh recorded below. No uninstall, normal-save reset, signing-team/account change or device-security change is used. XCTest attachment screenshots on these runtimes are misframed; actual landscape captures use native simulator framebuffer screenshots at asserted UI stages. Evidence is under `docs/screenshots/seed-027`, with final captures explicitly named `phone-final-*` and `mini-final-*`.

## Graphics assessment and boundary

See `docs/design/graphics-feasibility-03.md`: existing renderer analysis, baked 3D-to-2D sprites, real-time RealityKit/Metal alternatives, terrain textures/meshes, model/sprite formats, thumbnail/icon pipelines, asset reuse/historical variants and hardware performance considerations. Recommendation is a separately approved small comparison prototype, not a production renderer/art decision. No original/final assets were produced or inserted. Stop after this report/assessment. Second age, additional cities, warfare, purchases, new gameplay milestones and renderer replacement remain outside authorization.

## Limits and decisions

No physical FPS, thermals, battery or human enjoyment claims. Requested A15/M1 physical tablets were not available; A17/M4 simulator substitutes are not hardware benchmarks. Balancing remains experimental; no numerical tuning was changed. No Git repository exists in this checkout, so no commits or worktree were fabricated. The user-requested continuity is recorded in the plan and active goal; platform usage limits cannot be bypassed or guaranteed to resume at a fixed time.

## Final deployment result — 19 November 2026

Final signed Debug iOS build succeeds (`/tmp/civilization-027-signed-final.log`), as does the final Release simulator build (`/tmp/civilization-027-release-build.log`). Installed on Dima's connected iPhone 17 Pro Max without uninstalling or changing account/signing settings. Fresh backup `/tmp/civilization-iphone-before-027-final-20261119` validated through production SaveStore/GameEngine; normal v5 save has four buildings. Post-install directory `/tmp/civilization-iphone-after-027-final-20261119`: **both normal and developer files byte-for-byte identical**. Normal SHA-256 remains `28a6259eab9a3882f2a01d5de6c86f3034fdcffc5e74d543a2abc119a98f983b`. Install log `/tmp/civilization-027-final-install.log`. No hardware performance or new human playtest is claimed.

Final phone UI suite: **3/3 pass**, including the readiness detail sheet, `/tmp/civilization-027-phone-verified.xcresult`. Pro tablet UI suite: **3/3 pass**, `/tmp/civilization-027-pro-final.xcresult`. Mini tablet final consolidated UI suite: **3/3 pass**, `/tmp/civilization-027-mini-verified.xcresult`, including readiness sheet verification. iOS18 tests use map reinspection after gestures; the original phone tests continue to use the building picker. The one initially failing Done query was scoped to the readiness navigation bar because the underlying research screen also exposes Done; this was a test locator ambiguity, not a product control failure.

Final status: Seed 0.2.7 implementation, regression/phone/tablet verification, signed installation with save preservation, milestone records and proposal-only graphics assessment complete. No further implementation is authorized by this report.

## Coordination reporting completed

On 19 November, at Dima's explicit request, a concise completion summary and updated-roadmap request were submitted to ChatGPT City Design Coordination through the chat connector. Automatic approval review rejected the extensive device/internal payload; a reduced summary without device identifiers, save details or internal paths was accepted. The reply was retrieved: 0.2.7 accepted based on report, project stages now 5/7, next 0.3.1–0.3.2 visual identity/pipeline brief PROPOSED pending Dima. Exact roadmap and factual annotations are in `docs/design/roadmap-after-027.md`. No further implementation was started.
