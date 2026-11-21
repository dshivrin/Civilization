# Civilization local QA report

**Status:** passed
**Revision:** fb068aba76ee4cc5104dbb9c696173d8b94bf75b (working tree modified)

| Step | Result | Tests | Seconds | Log |
|---|---|---:|---:|---|
| ui-release-1 | passed | 1 | 77.848 | [ui-release-1.log](ui-release-1.log) |

## Scope

```json
{
  "command": "test",
  "suite": "ui",
  "configuration": "release",
  "derived_data": "/tmp/civilization-qa-builds",
  "filter": null,
  "simulator": [
    "EC995F2A-534A-4E57-A59C-0DE408729150"
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
xcodebuild test -project /Users/dima/.codex/worktrees/f0dd/Civilazation/Civilization.xcodeproj -scheme Civilization -configuration Release -destination 'platform=iOS Simulator,id=EC995F2A-534A-4E57-A59C-0DE408729150' -derivedDataPath /private/tmp/civilization-qa-builds/release/EC995F2A-534A-4E57-A59C-0DE408729150 -resultBundlePath /private/tmp/civilization-qa-aabbc8cc353345bfbed7278204e2b7b9/ui-release-1.xcresult CODE_SIGNING_ALLOWED=NO PRODUCT_BUNDLE_IDENTIFIER=com.civilization.seed.qa -only-testing:CivilizationUITests/NormalEntryUITests
```
