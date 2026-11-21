# Civilization local QA report

**Status:** passed
**Revision:** 3f27d1e711096bc22cc400f354bb627cbb9e9535 (working tree modified)

| Step | Result | Tests | Seconds | Log |
|---|---|---:|---:|---|
| ui-release-1 | passed | 4 | 82.233 | [ui-release-1.log](ui-release-1.log) |

## Scope

```json
{
  "command": "test",
  "suite": "ui",
  "configuration": "release",
  "derived_data": "/tmp/civilization-qa-builds",
  "qa_identity": null,
  "prepared_earned_container": false,
  "filter": null,
  "simulator": [
    "E118C061-9C37-4E18-9B03-A633E7240149"
  ],
  "only_testing": [
    "CivilizationUITests/NormalEntryUITests/testStoneAgeGoalsStayAvailableDuringContext",
    "CivilizationUITests/NormalEntryUITests/testStoneAgeMapFeedback",
    "CivilizationUITests/NormalEntryUITests/testStoneAgeExploreResearchAndReturn",
    "CivilizationUITests/NormalEntryUITests/testStoneAgeHUDLargerTextAndOrdinaryRoutes"
  ],
  "output": null
}
```

Counts describe executed tests, not parameterized case counts. Commands are listed below; raw logs retain tool output and failures. No human acceptance or sustained physical performance is inferred.

## Commands

```sh
xcodebuild test -project /Users/dima/.codex/worktrees/e735/Civilazation/Civilization.xcodeproj -scheme Civilization -configuration Release -destination 'platform=iOS Simulator,id=E118C061-9C37-4E18-9B03-A633E7240149' -derivedDataPath /private/tmp/civilization-qa-builds/release/E118C061-9C37-4E18-9B03-A633E7240149 -resultBundlePath /private/tmp/civilization-qa-a9f05b30e9ce412eb6dcc2c7d90f4071/ui-release-1.xcresult CODE_SIGNING_ALLOWED=NO PRODUCT_BUNDLE_IDENTIFIER=com.civilization.seed.qa -parallel-testing-enabled NO -only-testing:CivilizationUITests/NormalEntryUITests/testStoneAgeGoalsStayAvailableDuringContext -only-testing:CivilizationUITests/NormalEntryUITests/testStoneAgeMapFeedback -only-testing:CivilizationUITests/NormalEntryUITests/testStoneAgeExploreResearchAndReturn -only-testing:CivilizationUITests/NormalEntryUITests/testStoneAgeHUDLargerTextAndOrdinaryRoutes
```
