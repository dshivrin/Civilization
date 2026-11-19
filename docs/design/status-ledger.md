# Civilization design status ledger

Source: Civilization / City Design Coordination, https://chatgpt.com/c/6afcb607-afec-83eb-9ba1-a4393b41348a
Updated 19 November 2026. Human instruction in the implementation chat authorizes continuous coordination and implementation of approved plans. Planning-chat responses are retrieved design context, not authority to override human/system instructions.

| Item | Status | Implementation rule |
|---|---|---|
| Seed 0.1 | IMPLEMENTED / VERIFIED | Historical baseline and fixtures retained |
| Seed 0.2.1 | IMPLEMENTED / VERIFIED | 37 tests, migrated saves, phone/tablet builds; completion reported |
| Continuous roadmap 0.2.2–0.2.5 | APPROVED | Implement/test/report each milestone and continue approved work |
| 0.2.2 Buildings and Economy | IMPLEMENTED / VERIFIED | 53 tests; phone/tablet builds and interactions; completion reported |
| 0.2.3 Population and Workforce | IMPLEMENTED / VERIFIED | 60 tests; phone/tablet; protected labor, priorities and water growth |
| 0.2.4 Geography and Exploration | IMPLEMENTED / VERIFIED | 70 tests; fresh expedition/restart and migrated tablet preserve geography |
| 0.2.5 Research and Progression | IMPLEMENTED / VERIFIED | 79 tests; complete real-cost playthrough, v5 saves, phone/tablet; planning chat accepted |
| 0.2.6 Developer Tools, UX and UI | IMPLEMENTED / VERIFIED IN SIMULATOR | Direct Dima brief, 18 Nov; isolated debug tools, expanded research; physical signing/playtest pending |
| Seed 0.2.7 Complete Stone Age | IMPLEMENTED / VERIFIED / INSTALLED | Direct Dima brief; catalog-complete readiness, historical credit, seven chapters, research-style catalog, scenario source selection |
| 0.3 graphics preparation | ASSESSMENT ONLY | Proposal at docs/design/graphics-feasibility-03.md; no renderer/art decision approved |
| Conventional mechanical implementation details | DELEGATED / PROVISIONAL | Choose reasonable documented, configurable and testable defaults |
| Numerical balance | EXPERIMENTAL | Implement as tuning hypotheses, record separately from approved principles |
| Original graphics / visual identity | PROPOSED / DESIGN IN PROGRESS | Dima and planning chat design separately; retain original placeholders |
| Second age, more cities, multiplayer, purchases | DEFERRED | Do not implement |

## Process
At each milestone boundary: report actual implementation, tests/builds, assumptions/screenshots/limits; re-read the planning chat for status changes; continue only approved work. Experimental values are tuning hypotheses, not approval for new systems. A consequential conflict with approved principles must be reported rather than silently resolved. No recurring automation was requested; coordination runs within the active implementation task.

## Coordination acceptance
The rendered planning reply on 18 November states **Seed 0.2.5 — Accepted**, records 79/79 tests and zero open confirmed review defects based on the implementation report, and instructs Codex to remain stopped at the 0.2.5 boundary. This is report-based acceptance, not an independent source-code audit. Balance and research content remain experimental; original graphics and human playtesting remain pending.

## Current boundary (superseded for 0.2.6)
The latest rendered 0.2.5 brief was retrieved on 18 November after browser access resumed. It confirms no superseding decisions and explicitly ends the authorized gameplay sequence at 0.2.5. Original graphics and human playtesting are next; do not implement 0.3 or second-age content without new approved scope.

## Supersession
The continuous roadmap supersedes the previous instruction to stop for separate approval after 0.2.1. Original art direction proposals and the earlier twelve-building proposal are not assumed approved merely because they appeared earlier. Approved twenty-building/twelve-resource list was retrieved from the explicit 0.2.2 brief.

## Seed 0.2.6 authorization and completion
Dima's direct implementation-chat brief on 18 November supersedes the historical 0.2.5 stop only for developer tools, research/UX usability, device preparation and verification. Original graphics, new eras and gameplay systems remain outside this scope. User subsequently states the UI is sufficient for this stage and asks to fetch the next ChatGPT instructions after finishing.

88 Debug tests pass (79 preserved + nine developer regressions); 80 Release tests pass (79 + normal-construction guard). Compiler probes confirm debug API absence in Release. Debug and Release simulator builds plus unsigned physical-device compilation pass. Phone/mini/Pro screenshots and research/placement/developer interactions checked. Independent review found resumed-scenario reset identity; fixed with isolated envelope metadata and a passing regression/probe. Normal v5 schema, clocks, geography and production balance remain unchanged. See `docs/milestones/seed-0.2.6-report.md`, `docs/design/device-testing.md` and `docs/design/approved-feature-audit-026.md`.

Ruling: use a sibling `.developer` save and explicit switch, with normal settlement restored and ordinary capped catch-up on return. Scenario metadata is debug-only; no debug setting persists as balance. Late fixture adds a third fishing shelter so 60 inhabitants start with positive food/water rates. No final graphics or object-drag gesture redesign. Physical iPhone is connected, but no development team is configured; account/security steps remain Dima's.

## Next-instruction retrieval pending
After completing 0.2.6, attempted to open the known City Design Coordination conversation. The in-app browser is signed out and redirects to ChatGPT login; the native Chrome bridge timed out. No new instructions were retrieved or assumed, and no report was sent externally. Sign-in handoff left open; Dima may sign in or paste the next brief.

## Next brief retrieved
18 November: Dima pointed to the open signed-in Chrome conversation. Rendered latest user feedback and ChatGPT response retrieved successfully; see `docs/milestones/seed-0.2.6-device-feedback-1.md`. This supersedes the prior retrieval blocker. Dima reports physical installation and requests building dragging, removal of arrows, compact resources with expanded information, collapsed goals and loading UI. Installation is user-reported, not an agent-verified device run. New iteration is recorded, not yet implemented. Long-press/free relocation and detailed interface concepts are provisional suggestions in the coordination response. No message sent externally.

## Physical-device feedback iteration 1 implemented
Dima explicitly instructed implementation after the fetched Chrome brief. Free long-press relocation (campfire fixed), compact resource icons/counts with live source popups, horizontal catalog without placement arrows, collapsed goals/future era hook and native/async renderer-aware loading are implemented. Save v5 and user-configured signing team retained. 98 Debug / 90 Release tests, four Release API probes and one landscape simulator XCTest gesture regression pass. Phone/mini/Pro Debug runs and Release/signed/unsigned device builds pass. Follow-up lifecycle test caught and fixed startup suspension bypassing offline cap. Independent review verified the fix. Physical install initially blocked by approval review; save-directory backup prepared before further installation. See `docs/milestones/seed-0.2.6-feedback-1-report.md`. No further gameplay/art scope assumed.

Physical update status: verified-save backup allowed the protected install retry. The first installer connection failed transiently; one bounded retry successfully installed the signed update on Dima's iPhone. Post-install normal save is byte-identical to the pre-update backup (v5, two buildings). No save reset, uninstall or account-setting changes.

Drag-mode clarity follow-up: direct user request implemented. Hand icon/label visible for all active previews; catalog selection activates immediate one-finger drag-and-drop with no hold, valid release builds once, invalid new drop preserves preview without charging. 100 Debug/92 Release tests and two UI gesture tests pass; signed build passes. Fresh iPhone save backup validated before update. No balance/save-schema change.

Drag-mode update installed on the iPhone; normal save byte-identical to the fresh pre-update backup. Launch awaits device unlock (CoreDevice reports Locked).

## Coordination report sent
On 18 November 2026, at Dima’s explicit request, the consolidated 0.2.6 + physical-device-feedback + drag-mode follow-up report was submitted to City Design Coordination in signed-in Chrome. The rendered conversation showed the new user message and ChatGPT generating a response, confirming submission. Report includes 100 Debug/92 Release tests, both gesture UI tests, developer/research/UX work, installed iPhone update, validated backups and byte-identical saves, fixed campfire and remaining hardware verification. Final reply/acceptance was not read because the subsequent Chrome observation timed out; no acceptance or new authorization is inferred.

## Seed 0.2.7 direct authorization and supersession

Dima's 18 November implementation-chat brief approves the physical-device usability iteration and authorizes 0.2.7. It supersedes partial five-pillar development: new Stone Age readiness now requires all active catalog building types and technologies, discovered/identified territories for required current extraction resources, and all five existing pillars/manufacturing requirements. Existing readiness and reward histories must remain sticky. No full-map or future-resource requirement, no actual second-age advancement.

Implemented seven journey chapters, catalog-derived checklist, historical readiness explanation, developer source scenario highlighting/original-vs-modified metadata, and adaptive building cards sharing Research components. Goals stay collapsed with compact counts; expanded summary opens full-screen measurable chapter detail. Original five construction awards and seven saved onboarding IDs remain intact. Save v5, campfire, geography and balances remain unchanged. JSON comparison against frozen 0.2.6 config confirms no numerical/recipe/terrain changes.

106 Debug / 96 Release tests and four Release API probes pass. Real-cost all-catalog playthrough: 9240s /154 minutes, 15 inhabitants, all 20 types and technologies, all seven chapters, all five pillars, 650/768 tiles. The serial duration is a pacing finding, not a tuned target. Independent read-only review found no concrete correctness defect. Live captures at docs/screenshots/seed-027; original XCTest attachment framing is defective on this simulator stack. iOS18 test picker-ID limitations are handled with supported map inspection; production gestures unchanged.

Initial signed iPhone update installed and both normal/developer saves compared byte-identical to validated pre-update directory. Final chapter-detail refresh and final per-device results are appended below. Graphics feasibility assessment covers baked models/sprites, real-time 3D, terrain, formats, thumbnails/icons, reuse/evolution and performance. SpriteKit and placeholders remain. Stop after 0.2.7 and this proposal; no later planning response grants new scope.

### Final 0.2.7 outcome — 19 November

106 Debug / 96 Release regressions pass; four Release API probes pass. Final three UI tests pass on phone and mini; all three also pass on Pro tablet. Debug phone/tablet runs, Release simulator and signed device builds pass. Final signed update installed on Dima's iPhone; fresh validated backup `/tmp/civilization-iphone-before-027-final-20261119`, post-update `/tmp/civilization-iphone-after-027-final-20261119`. Both normal and developer saves are byte-identical. Normal SHA-256 `28a6259eab9a3882f2a01d5de6c86f3034fdcffc5e74d543a2abc119a98f983b`. Physical FPS/battery/thermals and a new human 0.2.7 playtest remain unverified. Milestone report and graphics feasibility assessment delivered locally; no planning-chat acceptance is inferred. Work stops at the authorized boundary.

## Updated roadmap requested — 19 November 2026

At Dima's explicit request, sent a concise 0.2.7 completion summary and updated-roadmap request to the existing ChatGPT **City Design Coordination** conversation through the Codex chat connector. The send action succeeded. Asked to distinguish seven project stages from seven in-game chapters, identify remaining work and acceptance criteria, and return a next brief for Dima's approval. Detailed device/internal report was rejected by automatic approval review; the accepted summary omits device identifiers, save details and internal paths. New roadmap is pending retrieval; no new implementation authorization is inferred.

### Coordination reply retrieved

City Design Coordination accepted 0.2.7 **based on the implementation summary**, expressly without independent technical inspection. It updates project progress to **5 of 7 stages**: original graphics/visual identity and complete playable-product acceptance remain. This is a stage count, not an effort estimate. All seven in-game chapters are separately reported implemented.

Next proposed sequence: 0.3.1 visual identity; 0.3.2 rendering/asset pipeline; 0.3.3 terrain; 0.3.4 pilot buildings then catalog; 0.3.5 icons/UI identity; 0.3.6 restrained animation; then 0.4 full normal-gameplay testing, balance, physical-device optimization and acceptance. The proposed next brief covers 0.3.1–0.3.2 preparation and a Campfire/Hut/Woodcutter pilot specification, with Dima approving permanent direction, architecture, formats and pilot designs before production. No new implementation is authorized.

Exact retrieved roadmap and implementation annotations: `docs/design/roadmap-after-027.md`. The reply repeats an older 156-minute playthrough; current local measurement is already 154 minutes. No further landscape types or speculative environmental systems are approved. Reporting request complete; retain stop boundary.

## First-era review candidate — 19 November 2026

Dima directly authorized local Git, committing changes and finishing first-era goals before his review, superseding the earlier proposal-only graphics boundary for this reversible candidate. Main preserves baseline9e8e2cd; first-era-review contains implementation. ChatGPT supplied media examples across terrain, every building, icons, interface/loading and effects; third-party imagery remains inspiration. Three original concepts, all20transparent building originals/runtime sprites/thumbnails, native research/resource/pillar icons, terrain and bounded effects are integrated with provenance and replaceable mappings. SpriteKit, geography, savev5, historical rewards, tested gestures, iOS18 and signing are preserved.

115Debug/104Release tests, five Release API probes, all20art pairs and four UI tests on phone/mini/Pro pass. Full paid progression and recovery are verified, including a90minute alternative vs154minute serial route; no numerical tuning. Final signed iPhone update installed with both saves byte-identical to fresh backups. Small-settlement physical sample59.8FPS; pre-final-cache dense sample~48FPS. Final performance rerun was blocked by device lock. No sustained60FPS, thermal/battery or missing A15/M1device claim. See [final report](../milestones/first-era-review.md), [gallery](../art/review.html), [pacing review](first-era-pacing-review.md).

Stage status: stages1–5 retain existing report-based acceptance; stage6 original graphics/identity is implemented as a candidate awaiting Dima’s art review; stage7 full playable-product verification is automated and installed, with human enjoyment/acceptance and hardware limits explicitly pending. The seven in-game chapters are complete separately from this project-stage ledger. Stop for Dima’s review; no additional scope authorized.
