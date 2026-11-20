# ENG-TOOLS-001 — reusable local engineering tools

20 November 2026. Authority: Dima directly requests reviewing the reconstructed proposal and saving repeated scripts with parameters for reuse. This authorizes local engineering tooling; S1-PLAY human acceptance remains open. Existing DEV-001 retains its identity.

## Review and approach

Reuse Swift Testing/XCTest, xcodebuild, devicectl, Git and the existing Release exclusion probes. A small Python standard-library CLI is preferable to a new framework or mandatory Fastlane/SwiftLint/xcbeautify installation. A local SwiftPM save-inspector executable packages its own resources and invokes real GameCore/GamePersistence validation; copying ad hoc swiftc executables caused a missing-resource-bundle failure in the last installation.

Save repeatable operations: prerequisite inventory, core/native test execution with JSON/Markdown summaries and raw logs, read-only device backup with production validation, and byte/metadata preservation comparison. Parameterize configuration, filter, simulator, native cases, device/bundle, backup root and report directory. Use argv arrays, explicit paths and unique output directories. Record exact command/configuration/revision/count/exit/time; zero executed tests never pass. No silent full-suite claim for filters. Never erase a simulator, reset a game, upload private saves, change signing, install an app, or access a physical device implicitly. Physical backup is opt-in with explicit device/bundle; it fails if output exists. Comparison fails on mutations; explicit allow-new-games permits additive slots/index selection only while preserving all prior bytes/entries.

## Scope

Small local CLI + focused save-inspection Swift package + safety/reporting tests + usage docs. Core/native suites stay in their established targets. No CI, visual-baseline comparison, in-game diagnostics, gameplay, persistence schema or economy changes. These remain proposed follow-ups. Art/human playtest acceptance is unchanged.

## Verification

Test failure/zero-test reporting, paths with spaces, output reuse, source mutation/symlink rejection, strict/additive comparison, legacy/grouped/current validation and damaged/missing saves. Run real full core Debug/Release/exclusion workflow through the CLI and a scoped native Release entry test. Exercise validator/comparison on existing private backup copies read-only. Exercise backup planning without physical access; no new physical transfer or installation needed in this tooling task. Commit/push coherent tooling and retain usage instructions for future sessions.
