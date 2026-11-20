# Current native UI audit and plan review

Fresh evidence from baselineff94a05 on phone/mini/Pro using the isolated QA app. [Phone board](captures-phone-board.png), [mini board](captures-mini-board.png), [Pro board](captures-pro-board.png); all27raw attachments are in [captures](captures/). Boards preserve each full screenshot's aspect ratio without cropping. Findings below refer to this run, not older captures or generated mockups.

## Plan reconciliation

The [owner plan](../../../plans/2026-11-20-ui-themes-animations-loading-branding.md) at a7e38c2 authorizes audit/design/prototype preparation independently, with review before runtime integration. This delivery implements those gates in a separate workbench. The direct “implement” follows that staged brief; it does not silently activate its gated native integration, R2-07, later-era gameplay or building-art production. No source-art/geometry acceptance is inferred.

Current native layout, gestures, exact development links, resource semantics and accessibility IDs are the grounding target. Materials/brand/motion become a proposed shared contract, rather than restyling or relocating native controls during this audit. Three material comparisons use the same mockup templates and sample Stone Age data. Egypt/Mesopotamia are appearance studies, not playable era unlocks.

## Captured flow

| Step / raw capture suffix | Health | Evidence and action |
|---|---|---|
| 01 launch | Functional | New Game/Continue remain separate and explain retained saves. Title and background are hard-coded in LaunchMenuView; move brand fields to a replaceable contract only after review. |
| 02 HUD | Functional, dense |12resource identities/order, Build/Research upper-right, goals/Explore/Games lower-left, source-center action. Small text and muted dark icons warrant native accessibility/contrast testing. Preserve meanings/anchors across themes. |
| 03 catalog | Functional | Actual source thumbnails, costs and locked states; phone horizontal filters vs tablet sidebar. Available/blocked labels support color. Theme must not alter affordability or button actions. |
| 04 expanded catalog | Functional, space tradeoff | Exact requirements and detail remain on selected card. Row-height expansion leaves spare space beside shorter cards; this is current layout behavior, not a theme license to rearrange controls. |
| 05 research | Functional | Pillar filters, readiness and costs visible on all profiles. Small colored secondary labels need semantic contrast tokens for every material. |
| 06 expanded research | Functional | Oral Tradition description and civic benefits tied to exact card. Keep prerequisites/target return behavior and no purchase on navigation. Prototype uses current canonical IDs. |
| 07 inspector | Functional | Campfire ID/level, workers, civic provisions and paid research gate are visibly associated. This fixture is completed civic only; construction timing and selection races are not proven by this screenshot. |
| 08 journey | Functional | Seven chapters/readiness guidance preserved, exact action links retained. Human comprehension/full completion not established by this audit. |
| 09 Games | Functional | Original settlement entry and separate new-game section. System Form appearance differs from custom panels; future theme contract must accommodate native system surfaces without breaking controls. Phone new-game row is below fold; requiring its immediate existence was a capture-test error, not a product defect. |

Native evidence: mini passes in `/tmp/civilization-qa-63821896e03f467cb1d4671c9c3917f7` (one selected test); phone passes `/tmp/civilization-qa-b0e45e73588e47beae754742d4ca791f`; Pro passes `/tmp/civilization-qa-440740af4f624f70a624744de02cec81`. Initial phone capture runs failed at the Games selector; artifacts retained. Final test asserts the visible current-game section. All captures inspected in boards plus full-resolution HUD/catalog.

## Source-only findings and limits

`SettlementView` owns global parchment/panel constants, with additional local colors in cards; `LaunchMenuView` and `SettlementLoadingView` embed brand strings. `EraIcon` provides code-native scalable resource/research art; the review renderer compiles that exact file through a symlink, with a tool-only macOS thumbnail bridge. Native SF Symbols preserve research=sparkles, goals=flag, Build=hammer, Explore=map and Games=stack semantics. No achievement toolbar icon exists: the proposal keeps independent goal/achievement unread groups at the existing goals/journey position, pending owner review.

Current loading uses an indeterminate spinner and stage text, which is honest. Its transient live state, app launch performance and error dialogs were not captured here. No standalone Settings screen was found in the current UI files; system Reduce Motion is relevant, not evidence of a shipped in-app switch. Current source includes Dynamic Type accommodations in catalog/research and gesture/render pause handling. These screenshots are not VoiceOver, Switch Control, all Dynamic Type sizes, color-blindness or full contrast compliance tests.

The standalone workbench covers the first HUD/catalog/research skin proposals and motion/brand studies. It does not implement all native screens, system Form styling, save migration, actual event delivery, advanced construction meshes, real layered weather/agents or production loading performance. Future integration needs native lifecycle, interruption, event persistence and physical performance verification. No screenshot of the review model should be labeled an implemented iOS screen.
