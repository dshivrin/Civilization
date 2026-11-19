# Compact development menus — evening review candidate

19 November 2026. Dima’s screenshot feedback is implemented for both Buildings and Research: compact aligned cards, smaller artwork, resource-icon costs, individual red shortages and expandable secondary information. First-era chapters, simulation and save history remain unchanged.

## Changes

Both catalogs share `DevelopmentSummary`, `DevelopmentCosts`, `DevelopmentDetailsButton`, category navigation and card surfaces. Compact cards keep a44point thumbnail/icon, name, state, icon costs, explicit action and detail chevron. Description, exact required/stored/missing counts, prerequisites, production/benefits, construction/worker/terrain information appear on expansion. Locked and completed entries remain inspectable. Repeatable constructed buildings retain Build; completed technologies stay disabled and show already-paid nominal costs without false shortage warnings.

Only individually insufficient resources turn red, with an exclamation marker and accessible resource names/counts. The displayed deficit rounds upward to the whole units needed; stored quantities round down, consistent with the resource HUD. Affordability uses actual fractional balances and updates from the current session state. A test purchases Oral Tradition from ordinary balances and verifies the wood stock changes100→90 and the paid action disables; a mixed Hunting cost has available wood and missing Knowledge simultaneously.

Categories are shorter; grid items align at their top, share summary/cost baselines and adapt to width. Cost/action share one row to reduce height. Separate44point controls retain comfortable targets. At accessibility text sizes the grid uses fewer columns and allows natural heights. The cost strip wraps only if necessary. Scroll regions clip their own contents so expanded text cannot overlap the fixed navigation.

The Build action still calls the existing choose/dismiss flow and enters immediate drag placement. Research retains the same validated transaction. No resource cost, economy equation, save schema, reward, geography, ID, original art, signing or platform change.

## ChatGPT visual guidance

Feedback/report and the explicit request were sent to [City Design Coordination](https://chatgpt.com/c/6afcb607-afec-83eb-9ba1-a4393b41348a). Its returned [guide](../art/chatgpt-compact-menu-guide.md) includes compact/expanded hierarchy, phone/tablet layouts, four states, spacing, affordability and accessibility criteria. The [alignment SVG](../art/compact-card-alignment.svg) is retained separately. Interactive examples are not exported by the text connector; the saved guide identifies that limitation. No reference imagery was copied into the app.

Implementation decisions: inline expansion on both devices avoids another navigation mode. More than one card may remain expanded independently. A tablet detail panel was an optional proposal and is not needed for this iteration. Candidate compact cards are approximately128points rather than the guide’s provisional76–96points, retaining separate44point actions, legible icon costs, a scaled two-line title reservation and status. Grid minimum280points yields two phone and typically three tablet columns. These are reversible sizing choices for Dima’s review.

## Screenshots

| State | Phone | Tablet mini |
|---|---|---|
| Compact Buildings |[Phone](../screenshots/first-era-review/compact-final-phone-compact-buildings.png)|[Mini](../screenshots/first-era-review/compact-final-mini-compact-buildings.png)|
| Expanded building |[Phone](../screenshots/first-era-review/compact-final-phone-expanded-building.png)|[Mini](../screenshots/first-era-review/compact-final-mini-expanded-building.png)|
| Compact Research |[Phone](../screenshots/first-era-review/compact-final-phone-compact-research.png)|[Mini](../screenshots/first-era-review/compact-final-mini-compact-research.png)|
| Expanded research |[Phone](../screenshots/first-era-review/compact-final-phone-expanded-research.png)|[Mini](../screenshots/first-era-review/compact-final-mini-expanded-research.png)|
| Missing resource |[Phone](../screenshots/first-era-review/compact-final-phone-missing-resource.png)|[Mini](../screenshots/first-era-review/compact-final-mini-missing-resource.png)|
| Mixed affordability |[Phone](../screenshots/first-era-review/compact-final-phone-mixed-affordability.png)|[Mini](../screenshots/first-era-review/compact-final-mini-mixed-affordability.png)|
| Completed research |[Phone](../screenshots/first-era-review/compact-final-phone-completed-research.png)|[Mini](../screenshots/first-era-review/compact-final-mini-completed-research.png)|

Before: [user-supplied phone screenshot](../screenshots/first-era-review/compact-before-user.jpg), [earlier phone catalog](../screenshots/first-era-review/phone-art-building-catalog.png), [earlier mini catalog](../screenshots/first-era-review/mini-ui-building-catalog.png), [earlier mini research](../screenshots/first-era-review/mini-optimized-research-icons.png). After captures use native simulator framebuffers; XCTest attachment framing on this machine is unreliable.

## Verification

- 115Debug /104Release Swift Testing tests pass, preserving every first-era progression, migration, historical reward and compatibility regression. Paid playthroughs still reach all7chapters/20types/20technologies/5pillars; no balance tuning.
- 5 Release compiler probes pass; debug benchmark/developer APIs remain absent.
- New UI test was observed failing on the missing building expansion control, then proceeding through passing building alignment/expansion to missing research expansion, then passing both menus. The shortage fixture was corrected because developer scenarios intentionally start with full stocks; a unique temporary **normal starting save** now tests actual shortages without opening/resetting the real settlement. Its launch branch compiles only in Debug.
- The UI regression verifies collapsed defaults, aligned action baselines, expansion/collapse, missing/available mixed costs, research cost updates and completed purchase disablement. Existing four UI tests retain developer selection, chapters/readiness, catalog→drag placement, relocation, pan/pinch and dense art.
- All5UI tests pass on iPhone17ProMax/iOS26.5 (100.7seconds), miniA17Pro/iOS18.6 (91.0seconds) and Pro13M4/iOS18.6 (90.9seconds). Result bundles: `/tmp/civilization-compact-{phone,mini,pro}-full.xcresult`. After final screenshot review exposed4.5point displacement from a wrapping title, a new same-row assertion reproduced it and a shared scaled two-line title reservation fixed it. Targeted final runs on all3profiles and refreshed phone/mini captures verify that correction. The five-test full suites above precede only this title-height correction. Corrected capture bundles use `/tmp/civilization-first-era-compact-aligned-{phone,mini}-capture.xcresult`; Pro retest is `/tmp/civilization-compact-pro-aligned.xcresult`.
- Signed Debug device and Release simulator builds both succeeded.
- Independent read-only review found no actionable correctness, save, geography, reward or Release-isolation defect; live images were inspected independently.

Commands: `swift test --package-path Packages/GameCore`, the same with `-c release`, `python3 scripts/verify-developer-release.py`, and `xcodebuild ... -only-testing:CivilizationUITests/RelocationUITests test` on each landscape profile. Local logs use `/tmp/civilization-compact-{core-debug,core-release,release-probes,phone-full,mini-full,pro-full,signed-build,release-build}.log`.

## Installation and limits

The signed update is built. The fresh physical save-backup attempt failed with CoreDevice4016; device inventory reports Dima’s iPhone **unavailable**. No installation was attempted without a fresh validated backup. The previously installed first-era candidate and its preserved saves remain intact. This menu update’s physical installation therefore remains pending device reconnection; simulator screenshots and signed binary are ready for review.

Previous performance evidence and limitations remain in the [first-era report](first-era-review.md): small-scene59.8FPS, dense pre-cache~48FPS, final physical rerun blocked by lock, no sustained60FPS/A15/M1/battery/thermal claim. Human art/enjoyment acceptance remains Dima’s review. No new gameplay scope was added.

### Coordination response

ChatGPT subsequently accepted the compact refinement **based on the report**, confirmed visual-guidance coverage across the existing first era, and retained the5-of-7accepted project-stage ledger pending human review. It explicitly requests no further artwork/gameplay expansion. This is not an independent code/art audit or Dima’s final acceptance.

## Commits and boundary

Local branch `first-era-review`:54373a6(spec/red test),e2cc309(shared controls/buildings),7acf3be(research/deficits/ChatGPT guide),ab76708(density/mixed/live-cost coverage),c255d2b(long-name baseline fix), followed by final verification/media report commit. Every implementation step is committed separately; no remote push. This feedback iteration and available verification are complete for evening review; physical reconnection is the remaining deployment dependency. Do not infer approval for a second age, extra cities, warfare, monetization or further systems.
