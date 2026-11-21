# Civilization local QA report

**Status:** failed
**Revision:** 001024ded76cb0a5dab57db870fa1d3567f6a2c4 (working tree modified)

| Step | Result | Tests | Seconds | Log |
|---|---|---:|---:|---|
| ui-release-1 | failed | 2 | 81.798 | [ui-release-1.log](ui-release-1.log) |

**ui-release-1:** Command exited 65; see raw log.

## Scope

```json
{
  "command": "test",
  "suite": "ui",
  "configuration": "release",
  "derived_data": "/private/tmp/completion-cues-native-builds",
  "qa_identity": "6B8DC41B-C627-4615-AB15-7088438250FA",
  "prepared_earned_container": false,
  "filter": null,
  "simulator": [
    "2361BBE2-9172-41D7-AD30-A353CACD332F"
  ],
  "only_testing": [
    "CivilizationUITests/NormalEntryUITests/testOrdinaryCompletionCuesEarnContinueAndViewExactResults",
    "CivilizationUITests/NormalEntryUITests/testStoneAgeHUDHierarchyAndOrdinaryRoutes"
  ],
  "output": null
}
```

Counts describe executed tests, not parameterized case counts. Commands are listed below; raw logs retain tool output and failures. No human acceptance or sustained physical performance is inferred.

## Commands

```sh
xcodebuild test -project /private/tmp/civilization-stone-age-completion-cues/Civilization.xcodeproj -scheme Civilization -configuration Release -destination 'platform=iOS Simulator,id=2361BBE2-9172-41D7-AD30-A353CACD332F' -derivedDataPath /private/tmp/completion-cues-native-builds/release/2361BBE2-9172-41D7-AD30-A353CACD332F -resultBundlePath /private/tmp/civilization-qa-e068749e51424b7484f680386a6ef62a/ui-release-1.xcresult CODE_SIGNING_ALLOWED=NO PRODUCT_BUNDLE_IDENTIFIER=com.civilization.seed.qa.earned.6b8dc41b-c627-4615-ab15-7088438250fa -parallel-testing-enabled NO -only-testing:CivilizationUITests/NormalEntryUITests/testOrdinaryCompletionCuesEarnContinueAndViewExactResults -only-testing:CivilizationUITests/NormalEntryUITests/testStoneAgeHUDHierarchyAndOrdinaryRoutes
```
