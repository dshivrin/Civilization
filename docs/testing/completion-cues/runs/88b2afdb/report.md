# Civilization local QA report

**Status:** failed
**Revision:** 0b9b754fc601a71d83020f569355553a65007d5f (working tree modified)

| Step | Result | Tests | Seconds | Log |
|---|---|---:|---:|---|
| ui-debug-1 | failed | 1 | 42.863 | [ui-debug-1.log](ui-debug-1.log) |

**ui-debug-1:** Command exited 65; see raw log.

## Scope

```json
{
  "command": "test",
  "suite": "ui",
  "configuration": "debug",
  "derived_data": "/tmp/civilization-qa-builds",
  "qa_identity": "923A9541-0107-4599-9AB5-5F7DE1D1EE60",
  "prepared_earned_container": false,
  "filter": null,
  "simulator": [
    "2361BBE2-9172-41D7-AD30-A353CACD332F"
  ],
  "only_testing": [
    "CivilizationUITests/NormalEntryUITests/testOrdinaryCompletionCuesEarnContinueAndViewExactResults"
  ],
  "output": null
}
```

Counts describe executed tests, not parameterized case counts. Commands are listed below; raw logs retain tool output and failures. No human acceptance or sustained physical performance is inferred.

## Commands

```sh
xcodebuild test -project /private/tmp/civilization-stone-age-completion-cues/Civilization.xcodeproj -scheme Civilization -configuration Debug -destination 'platform=iOS Simulator,id=2361BBE2-9172-41D7-AD30-A353CACD332F' -derivedDataPath /private/tmp/civilization-qa-builds/debug/2361BBE2-9172-41D7-AD30-A353CACD332F -resultBundlePath /private/tmp/civilization-qa-88b2afdb42e0419fbcb64cc7f8cef048/ui-debug-1.xcresult CODE_SIGNING_ALLOWED=NO PRODUCT_BUNDLE_IDENTIFIER=com.civilization.seed.qa.earned.923a9541-0107-4599-9ab5-5f7de1d1ee60 -parallel-testing-enabled NO -only-testing:CivilizationUITests/NormalEntryUITests/testOrdinaryCompletionCuesEarnContinueAndViewExactResults
```
