# Civilization local QA report

**Status:** passed
**Revision:** 47e351f6599971d595bb5a04864cc0f807fd4794 (working tree modified)

| Step | Result | Tests | Seconds | Log |
|---|---|---:|---:|---|
| ui-debug-1 | passed | 1 | 331.004 | [ui-debug-1.log](ui-debug-1.log) |

## Scope

```json
{
  "command": "test",
  "suite": "ui",
  "configuration": "debug",
  "derived_data": "/tmp/civilization-qa-builds",
  "qa_identity": null,
  "prepared_earned_container": false,
  "filter": null,
  "simulator": [
    "FC0EFF78-D008-4CCB-84A3-C40C0DDB3BBB"
  ],
  "only_testing": [
    "CivilizationUITests/RelocationUITests/testFirstCraftGatherCraftSpendAndReload"
  ],
  "output": null
}
```

Counts describe executed tests, not parameterized case counts. Commands are listed below; raw logs retain tool output and failures. No human acceptance or sustained physical performance is inferred.

## Commands

```sh
xcodebuild test -project /Users/dima/dev/Civilazation-riverbend-player-review/Civilization.xcodeproj -scheme Civilization -configuration Debug -destination 'platform=iOS Simulator,id=FC0EFF78-D008-4CCB-84A3-C40C0DDB3BBB' -derivedDataPath /private/tmp/civilization-qa-builds/debug/FC0EFF78-D008-4CCB-84A3-C40C0DDB3BBB -resultBundlePath /private/tmp/civilization-qa-57d1c2b27aa84ad8bc9b9ef9db06ae13/ui-debug-1.xcresult CODE_SIGNING_ALLOWED=NO PRODUCT_BUNDLE_IDENTIFIER=com.civilization.seed.qa -parallel-testing-enabled NO -only-testing:CivilizationUITests/RelocationUITests/testFirstCraftGatherCraftSpendAndReload
```
