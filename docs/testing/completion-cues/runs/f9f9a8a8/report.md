# Civilization local QA report

**Status:** passed
**Revision:** c11dbd3f2a86e6e916569576195321a10432ef0f (working tree modified)

| Step | Result | Tests | Seconds | Log |
|---|---|---:|---:|---|
| core-debug | passed | 1 | 2.037 | [core-debug.log](core-debug.log) |

## Scope

```json
{
  "command": "test",
  "suite": "core",
  "configuration": "debug",
  "derived_data": "/tmp/civilization-qa-builds",
  "qa_identity": null,
  "prepared_earned_container": false,
  "filter": "completionCueHiddenGamesSheet",
  "simulator": [],
  "only_testing": [],
  "output": null,
  "releaseAPIExclusions": "Not run: both configurations must pass in this invocation"
}
```

Counts describe executed tests, not parameterized case counts. Commands are listed below; raw logs retain tool output and failures. No human acceptance or sustained physical performance is inferred.

## Commands

```sh
swift test --package-path /private/tmp/civilization-stone-age-completion-cues/Packages/GameCore --filter completionCueHiddenGamesSheet
```
