# Pinned ordinary Riverbend native progression audit

Baseline: `ca1426b4613697ee0b5fc7558c2d0a1c38565821` (`riverbend-stone-age-hud-review`). Test-only branch: `codex/riverbend-native-route-audit`. Dedicated iPhone SE (3rd generation), iOS 18.6, landscape 667×375 points. No owner data, shared simulator, physical install, gameplay fix or merge.

## Evidence rules

The route starts at actual ordinary New Game with standard resources. It uses normal Build, Goals, inspection, roads, survey, bounded fallen-branch recovery, research and Continue controls. There is no earned-state import, fixture, grant, clock override or protected hook. `--qa-identity` reuses the runner’s UUID bundle naming (`qa.earned`); that name does not indicate prepared data. Every attempt starts a new ordinary game in this isolated identity.

The owner share exposed ten placeholders rather than pixels. These results do not reproduce Dima’s exact sequence or establish human readability, touch comprehension, hardware timing or performance.

## Confirmed compact-phone finding

After the Hut completes, Goals changes to **Connect Hut**. Opening inspection shows its connection reason in the accessibility tree, but **Connect paths** lies below the visible scroll area and is not hittable. The pinned Move action occupies the visible lower inspector. An explicitly named strict test asserts opening visibility and intentionally fails; the separate functional baseline route captures before scrolling and successfully connects through the normal suggested-path confirmation. The same layout also hides the connection control for the Shelter, Woodcutter and Stone gatherer. This audit changes no UI.

The immediate third next action, before Hut construction finishes, is **Complete Hut**. Its inspection opens successfully. That short passing test alone does not establish that the later connection action is discoverable.

## Attempt ledger

- Run 1: inherited ordinary opening/Continue **passes**, 104.967 s including 61.712908 s real survey. Immediate-third-action test **passes**, with Complete Hut. New continuous driver **fails** after 33.668 s because it queried a construction container as text and checked completion too soon; this is a driver error, not product evidence.
- Run 2: continuous route reaches Shelter completion/connection and whole-forest survey (59.924586 s measured after the timer appears), then the driver wrongly expects a catalog where the real next action **Find materials for Woodcutter** opens Explore. Failed 179.620 s; preserved. The corrected driver follows ordinary bounded branch recovery.
- Run 3: strict opening-visibility test **deliberately RED**, 39.292 s, exact message `Primary action must be visible on opening: connectBuildingPaths`. Continuous ordinary route **passes**, 618.570 s XCTest duration / 618.285312 s measured from launch through Chapter 4 next guidance. The aggregate runner correctly reports **failed** because it includes the RED; it is never represented as a green suite. Real measured survey wait 60.473672 s; Wood for Stone construction wait 45.072192 s; Oral Tradition resource wait 124.135201 s; Natural Knowledge resource wait 158.077781 s. Timer intervals start after UI observation, so they are not exact configured durations.
- Run 4: dedicated iPad mini (A17 Pro), iOS 18.6, 1133×744 points. **3/3 pass**: strict connection opening 39.483 s; inherited ordinary opening/Continue 101.660 s with 61.572800 s real survey; immediate third action 24.838 s. The connection control is visible/hittable on opening here. No full iPad Chapter 3 route is claimed.

Original runner receipts/logs are retained under `runs/`; raw `.xcresult` bundles remain at the recorded local paths. Published captures are original exported screenshot bytes with exact source attachment metadata and SHA-256. Earlier failures remain unmodified.

## Proven continuous phone sequence

New Game → original Campfire upgraded to Lodge → Hut paid/completed → missing-road reason captured → suggested path confirmed → Gathering shelter paid/completed/connected → paid whole-forest survey → ordinary bounded branch recovery in Explore → Woodcutter paid/completed/connected → terminate/normal Continue into the same four-building game → wait for earned Wood → Stone gatherer paid/completed/connected → Oral Tradition paid → Natural Knowledge paid → Goals **3/7 chapters / Research Stone Tools**, the next Chapter 4 objective.

Captured native inspector trees show Shelter and Woodcutter **Operating / 100%**, and Stone gatherer **Workers limited / 50% / 0.5 of 1 worker** after connection. This is functional production, not a claim of full staffing. Earlier core tests and earned checkpoints are not substituted for this native continuous sequence.

Build and selected-building actions for Hut, Gathering shelter, Woodcutter and Stone gatherer were hittable on opening. Exact research opening trees place Oral Tradition at `(248.5,274.5,71,44)` and Natural Knowledge at `(574,274.5,71,44)` within the 667×375 screen; their disabled state reflects missing resources. The connection primary action at `(304,295,136,34.5)` is below the approximately 89-point-high visible inspection scroll area. The reason itself clips in the opening screenshot. Explore survey, branch recovery and Close also required recorded scrolling. Passing the baseline route does not negate those discoverability findings.

## Key original phone screens

[Exact hidden-connection opening](captures/run3/0D2E9214-0206-4F2E-A8D3-7B5B62F73004.png) · [Chapter 4 next objective reached](captures/run3/0E5D9DBE-A80F-487E-9683-CCC12213681B.png) · [Stone gatherer connected](captures/run3/D6BB925B-FA3B-4B21-8597-C1BF3AA0988B.png) · [Natural Knowledge paid](captures/run3/F95ACBEA-79A2-4013-960A-1D915A41D6AC.png)

These are full original 1334×750 native phone captures, not mockups. Human interpretation of resource icons, long clipped text, art and physical gestures remains unverified. No balance/UI correction is included.

## Final handoff

Three native test cases were added; four distinct cases were executed, with nine executions total: six passes, two preserved driver failures, one deliberate compact visibility RED. Run 3’s functional route passes while its aggregate remains failed; run 4 is fully green for its three selected cases. `verification.json` records exact selections, per-case results and SHA-256 of the final test source. All **201 protected product/core/project/runner files match the installed baseline**; The authored-file `git diff --check` passes; the full-range check flags trailing whitespace in original xcodebuild logs, which are preserved byte-for-byte. This is test and evidence delivery only. No core tests were repeated because product sources did not change.

The two dedicated simulator identities retain their own disposable games and local result bundles. No shared simulator was erased, reset or controlled. The temporary worktree is retained for review. No physical iPhone interaction, FPS/thermal result or human acceptance is claimed.

[iPad opening comparison](captures/run4/99C50F47-417F-469C-B682-701F3A94084D.png) · [machine verification](verification.json) · [plan](../../../plans/2026-11-21-native-route-audit.md)

## Branch-only delivery receipt

Test/evidence commit `f8bbd292ed003786c17b8c063948b9e2b1be712a` was normal-pushed to `git@github.com:dshivrin/Civilization.git`, branch `codex/riverbend-native-route-audit`; `git ls-remote` independently matched that exact commit. This documentation receipt follows on the same branch. No PR, merge or current-review-branch write was made.
