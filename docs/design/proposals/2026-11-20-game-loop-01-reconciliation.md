# GAME-LOOP-01 reconciliation and approval questions

20 November 2026. Authority: owner-approved [plan](../../../plans/GAME-LOOP-01.md), commit `661db65`, and direct Start GAME-LOOP-01 instruction. Fetched personal `dshivrin/Civilization` origin/first-era-review; local and remote both `b87ca0b`. Implementation is blocked on the explicit product decisions below, not engineering permission. No product code or player saves changed.

## Approved supersessions

The same founding `campfire` entity becomes the permanent civic center, with Stone Age L1 Campfire, L2 Gathering Place and L3 Council Circle. Its ID, position, upgrades and history persist. Relocation uses existing placement rules. This supersedes FP-002 immovability and the fixed-anchor restriction in MOVE-003; uniqueness and the existing 1×1 footprint remain. Historical fixed-campfire passages in canonical documents are superseded for this task.

Mandatory duplicate Storytelling Circle construction is replaced by civic upgrades. This supersedes the mandatory Storytelling Circle portions of chapter 5, cultureFoundation and full-catalog readiness. It does not authorize deleting existing circles, changing unrelated building requirements, or other GAME-UX/LOOP/EXP backlog. Existing earned rewards, pillar achievements and era readiness remain protected. No second-era gameplay is authorized: current completion is Bronze Age readiness, with no actual era-transition command to test.

## Decisions requiring owner approval

The plan explicitly requires approval of unestablished economy values and an explicit legacy proposal. A repository search found no civic level table or approved dependency mapping beyond the conceptual names. The following is a concrete proposal, NOT approved tuning:

| Upgrade | Prerequisite research | Paid cost | Total cultural output before technology/staffing modifiers |
|---|---|---|---|
| L1 → L2 Gathering Place | Oral Tradition | 10 food, 20 wood, 10 stone | 3 knowledge/min, 2 culture/min |
| L2 → L3 Council Circle | Social Order | 10 wood, 5 stone | 3.75 knowledge/min, 2.5 culture/min |

L2 uses the existing Storytelling Circle construction cost/output. L3 uses its existing first upgrade cost and 25% output increment, rather than introducing unrelated balance numbers. Both upgrades would be instantaneous, matching existing upgrade transactions. Proposal: one shared worker for cultural output at L2/L3, as for an existing circle; food 2/min, water 3/min and housing 5 remain independent of cultural staffing and level. Existing Natural Knowledge/Rituals bonuses apply normally. This split is necessary to avoid the generic level multiplier silently increasing housing or reducing founding provisions when workers are scarce. These civic mechanics and gates need approval even though their numerical sources exist elsewhere.

Proposed chapter mapping: L2 in chapter 1 after Oral Tradition, supplying knowledge before chapter 2's Natural Knowledge; L3 replaces the chapter 5 circle objective after Social Order. Culture pillar uses L3 plus the existing shrine/culture thresholds. Full-catalog readiness excludes the optional Storytelling Circle and explicitly requires L3. Chapters 2–4 and 6 retain their existing requirements; chapter 7 reflects the new readiness checklist. All existing technologies remain required; no new research is proposed.

Proposed legacy policy: retain each building/ID/geometry/level/timer/production mode, every resource amount, research, roads, discoveries, deposits and reward/achievement history. Existing civic center starts at its recorded level (ordinary old saves L1); no automatic free upgrade or circle conversion. Existing Storytelling Circles remain operational and available as optional additional producers. Snapshot completed old chapter/objective credit before changing requirements; retain earned chapter/pillar/era credit without requiring a repurchase. Missing new objectives remain payable only where they do not revoke already-earned completion. Repeated migration must not grant rewards or change assets. Preserve the old storytelling reward ID and its earned state; proposal for new games: award that same one-time construction reward on L2, without rewarding again if an optional circle is later built. This reward substitution and optional-circle availability require approval.

Approve the economy/research/chapter mapping and legacy/reward policy above, or provide changes, before implementation. There is no authorized catalog table that resolves these choices automatically.

## Evidence and implementation impact

- `Resources/seed.json`: campfire has no upgradeCost, zero workers, food/water provisions; circle costs and rates above; maximum upgrade level 3 and output bonus 0.25. `development-32x24.json` also needs compatible handling.
- `Economy.swift`: upgradeCost explicitly excludes campfire; generic output scaling applies to all outputs. `GameEngine.housingCapacity` multiplies housing by building level.
- `GameEngine.swift` and `GameSession.swift`: relocation currently rejects campfire; load validation requires its original map coordinate. Discovery starts from the geographical founding coordinate, which must remain separate from movable entity identity.
- `StoneAgeJourney.swift`: chapters are derived, not persisted. Preserving completed chapter credit requires explicit retained history; changing a predicate alone would revoke credit. Chapter 5, all-building readiness, culture pillar and guidance currently require circles.
- `SaveStore.swift`: supports versions 1–5, validates original goal/building witnesses and progression. A new migration must preserve supported legacy versions, existing backups and normal/developer isolation; cannot merely rename the legacy goal.
- No actual era transition exists. Verify civic history through save/reload and sticky readiness; defer later-era appearance/costs/transition mechanics until specified.

## Media access

Sibling `/Users/dima/dev/Civilization-Media` is readable, clean on `main`. Existing campfire and Storytelling Circle masters/runtime exports and registry are accessible; no Gathering Place/Council Circle-specific assets were found. No media was changed or imported. Graphics production stays separate.

## Verification status and next action

No gameplay implementation or migration has run. No physical install, launch, reset or save write. Existing product test results are historical, not evidence for this unimplemented feature. Reuse `scripts/dev.py test`, toolkit regressions, SaveInspector and preservation comparison once the decisions are approved. Implement failing civic/economy/research/relocation/migration/chapter tests first, then product/UI and full Debug/Release/native regression checks using isolated QA identity. Physical validation must respect this task's no-reinstall/no-overwrite instruction.

Documentation-stage verification: `python3 -m unittest discover -s scripts/tests -v` passed 10/10 tests, zero failures. The existing child-interruption test emitted a subprocess ResourceWarning; this was not a gameplay test or a civic migration verification. No unrelated toolkit behavior was changed.
