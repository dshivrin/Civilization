# Civilization local QA report

**Status:** passed
**Revision:** b1255f38d524a47061949fd1eadbadc3f966676f

| Step | Result | Tests | Seconds | Log |
|---|---|---:|---:|---|
| ui-release-1 | passed | 9 | 303.878 | [ui-release-1.log](ui-release-1.log) |
| ui-release-2 | passed | 9 | 306.408 | [ui-release-2.log](ui-release-2.log) |

## Scope

```json
{
  "command": "test",
  "suite": "ui",
  "configuration": "release",
  "derived_data": "/tmp/civilization-stone-hud-legibility-delivery",
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
  "output": null
}
```

Counts describe executed tests, not parameterized case counts. Commands are listed below; raw logs retain tool output and failures. No human acceptance or sustained physical performance is inferred.

## Commands

```sh
xcodebuild test -project /Users/dima/.codex/worktrees/e735/Civilazation/Civilization.xcodeproj -scheme Civilization -configuration Release -destination 'platform=iOS Simulator,id=2361BBE2-9172-41D7-AD30-A353CACD332F' -derivedDataPath /private/tmp/civilization-stone-hud-legibility-delivery/release/2361BBE2-9172-41D7-AD30-A353CACD332F -resultBundlePath /private/tmp/civilization-qa-57257252a7bb4d15a414a7148aeb4562/ui-release-1.xcresult CODE_SIGNING_ALLOWED=NO PRODUCT_BUNDLE_IDENTIFIER=com.civilization.seed.qa -parallel-testing-enabled NO -only-testing:CivilizationUITests/NormalEntryUITests
```

```sh
xcodebuild test -project /Users/dima/.codex/worktrees/e735/Civilazation/Civilization.xcodeproj -scheme Civilization -configuration Release -destination 'platform=iOS Simulator,id=248B6E1A-8719-40B6-88D8-36593DAE9119' -derivedDataPath /private/tmp/civilization-stone-hud-legibility-delivery/release/248B6E1A-8719-40B6-88D8-36593DAE9119 -resultBundlePath /private/tmp/civilization-qa-57257252a7bb4d15a414a7148aeb4562/ui-release-2.xcresult CODE_SIGNING_ALLOWED=NO PRODUCT_BUNDLE_IDENTIFIER=com.civilization.seed.qa -parallel-testing-enabled NO -only-testing:CivilizationUITests/NormalEntryUITests
```
