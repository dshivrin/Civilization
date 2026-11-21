# Stone Age Completion Cues Implementation Plan

Goal: Ordinary Stone Age New Game and Continue acknowledge newly earned research,
objective, chapter and pillar completions with compact HUD cues and persistent
per-game unread markers. Integrate into the existing review branch after testing.

Base: ca1426b4613697ee0b5fc7558c2d0a1c38565821, verified clean checkout and personal
origin/riverbend-stone-age-hud-review. Approved spec: compact notifications in
plans/2026-11-20-ui-themes-animations-loading-branding.md.

## Task 1 — durable earned-event delivery
- Trace authoritative research, goal, journey and save transactions.
- Write failing deterministic tests, then implement stable earned IDs, per-save
  unread state and targeted acknowledgement. Optional additive save field defaults
  safely for legacy saves. Historical snapshots never become unread or pulse.
- Cover actual successful commands, duplicates, simultaneous categories, independent
  games, legacy/current reload, failed persistence and acknowledgement isolation.
- Pulse delivery is transient and only follows a successful durable transaction;
  foreground/reload never replays it. Progression and rewards stay unchanged.
- Verify with python3 scripts/dev.py test (both core configurations and exclusions).

## Task 2 — ordinary HUD and exact content acknowledgement
- Preserve HUD positions, routing and accessibility labels. Research gets a restrained
  0.5–1s highlight; Goals gets a short checkmark, then non-color-only unread markers.
- Coalesce bursts by destination without clearing other events. Clear only actual
  visible completed content, never on menu opening alone. Honor Reduce Motion with
  static markers and announce newly earned results concisely for VoiceOver.
- No toast/banner/modal/analytics/dependency/developer-only delivery.
- Verify ordinary phone/iPad New Game/Continue earned research and chapter/goal,
  unread persistence, no replay, acknowledgement, tap/layout and Reduce Motion.
  Use isolated QA identities; no fixtures/grants/accelerated time on these native paths.

## Task 3 — review, evidence and safe integration
- Run core Debug/Release/exclusions and relevant HUD/Continue regressions; preserve
  original runner receipts, screenshots and timestamped motion evidence where supported.
- Record observed accessibility coverage and limitations in a pinned handoff.
- Obtain one fresh-context whole-branch review, fix important findings with RED→GREEN.
- Recheck target checkout clean, approved base unchanged, remote unchanged. Fast-forward
  riverbend-stone-age-hud-review to the exact tested commit and normal non-force push.
  Verify local/remote SHA and launch guidance; preserve work if integration is blocked.

Constraints: separate temporary branch/worktree during implementation; no owner-save
access/change/deletion, physical installation, main merge, deployment, signing changes,
Bronze/finale/era-transition/achievement system/new rewards/balancing. Existing achievement
history is connected only when already durable and relevant to a real destination.

## Execution ledger
- Setup: native managed-worktree request stalled without an operation ID; terminated
  waiting call and used authorized Git fallback at /private/tmp/civilization-stone-age-completion-cues.
- Pre-flight: Task 1 durable IDs/unread and transient delivery are consumed by Task 2;
  content acknowledgement uses the same exact IDs. Task 3 must test the integrated tree.
- Task 1: complete. Initial command/unread/pulse/acknowledgement tests observed RED,
  then GREEN. Core 354 Debug /261 Release +23 exclusion probes pass in
  /private/tmp/civilization-qa-9e7049ea3196424fa39c2e58a3deffe7.
  Seventh completion test (actual library game switching) passes in scoped
  /private/tmp/civilization-qa-a31c8d803e33449e8867d6eb1326b7b0.
- Ruling: existing whole-state preservation assertions now compare gameplay with
  only the additive notification inbox removed; dedicated tests cover the inbox.
  This preserves every original gameplay assertion while allowing the intentional
  silent historical baseline. Cost if wrong: presentation regressions must be
  caught by the dedicated completion tests rather than those geometry/library tests.
- Native RED confirms missing HUD unread value. Follow-up compile found undefined
  color token (fixed to existing panelColor). Native test route corrected from
  Culture to actual Science and split into independent authentic games because
  Lodge+Hut spend all opening Wood. No balance or grant change was made.
- Legacy foreground regression: RED in /private/tmp/civilization-qa-f0053abd210445dfaad92dea5c87a69a;
  GREEN in /private/tmp/civilization-qa-1c90947aea2341f88da8dc82790e4937. Offline
  completion persists unread but updates transient delivery silently.
- Visual implementation candidate: fixed-position symbol markers, reduced-motion
  static fallback, concise announcement, post-dismissal queued pulses and exact
  scroll-visible result acknowledgement. Retained older ordinary HUD layouts use
  the same markers. Native evidence and final review remain pending.
