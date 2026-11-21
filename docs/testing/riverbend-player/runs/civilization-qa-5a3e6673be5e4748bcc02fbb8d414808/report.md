# Civilization local QA report

**Status:** failed
**Revision:** 47e351f6599971d595bb5a04864cc0f807fd4794 (working tree modified)

| Step | Result | Tests | Seconds | Log |
|---|---|---:|---:|---|
| core-release | failed | 2 | 1.484 | [core-release.log](core-release.log) |

**core-release:** Command exited 1; see raw log.

## Scope

```json
{
  "command": "test",
  "suite": "core",
  "configuration": "release",
  "derived_data": "/tmp/civilization-qa-builds",
  "qa_identity": null,
  "prepared_earned_container": false,
  "filter": "riverbendPlayerNormalNewGame|riverbendPlayerCraftStorage",
  "simulator": [],
  "only_testing": [],
  "output": null,
  "releaseAPIExclusions": "Not run: both configurations must pass in this invocation"
}
```

Counts describe executed tests, not parameterized case counts. Commands are listed below; raw logs retain tool output and failures. No human acceptance or sustained physical performance is inferred.

## Commands

```sh
swift test --package-path /Users/dima/dev/Civilazation-riverbend-player-review/Packages/GameCore -c release --filter 'riverbendPlayerNormalNewGame|riverbendPlayerCraftStorage'
```
