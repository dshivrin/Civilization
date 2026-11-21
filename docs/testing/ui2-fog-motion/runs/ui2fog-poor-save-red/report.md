# Civilization local QA report

**Status:** failed
**Revision:** 095e2c99bc02970255c33b0794229a124de1dd57 (working tree modified)

| Step | Result | Tests | Seconds | Log |
|---|---|---:|---:|---|
| core-debug | failed | 0 | 2.952 | [core-debug.log](core-debug.log) |

**core-debug:** Command exited 1; see raw log.

## Scope

```json
{
  "command": "test",
  "suite": "core",
  "configuration": "debug",
  "derived_data": "/tmp/civilization-qa-builds",
  "filter": "temporaryForestHutSuggestion",
  "simulator": [],
  "only_testing": [],
  "output": "/tmp/ui2fog-poor-save-red",
  "releaseAPIExclusions": "Not run: both configurations must pass in this invocation"
}
```

Counts describe executed tests, not parameterized case counts. Commands are listed below; raw logs retain tool output and failures. No human acceptance or sustained physical performance is inferred.

## Commands

```sh
swift test --package-path /Users/dima/.codex/worktrees/a06c/Civilazation/Packages/GameCore --filter temporaryForestHutSuggestion
```
