# Civilization local QA report

**Status:** passed
**Revision:** 6078cd6b71b29ca01cbc8dbe28d53899675fa072 (working tree modified)

| Step | Result | Tests | Seconds | Log |
|---|---|---:|---:|---|
| ui-release-1 | passed | 3 | 207.777 | [ui-release-1.log](ui-release-1.log) |

## Scope

```json
{
  "command": "test",
  "suite": "ui",
  "configuration": "release",
  "derived_data": "/tmp/civilization-route-audit-builds",
  "qa_identity": "7107d02a-85e4-4f13-979a-46b2cb39060a",
  "prepared_earned_container": false,
  "filter": null,
  "simulator": [
    "041217BC-7655-4195-B255-813B8D5078AE"
  ],
  "only_testing": [
    "CivilizationUITests/NormalEntryUITests/testRiverbendOrdinaryOpeningAndContinue",
    "CivilizationUITests/NormalEntryUITests/testRiverbendCompletedHutConnectPrimaryVisibleOnOpening",
    "CivilizationUITests/NormalEntryUITests/testRiverbendThirdVisibleActionPrimaryVisibleWithoutScrolling"
  ],
  "output": "/tmp/civilization-route-audit-ipad-run4"
}
```

Counts describe executed tests, not parameterized case counts. Commands are listed below; raw logs retain tool output and failures. No human acceptance or sustained physical performance is inferred.

## Commands

```sh
xcodebuild test -project /private/tmp/civilization-native-route-audit/Civilization.xcodeproj -scheme Civilization -configuration Release -destination 'platform=iOS Simulator,id=041217BC-7655-4195-B255-813B8D5078AE' -derivedDataPath /private/tmp/civilization-route-audit-builds/release/041217BC-7655-4195-B255-813B8D5078AE -resultBundlePath /private/tmp/civilization-route-audit-ipad-run4/ui-release-1.xcresult CODE_SIGNING_ALLOWED=NO PRODUCT_BUNDLE_IDENTIFIER=com.civilization.seed.qa.earned.7107d02a-85e4-4f13-979a-46b2cb39060a -parallel-testing-enabled NO -only-testing:CivilizationUITests/NormalEntryUITests/testRiverbendOrdinaryOpeningAndContinue -only-testing:CivilizationUITests/NormalEntryUITests/testRiverbendCompletedHutConnectPrimaryVisibleOnOpening -only-testing:CivilizationUITests/NormalEntryUITests/testRiverbendThirdVisibleActionPrimaryVisibleWithoutScrolling
```
