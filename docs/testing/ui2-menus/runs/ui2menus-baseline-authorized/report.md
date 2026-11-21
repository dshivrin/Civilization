# Civilization local QA report

**Status:** passed
**Revision:** 07e1011b8485cb245359ebe05afbe6dfca7eee32 (working tree modified)

| Step | Result | Tests | Seconds | Log |
|---|---|---:|---:|---|
| core-debug | passed | 9 | 11.536 | [core-debug.log](core-debug.log) |

## Scope

```json
{
  "command": "test",
  "suite": "core",
  "configuration": "debug",
  "derived_data": "/tmp/civilization-qa-builds",
  "filter": "foundingReview",
  "simulator": [],
  "only_testing": [],
  "output": "/tmp/ui2menus-baseline-authorized",
  "releaseAPIExclusions": "Not run: both configurations must pass in this invocation"
}
```

Counts describe executed tests, not parameterized case counts. Commands are listed below; raw logs retain tool output and failures. No human acceptance or sustained physical performance is inferred.

## Commands

```sh
swift test --package-path /Users/dima/.codex/worktrees/5e8f/Civilazation/Packages/GameCore --filter foundingReview
```
