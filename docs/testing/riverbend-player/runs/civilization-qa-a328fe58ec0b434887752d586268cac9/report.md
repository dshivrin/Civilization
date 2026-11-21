# Civilization local QA report

**Status:** failed
**Revision:** 47e351f6599971d595bb5a04864cc0f807fd4794 (working tree modified)

| Step | Result | Tests | Seconds | Log |
|---|---|---:|---:|---|
| ui-release-1 | failed | 2 | 75.829 | [ui-release-1.log](ui-release-1.log) |
| ui-release-2 | failed | 2 | 99.619 | [ui-release-2.log](ui-release-2.log) |

**ui-release-1:** Command exited 65; see raw log.

**ui-release-2:** Command exited 65; see raw log.

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
    "E118C061-9C37-4E18-9B03-A633E7240149",
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
xcodebuild test -project /Users/dima/dev/Civilazation-riverbend-player-review/Civilization.xcodeproj -scheme Civilization -configuration Release -destination 'platform=iOS Simulator,id=E118C061-9C37-4E18-9B03-A633E7240149' -derivedDataPath /private/tmp/civilization-qa-builds/release/E118C061-9C37-4E18-9B03-A633E7240149 -resultBundlePath /private/tmp/civilization-qa-a328fe58ec0b434887752d586268cac9/ui-release-1.xcresult CODE_SIGNING_ALLOWED=NO PRODUCT_BUNDLE_IDENTIFIER=com.civilization.seed.qa -parallel-testing-enabled NO -only-testing:CivilizationUITests/NormalEntryUITests/testRiverbendOrdinaryOpeningAndContinue -only-testing:CivilizationUITests/NormalEntryUITests/testNormalEntryPersistenceWithoutDeveloperHooks
```

```sh
xcodebuild test -project /Users/dima/dev/Civilazation-riverbend-player-review/Civilization.xcodeproj -scheme Civilization -configuration Release -destination 'platform=iOS Simulator,id=390CFA90-D4C9-40F9-BA4A-FE3489C20809' -derivedDataPath /private/tmp/civilization-qa-builds/release/390CFA90-D4C9-40F9-BA4A-FE3489C20809 -resultBundlePath /private/tmp/civilization-qa-a328fe58ec0b434887752d586268cac9/ui-release-2.xcresult CODE_SIGNING_ALLOWED=NO PRODUCT_BUNDLE_IDENTIFIER=com.civilization.seed.qa -parallel-testing-enabled NO -only-testing:CivilizationUITests/NormalEntryUITests/testRiverbendOrdinaryOpeningAndContinue -only-testing:CivilizationUITests/NormalEntryUITests/testNormalEntryPersistenceWithoutDeveloperHooks
```
