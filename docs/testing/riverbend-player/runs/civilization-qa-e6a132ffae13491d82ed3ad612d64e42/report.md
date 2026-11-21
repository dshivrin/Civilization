# Civilization local QA report

**Status:** passed
**Revision:** 47e351f6599971d595bb5a04864cc0f807fd4794 (working tree modified)

| Step | Result | Tests | Seconds | Log |
|---|---|---:|---:|---|
| core-debug | passed | 347 | 26.917 | [core-debug.log](core-debug.log) |
| core-release | passed | 254 | 35.061 | [core-release.log](core-release.log) |
| release-api-exclusions | passed | — | 6.132 | [release-api-exclusions.log](release-api-exclusions.log) |

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
swift test --package-path /Users/dima/dev/Civilazation-riverbend-player-review/Packages/GameCore
```

```sh
swift test --package-path /Users/dima/dev/Civilazation-riverbend-player-review/Packages/GameCore -c release
```

```sh
/Applications/Xcode.app/Contents/Developer/usr/bin/python3 /Users/dima/dev/Civilazation-riverbend-player-review/scripts/verify-developer-release.py
```
