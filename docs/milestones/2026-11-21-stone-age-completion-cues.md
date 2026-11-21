# Stone Age completion cues — bounded handoff

Goal: earned research and journey results receive a compact acknowledgement at
ordinary Research and Goals, then remain independently unread until the exact
completed content is viewed. The committed plan is
[plans/2026-11-21-stone-age-completion-cues.md](../../plans/2026-11-21-stone-age-completion-cues.md).

The same review branch is the delivery destination: `riverbend-stone-age-hud-review`,
checkout `/Users/dima/.codex/worktrees/e735/Civilazation`. Open `Civilization.xcodeproj`,
select Civilization and an iPhone/iPad simulator, Run, then use ordinary New Game or
Continue. Existing developer tools are not the delivery surface.

Research gets a restrained 0.8-second outline. Goals gets a brief checkmark/outline.
Both retain a small exclamation-circle marker and an accessibility unread count.
The indicators do not move HUD controls. Bursts retain all destinations; results
behind Research/Journey/Build/Games defer their cue until the HUD is available.
System Reduce Motion keeps static markers. Background/reload does not replay cues.

Unread state is an optional additive field in the existing per-game atomic save.
Historical completed snapshots establish a silent baseline. Research, chapter,
objective and pillar IDs are stable. Newly earned legacy offline catch-up becomes
unread without a foreground pulse; failed/unpublished saves do not expose new HUD
unread state. Viewing completed expanded research benefits or exact visible journey/
readiness results clears only those IDs. Merely opening another category does not.
There is no separate achievement system/destination to connect; legacy goal witnesses
are already represented by the journey objectives. Progression/rewards stay unchanged.

Verification and original receipts: [exact ledger](../testing/completion-cues/README.md),
[gallery and clips](../testing/completion-cues/index.html),
[machine-readable verification](../testing/completion-cues/verification.json).
Verified source **2495193e1e1f9818f41fdf2d41c92f5031d84e43** passes362Debug /268Release /23exclusions and5ordinary Release tests each on iPhone and iPad,0failures.38original captures and two packet-preserving short clips are pinned. The subsequent evidence commit changes documentation only.

Native earned paths use two authentic New Games and ordinary costs: initial Oral
Tradition research in one game; paid Lodge/Hut and real construction behind Saved
Games in a second. No fixture, grants, Developer Tools or accelerated time are used
for these native completion paths. Independent Continue, no replay, exact viewing,
static OS setting, fixed HUD/44-point targets and larger text are checked separately.

One fresh-context source review produced six important findings, addressed with
publication/burst/legacy regressions and shared visibility/lifecycle corrections.
The inherited HUD audit also caught a real AX hit-testing problem from decoration
on the Button wrapper; moving it inside the labels preserves the Button's semantics.
A startup-wait hypothesis was rejected by its timed failure and is not credited as
that fix. Initial apparent missing-pulse evidence was captured while OS Reduce Motion
was already enabled. Runtime traces later confirmed successful cue start and HUD
rendering; immediate AX queries preceded onDismiss and standard one-second polling
missed the transient window. Final tests explicitly set/restore OS motion and poll
the actual0.8-second cue at bounded30ms intervals. Temporary diagnostics and an
unnecessary observation experiment were removed. Earlier failures, stale-cache execution and partial aggregates remain visible.

Ruling: old gameplay-preservation equality assertions exclude only the additive
presentation inbox, which has dedicated tests. Cost if wrong: those old assertions
alone cannot detect an inbox regression; the completion suite must catch it.

Limits: simulator/source evidence is not human acceptance or physical performance.
VoiceOver announcement dispatch and non-color AX cues are implemented; spoken quality
was not listened to. Late earned-pillar readiness acknowledgement uses the shared
visible-item callback and source/model verification, not a full real-time native
late-game playthrough. No maximum Dynamic Type claim is made. No owner saves were
accessed, no physical installation/signing/main merge/deployment was performed, and
no Bronze/finale/era transition, rewards or balance work was started or queued.
