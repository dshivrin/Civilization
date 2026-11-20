# Isolated gameplay review controls

Approved by direct owner request after GAME-LOOP-01: reuse time-progress multipliers and resource grants to review Stone Age play without its ordinary two-hour wait. Owner explicitly chose **separate review copy; preserve normal progress**. Civic implementation is delivered in bcf8480; this is a bounded Debug tooling follow-up, not a normal economy change or a new canonical DEV backlog number.

## Goal and acceptance

- Developer tools → Review this game clones the currently selected normal game, at its authentic current state, into an independent `.review` companion. It must not replace an existing `.developer` companion or any normal game.
- If a review companion already exists, resume it explicitly; never silently reset it. Invalid review bytes remain unchanged. Return to normal uses the existing isolated-session lifecycle; only ordinary wall-clock catch-up may apply to normal progress, never accelerated time or grants.
- Reuse existing 1×/2×/5×/10× speed selection, pause, time advance and Add250resource controls. Grants obey existing capacities. Settings reset when resumed, as in developer scenarios; review progress persists without developer offline simulation.
- Clearly label Review copy and provide Return to normal. Scenario selection/reset must not overwrite the review companion. Keep ordinary normal/developer separation and all game/library semantics.
- All entry points and UI are DEBUG-only; add a Release API exclusion probe. Read-only SaveInspector recognizes valid review companions and backups.

## Approach

Reuse the existing developer simulation controller and value-type engine snapshot, with a separate store selected only while review mode is active. This avoids duplicating production or timing mechanics. Existing authored scenarios stay independent; starting/resuming a review is allowed only from normal mode. This is an engineering implementation choice within the approved preservation requirement.

## Execution and verification

1. Write failing tests for exact cloning, normal/developer byte preservation, accelerated simulation and capped grants; resume/relaunch/no-offline/settings reset; damaged companion protection.
2. Add the separate review store and Debug session commands, then expose the review action and existing controls with stable native test IDs.
3. Extend existing SaveInspector filename recognition and Release API probes. Run full Debug/Release core matrix and tooling tests, plus native review-copy UI and Release entry regression.
4. Review the bounded change, update canonical checkpoint/report, commit and push. No physical install/reset or normal balance/media changes.
