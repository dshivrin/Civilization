# Civilization local QA report

**Status:** passed
**Revision:** 47e351f6599971d595bb5a04864cc0f807fd4794 (working tree modified)

| Step | Result | Tests | Seconds | Log |
|---|---|---:|---:|---|
| core-debug | passed | 16 | 5.759 | [core-debug.log](core-debug.log) |

## Scope

```json
{
  "command": "test",
  "suite": "core",
  "configuration": "debug",
  "derived_data": "/tmp/civilization-qa-builds",
  "filter": "riverbendPlayer|smallMapRetirement|eachNormalGameResumesItsOwnDeveloperCompanion|normalEntryMetadata|launchNewGame",
  "simulator": [],
  "only_testing": [],
  "output": null,
  "releaseAPIExclusions": "Not run: both configurations must pass in this invocation"
}
```

Counts describe executed tests, not parameterized case counts. Commands are listed below; raw logs retain tool output and failures. No human acceptance or sustained physical performance is inferred.

## Commands

```sh
swift test --package-path /Users/dima/dev/Civilazation-riverbend-player-review/Packages/GameCore --filter 'riverbendPlayer|smallMapRetirement|eachNormalGameResumesItsOwnDeveloperCompanion|normalEntryMetadata|launchNewGame'
```
