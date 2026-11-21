# Civilization local QA report

**Status:** failed
**Revision:** 07e1011b8485cb245359ebe05afbe6dfca7eee32 (working tree modified)

| Step | Result | Tests | Seconds | Log |
|---|---|---:|---:|---|
| ui-debug-1 | failed | 4 | 146.729 | [ui-debug-1.log](ui-debug-1.log) |

**ui-debug-1:** Command exited 65; see raw log.

## Scope

```json
{
  "command": "test",
  "suite": "ui",
  "configuration": "debug",
  "derived_data": "/tmp/ui2menus-se-build",
  "filter": null,
  "simulator": [
    "E118C061-9C37-4E18-9B03-A633E7240149"
  ],
  "only_testing": [
    "CivilizationUITests/RelocationUITests/testUI2MenusActionsAndRetainedReturn",
    "CivilizationUITests/RelocationUITests/testUI2MenusLargerText",
    "CivilizationUITests/RelocationUITests/testUI2FoundingMapInteractionAndReload",
    "CivilizationUITests/RelocationUITests/testEconomyLabGestureRouteAndReload"
  ],
  "output": "/tmp/ui2menus-phone-final"
}
```

Counts describe executed tests, not parameterized case counts. Commands are listed below; raw logs retain tool output and failures. No human acceptance or sustained physical performance is inferred.

## Commands

```sh
xcodebuild test -project /Users/dima/.codex/worktrees/5e8f/Civilazation/Civilization.xcodeproj -scheme Civilization -configuration Debug -destination 'platform=iOS Simulator,id=E118C061-9C37-4E18-9B03-A633E7240149' -derivedDataPath /private/tmp/ui2menus-se-build/debug/E118C061-9C37-4E18-9B03-A633E7240149 -resultBundlePath /private/tmp/ui2menus-phone-final/ui-debug-1.xcresult CODE_SIGNING_ALLOWED=NO PRODUCT_BUNDLE_IDENTIFIER=com.civilization.seed.qa -only-testing:CivilizationUITests/RelocationUITests/testUI2MenusActionsAndRetainedReturn -only-testing:CivilizationUITests/RelocationUITests/testUI2MenusLargerText -only-testing:CivilizationUITests/RelocationUITests/testUI2FoundingMapInteractionAndReload -only-testing:CivilizationUITests/RelocationUITests/testEconomyLabGestureRouteAndReload
```
