# Development infrastructure plan — coordination reconstruction

Source: designated Master Development Coordination conversation `6aff4440-ac14-83eb-b7bd-1f2d8bd9a0a9`, reply `a8cdbd33-338d-4af4-8640-1cab1d090b2d`, retrieved 20 November 2026 after Dima explicitly asked Codex to request the plan. This is the assistant's reconstructed proposal, not independently recovered original requirements or a new implementation authorization. Its DEV-001–006 labels are candidate infrastructure labels; existing canonical DEV-001 (isolated developer saves/tools) remains authoritative. Do not overwrite or renumber existing roadmap IDs. Current physical-installation evidence supersedes the reply's pending-installation statement. Human playtest remains the acceptance gate.

## Retrieved reply (verbatim)

## Civilization — Development tools and test suites plan

I recovered the earlier plan and checked it against the current urlS1-PLAY readiness registerhttps://github.com/dshivrin/Civilization/blob/first-era-review/docs/testing/s1-play-readiness.md\.

The intended plan was **DEV-001–006: Development Infrastructure &amp; Automated Quality Assurance**\. Its purpose is to give Codex a repeatable development and testing environment, catch regressions early, and produce consistent evidence before handing builds to you.

Importantly, this is a **separate engineering infrastructure workstream**, not another gameplay milestone.

### 1\. Original plan, reconstructed

| ID | Workstream | Intended scope | Status |
|--------|--------|--------|--------|
| DEV-001 | Toolchain and permissions | Verify Xcode, Swift, simulators, signing boundaries and Git access | Existing tooling verified |
| DEV-002 | Automated test matrix | Core Debug/Release, native UI, persistence, geography, progression and Release safety | Substantial coverage exists |
| DEV-003 | Unified test reporting | One repeatable command/report summarizing results, failures, devices and evidence | Proposed; not verified as implemented |
| DEV-004 | Visual and gameplay regression | Deterministic scenarios, screenshots, UI comparison and gameplay traces | Partially implemented; broader harness proposed |
| DEV-005 | Performance and diagnostics | Frame timing, memory, scene counts, simulation costs and sustained-device measurements | Short simulator evidence exists; broader diagnostics proposed |
| DEV-006 | CI automation | Automated validation on commits/PRs, with explicit tool and signing boundaries | Proposed; not verified as implemented |

The earlier recommended implementation sequence was **DEV-001 → DEV-002 → DEV-003**, with the remaining workstreams introduced incrementally.

### 2\. Required test suites

| Suite | Coverage |
|--------|--------|
| GameCore | Resources, costs, production, population, technology, construction and rewards |
| Persistence | Save/load, independent worlds, damaged files, offline catch-up and idempotency |
| Progression | Seven Stone Age chapters, paid completion routes, Bronze readiness and deadlock prevention |
| Geography | 64×48 bounds, quarry reserves, fog concealment, expeditions and discovery persistence |
| Native UI | New Game/Continue, building interaction, roads, relocation, gestures, menus and completion |
| Visual | Actual landscape screenshots, clipping, overlays, fog and different screen sizes |
| Performance | FPS/frame times, memory, cache rebuilds, scene counts, loading, thermals and battery |
| Release safety | Debug tools absent from Release, ordinary gameplay functioning without debug APIs |

The core tests, five Release exclusion probes and scoped native tests are already established. The current register confirms **189 Debug and 171 Release core tests**, plus Release-capable entry and completion tests.

Those results establish automated engineering readiness, not human playtest acceptance.

### 3\. Tools and dependencies

The earlier discussion established that **no additional mandatory software installation is needed** for the local testing workflow.

| Tool | Status |
|--------|--------|
| Xcode / Swift / Swift Package Manager | Available |
| XCTest / XCUITest | Available |
| iPhone, iPad mini, large iPad simulators | Available |
| `xcodebuild`, `simctl`, Git | Available with existing authorization |
| XcodeBuildMCP | Previously available, but availability can vary |
| `xcbeautify` | Optional log formatting |
| SwiftLint | Optional static analysis |
| Fastlane | Not required |
| CI runner | Not yet verified or provisioned |

The standing permission model should remain unchanged: use authorized build/test commands, preserve existing signing settings, and obtain separate authorization for consequential account or signing changes.

### 4\. Fixtures and reporting

**Existing\:** isolated Early/Developed/Late developer scenarios, the 64×48 grouped village, independent save fixtures, damaged-save recovery tests, legacy geography regression data, and deterministic progression routes.

**Proposed additions\:** a single test runner that executes the appropriate suites and produces a concise Markdown/JSON report; gameplay traces recording resources, elapsed time, chapter progression and actions; screenshot baselines; and a developer diagnostics view for frame timing, memory and simulation behavior.

These additions should reuse the current tests rather than create a parallel test architecture.

### 5\. Physical-device acceptance

The physical iPhone update is currently being prepared, not yet reported as installed. Its next evidence must establish the signed build version, validated backup, successful launch, preservation of existing development data and whether New Game/Continue works.

After installation, the human playtest should cover the first one to two hours of Stone Age gameplay: whether goals are understandable, resources appear when needed, progression feels natural, and the player can reach Bronze readiness without developer shortcuts.

Sustained physical FPS, thermal behavior and battery impact remain unverified. Short simulator samples do not close that gap.

### 6\. Recommended next engineering sequence

1. Finish the physical installation and collect Dima's actual playtest findings.
2. Implement DEV-003, the unified test runner/report, as the smallest infrastructure improvement.
3. Extend DEV-004 with deterministic gameplay traces and targeted visual regressions.
4. Add DEV-005 diagnostics and physical performance measurements.
5. Consider DEV-006 CI once the local runner is stable.

**Do not interrupt the current physical-installation work or launch another Codex session.** This plan belongs in the existing roadmap and can be implemented through the same development workflow.

The previous suggested document name was `CIVILIZATION_DEV_INFRASTRUCTURE.md`; I have not verified that it exists in the repository. The current readiness register is verified, but it does not establish that DEV-003–006 are implemented.

No additional source is required from Dima to reconstruct the plan. The only missing evidence for the immediate next step is Codex's physical-installation result and Dima's actual playtest feedback.
