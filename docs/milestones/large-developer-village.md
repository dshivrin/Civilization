# Large developer village and navigation correction — 20 November2026

Product **2ab7492**, spec20461af; [actual GitHub handover](https://github.com/dshivrin/Civilization/issues/1#issuecomment-7034130861).

Dima authorized a larger developer review world, then explicitly approved **64×48size** and reported first-attempt pan/pinch retries and reduced smoothness. [Direct source](../design/sources/2026-11-20-large-preview-approval-navigation.md), [bounded spec](../superpowers/specs/2026-11-20-grouped-developer-village.md), [plan](../superpowers/plans/2026-11-20-grouped-developer-village.md). Size acceptance is distinct from normal-save migration, human touch/art/enjoyment acceptance and sustained hardware performance.

## Delivered review scenario

**Developer tools → Large grouped village (64×48)** adds a fourth scenario; early/developed/late remain. Three residential neighborhoods contain24homes, alongside food/farming/animals, quarry/wood/crafting, civic and storage/scouting districts.64structures cover all20catalog types.566connected pedestrian road tiles reach every building. The studied additive annex preserves all768original terrain cells and fixed campfire; proposed variable footprints apply only to this Debug review configuration. Normal configuration/catalog/map/savev5 and geometry remain unchanged. Near-side stone/worksites retain existing extraction IDs/ranges/reserves; no new normal quarry, cloud system or migration is claimed.

The **64×48 · Map overview** control and initial overview expose the expanded map; pinch and pan inspect neighborhoods. Resume developer save selects configuration from scenario metadata before validating the large state. Return to normal restores original32×24geometry and renderer. Choosing/resetting a fixture intentionally replaces that world's isolated developer state; normal save/library selection remain independent. Background preparation has loading feedback, single-flight protection and cooperative cancellation; Done and interactive dismissal cancel publication. The fixture clock is rebased when published.

An initial native test caught a Metal texture-descriptor abort in `SKView.texture(from:)` when flattening the entire expanded terrain. The review map now caches bounded16×16ground sections and bounded scenery strips with global depth ordering. Ground cannot cover neighboring tree/rock overhang. Legacy32×24caching is unchanged; no renderer replacement or new art assets.

Review-layout captures, taken during native QA before the subsequent navigation corrections: [overview](../screenshots/grouped-village/phone-large-grouped-overview.png), [districts](../screenshots/grouped-village/phone-large-grouped-districts.png), [returned normal](../screenshots/grouped-village/phone-large-grouped-returned-normal.png). These are actual landscape simctl captures; misframed portrait XCTest attachment canvases were excluded from the review artifacts.

## Navigation diagnosis and fix

- A symbolicated native host sample of the copied physical64building/566road state identified repeated workforce allocation inside every economy flow and redundant economy snapshots. Reuse the existing immutable snapshot's labor and technology multipliers; calculate rates once and reuse net production for growth checks. Check whether the growth timer is due before recomputing growth eligibility. Production formulas, priorities, costs, rates, tuning and gameplay outcomes are preserved.
- Scene construction in `State(initialValue: Scene(...))` allocated disposable full terrain scenes during parent resource updates. A native regression failed **9→11scene allocations in2.5seconds**. Scene creation now happens once after the map view mounts; stored `mapIdentity` changes only when replacing the world configuration. The final native regression keeps scene count stable across resource ticks and verifies switching64→32→64.
- Camera pan no longer waits unconditionally for the long-press recognizer to fail. An active deliberate hold retains relocation ownership; pinch can transition from pan, clears pending road strokes and resets hold recognition. Existing relocation/road cancellation cases remain covered. This does not implement direct building movement without the established long press/edit workflow.

[Local performance record](../testing/grouped-village/navigation-performance.json): median one-second simulation update **240.70ms→8.95ms**, presentation **12.79ms→2.02ms**, on the same copied physical state in macOS Debug. The complete state after12seconds is equivalent at numeric tolerance1e-9, ignoring set-serialization order. These are local CPU timings, **not physical FPS, thermal or battery measurements**. The first-pan/first-pinch simulator test passed before optimization too: the physical retry complaint is not claimed universally reproduced by that test. The native scene-allocation failure and periodic local main-thread stall were reproduced directly.

## Verification

| Check | Actual result |
|---|---|
| Final full core Debug |177passed,13.268s; includes fractional staffing, preview bounds/roads, cancellation, save isolation/resume and pending expeditions beyond768tiles |
| Final full core Release |159passed,~1.3s; production dimensions/behavior retained |
| Release API exclusions |All five probes pass; developer scenario/API remains absent |
| Phone gesture set |Four cases passed93.098s: large map/resume/normal return, long press/camera, road pinch cancellation, road draw/erase/building gestures |
| Mini gesture set |Same four cases passed;80.428srun |
| Final scene reuse + first input checks |Phone46.198srun and mini39.833srun pass after lazy scene fix |
| Final large Pro tablet |Large-map scene/first-input/resume/return plus long-press/camera cases pass;53.372srun |
| Signed device build |Passes with unchanged signing/account settings; strict codesign verifies |

Native commands use `xcodebuild test -project Civilization.xcodeproj -scheme Civilization -configuration Debug -destination 'platform=iOS Simulator,id=<profile>' -derivedDataPath /tmp/civilization-grouped-<profile>-build -only-testing:CivilizationUITests/RelocationUITests/<case> CODE_SIGNING_ALLOWED=NO`. Core: `swift test --package-path Packages/GameCore`, plus `-c release`; exclusion check: `python3 scripts/verify-developer-release.py`. Scope includes targeted native cases, not a newly rerun full19case/profile suite. Independent review found and corrected main-thread fixture loading, pending-expedition768limit, cross-chunk scenery order, and immediate Done cancellation; final changed-scope review found no further consequential defects.

## Device and remaining acceptance

The initial preview build was installed after fresh production-validated backup: normal5buildings/15roads, existing developer18buildings/0roads and library index were byte-identical before launch. Dima selected the new scenario; a subsequent physical copy production-validates **64×48,64buildings,566roads**, with original32×24normal world retained. It is not a claim that the developer file stays byte-identical after deliberately selecting a different fixture.

Final navigation update installed after a new production-validated backup. All three files (normal save,64×48developer save and library index) are byte-identical before launch; the extra read-only copy also validates. [Exact preservation metadata](../testing/grouped-village/device-preservation.json). Initial launch was denied by iOS Locked. After Dima explicitly confirmed unlock, **final-update physical launch succeeds**. A fresh copy production-validates both original normal and grouped64×48developer states and the selected legacy library; normal geometry/progress preserved; developer geometry/roads/IDs and researched/earned/discovered sets retained. Developer time/resources/depletion advanced after resumed use, so no post-use byte-identity claim. Dima subsequently confirms **“Yes, navigation improved. Approved, commit and report to chat.”** Size and current physical navigation are accepted; sustained hardware performance and broader art/enjoyment remain separate. Private save contents remain local. No normal-world expansion/reset/uninstall, signing/account change, second-era gameplay or media-repository change. All approved/deferred backlog remains. Next: bounded S1-Geography migration/quarry/cloud/permanent-discovery reconciliation using approved64×48size; normal migration policy is still a separate gate.
