# Civilization local QA report

**Status:** failed
**Revision:** 94c3e6934f39250ad4e073b5b9b6581099f85a52 (working tree modified)

| Step | Result | Tests | Seconds | Log |
|---|---|---:|---:|---|
| core-debug | failed | 1 | 4.054 | [core-debug.log](core-debug.log) |

**core-debug:** Command exited 1; see raw log.

## Scope

```json
{
  "command": "test",
  "suite": "core",
  "configuration": "debug",
  "derived_data": "/tmp/civilization-qa-builds",
  "filter": "foundingReviewKeeps",
  "simulator": [],
  "only_testing": [],
  "output": "/tmp/ui2-yard-red-runtime",
  "releaseAPIExclusions": "Not run: both configurations must pass in this invocation"
}
```

Counts describe executed tests, not parameterized case counts. Commands are listed below; raw logs retain tool output and failures. No human acceptance or sustained physical performance is inferred.

## Commands

```sh
swift test --package-path /Users/dima/.codex/worktrees/f350/Civilazation/Packages/GameCore --filter foundingReviewKeeps
```
