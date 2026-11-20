# GAME-LOOP-01 — Permanent Civic Center Evolution

Authority: [approved plan](../../plans/GAME-LOOP-01.md), [owner decisions and preservation safeguard](../../plans/GAME-LOOP-01-APPROVAL.md), reconciliation390e03c. Implementation and available automated verification complete; human play acceptance remains separate.

The founding campfire is the settlement's unique civic entity. It retains its building ID and 1×1 footprint while evolving through Campfire, Gathering Place and Council Circle. L2 is gated by Oral Tradition and costs10food/20wood/10stone; L3 by Social Order and costs10wood/5stone. Both upgrades are instant. Base cultural output is3knowledge/2culture and3.75knowledge/2.5culture per minute, respectively, sharing one worker. Natural Knowledge and Rituals apply; housing5 and founding2food/3water per minute do not scale with civic level or staffing.

Chapter1 introduces L2 before knowledge-dependent chapter2 research; chapter5 uses L3, alongside existing society requirements. Culture pillar retains shrine/culture thresholds and requires L3. The nineteen mandatory building types exclude optional Storytelling Circles; all twenty technologies, required territories and five pillars still govern readiness, with an explicit L3 check. Chapter2–4/6 requirements are retained. Ordinary guidance directs civic upgrades and follows real resource/research dependencies. Inspection opens the exact locked prerequisite with a visible return to the same civic center.

## Existing saves and rewards

“Earlier save” means data written by previous builds of this same game, not an obsolete gameplay mode. Supported v1–v5 saves load through historical validation, then retain completed chapter/objective witnesses before the new predicates apply. The v6 save carries stable civic identity, reached levels and permanent completed credit. Existing center level and all circles/buildings/resources/placements/timers/roads/research/discoveries/deposits/reward IDs remain; no automatic upgrades or conversions. Existing circles keep operating and remain optionally buildable.

New games award the existing storytelling reward once on L2. Existing circle reward credit is retained, so upgrading an old center or building another circle cannot repeat it. Completed chapters/pillars/readiness never require repurchase. First v5→v6 write preserves an exact `pre-civic-v5.bak`; mismatched backups or attempted version downgrades reject the write. Normal and developer metadata envelopes share this preflight; library index version1 and independent games/companions remain. Load without normal game restoration does not advance time or alter source bytes.

## Scope limits

No player save was reset/overwritten and no physical build installed, reinstalled or launched. Simulator QA uses the separate com.civilization.seed.qa identity and isolated fixtures. There is no actual era-transition command in this product: civic identity/level history persist through save/reload and retained Bronze readiness, with later-era architecture/economics deferred. No new era gameplay or unrelated GAME-UX/EXP/LOOP backlog.

Civilization-Media is readable, clean on main; existing campfire/circle masters and exports are accessible. No level-specific new art found or imported. Existing art remains replaceable; this task changes gameplay and level labels, not media production.

## Verification

- Core: **204 Debug / 184 Release passed**, plus all five Release API exclusions. [Exact runner report](../testing/game-loop-01/core-report.json).
- Civic UI: both cases pass on phone/mini/Pro, covering paid L2/L3, exact research/return, restart, relocation, recentering and invalid long-press cancel. Pro recheck [report](../testing/game-loop-01/pro-civic-recheck.json).
- Regression: phone chapters/scenarios, guidance, independent saves, long-press/camera and roads pass; normal earned completion [recheck](../testing/game-loop-01/earned-completion-recheck.json) passes. Ordinary Debug phone and [Release iOS18 mini entry/persistence](../testing/game-loop-01/release-entry-report.json) pass.
- Tooling: Python10 and SaveInspector8Debug/7Release pass. Actual earlier iPhone backup production-validates read-only with every source byte unchanged: [report](../testing/game-loop-01/backup-readonly-report.json), [hash/count evidence](../testing/game-loop-01/backup-inspection.json).
- Independent whole-change review found no Critical issues; Important findings fixed with failing regressions before fixes and complete core rerun. Known minor: an untouched old developer scenario may display “Modified” because its comparison snapshot predates civic metadata. This label does not alter progress or source backups and remains in the existing developer-label backlog.

No outstanding product decision or unresolved automated failure. Initial failed tests, fixture corrections and exact local native report paths are retained in the [execution evidence](../testing/game-loop-01/progress.md). Physical feature validation was not attempted under the no-reinstall/no-overwrite instruction.
