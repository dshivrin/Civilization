# Civilization local QA report

**Status:** failed
**Revision:** adc4c2ce7b3c4d08fa04e597a2f376120cd96ebb

| Step | Result | Tests | Seconds | Log |
|---|---|---:|---:|---|
| ui-debug-1 | failed | 2 | 77.765 | [ui-debug-1.log](ui-debug-1.log) |

**ui-debug-1:** Command exited 65; see raw log.

## Scope

```json
{
  "command": "test",
  "suite": "ui",
  "configuration": "debug",
  "derived_data": "/tmp/civilization-stone-hud-fresh-build",
  "qa_identity": null,
  "prepared_earned_container": false,
  "filter": null,
  "simulator": [
    "E118C061-9C37-4E18-9B03-A633E7240149"
  ],
  "only_testing": [
    "CivilizationUITests/NormalEntryUITests/testStoneAgeMapFeedback",
    "CivilizationUITests/NormalEntryUITests/testStoneAgeHUDLargerTextAndOrdinaryRoutes"
  ],
  "output": null
}
```

Counts describe executed tests, not parameterized case counts. Commands are listed below; raw logs retain tool output and failures. No human acceptance or sustained physical performance is inferred.

## Commands

```sh
xcodebuild test -project /Users/dima/.codex/worktrees/e735/Civilazation/Civilization.xcodeproj -scheme Civilization -configuration Debug -destination 'platform=iOS Simulator,id=E118C061-9C37-4E18-9B03-A633E7240149' -derivedDataPath /private/tmp/civilization-stone-hud-fresh-build/debug/E118C061-9C37-4E18-9B03-A633E7240149 -resultBundlePath /private/tmp/civilization-qa-1e66a4b45a224a0ea79e882b7cc97c07/ui-debug-1.xcresult CODE_SIGNING_ALLOWED=NO PRODUCT_BUNDLE_IDENTIFIER=com.civilization.seed.qa -parallel-testing-enabled NO -only-testing:CivilizationUITests/NormalEntryUITests/testStoneAgeMapFeedback -only-testing:CivilizationUITests/NormalEntryUITests/testStoneAgeHUDLargerTextAndOrdinaryRoutes
```
