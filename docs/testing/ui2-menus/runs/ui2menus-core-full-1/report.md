# Civilization local QA report

**Status:** passed
**Revision:** 07e1011b8485cb245359ebe05afbe6dfca7eee32 (working tree modified)

| Step | Result | Tests | Seconds | Log |
|---|---|---:|---:|---|
| core-debug | passed | 319 | 25.384 | [core-debug.log](core-debug.log) |
| core-release | passed | 235 | 35.524 | [core-release.log](core-release.log) |
| release-api-exclusions | passed | — | 5.402 | [release-api-exclusions.log](release-api-exclusions.log) |

## Scope

```json
{
  "command": "test",
  "suite": "core",
  "configuration": "both",
  "derived_data": "/tmp/civilization-qa-builds",
  "filter": null,
  "simulator": [],
  "only_testing": [],
  "output": "/tmp/ui2menus-core-full-1"
}
```

Counts describe executed tests, not parameterized case counts. Commands are listed below; raw logs retain tool output and failures. No human acceptance or sustained physical performance is inferred.

## Commands

```sh
swift test --package-path /Users/dima/.codex/worktrees/5e8f/Civilazation/Packages/GameCore
```

```sh
swift test --package-path /Users/dima/.codex/worktrees/5e8f/Civilazation/Packages/GameCore -c release
```

```sh
/Applications/Xcode.app/Contents/Developer/usr/bin/python3 /Users/dima/.codex/worktrees/5e8f/Civilazation/scripts/verify-developer-release.py
```
