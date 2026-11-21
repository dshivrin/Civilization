# Civilization local QA report

**Status:** passed
**Revision:** fb068aba76ee4cc5104dbb9c696173d8b94bf75b (working tree modified)

| Step | Result | Tests | Seconds | Log |
|---|---|---:|---:|---|
| ui-debug-1 | passed | 2 | 112.022 | [ui-debug-1.log](ui-debug-1.log) |

## Scope

```json
{
  "command": "test",
  "suite": "ui",
  "configuration": "debug",
  "derived_data": "/tmp/civilization-qa-builds",
  "filter": null,
  "simulator": [
    "FC0EFF78-D008-4CCB-84A3-C40C0DDB3BBB"
  ],
  "only_testing": [
    "CivilizationUITests/RelocationUITests/testEconomyLabGestureRouteAndReload",
    "CivilizationUITests/RelocationUITests/testMapFindsWaitDismissGatherObserveAndReload"
  ],
  "output": null
}
```

Counts describe executed tests, not parameterized case counts. Commands are listed below; raw logs retain tool output and failures. No human acceptance or sustained physical performance is inferred.

## Commands

```sh
xcodebuild test -project /Users/dima/.codex/worktrees/f0dd/Civilazation/Civilization.xcodeproj -scheme Civilization -configuration Debug -destination 'platform=iOS Simulator,id=FC0EFF78-D008-4CCB-84A3-C40C0DDB3BBB' -derivedDataPath /private/tmp/civilization-qa-builds/debug/FC0EFF78-D008-4CCB-84A3-C40C0DDB3BBB -resultBundlePath /private/tmp/civilization-qa-daeb3bcb94a846cd8db728e191e5dbbf/ui-debug-1.xcresult CODE_SIGNING_ALLOWED=NO PRODUCT_BUNDLE_IDENTIFIER=com.civilization.seed.qa -only-testing:CivilizationUITests/RelocationUITests/testEconomyLabGestureRouteAndReload -only-testing:CivilizationUITests/RelocationUITests/testMapFindsWaitDismissGatherObserveAndReload
```
