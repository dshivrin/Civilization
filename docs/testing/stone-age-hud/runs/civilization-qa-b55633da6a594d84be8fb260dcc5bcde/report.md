# Civilization local QA report

**Status:** passed
**Revision:** 88a659e510de13bb057c465ad11f65bcdb4a85bc

| Step | Result | Tests | Seconds | Log |
|---|---|---:|---:|---|
| core-debug | passed | 348 | 38.755 | [core-debug.log](core-debug.log) |
| core-release | passed | 255 | 17.889 | [core-release.log](core-release.log) |
| release-api-exclusions | passed | — | 6.932 | [release-api-exclusions.log](release-api-exclusions.log) |

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
swift test --package-path /Users/dima/.codex/worktrees/e735/Civilazation/Packages/GameCore
```

```sh
swift test --package-path /Users/dima/.codex/worktrees/e735/Civilazation/Packages/GameCore -c release
```

```sh
/Applications/Xcode.app/Contents/Developer/usr/bin/python3 /Users/dima/.codex/worktrees/e735/Civilazation/scripts/verify-developer-release.py
```
