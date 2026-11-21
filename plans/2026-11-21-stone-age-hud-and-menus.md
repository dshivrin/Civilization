# Stone Age HUD and Menus Implementation Plan

**Goal:** Deliver a coherent carved-stone HUD and menus in ordinary New Game/Continue, with a temporary sunrise Home Screen icon on iPhone and iPad.
**Authority/spec:** Dima’s directly approved delegated brief, 21 November 2026. Continuous implementation and verified branch-only push are explicitly authorized; no additional routine design sign-off. Base/remote predecessor verified at `3f27d1e711096bc22cc400f354bb627cbb9e9535` (product `623b9ad`).
**Architecture:** SwiftUI presentation over the existing ordinary GameSession; retain catalog memory, guidance targets and return stacks. Shared stone surface/action vocabulary, no engine/save changes. Original native vector sunrise rendered into a replaceable AppIcon asset catalog.
**Tech:** SwiftUI, SpriteKit, UIKit/AppKit, XCTest, established python3 scripts/dev.py runner.

## Constraints
- Only riverbend-stone-age-hud-review is pushed; preserve linked worktrees and all saves.
- No main merge, physical install, owner-save access, signing change, deployment, Developer Tools expansion or Bronze work/queue.
- Ordinary gameplay is the acceptance surface. Developer Tools may only set up/accelerate ordinary states for spot tests.
- Preserve seven chapters, economy, geography, resource reveal, exact research/catalog routes, search, selection, return and Continue.
- Landscape iOS18+, safe areas, at least44point targets, accessible labels and larger text.

## Design decisions
Use a compact resource ledger at the top; one stable Goals home at bottom left with current objective and explicit action on opening. Group Build/Research/Explore in one labeled dock. Put Center, building list and Games in a labeled Settlement menu. Hide optional HUD detail during placement; keep map gestures and candidate controls above the HUD. Phone inspectors sit at the bottom; iPad inspectors sit to the side. Use warm gray stone, pale readable ink, restrained gold selection, engraved borders; no texture images or ornament over text. Retain fixed catalog cards and the exact existing inspector/route state. Alternative floating individual controls retain the reported hierarchy problem; full-screen navigation for every action consumes map context. These choices are engineering defaults under Dima’s continuous execution authorization.

## Review focus
Small landscape safe areas; large text scroll versus fixed actions; Goals after inspection and relaunch; exact prerequisite/Explore return; placement/road controls versus HUD and map gestures.

## Tasks
- [ ] 1. Write native HUD hierarchy/ordinary navigation regression and observe RED. Run clean baseline core Debug/Release/exclusions.
- [ ] 2. Implement ordinary HUD and shared carved-stone surfaces in SettlementView/DevelopmentComponents; style actual catalog/research without altering state. Add root standing directive. Verify new and inherited native routes on phone/iPad, normal and larger text.
- [ ] 3. Render original simple sunrise/horizon AppIcon, wire actual app target asset catalog, verify compiled icons and both simulator Home Screens. Retain source/provenance.
- [ ] 4. Full core Debug/Release/exclusions, targeted ordinary native Release and Debug gates, screenshots and exact receipts. Independent whole-branch review, fix important findings with regression evidence.
- [ ] 5. Pinned milestone/launch/evidence and exact verified remote SHA; branch-only push. Stop for Dima’s Stone Age playtest and explicit future Bronze approval.

## Execution ledger
- Worktree already managed/isolated; prior player worktree preserved. Remote predecessor matches exact expected SHA. Initial sandbox Git/network/simulator access denials resolved only through ordinary host escalation.

- Independent review: two important regressions reproduced RED in native Release (missing contextual Goals and missing clear-map feedback); one fix pass retains compact Goals through Explore/inspection/placement/roads and restores status. Native exact Explore→expedition Research→Explore route also pinned RED before adding the ordinary link.
- Minor limit: XXXL is larger text, not maximum/accessibility Dynamic Type acceptance. No such claim is made. Removed unreachable old phone overlay during the same HUD fix.
- Initial native SE hierarchy route passed. Failed preimplementation/accessibility/expected-regression receipts remain separate. Icon renderer’s two unsupported AppKit bitmap variants failed; final opaque CoreGraphics export is original1024×1024RGB/no alpha.
