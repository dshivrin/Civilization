# S1-PLAY readiness and missing-dependency register

20 November 2026. This list tracks real dependencies; it cannot guarantee that no new defect or host failure will occur. No added service/account or paid tool is required for this local milestone.

| Need | Current evidence / gap | Resolution / owner | Blocks what? |
|---|---|---|---|
| Canonical design and pushed branch | Read; HEAD matched origin at3c72d88 | Engineering reconciliation/spec committed4f1f255 | Clear |
| Xcode / Swift / SDK | Installed; core tests compile, simulator inventory works | Use existing toolchain; no signing changes | Clear |
| Compiler cache access | Sandbox-only Swift run failed | Approved escalated swift test succeeds; standing build/test authorization | Resolved tool restriction |
| Simulator service access | Sandbox-only simctl refused connection | Approved escalated simctl lists booted phone/mini/Pro | Resolved tool restriction |
| XcodeBuildMCP | Availability changed mid-session; returned with simulator tools | Prefer available capabilities; xcodebuild/XCTest fallback for native matrix | No blocker |
| UI automation / screenshots | XCTest suite exists; prior XCTest image canvas bug documented | XCTest assertions plus inspected landscape simctl PNG; no test bypass in product | Native assertions pass; direct menu capture inspected; prior XCTest image export limitation remains |
| Git write / network | Personal dshivrin origin verified; fetch works; sandbox index write denied | Approved git add/commit/push outside sandbox | Resolved tool restriction |
| New Game / Continue tests | Existing independent library suite; new metadata/fresh/damaged-preservation tests green | Native launch/menu and relaunch checks in this milestone | Verified; see milestone evidence |
| Release UI suite | Existing RelocationUITests is DEBUG-only | Add shared ordinary-entry Release-capable test; isolate by separate simulator/test bundle ID, without Release fixture hooks | Resolved: Release phone/Pro entry and phone/mini completion pass |
| Progression / deadlock tests | Paid guided routes, strategies, starter reserve, worker recovery, persistence already exist | Rerun full core Debug/Release with current64×48config; publish chapter/timing evidence | Verified; see milestone evidence |
| Full-map optionality | Core guided routes assert discovered tiles < map area | Keep assertion and production geography regressions | No missing design |
| Save fixtures / isolation | UUID temporary Debug libraries, damaged/missing slots, developer companions | Preserve production containers; Release uses separate test app identity | No progress reset needed |
| Backup before replacing data | No replacement/reset action in this task; New Game creates separate file | Preserve geography validated backups. Any later physical update requires fresh validated backup | No backup gate for additive New Game |
| Physical playtest / unlocked device | Not established in this task | Dima launches candidate and plays normal route | Human acceptance; cannot substitute simulator results |
| Physical sustained performance | No new thermal/battery/FPS evidence | Dedicated physical measurement after playtest if needed | Open quality evidence, not launch implementation |
| Human pacing observation | Scripted routes are not natural player timing | Record real confusion, waits and elapsed play during1–2hour introductory target | Human tuning/acceptance |
| Bronze Age gameplay | Explicitly out of scope | Show readiness milestone only; preserve future backlog | No blocker |

## Required verification matrix

- Core Debug and Release: all tests, including fresh authentic start, independent games, damaged saves, background/switch atomicity, economy/reserve, ordinary paid full-era routes, required discoveries, sticky completion and reload.
- Release five developer-API exclusion probes.
- Debug phone + iPad mini + large iPad: normal entry/new/continue, independent games/persistence, developer isolation, earned completion; affected settlement interactions remain in existing suite.
- Release phone + iPad: ordinary menu/new/continue/persistence, no developer controls. Shared XCTest code must compile in Release. Core Release verifies paid completion without debug API.
- Inspect native landscape captures for menu and goal/completion readability; retain command/results and honest failures.
- Git diff/check, final review, personal-origin push and clean status. Human playtest is the milestone acceptance gate.

## Final readiness / remaining needs

No missing engineering tool blocks this milestone. Full core Debug189/Release171and five exclusion probes pass. Shared Release entry and earned-completion suites now exist and pass on phone/tablet, closing the identified suite gap. [Actual scope/results and commands](../milestones/s1-play.md). Independent review found no blocking defect.

Remaining needs: Dima's normal human playtest; optional sustained physical metrics; future damaged-index repair/back-to-menu recovery UX. No dedicated rapid-double-tap entry test yet; the MainActor guard and core concurrency regressions cover the underlying serialization. These are recorded gaps, not silently assumed coverage. No new accounts, plugins, signing changes, purchases or network services are required.

## Requested plan and physical update

Signed2f0e4b9now installed/launched on Dima's iPhone with fresh validated backup and byte-identical original progress; [actual evidence](s1-play/device-install.json). Human acceptance remains open. Dima asked us to request the plan from the Master chat; [retrieved reconstruction](../design/sources/2026-11-20-development-infrastructure-reconstructed.md) proposes unified reporting, broader regression harness, diagnostics and eventual CI. These are proposed next engineering stages, not missing mandatory software or already authorized implementation. Existing DEV IDs retain their meanings.
