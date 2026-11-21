# Civilization local QA report

**Status:** failed
**Revision:** 8f0146300e3efdca1a2b7cd87d36e7fcb3d9be5c (working tree modified)

| Step | Result | Tests | Seconds | Log |
|---|---|---:|---:|---|
| ui-debug-1 | failed | 8 | 508.225 | [ui-debug-1.log](ui-debug-1.log) |
| ui-debug-2 | failed | 7 | 677.124 | [ui-debug-2.log](ui-debug-2.log) |

**ui-debug-1:** Command exited 65; see raw log.

**ui-debug-2:** Command exited 65; see raw log.

## Scope

```json
{
  "command": "test",
  "suite": "ui",
  "configuration": "debug",
  "derived_data": "/tmp/civilization-qa-builds",
  "filter": null,
  "simulator": [
    "E118C061-9C37-4E18-9B03-A633E7240149",
    "390CFA90-D4C9-40F9-BA4A-FE3489C20809"
  ],
  "only_testing": [
    "CivilizationUITests/RelocationUITests/testUI2FoothillIntegratedTraversalAndSaveIsolation",
    "CivilizationUITests/RelocationUITests/testUI2FoundingMapInteractionAndReload",
    "CivilizationUITests/RelocationUITests/testUI2MenusActionsAndRetainedReturn",
    "CivilizationUITests/RelocationUITests/testUI2MenusLargerText",
    "CivilizationUITests/RelocationUITests/testUI2FogMotionIntegrated",
    "CivilizationUITests/RelocationUITests/testUI2FogComparisonMenusExit",
    "CivilizationUITests/RelocationUITests/testEconomyLabGestureRouteAndReload",
    "CivilizationUITests/RelocationUITests/testFirstEraDelayedDepletedRecoveryThroughCraft"
  ],
  "output": "/tmp/ui2-foothill-native-final"
}
```

Counts describe executed tests, not parameterized case counts. Commands are listed below; raw logs retain tool output and failures. No human acceptance or sustained physical performance is inferred.

## Commands

```sh
xcodebuild test -project /Users/dima/.codex/worktrees/0c84/Civilazation/Civilization.xcodeproj -scheme Civilization -configuration Debug -destination 'platform=iOS Simulator,id=E118C061-9C37-4E18-9B03-A633E7240149' -derivedDataPath /private/tmp/civilization-qa-builds/debug/E118C061-9C37-4E18-9B03-A633E7240149 -resultBundlePath /private/tmp/ui2-foothill-native-final/ui-debug-1.xcresult CODE_SIGNING_ALLOWED=NO PRODUCT_BUNDLE_IDENTIFIER=com.civilization.seed.qa -only-testing:CivilizationUITests/RelocationUITests/testUI2FoothillIntegratedTraversalAndSaveIsolation -only-testing:CivilizationUITests/RelocationUITests/testUI2FoundingMapInteractionAndReload -only-testing:CivilizationUITests/RelocationUITests/testUI2MenusActionsAndRetainedReturn -only-testing:CivilizationUITests/RelocationUITests/testUI2MenusLargerText -only-testing:CivilizationUITests/RelocationUITests/testUI2FogMotionIntegrated -only-testing:CivilizationUITests/RelocationUITests/testUI2FogComparisonMenusExit -only-testing:CivilizationUITests/RelocationUITests/testEconomyLabGestureRouteAndReload -only-testing:CivilizationUITests/RelocationUITests/testFirstEraDelayedDepletedRecoveryThroughCraft
```

```sh
xcodebuild test -project /Users/dima/.codex/worktrees/0c84/Civilazation/Civilization.xcodeproj -scheme Civilization -configuration Debug -destination 'platform=iOS Simulator,id=390CFA90-D4C9-40F9-BA4A-FE3489C20809' -derivedDataPath /private/tmp/civilization-qa-builds/debug/390CFA90-D4C9-40F9-BA4A-FE3489C20809 -resultBundlePath /private/tmp/ui2-foothill-native-final/ui-debug-2.xcresult CODE_SIGNING_ALLOWED=NO PRODUCT_BUNDLE_IDENTIFIER=com.civilization.seed.qa -only-testing:CivilizationUITests/RelocationUITests/testUI2FoothillIntegratedTraversalAndSaveIsolation -only-testing:CivilizationUITests/RelocationUITests/testUI2FoundingMapInteractionAndReload -only-testing:CivilizationUITests/RelocationUITests/testUI2MenusActionsAndRetainedReturn -only-testing:CivilizationUITests/RelocationUITests/testUI2MenusLargerText -only-testing:CivilizationUITests/RelocationUITests/testUI2FogMotionIntegrated -only-testing:CivilizationUITests/RelocationUITests/testUI2FogComparisonMenusExit -only-testing:CivilizationUITests/RelocationUITests/testEconomyLabGestureRouteAndReload -only-testing:CivilizationUITests/RelocationUITests/testFirstEraDelayedDepletedRecoveryThroughCraft
```
