# Civilization local QA report

**Status:** failed
**Revision:** 50030fd11aa70d87ed1b2611e161b6c36651eeab (working tree modified)

| Step | Result | Tests | Seconds | Log |
|---|---|---:|---:|---|
| ui-release-1 | passed | 9 | 307.563 | [ui-release-1.log](ui-release-1.log) |
| ui-release-2 | failed | 0 | 108.78 | [ui-release-2.log](ui-release-2.log) |

**ui-release-2:** Command exited 130; see raw log.

## Scope

```json
{
  "command": "test",
  "suite": "ui",
  "configuration": "release",
  "derived_data": "/tmp/civilization-stone-hud-delivery-final",
  "qa_identity": null,
  "prepared_earned_container": false,
  "filter": null,
  "simulator": [
    "2361BBE2-9172-41D7-AD30-A353CACD332F",
    "248B6E1A-8719-40B6-88D8-36593DAE9119"
  ],
  "only_testing": [
    "CivilizationUITests/NormalEntryUITests"
  ],
  "output": null,
  "cancelled": true
}
```

Counts describe executed tests, not parameterized case counts. Commands are listed below; raw logs retain tool output and failures. No human acceptance or sustained physical performance is inferred.

## Commands

```sh
xcodebuild test -project /Users/dima/.codex/worktrees/e735/Civilazation/Civilization.xcodeproj -scheme Civilization -configuration Release -destination 'platform=iOS Simulator,id=2361BBE2-9172-41D7-AD30-A353CACD332F' -derivedDataPath /private/tmp/civilization-stone-hud-delivery-final/release/2361BBE2-9172-41D7-AD30-A353CACD332F -resultBundlePath /private/tmp/civilization-qa-5d26785ba0cf4363a30e72cd44738ed3/ui-release-1.xcresult CODE_SIGNING_ALLOWED=NO PRODUCT_BUNDLE_IDENTIFIER=com.civilization.seed.qa -parallel-testing-enabled NO -only-testing:CivilizationUITests/NormalEntryUITests
```

```sh
xcodebuild test -project /Users/dima/.codex/worktrees/e735/Civilazation/Civilization.xcodeproj -scheme Civilization -configuration Release -destination 'platform=iOS Simulator,id=248B6E1A-8719-40B6-88D8-36593DAE9119' -derivedDataPath /private/tmp/civilization-stone-hud-delivery-final/release/248B6E1A-8719-40B6-88D8-36593DAE9119 -resultBundlePath /private/tmp/civilization-qa-5d26785ba0cf4363a30e72cd44738ed3/ui-release-2.xcresult CODE_SIGNING_ALLOWED=NO PRODUCT_BUNDLE_IDENTIFIER=com.civilization.seed.qa -parallel-testing-enabled NO -only-testing:CivilizationUITests/NormalEntryUITests
```
