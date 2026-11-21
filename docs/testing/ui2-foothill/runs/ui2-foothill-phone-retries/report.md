# Civilization local QA report

**Status:** passed
**Revision:** 8f0146300e3efdca1a2b7cd87d36e7fcb3d9be5c (working tree modified)

| Step | Result | Tests | Seconds | Log |
|---|---|---:|---:|---|
| ui-debug-1 | passed | 3 | 467.65 | [ui-debug-1.log](ui-debug-1.log) |

## Scope

```json
{
  "command": "test",
  "suite": "ui",
  "configuration": "debug",
  "derived_data": "/tmp/ui2-foothill-clean-cache",
  "filter": null,
  "simulator": [
    "E118C061-9C37-4E18-9B03-A633E7240149"
  ],
  "only_testing": [
    "CivilizationUITests/RelocationUITests/testUI2FoothillIntegratedTraversalAndSaveIsolation",
    "CivilizationUITests/RelocationUITests/testFirstEraDelayedDepletedRecoveryThroughCraft",
    "CivilizationUITests/RelocationUITests/testUI2MenusLargerText"
  ],
  "output": "/tmp/ui2-foothill-phone-retries"
}
```

Counts describe executed tests, not parameterized case counts. Commands are listed below; raw logs retain tool output and failures. No human acceptance or sustained physical performance is inferred.

## Commands

```sh
xcodebuild test -project /Users/dima/.codex/worktrees/0c84/Civilazation/Civilization.xcodeproj -scheme Civilization -configuration Debug -destination 'platform=iOS Simulator,id=E118C061-9C37-4E18-9B03-A633E7240149' -derivedDataPath /private/tmp/ui2-foothill-clean-cache/debug/E118C061-9C37-4E18-9B03-A633E7240149 -resultBundlePath /private/tmp/ui2-foothill-phone-retries/ui-debug-1.xcresult CODE_SIGNING_ALLOWED=NO PRODUCT_BUNDLE_IDENTIFIER=com.civilization.seed.qa -only-testing:CivilizationUITests/RelocationUITests/testUI2FoothillIntegratedTraversalAndSaveIsolation -only-testing:CivilizationUITests/RelocationUITests/testFirstEraDelayedDepletedRecoveryThroughCraft -only-testing:CivilizationUITests/RelocationUITests/testUI2MenusLargerText
```
