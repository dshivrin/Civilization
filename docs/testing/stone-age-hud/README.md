# Stone Age HUD — owner launch

Open this managed checkout’s `Civilization.xcodeproj`, choose **Civilization** and an **iPhone/iPad simulator**, then Run → **New Game** or **Continue**. No Developer Tools are required. The default Xcode app and the runner’s `com.civilization.seed.qa` use independent saves.

**Goals** stays bottom-left; tap for the current objective and its exact action. **Build / Research / Explore** share the bottom-right dock. **Settlement** at top-right contains Center, owned buildings and Games. In Build, choose the exact building and use the contextual inspector; on the map, drag the footprint, pan outside it, pinch, then green Confirm or red Cancel. Roads remain in Build. Explore’s Expedition research opens the exact technology and returns to the same panel. Continue preserves the selected ordinary Riverbend game.

[34 native captures](index.html) · [verification](verification.json) · [all original runner receipts](run-index.json) · [pinned handoff](../../milestones/2026-11-21-stone-age-hud-handoff.md).

Passed:348 Debug /255 Release +23 exclusions, and20 final native case executions (9 phone Release +9 iPad Release +2 compact Debug),0 failures/skips. Tests exercise ordinary campaign entry, not a separate Lab or mockup. The main profiles are iPhone16Pro and iPad mini A17Pro on iOS18.6; compact checks use iPhone SE3. Source provenance and earlier failures are explicit in verification.json.

Press Home in Simulator to see the sunrise Riverbend icon. The nearby white grid CivilizationUITests icon belongs to the test harness.

XXXL larger text is tested; maximum/accessibility Dynamic Type, human VoiceOver comprehension and physical performance are not accepted. Long inspector text scrolls and compact status is limited to two lines. Existing art remains provisional. No full real-time first-era playthrough is claimed by this HUD slice.

End this goal after verified branch-only push. **Bronze has not been implemented or queued. Dima must personally play this ordinary Stone Age build and explicitly approve Bronze later.**
