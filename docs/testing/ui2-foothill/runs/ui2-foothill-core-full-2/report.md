# Civilization local QA report

**Status:** passed
**Revision:** 8f0146300e3efdca1a2b7cd87d36e7fcb3d9be5c (working tree modified)

| Step | Result | Tests | Seconds | Log |
|---|---|---:|---:|---|
| core-debug | passed | 327 | 27.48 | [core-debug.log](core-debug.log) |
| core-release | passed | 235 | 30.091 | [core-release.log](core-release.log) |
| release-api-exclusions | passed | — | 6.4 | [release-api-exclusions.log](release-api-exclusions.log) |

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
  "output": "/tmp/ui2-foothill-core-full-2"
}
```

Counts describe executed tests, not parameterized case counts. Commands are listed below; raw logs retain tool output and failures. No human acceptance or sustained physical performance is inferred.

## Commands

```sh
swift test --package-path /Users/dima/.codex/worktrees/0c84/Civilazation/Packages/GameCore
```

```sh
swift test --package-path /Users/dima/.codex/worktrees/0c84/Civilazation/Packages/GameCore -c release
```

```sh
/Applications/Xcode.app/Contents/Developer/usr/bin/python3 /Users/dima/.codex/worktrees/0c84/Civilazation/scripts/verify-developer-release.py
```
