# Civilization local QA report

**Status:** failed
**Revision:** 8f0146300e3efdca1a2b7cd87d36e7fcb3d9be5c (working tree modified)

| Step | Result | Tests | Seconds | Log |
|---|---|---:|---:|---|
| ui-debug-1 | failed | 0 | 47.994 | [ui-debug-1.log](ui-debug-1.log) |

**ui-debug-1:** Command exited 130; see raw log.

## Scope

```json
{
  "command": "test",
  "suite": "ui",
  "configuration": "debug",
  "derived_data": "/tmp/ui2-foothill-clean-cache",
  "filter": null,
  "simulator": [
    "390CFA90-D4C9-40F9-BA4A-FE3489C20809"
  ],
  "only_testing": [
    "CivilizationUITests/RelocationUITests/testUI2FoothillIntegratedTraversalAndSaveIsolation"
  ],
  "output": "/tmp/ui2-foothill-clean-ipad",
  "cancelled": true
}
```

Counts describe executed tests, not parameterized case counts. Commands are listed below; raw logs retain tool output and failures. No human acceptance or sustained physical performance is inferred.

## Commands

```sh
xcodebuild test -project /Users/dima/.codex/worktrees/0c84/Civilazation/Civilization.xcodeproj -scheme Civilization -configuration Debug -destination 'platform=iOS Simulator,id=390CFA90-D4C9-40F9-BA4A-FE3489C20809' -derivedDataPath /private/tmp/ui2-foothill-clean-cache/debug/390CFA90-D4C9-40F9-BA4A-FE3489C20809 -resultBundlePath /private/tmp/ui2-foothill-clean-ipad/ui-debug-1.xcresult CODE_SIGNING_ALLOWED=NO PRODUCT_BUNDLE_IDENTIFIER=com.civilization.seed.qa -only-testing:CivilizationUITests/RelocationUITests/testUI2FoothillIntegratedTraversalAndSaveIsolation
```
