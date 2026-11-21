# Civilization local QA report

**Status:** passed
**Revision:** 47e351f6599971d595bb5a04864cc0f807fd4794 (working tree modified)

| Step | Result | Tests | Seconds | Log |
|---|---|---:|---:|---|
| ui-release-1 | passed | 1 | 76.145 | [ui-release-1.log](ui-release-1.log) |

## Scope

```json
{
  "command": "test",
  "suite": "ui",
  "configuration": "release",
  "derived_data": "/tmp/civilization-qa-builds",
  "qa_identity": "9920c31f-b53b-4165-b6ab-c7278bfd165c",
  "prepared_earned_container": true,
  "filter": null,
  "simulator": [
    "390CFA90-D4C9-40F9-BA4A-FE3489C20809"
  ],
  "only_testing": [
    "CivilizationUITests/RiverbendEarnedUITests/testEnclosureGateAndSameGameContinue"
  ],
  "output": null
}
```

Counts describe executed tests, not parameterized case counts. Commands are listed below; raw logs retain tool output and failures. No human acceptance or sustained physical performance is inferred.

## Commands

```sh
xcodebuild test -project /Users/dima/dev/Civilazation-riverbend-player-review/Civilization.xcodeproj -scheme Civilization -configuration Release -destination 'platform=iOS Simulator,id=390CFA90-D4C9-40F9-BA4A-FE3489C20809' -derivedDataPath /private/tmp/civilization-qa-builds/release/390CFA90-D4C9-40F9-BA4A-FE3489C20809 -resultBundlePath /private/tmp/civilization-qa-645f85876ace41499a60253681c7975e/ui-release-1.xcresult CODE_SIGNING_ALLOWED=NO PRODUCT_BUNDLE_IDENTIFIER=com.civilization.seed.qa.earned.9920c31f-b53b-4165-b6ab-c7278bfd165c -parallel-testing-enabled NO -only-testing:CivilizationUITests/RiverbendEarnedUITests/testEnclosureGateAndSameGameContinue
```
