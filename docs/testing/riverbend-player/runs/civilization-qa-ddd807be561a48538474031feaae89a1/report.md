# Civilization local QA report

**Status:** failed
**Revision:** 47e351f6599971d595bb5a04864cc0f807fd4794 (working tree modified)

| Step | Result | Tests | Seconds | Log |
|---|---|---:|---:|---|
| ui-release-1 | failed | 2 | 68.686 | [ui-release-1.log](ui-release-1.log) |

**ui-release-1:** Command exited 65; see raw log.

## Scope

```json
{
  "command": "test",
  "suite": "ui",
  "configuration": "release",
  "derived_data": "/tmp/civilization-riverbend-earned-builds",
  "qa_identity": "3972f2de-b8f2-49dc-9140-bec1cfbf428c",
  "prepared_earned_container": true,
  "filter": null,
  "simulator": [
    "390CFA90-D4C9-40F9-BA4A-FE3489C20809"
  ],
  "only_testing": [
    "CivilizationUITests/RiverbendEarnedUITests/testEnclosureGateAndSameGameContinue",
    "CivilizationUITests/NormalCompletionUITests"
  ],
  "output": null
}
```

Counts describe executed tests, not parameterized case counts. Commands are listed below; raw logs retain tool output and failures. No human acceptance or sustained physical performance is inferred.

## Commands

```sh
xcodebuild test -project /Users/dima/dev/Civilazation-riverbend-player-review/Civilization.xcodeproj -scheme Civilization -configuration Release -destination 'platform=iOS Simulator,id=390CFA90-D4C9-40F9-BA4A-FE3489C20809' -derivedDataPath /private/tmp/civilization-riverbend-earned-builds/release/390CFA90-D4C9-40F9-BA4A-FE3489C20809 -resultBundlePath /private/tmp/civilization-qa-ddd807be561a48538474031feaae89a1/ui-release-1.xcresult CODE_SIGNING_ALLOWED=NO PRODUCT_BUNDLE_IDENTIFIER=com.civilization.seed.qa.earned.3972f2de-b8f2-49dc-9140-bec1cfbf428c -parallel-testing-enabled NO -only-testing:CivilizationUITests/RiverbendEarnedUITests/testEnclosureGateAndSameGameContinue -only-testing:CivilizationUITests/NormalCompletionUITests
```
