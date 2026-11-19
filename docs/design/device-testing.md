# Seed 0.2.6 physical-device setup and test sheet

18 November 2026. Target: iPhone 17 Pro Max, iPad mini 6 (A15), iPad Pro 12.9-inch (M1). Keep iOS/iPadOS deployment target 18.0, universal device family and landscape orientations. Debug/Release signing style remains Automatic; no team was added and no Apple account, certificate or provisioning configuration was changed.

## Run on a physical device

1. Open `Civilization.xcodeproj` in Xcode. Select the **Civilization** scheme and **Debug** configuration so the developer panel is available.
2. Connect and unlock the device. Trust this Mac on the device if prompted. Select it in the run-destination menu. Xcode's Device Hub (or Devices and Simulators on older Xcode) shows pairing status.
3. If required, enable Developer Mode in **Settings → Privacy & Security → Developer Mode**, restart and confirm on the device. Dima performs device-security/account confirmations himself.
4. Update after device-feedback iteration 1: Dima has now configured a development team, which the implementation preserves. If setting up another checkout without a team, In the target's **Signing & Capabilities**, Dima chooses his intended existing personal/development team. If no account is configured, Dima adds it in Xcode Settings → Apple Accounts. Automatic signing can create signing assets/register a device; these are user-controlled account changes, not actions performed by this implementation.
5. Run (⌘R). Resolve any signing/provisioning prompt for that chosen team. Do not lower the deployment target or change the bundle identifier to bypass an error. Do not uninstall an existing app to resolve signing errors without backing up its normal settlement.
6. Repeat with each iPad when connected. The connected-device check found the physical iPhone 17 Pro Max; neither requested physical iPad was connected. Unsigned device compilation succeeded; installation and physical interaction remain pending signing.

Apple references: [Run on simulated or physical devices](https://developer.apple.com/documentation/xcode/building-and-running-an-app), [Developer Mode](https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device), [Signing workflow](https://help.apple.com/xcode/mac/current/en.lproj/dev60b6fbbc7.html). Simulator compilation needs no account; a physical installation needs valid development signing.

## Developer workflow

Tap the wrench in Debug. Load Early (3 inhabitants), Developed (24), or Late (60). The orange **DEVELOPER** banner confirms isolation. Normal save: `Library/Application Support/Civilization/settlement-v1.json`; debug save: sibling `settlement-v1.json.developer`, both v5. Relaunch always opens normal play; **Resume developer save** reopens the fixture without offline catch-up. **Return to normal settlement** restores normal play and applies ordinary capped elapsed time. Scenario loading/reset replaces only the developer state. A damaged developer file is archived with an `.invalid-<UUID>.bak` suffix before an explicit scenario reset. Invalid normal saves remain protected across switches.

Controls: pause; 1×/2×/5×/10× speed; explicit +1 minute/+1 hour; +250 of every resource within storage; +5 inhabitants within housing; individual research grants including prerequisite closure; all research; reveal territory; reset current scenario. Settings are temporary and excluded from save state. All debug APIs and UI compile out of Release. Fast construction applies **3 simulated seconds** to new buildings, including when a technology would normally reduce construction duration; at 1× this is three wall-clock seconds. Existing timers retain their original duration. Pause freezes ordinary progress; explicit advance still advances while paused. Speed affects construction, production, growth and exploration together.

Late has four pillars complete, 19/20 technologies and fully discovered territory. Its final objective is: research Fortification and build the missing Palisade. Population 60 is a fixture for testing; check net food/water and staffing rather than treating scenario settings as production balance.

## Device checklist for Dima

Run these in the isolated Early scenario at **1×** with fast construction enabled:

- Drag empty map, then pinch at several zoom levels. Center action returns to campfire; bounds should retain visible ground. No construction or charge should result from panning.
- Choose a hut and tap to move the ghost. Valid footprint is mint; blocked/occupied/unknown ground is red with a reason. Confirm is disabled until valid.
- Cancel placement; resources and occupancy should stay unchanged. Place again, confirm once, observe the three-second construction feedback and completion. Inspect it by map tap and building menu.
- Try repeated taps near HUD/panel edges, pan beginning near a ghost, pinch during placement, and rotate between both landscape orientations. Report accidental taps or camera jumps with device model and steps.
- Verify resource scrolling, population/workforce breakdown, catalog search/categories, recipes, priority controls, upgrade affordability, expedition cost/timer, all five research categories and readiness details. Dismiss and reopen research; category stays selected.
- Background/foreground and force-quit/relaunch. Normal progress must remain separate; resume the developer save explicitly.

Following Dima’s physical-device feedback, the gesture model is **drag empty map to pan, pinch to zoom, tap to place/inspect, long-press an existing building to relocate**. Arrows were removed. All non-campfire buildings may be moved for free, including construction in progress. Invalid drops cancel; inspection offers an alternative Move action with map-tap/confirm/cancel. The campfire remains the fixed map anchor. Simulator XCTest verified a real long-press move and subsequent pan/pinch without losing identity. Pinch/multitouch, palm/edge touches, FPS, battery and thermals require real-device testing. Simulator profiles are newer substitutes for the requested A15/M1 tablets and are not hardware benchmarks.

## Iteration 1 deployment result
The signed update was installed on Dima's iPhone 17 Pro Max after he handled the signing prompt. Before updating, the save directory was backed up read-only to `/tmp/civilization-iphone-before-feedback-20261118`; production SaveStore/GameEngine validation passed. The post-install normal save is byte-identical to that backup. Signing team/account configuration was preserved. Simulator XCTest verified long-press movement, pan and pinch; real-device gesture comfort, performance and tablet installation still need Dima's feedback.

## Seed 0.2.7 update — 19 November 2026

Dima reports the first physical usability iteration passed and directly authorizes 0.2.7. Final signed update installed on his iPhone 17 Pro Max using the existing signing identity. Save directory backed up to `/tmp/civilization-iphone-before-027-final-20261119`; production loaders validate the normal v5 save with four buildings. Both normal and developer saves remain byte-identical in `/tmp/civilization-iphone-after-027-final-20261119`. No uninstall/reset or account/security settings changed.

Developer scenario checkmarks identify the source fixture. Top status distinguishes Original scenario from Modified developer state; advancing simulation also modifies state. Legacy developer files without comparison metadata say comparison unavailable. Reset reloads the selected source. Late still finishes by researching Fortification and constructing Palisade; the complete catalog/checklist now applies in normal play.

Building menu now occupies an adaptive full screen using research-style categories/cards, then dismisses into the same immediate drag mode. Goals remain collapsed with counts, expand to the next objective and open a full-screen seven-chapter checklist. New readiness requires all catalog types/technologies, required resource territories and five pillars; old readiness is preserved. Phone/mini/Pro simulator verification and limits are in `docs/milestones/seed-0.2.7-report.md`. Physical FPS, thermals and this update's human comfort assessment remain for Dima.
