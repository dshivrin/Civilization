# Compact completion cues — verification notes

Goal: ordinary Stone Age earned research and journey results use unobtrusive cues
at the existing Research and Goals controls, with independent per-game unread state.

## Persistence and event identity

`GameState.completionInbox` is an optional additive field in the existing save
transaction. Missing old-save state establishes a silent baseline from already earned
research and journey predicates/history. Stable IDs are `research:<technology>`,
`objective:<chapter>:<objective>`, `chapter:<chapter>` and `pillar:<goal>`.
No new progression rule, reward or separate achievement system is introduced.

The existing authoritative completion evaluation records new unread IDs. Successful
ordinary save publication delivers transient session events; failed Riverbend saves
roll back earn/acknowledgement. Reload initializes transient delivery from all seen
IDs. Offline/foreground catch-up persists unread results quietly. Developer copies
are not a delivery surface. Existing legacy construction/knowledge achievements are
represented through the existing journey objectives; there is no achievement menu.

Research acknowledgement requires the completed item's expanded benefits to be
actually visible. Journey acknowledgement requires the exact earned chapter,
objective or pillar row to be visible. Scroll visibility, completion and frontmost
presentation are checked together. Merely opening a category/menu does not clear
items in another category or outside the viewport. Acknowledging one ID never
clears unrelated unread IDs.

## Verification record (in progress)

- Initial new-game baseline test observed an expected missing-inbox RED.
- Command recording tests observed missing unread RED; delivery/acknowledgement
  tests observed missing pulse and clearing RED; corrected deterministic tests pass.
- Full core after initial implementation: 354 Debug /261 Release +23 exclusions,
  zero failures/skips. One subsequent library-switching test passes separately.
- Legacy foreground catch-up regression observed an unwanted pulse RED, then GREEN.
- Native initial RED confirms no HUD unread value. Follow-ups preserve an undefined
  color-token compile error, a wrong-category test target, an unaffordable test
  spending order and a result-scroll test failure. Inherited incremental cache
  subsequently executed stale test contents/missed a newly selected test despite
  compiling current sources; it is excluded from verification credit. Fresh cache
  and separate identity verification is required.

Only isolated simulator QA games are used. No owner-save/container access, physical
installation, signing change, main merge or deployment is part of this task.

## Accessibility limits

The implementation uses an exclamation-mark circle plus accessibility unread
counts, preserves exact menu routing/labels, posts a concise new-result VoiceOver
announcement, and uses static markers under the system Reduce Motion setting.
Simulator screenshot/AX checks do not establish spoken VoiceOver quality, human
visual acceptance, maximum text-size behavior or physical performance.

## Independent source review and corrections

A single fresh-context source review found six important lifecycle/visibility cases.
First legacy Continue now establishes its historical baseline before offline catch-up.
HUD unread reads only successfully published IDs, preserving the existing legacy
autosave policy. Undrained transient events accumulate across rapid transactions.
Readiness-sheet pillar/requirement results share exact visible-content acknowledgement.
The expanded Goals panel keeps its badge/outline attached to the button. Saved Games
explicitly gates HUD cue presentation until its dismissal, retaining same-game pending
cues. Switching games constructs a fresh transient presentation identity.

Deterministic regressions reproduce the legacy/burst issues. A negative control
that ignores HUD visibility fails the presentation regression; restoring the guard
passes. Reduce Motion and background clearing are covered in that same real production
presentation controller. Core full matrix before these review fixes was356Debug/
263Release+23exclusions; final matrix below must supersede it.
