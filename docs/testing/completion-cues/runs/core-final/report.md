# Civilization local QA report

**Status:** passed
**Revision:** d892d9a97e825fb29b712fe84b365b3032eb2898 (working tree modified)

| Step | Result | Tests | Seconds | Log |
|---|---|---:|---:|---|
| core-debug | passed | 362 | 31.507 | [core-debug.log](core-debug.log) |
| core-release | passed | 268 | 36.448 | [core-release.log](core-release.log) |
| release-api-exclusions | passed | — | 6.183 | [release-api-exclusions.log](release-api-exclusions.log) |

## Scope

```json
{
  "command": "test",
  "suite": "core",
  "configuration": "both",
  "derived_data": "/tmp/civilization-qa-builds",
  "qa_identity": null,
  "prepared_earned_container": false,
  "filter": null,
  "simulator": [],
  "only_testing": [],
  "output": null
}
```

Counts describe executed tests, not parameterized case counts. Commands are listed below; raw logs retain tool output and failures. No human acceptance or sustained physical performance is inferred.

## Commands

```sh
swift test --package-path /private/tmp/civilization-stone-age-completion-cues/Packages/GameCore
```

```sh
swift test --package-path /private/tmp/civilization-stone-age-completion-cues/Packages/GameCore -c release
```

```sh
/Applications/Xcode.app/Contents/Developer/usr/bin/python3 /private/tmp/civilization-stone-age-completion-cues/scripts/verify-developer-release.py
```
