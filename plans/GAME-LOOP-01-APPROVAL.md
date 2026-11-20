# GAME-LOOP-01 — Owner approval of reconciliation

Date: 2026-11-20
Status: APPROVED for implementation
Source proposal: docs/design/proposals/2026-11-20-game-loop-01-reconciliation.md (Codex reconciliation pushed as 390e03c)
Parent plan: plans/GAME-LOOP-01.md

## Approved economy and mechanics
- L1 Campfire -> L2 Gathering Place: prerequisite Oral Tradition; instant upgrade; cost 10 food, 20 wood, 10 stone; total base cultural output 3 knowledge/min and 2 culture/min before modifiers.
- L2 -> L3 Council Circle: prerequisite Social Order; instant upgrade; cost 10 wood, 5 stone; total base cultural output 3.75 knowledge/min and 2.5 culture/min before modifiers.
- One shared worker controls cultural output at L2/L3, matching Storytelling Circle behavior. Founding food 2/min, water 3/min and housing 5 remain independent of cultural staffing and civic level.
- Existing Natural Knowledge and Rituals modifiers continue to apply. Do not let generic upgrade scaling accidentally multiply housing or founding provisions.

## Approved chapter mapping
- L2 is a chapter 1 objective after Oral Tradition and supplies knowledge before chapter 2 Natural Knowledge.
- L3 replaces mandatory Storytelling Circle construction in chapter 5, after Social Order.
- Culture pillar uses L3 and existing shrine/culture thresholds.
- Full-catalog readiness requires L3, excluding optional Storytelling Circle.
- Chapters 2–4 and 6 retain existing requirements; chapter 7 reflects readiness checklist. No new technologies or unrelated mechanics.

## Approved migration and rewards, with explicit safeguard
- Retain existing building identities, positions, levels, timers, production modes, all resources, research, roads, discoveries, deposits, and reward/achievement history.
- Existing civic centers begin at their recorded level; do not auto-upgrade or convert old circles.
- Existing Storytelling Circles remain operational and optionally buildable.
- Preserve all completed chapter, objective, pillar and era-readiness credit permanently; snapshot historical completion before predicate changes. A new predicate may govern future progression, but must not revoke earned historical completion or require repurchase.
- Preserve old storytelling reward identifier and earned state. In new games, award the same one-time reward for L2; later optional circle construction must not re-award it.
- Migration must be idempotent; no duplicated rewards or changed assets on repeated loads. Preserve save versions/backups and normal/developer isolation.

## Execution
Codex: pull this approval and implement GAME-LOOP-01 now. Use test-first coverage for civic production, research gating, relocation, persistence, chapters, migration and reward idempotence. Run tooling and product regressions. Keep graphics/media and other GAME-UX/EXP tasks out of scope. No physical reinstall, reset, or overwriting player saves. Commit and push code, tests and canonical documentation. Report concise commit hash, tests, migration proof and blockers.
