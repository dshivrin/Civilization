# Civilization local QA report

**Status:** passed
**Revision:** 05d3f56c0009585feb45441cffc1dbf1432aa1b5 (working tree modified)

| Step | Result | Tests | Seconds | Log |
|---|---|---:|---:|---|
| ui-release-1 | passed | 9 | 294.78 | [ui-release-1.log](ui-release-1.log) |

## Scope

```json
{
  "command": "test",
  "suite": "ui",
  "configuration": "release",
  "derived_data": "/tmp/civilization-qa-builds",
  "qa_identity": null,
  "prepared_earned_container": false,
  "filter": null,
  "simulator": [
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
xcodebuild test -project /Users/dima/.codex/worktrees/e735/Civilazation/Civilization.xcodeproj -scheme Civilization -configuration Release -destination 'platform=iOS Simulator,id=248B6E1A-8719-40B6-88D8-36593DAE9119' -derivedDataPath /private/tmp/civilization-qa-builds/release/248B6E1A-8719-40B6-88D8-36593DAE9119 -resultBundlePath /private/tmp/civilization-qa-25108c18c79043119e3cb506d009c4de/ui-release-1.xcresult CODE_SIGNING_ALLOWED=NO PRODUCT_BUNDLE_IDENTIFIER=com.civilization.seed.qa -parallel-testing-enabled NO -only-testing:CivilizationUITests/NormalEntryUITests
```
