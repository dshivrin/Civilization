# Civilization local QA report

**Status:** passed
**Revision:** 095e2c99bc02970255c33b0794229a124de1dd57 (working tree modified)

| Step | Result | Tests | Seconds | Log |
|---|---|---:|---:|---|
| ui-debug-1 | passed | 4 | 246.462 | [ui-debug-1.log](ui-debug-1.log) |

## Scope

```json
{
  "command": "test",
  "suite": "ui",
  "configuration": "debug",
  "derived_data": "/tmp/civilization-qa-builds",
  "filter": null,
  "simulator": [
    "390CFA90-D4C9-40F9-BA4A-FE3489C20809"
  ],
  "only_testing": [
    "CivilizationUITests/RelocationUITests/testUI2FogMotionIntegrated",
    "CivilizationUITests/RelocationUITests/testUI2FoundingMapInteractionAndReload",
    "CivilizationUITests/RelocationUITests/testUI2MenusActionsAndRetainedReturn",
    "CivilizationUITests/RelocationUITests/testEconomyLabGestureRouteAndReload"
  ],
  "output": "/tmp/ui2fog-ipad-final"
}
```

Counts describe executed tests, not parameterized case counts. Commands are listed below; raw logs retain tool output and failures. No human acceptance or sustained physical performance is inferred.

## Commands

```sh
xcodebuild test -project /Users/dima/.codex/worktrees/a06c/Civilazation/Civilization.xcodeproj -scheme Civilization -configuration Debug -destination 'platform=iOS Simulator,id=390CFA90-D4C9-40F9-BA4A-FE3489C20809' -derivedDataPath /private/tmp/civilization-qa-builds/debug/390CFA90-D4C9-40F9-BA4A-FE3489C20809 -resultBundlePath /private/tmp/ui2fog-ipad-final/ui-debug-1.xcresult CODE_SIGNING_ALLOWED=NO PRODUCT_BUNDLE_IDENTIFIER=com.civilization.seed.qa -only-testing:CivilizationUITests/RelocationUITests/testUI2FogMotionIntegrated -only-testing:CivilizationUITests/RelocationUITests/testUI2FoundingMapInteractionAndReload -only-testing:CivilizationUITests/RelocationUITests/testUI2MenusActionsAndRetainedReturn -only-testing:CivilizationUITests/RelocationUITests/testEconomyLabGestureRouteAndReload
```
