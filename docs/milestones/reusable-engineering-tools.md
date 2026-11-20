# ENG-TOOLS-001 — reusable local engineering tools

20 November 2026. Dima directly requested reviewing the reconstructed infrastructure proposal and saving repeated parameterized scripts. [Bounded design](../superpowers/specs/2026-11-20-reusable-engineering-tools-design.md), [plan](../superpowers/plans/2026-11-20-reusable-engineering-tools.md), [usage](../../scripts/README.md), [verification metadata](../testing/engineering-tools/verification.json).

## Proposal review and delivered scope

The useful immediate layer is local orchestration of existing tools and tests. No mandatory Fastlane, SwiftLint, xcbeautify, CI service or new framework is needed. Existing canonical DEV-001 remains developer/player separation; this tooling uses ENG-TOOLS-001. The reconstructed proposal's unified reporting is implemented locally in bounded form; broader diagnostics, screenshot baselines and CI remain future work.

Saved repetitions in `scripts/dev.py`:

| Command | Replaces | Reuse / limits |
|---|---|---|
|`doctor`|Repeated toolchain checks|Required/optional executable inventory, installed versions; no installs/accounts/device selection|
|`test`|Handwritten core/native commands, log paths and result summaries|Configuration/filter/simulator/case/cache/output parameters, existing suites, raw logs and JSON/Markdown reports; persistent native build caches|
|`validate-saves`|Repeated temporary swiftc validator scripts and manual bundle copies|Local SwiftPM SaveInspector carries resources, selects original configuration, validates files/backups/index/registered slots without migration/offline writes|
|`backup-device`|Repeated devicectl backup/copy/validation commands|Explicit device/bundle/new private output root, two matching copies, production validation; dry-run planning; no app launch/stop/install or writes to phone|
|`compare-saves`|Repeated temporary preservation/hash scripts|Strict bytes/file sets or explicit additive games/index comparison; previous data stays protected; separate production validation required for new files|

The script refuses existing outputs (including dangling aliases), empty preservation comparisons, symlink sources, private backup paths inside the repository and implicit device selection. It uses argv arrays rather than shell interpolation. Zero-test runs and missing explicitly requested native cases fail even when the subprocess exits zero; interruptions stop the rest of the matrix. Reports record exact scope, revision/dirty state, commands, counts, times, exit codes and evidence links. Physical/human acceptance is never inferred from simulator runs.

The inspector uses real GameCore/GamePersistence validation and packaged resources, accepts legitimate legacy/current lazy geography metadata pairs, rejects unsupported metadata and missing registered slots, and checks all source bytes before/after. Grouped developer geometry is available only in its Debug build. No raw save bodies or stocks are printed or committed.

## Actual verification

- Python standard-library suite: **10 tests pass**, including real child SIGINT, matrix cancellation, output/no-clobber/dangling alias, spaces, strict/additive preservation, zero-test failure and native selection detection.
- Inspector Swift Testing: **8 Debug / 7 Release pass**. Normal/legacy/backups, grouped Debug geometry, healthy indexed UUID slots, missing/damaged saves, unsupported index metadata, intentional lazy geography pairing and root/descendant aliases covered.
- Full existing GameCore through the reusable runner: **189 Debug / 171 Release pass**, plus all **five developer API exclusion probes**. Generated core report is under `/tmp/civilization-tools-final-core`.
- Real scoped Release iPad Pro13 M4/iOS18.6 `NormalEntryUITests`: **1 test passes** through the runner, separate QA identity; native result bundle/log/report under `/tmp/civilization-tools-native final`.
- Actual unmatched Swift test filter: Swift exits0/executes0, runner reports failure/exits1 as intended. This is an intentional negative check, not an unresolved test failure.
- Existing private iPhone backup copies validate read-only, including two normal games/developer companion and older geography backup; strict pre/post-install and additive post-new-game comparisons pass. Relative paths from another cwd and spaces in report directories work. No physical device action was issued in this task. New backup-wrapper transfer is not claimed hardware-tested; its dry-run is verified, and underlying copy commands were used in the prior installation.

Independent review found a map-metadata validation gap: production rejects an unsupported index identity although the first inspector accepted the healthy file. Regression failed first, then passed after compatibility validation. A dangling output alias also reproduced unwanted target creation and was fixed with a failing-before/passing-after test. Initial inspector tests exposed Foundation's `/var` versus `/private/var` enumeration mismatch; normalizing both paths fixed it. Earlier red logs remain local; final relevant suites are green. No deterministic concurrent source-mutation test was added; snapshot guards remain a documented coverage limit.

## Adoption and boundaries

Use [scripts/README.md](../../scripts/README.md) before writing another temporary test runner, save validator or hash comparison. Extend these focused commands for a repeated need rather than duplicate them. Existing XcodeBuildMCP capabilities and host permissions remain applicable. No gameplay/config/save schema/art/signing changes, app installation or external communication occurred in this tooling task. No third-party dependency added. Human S1-PLAY playtest remains open; CI, visual baselines and in-game performance diagnostics stay deferred.
