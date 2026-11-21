# Civilization local QA report

**Status:** passed
**Revision:** 05d3f56c0009585feb45441cffc1dbf1432aa1b5

| Step | Result | Tests | Seconds | Log |
|---|---|---:|---:|---|
| ui-release-1 | passed | 6 | 287.434 | [ui-release-1.log](ui-release-1.log) |
| ui-release-2 | passed | 9 | 333.022 | [ui-release-2.log](ui-release-2.log) |

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
xcodebuild test -project /Users/dima/.codex/worktrees/e735/Civilazation/Civilization.xcodeproj -scheme Civilization -configuration Release -destination 'platform=iOS Simulator,id=2361BBE2-9172-41D7-AD30-A353CACD332F' -derivedDataPath /private/tmp/civilization-qa-builds/release/2361BBE2-9172-41D7-AD30-A353CACD332F -resultBundlePath /private/tmp/civilization-qa-38aee1c731f84590ae2f8402de74c19a/ui-release-1.xcresult CODE_SIGNING_ALLOWED=NO PRODUCT_BUNDLE_IDENTIFIER=com.civilization.seed.qa -parallel-testing-enabled NO -only-testing:CivilizationUITests/NormalEntryUITests
```

```sh
xcodebuild test -project /Users/dima/.codex/worktrees/e735/Civilazation/Civilization.xcodeproj -scheme Civilization -configuration Release -destination 'platform=iOS Simulator,id=248B6E1A-8719-40B6-88D8-36593DAE9119' -derivedDataPath /private/tmp/civilization-qa-builds/release/248B6E1A-8719-40B6-88D8-36593DAE9119 -resultBundlePath /private/tmp/civilization-qa-38aee1c731f84590ae2f8402de74c19a/ui-release-2.xcresult CODE_SIGNING_ALLOWED=NO PRODUCT_BUNDLE_IDENTIFIER=com.civilization.seed.qa -parallel-testing-enabled NO -only-testing:CivilizationUITests/NormalEntryUITests
```
