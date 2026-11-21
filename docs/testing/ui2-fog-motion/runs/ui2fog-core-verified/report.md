# Civilization local QA report

**Status:** passed
**Revision:** 095e2c99bc02970255c33b0794229a124de1dd57 (working tree modified)

| Step | Result | Tests | Seconds | Log |
|---|---|---:|---:|---|
| core-debug | passed | 323 | 30.709 | [core-debug.log](core-debug.log) |
| core-release | passed | 235 | 30.98 | [core-release.log](core-release.log) |
| release-api-exclusions | passed | — | 5.857 | [release-api-exclusions.log](release-api-exclusions.log) |

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
  "output": "/tmp/ui2fog-core-verified"
}
```

Counts describe executed tests, not parameterized case counts. Commands are listed below; raw logs retain tool output and failures. No human acceptance or sustained physical performance is inferred.

## Commands

```sh
swift test --package-path /Users/dima/.codex/worktrees/a06c/Civilazation/Packages/GameCore
```

```sh
swift test --package-path /Users/dima/.codex/worktrees/a06c/Civilazation/Packages/GameCore -c release
```

```sh
/Applications/Xcode.app/Contents/Developer/usr/bin/python3 /Users/dima/.codex/worktrees/a06c/Civilazation/scripts/verify-developer-release.py
```
