# Civilization local QA report

**Status:** failed
**Revision:** 6078cd6b71b29ca01cbc8dbe28d53899675fa072 (working tree modified)

| Step | Result | Tests | Seconds | Log |
|---|---|---:|---:|---|
| ui-release-1 | failed | 2 | 670.588 | [ui-release-1.log](ui-release-1.log) |

**ui-release-1:** Command exited 65; see raw log.

## Scope

```json
{
  "command": "test",
  "suite": "ui",
  "configuration": "release",
  "derived_data": "/tmp/civilization-route-audit-builds",
  "qa_identity": "602aa339-d777-4103-93d8-b8f682f80080",
  "prepared_earned_container": false,
  "filter": null,
  "simulator": [
    "364B7F36-DEB5-45E2-BB93-E3F5B8E8398E"
  ],
  "only_testing": [
    "CivilizationUITests/NormalEntryUITests/testRiverbendCompletedHutConnectPrimaryVisibleOnOpening",
    "CivilizationUITests/NormalEntryUITests/testRiverbendContinuousBaselineRouteWithExplicitScrollingThroughChapterThree"
  ],
  "output": "/tmp/civilization-route-audit-run3"
}
```

Counts describe executed tests, not parameterized case counts. Commands are listed below; raw logs retain tool output and failures. No human acceptance or sustained physical performance is inferred.

## Commands

```sh
xcodebuild test -project /private/tmp/civilization-native-route-audit/Civilization.xcodeproj -scheme Civilization -configuration Release -destination 'platform=iOS Simulator,id=364B7F36-DEB5-45E2-BB93-E3F5B8E8398E' -derivedDataPath /private/tmp/civilization-route-audit-builds/release/364B7F36-DEB5-45E2-BB93-E3F5B8E8398E -resultBundlePath /private/tmp/civilization-route-audit-run3/ui-release-1.xcresult CODE_SIGNING_ALLOWED=NO PRODUCT_BUNDLE_IDENTIFIER=com.civilization.seed.qa.earned.602aa339-d777-4103-93d8-b8f682f80080 -parallel-testing-enabled NO -only-testing:CivilizationUITests/NormalEntryUITests/testRiverbendCompletedHutConnectPrimaryVisibleOnOpening -only-testing:CivilizationUITests/NormalEntryUITests/testRiverbendContinuousBaselineRouteWithExplicitScrollingThroughChapterThree
```
