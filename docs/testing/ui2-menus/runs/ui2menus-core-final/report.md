# Civilization local QA report

**Status:** failed
**Revision:** 07e1011b8485cb245359ebe05afbe6dfca7eee32 (working tree modified)

| Step | Result | Tests | Seconds | Log |
|---|---|---:|---:|---|
| core-debug | failed | 320 | 25.621 | [core-debug.log](core-debug.log) |
| core-release | passed | 235 | 27.053 | [core-release.log](core-release.log) |

**core-debug:** Command exited 1; see raw log.

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
  "output": "/tmp/ui2menus-core-final",
  "releaseAPIExclusions": "Not run: both configurations must pass in this invocation"
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
