# Civilization local QA report

**Status:** passed
**Revision:** 47e351f6599971d595bb5a04864cc0f807fd4794 (working tree modified)

| Step | Result | Tests | Seconds | Log |
|---|---|---:|---:|---|
| ui-release-1 | passed | 1 | 30.849 | [ui-release-1.log](ui-release-1.log) |

## Scope

```json
{
  "command": "test",
  "suite": "ui",
  "configuration": "release",
  "derived_data": "/tmp/civilization-riverbend-earned-builds",
  "qa_identity": "93c8ad32-25c7-4942-a924-994b35aadbb5",
  "prepared_earned_container": true,
  "filter": null,
  "simulator": [
    "FC0EFF78-D008-4CCB-84A3-C40C0DDB3BBB"
  ],
  "only_testing": [
    "CivilizationUITests/NormalCompletionUITests"
  ],
  "output": null
}
```

Counts describe executed tests, not parameterized case counts. Commands are listed below; raw logs retain tool output and failures. No human acceptance or sustained physical performance is inferred.

## Commands

```sh
xcodebuild test -project /Users/dima/dev/Civilazation-riverbend-player-review/Civilization.xcodeproj -scheme Civilization -configuration Release -destination 'platform=iOS Simulator,id=FC0EFF78-D008-4CCB-84A3-C40C0DDB3BBB' -derivedDataPath /private/tmp/civilization-riverbend-earned-builds/release/FC0EFF78-D008-4CCB-84A3-C40C0DDB3BBB -resultBundlePath /private/tmp/civilization-qa-cd46f382ac154581bb9244fb0f23005c/ui-release-1.xcresult CODE_SIGNING_ALLOWED=NO PRODUCT_BUNDLE_IDENTIFIER=com.civilization.seed.qa.earned.93c8ad32-25c7-4942-a924-994b35aadbb5 -parallel-testing-enabled NO -only-testing:CivilizationUITests/NormalCompletionUITests
```
