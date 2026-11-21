# Civilization local QA report

**Status:** passed
**Revision:** 2495193e1e1f9818f41fdf2d41c92f5031d84e43 (working tree modified)

| Step | Result | Tests | Seconds | Log |
|---|---|---:|---:|---|
| core-debug | passed | 362 | 35.453 | [core-debug.log](core-debug.log) |
| core-release | passed | 268 | 36.376 | [core-release.log](core-release.log) |
| release-api-exclusions | passed | — | 6.421 | [release-api-exclusions.log](release-api-exclusions.log) |

## Scope

```json
{
  "command": "test",
  "suite": "core",
  "configuration": "both",
  "derived_data": "/tmp/civilization-qa-builds",
  "qa_identity": null,
  "prepared_earned_container": false,
  "filter": null,
  "simulator": [],
  "only_testing": [],
  "output": null
}
```

Counts describe executed tests, not parameterized case counts. Commands are listed below; raw logs retain tool output and failures. No human acceptance or sustained physical performance is inferred.

## Commands

```sh
swift test --package-path /private/tmp/civilization-stone-age-completion-cues/Packages/GameCore
```

```sh
swift test --package-path /private/tmp/civilization-stone-age-completion-cues/Packages/GameCore -c release
```

```sh
/Applications/Xcode.app/Contents/Developer/usr/bin/python3 /private/tmp/civilization-stone-age-completion-cues/scripts/verify-developer-release.py
```
