# Civilization local QA report

**Status:** passed
**Revision:** 47e351f6599971d595bb5a04864cc0f807fd4794 (working tree modified)

| Step | Result | Tests | Seconds | Log |
|---|---|---:|---:|---|
| ui-release-1 | passed | 2 | 171.965 | [ui-release-1.log](ui-release-1.log) |
| ui-release-2 | passed | 2 | 134.964 | [ui-release-2.log](ui-release-2.log) |

## Scope

```json
{
  "command": "test",
  "suite": "ui",
  "configuration": "release",
  "derived_data": "/tmp/civilization-qa-builds",
  "qa_identity": "3ad4454e-f7bc-4637-a3d4-a45fcf82b198",
  "prepared_earned_container": false,
  "filter": null,
  "simulator": [
    "FC0EFF78-D008-4CCB-84A3-C40C0DDB3BBB",
    "390CFA90-D4C9-40F9-BA4A-FE3489C20809"
  ],
  "only_testing": [
    "CivilizationUITests/NormalEntryUITests/testRiverbendOrdinaryOpeningAndContinue",
    "CivilizationUITests/NormalEntryUITests/testNormalEntryPersistenceWithoutDeveloperHooks"
  ],
  "output": null
}
```

Counts describe executed tests, not parameterized case counts. Commands are listed below; raw logs retain tool output and failures. No human acceptance or sustained physical performance is inferred.

## Commands

```sh
xcodebuild test -project /Users/dima/dev/Civilazation-riverbend-player-review/Civilization.xcodeproj -scheme Civilization -configuration Release -destination 'platform=iOS Simulator,id=FC0EFF78-D008-4CCB-84A3-C40C0DDB3BBB' -derivedDataPath /private/tmp/civilization-qa-builds/release/FC0EFF78-D008-4CCB-84A3-C40C0DDB3BBB -resultBundlePath /private/tmp/civilization-qa-8d927eea52f94459a1e7a1ee365035f4/ui-release-1.xcresult CODE_SIGNING_ALLOWED=NO PRODUCT_BUNDLE_IDENTIFIER=com.civilization.seed.qa.earned.3ad4454e-f7bc-4637-a3d4-a45fcf82b198 -parallel-testing-enabled NO -only-testing:CivilizationUITests/NormalEntryUITests/testRiverbendOrdinaryOpeningAndContinue -only-testing:CivilizationUITests/NormalEntryUITests/testNormalEntryPersistenceWithoutDeveloperHooks
```

```sh
xcodebuild test -project /Users/dima/dev/Civilazation-riverbend-player-review/Civilization.xcodeproj -scheme Civilization -configuration Release -destination 'platform=iOS Simulator,id=390CFA90-D4C9-40F9-BA4A-FE3489C20809' -derivedDataPath /private/tmp/civilization-qa-builds/release/390CFA90-D4C9-40F9-BA4A-FE3489C20809 -resultBundlePath /private/tmp/civilization-qa-8d927eea52f94459a1e7a1ee365035f4/ui-release-2.xcresult CODE_SIGNING_ALLOWED=NO PRODUCT_BUNDLE_IDENTIFIER=com.civilization.seed.qa.earned.3ad4454e-f7bc-4637-a3d4-a45fcf82b198 -parallel-testing-enabled NO -only-testing:CivilizationUITests/NormalEntryUITests/testRiverbendOrdinaryOpeningAndContinue -only-testing:CivilizationUITests/NormalEntryUITests/testNormalEntryPersistenceWithoutDeveloperHooks
```
