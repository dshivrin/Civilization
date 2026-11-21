# Civilization local QA report

**Status:** passed
**Revision:** 8f0146300e3efdca1a2b7cd87d36e7fcb3d9be5c (working tree modified)

| Step | Result | Tests | Seconds | Log |
|---|---|---:|---:|---|
| ui-release-1 | passed | 1 | 51.497 | [ui-release-1.log](ui-release-1.log) |

## Scope

```json
{
  "command": "test",
  "suite": "ui",
  "configuration": "release",
  "derived_data": "/tmp/civilization-qa-builds",
  "filter": null,
  "simulator": [
    "390CFA90-D4C9-40F9-BA4A-FE3489C20809"
  ],
  "only_testing": [
    "CivilizationUITests/NormalEntryUITests"
  ],
  "output": "/tmp/ui2-foothill-release-ipad"
}
```

Counts describe executed tests, not parameterized case counts. Commands are listed below; raw logs retain tool output and failures. No human acceptance or sustained physical performance is inferred.

## Commands

```sh
xcodebuild test -project /Users/dima/.codex/worktrees/0c84/Civilazation/Civilization.xcodeproj -scheme Civilization -configuration Release -destination 'platform=iOS Simulator,id=390CFA90-D4C9-40F9-BA4A-FE3489C20809' -derivedDataPath /private/tmp/civilization-qa-builds/release/390CFA90-D4C9-40F9-BA4A-FE3489C20809 -resultBundlePath /private/tmp/ui2-foothill-release-ipad/ui-release-1.xcresult CODE_SIGNING_ALLOWED=NO PRODUCT_BUNDLE_IDENTIFIER=com.civilization.seed.qa -only-testing:CivilizationUITests/NormalEntryUITests
```
