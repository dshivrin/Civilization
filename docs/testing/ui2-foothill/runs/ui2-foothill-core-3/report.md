# Civilization local QA report

**Status:** failed
**Revision:** 8f0146300e3efdca1a2b7cd87d36e7fcb3d9be5c (working tree modified)

| Step | Result | Tests | Seconds | Log |
|---|---|---:|---:|---|
| core-debug | failed | 0 | 8.771 | [core-debug.log](core-debug.log) |

**core-debug:** Command exited 1; see raw log.

## Scope

```json
{
  "command": "test",
  "suite": "core",
  "configuration": "debug",
  "derived_data": "/tmp/civilization-qa-builds",
  "filter": "foothill",
  "simulator": [],
  "only_testing": [],
  "output": "/tmp/ui2-foothill-core-3",
  "releaseAPIExclusions": "Not run: both configurations must pass in this invocation"
}
```

Counts describe executed tests, not parameterized case counts. Commands are listed below; raw logs retain tool output and failures. No human acceptance or sustained physical performance is inferred.

## Commands

```sh
swift test --package-path /Users/dima/.codex/worktrees/0c84/Civilazation/Packages/GameCore --filter foothill
```
