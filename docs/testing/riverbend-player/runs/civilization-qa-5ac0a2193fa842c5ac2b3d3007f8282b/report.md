# Civilization local QA report

**Status:** failed
**Revision:** 47e351f6599971d595bb5a04864cc0f807fd4794 (working tree modified)

| Step | Result | Tests | Seconds | Log |
|---|---|---:|---:|---|
| ui-release-1 | failed | 1 | 286.055 | [ui-release-1.log](ui-release-1.log) |

**ui-release-1:** Command exited 65; see raw log.

## Scope

```json
{
  "command": "test",
  "suite": "ui",
  "configuration": "release",
  "derived_data": "/tmp/civilization-qa-builds",
  "qa_identity": "e1d72dfb-5292-4afc-9c9e-510dab325ce4",
  "prepared_earned_container": true,
  "filter": null,
  "simulator": [
    "E118C061-9C37-4E18-9B03-A633E7240149"
  ],
  "only_testing": [
    "CivilizationUITests/RiverbendEarnedUITests/testRealCraftStorageFindsAndRelaunch"
  ],
  "output": null
}
```

Counts describe executed tests, not parameterized case counts. Commands are listed below; raw logs retain tool output and failures. No human acceptance or sustained physical performance is inferred.

## Commands

```sh
xcodebuild test -project /Users/dima/dev/Civilazation-riverbend-player-review/Civilization.xcodeproj -scheme Civilization -configuration Release -destination 'platform=iOS Simulator,id=E118C061-9C37-4E18-9B03-A633E7240149' -derivedDataPath /private/tmp/civilization-qa-builds/release/E118C061-9C37-4E18-9B03-A633E7240149 -resultBundlePath /private/tmp/civilization-qa-5ac0a2193fa842c5ac2b3d3007f8282b/ui-release-1.xcresult CODE_SIGNING_ALLOWED=NO PRODUCT_BUNDLE_IDENTIFIER=com.civilization.seed.qa.earned.e1d72dfb-5292-4afc-9c9e-510dab325ce4 -parallel-testing-enabled NO -only-testing:CivilizationUITests/RiverbendEarnedUITests/testRealCraftStorageFindsAndRelaunch
```
