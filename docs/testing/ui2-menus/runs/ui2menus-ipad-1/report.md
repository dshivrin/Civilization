# Civilization local QA report

**Status:** failed
**Revision:** 07e1011b8485cb245359ebe05afbe6dfca7eee32 (working tree modified)

| Step | Result | Tests | Seconds | Log |
|---|---|---:|---:|---|
| ui-debug-1 | failed | 4 | 129.421 | [ui-debug-1.log](ui-debug-1.log) |

**ui-debug-1:** Command exited 65; see raw log.

## Scope

```json
{
  "command": "test",
  "suite": "ui",
  "configuration": "debug",
  "derived_data": "/tmp/ui2menus-native-build",
  "filter": null,
  "simulator": [
    "390CFA90-D4C9-40F9-BA4A-FE3489C20809"
  ],
  "only_testing": [
    "CivilizationUITests/RelocationUITests/testUI2MenusActionsAndRetainedReturn",
    "CivilizationUITests/RelocationUITests/testUI2MenusLargerText",
    "CivilizationUITests/RelocationUITests/testUI2FoundingMapInteractionAndReload",
    "CivilizationUITests/RelocationUITests/testEconomyLabGestureRouteAndReload"
  ],
  "output": "/tmp/ui2menus-ipad-1"
}
```

Counts describe executed tests, not parameterized case counts. Commands are listed below; raw logs retain tool output and failures. No human acceptance or sustained physical performance is inferred.

## Commands

```sh
xcodebuild test -project /Users/dima/.codex/worktrees/5e8f/Civilazation/Civilization.xcodeproj -scheme Civilization -configuration Debug -destination 'platform=iOS Simulator,id=390CFA90-D4C9-40F9-BA4A-FE3489C20809' -derivedDataPath /private/tmp/ui2menus-native-build/debug/390CFA90-D4C9-40F9-BA4A-FE3489C20809 -resultBundlePath /private/tmp/ui2menus-ipad-1/ui-debug-1.xcresult CODE_SIGNING_ALLOWED=NO PRODUCT_BUNDLE_IDENTIFIER=com.civilization.seed.qa -only-testing:CivilizationUITests/RelocationUITests/testUI2MenusActionsAndRetainedReturn -only-testing:CivilizationUITests/RelocationUITests/testUI2MenusLargerText -only-testing:CivilizationUITests/RelocationUITests/testUI2FoundingMapInteractionAndReload -only-testing:CivilizationUITests/RelocationUITests/testEconomyLabGestureRouteAndReload
```
