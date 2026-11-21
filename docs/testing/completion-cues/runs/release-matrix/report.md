# Civilization local QA report

**Status:** failed
**Revision:** 001024ded76cb0a5dab57db870fa1d3567f6a2c4 (working tree modified)

| Step | Result | Tests | Seconds | Log |
|---|---|---:|---:|---|
| ui-release-1 | failed | 4 | 217.147 | [ui-release-1.log](ui-release-1.log) |
| ui-release-2 | failed | 4 | 204.749 | [ui-release-2.log](ui-release-2.log) |

**ui-release-1:** Command exited 65; see raw log.

**ui-release-2:** Command exited 65; see raw log.

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
    "2361BBE2-9172-41D7-AD30-A353CACD332F",
    "248B6E1A-8719-40B6-88D8-36593DAE9119"
  ],
  "only_testing": [
    "CivilizationUITests/NormalEntryUITests/testOrdinaryCompletionCuesEarnContinueAndViewExactResults",
    "CivilizationUITests/NormalEntryUITests/testOrdinaryCompletionCuesWithSystemReduceMotion",
    "CivilizationUITests/NormalEntryUITests/testStoneAgeHUDHierarchyAndOrdinaryRoutes",
    "CivilizationUITests/NormalEntryUITests/testNormalEntryPersistenceWithoutDeveloperHooks"
  ],
  "output": null
}
```

Counts describe executed tests, not parameterized case counts. Commands are listed below; raw logs retain tool output and failures. No human acceptance or sustained physical performance is inferred.

## Commands

```sh
xcodebuild test -project /private/tmp/civilization-stone-age-completion-cues/Civilization.xcodeproj -scheme Civilization -configuration Release -destination 'platform=iOS Simulator,id=2361BBE2-9172-41D7-AD30-A353CACD332F' -derivedDataPath /private/tmp/completion-cues-native-builds/release/2361BBE2-9172-41D7-AD30-A353CACD332F -resultBundlePath /private/tmp/civilization-qa-0fb04736ca524749a06f6ce8a066e4ef/ui-release-1.xcresult CODE_SIGNING_ALLOWED=NO PRODUCT_BUNDLE_IDENTIFIER=com.civilization.seed.qa.earned.6b8dc41b-c627-4615-ab15-7088438250fa -parallel-testing-enabled NO -only-testing:CivilizationUITests/NormalEntryUITests/testOrdinaryCompletionCuesEarnContinueAndViewExactResults -only-testing:CivilizationUITests/NormalEntryUITests/testOrdinaryCompletionCuesWithSystemReduceMotion -only-testing:CivilizationUITests/NormalEntryUITests/testStoneAgeHUDHierarchyAndOrdinaryRoutes -only-testing:CivilizationUITests/NormalEntryUITests/testNormalEntryPersistenceWithoutDeveloperHooks
```

```sh
xcodebuild test -project /private/tmp/civilization-stone-age-completion-cues/Civilization.xcodeproj -scheme Civilization -configuration Release -destination 'platform=iOS Simulator,id=248B6E1A-8719-40B6-88D8-36593DAE9119' -derivedDataPath /private/tmp/completion-cues-native-builds/release/248B6E1A-8719-40B6-88D8-36593DAE9119 -resultBundlePath /private/tmp/civilization-qa-0fb04736ca524749a06f6ce8a066e4ef/ui-release-2.xcresult CODE_SIGNING_ALLOWED=NO PRODUCT_BUNDLE_IDENTIFIER=com.civilization.seed.qa.earned.6b8dc41b-c627-4615-ab15-7088438250fa -parallel-testing-enabled NO -only-testing:CivilizationUITests/NormalEntryUITests/testOrdinaryCompletionCuesEarnContinueAndViewExactResults -only-testing:CivilizationUITests/NormalEntryUITests/testOrdinaryCompletionCuesWithSystemReduceMotion -only-testing:CivilizationUITests/NormalEntryUITests/testStoneAgeHUDHierarchyAndOrdinaryRoutes -only-testing:CivilizationUITests/NormalEntryUITests/testNormalEntryPersistenceWithoutDeveloperHooks
```
