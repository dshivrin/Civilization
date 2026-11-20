# GAME-LOOP-01 — Permanent Civic Center Evolution

Status: APPROVED by project owner, 2026-11-20
Priority: P0 — first-era gameplay
Execution: After current QA infrastructure work; reconcile with canonical design documents before implementation.

## Decision
The starting campfire is the permanent, upgradeable civic center of each settlement across every era. Its identity and upgrades persist as its architecture and functions evolve. It replaces redundant mandatory Storytelling Circle construction.

## Scope
1. Read DESIGN_BASELINE.md, DEVELOPMENT_ROADMAP.md, DESIGN_DECISIONS.md, DESIGN_SYNC.md, and relevant catalogs, chapter definitions, tests and save models. Reconcile approved decision into canonical documents and identify conflicts before coding.
2. Stone Age conceptual levels: L1 Campfire; L2 Gathering Place; L3 Council Circle. Later-era names, visuals, statistics and costs are provisional and require catalog/economy alignment.
3. One founding civic center per settlement. Allow relocation with existing placement rules without resetting progression; do not conflate settlement identity with fixed map coordinates.
4. Upgrade knowledge and culture production via balanced, research-gated levels. No arbitrary economy values: propose values for approval if not already established.
5. Replace chapter goals requiring duplicate storytelling structures with upgrades of the civic center. Review all seven Stone Age chapters for reachability, pacing, research dependencies, and guidance.
6. Locked upgrades must link directly to their prerequisite research and provide a return path to the civic center.
7. Migration must be non-destructive: preserve pre-existing campfires, Storytelling Circles, materials, placements, and completed chapter progress; propose explicit legacy handling rather than deleting or silently converting player assets.
8. Across era transitions, persist the same civic center entity and level history, while upgrading its appearance and capabilities.
9. Keep graphics/media work separate from gameplay. Check the Civilization-Media repository for existing assets and report whether Codex can access them.

## Verification
- New normal game starts with exactly one civic center.
- Upgrades work, persist across restart, and do not require duplicate storytelling buildings.
- Knowledge/culture rates and research locks are covered by tests.
- Relocation preserves identity and upgrades.
- Legacy saves retain all progress and assets; migration is idempotent.
- All seven Stone Age chapters remain completable; normal/developer saves stay isolated.
- Regression coverage for economy, research, building placement, save/load and era transition.
- Physical iPhone validation when available, without reset, uninstall, or overwriting existing saves.

## Related first-playthrough backlog (separate tasks)
- GAME-UX-01: Guide deep links to exact research/building/location, research search, keyboard dismissal, locked-building research action and return navigation.
- GAME-UX-02: Countdown formatting minutes+seconds, seconds only below one minute.
- GAME-LOOP-02: Meaningful optional decisions and activities during passive knowledge accumulation; avoid replacing idle waits with more timers.
- GAME-EXP-01: Destination-based exploration with frontier markers, previews and uncertain discoveries rather than only radial reveals.
- GAME-EXP-02: Seamless continuous fog and partially transparent next frontier.
These related tasks are not automatically authorized for implementation by this file.

## Delivery
Finish existing QA infrastructure work first. Commit and push reconciled specs, implementation and tests. Report concise commit SHAs, test outcomes, migration behavior, unresolved decisions and next action. Do not change signing or overwrite user saves.
