# Civilization local QA report

**Status:** passed
**Revision:** 47e351f6599971d595bb5a04864cc0f807fd4794 (working tree modified)

| Step | Result | Tests | Seconds | Log |
|---|---|---:|---:|---|
| validate-saves | passed | — | 3.206 | [validate-saves.log](validate-saves.log) |

## Scope

```json
{
  "command": "validate-saves",
  "root": "/tmp/riverbend-earned-reviewed-20261121/ending",
  "sourceByteIdentical": true
}
```

Counts describe executed tests, not parameterized case counts. Commands are listed below; raw logs retain tool output and failures. No human acceptance or sustained physical performance is inferred.

## Commands

```sh
swift run --package-path /Users/dima/dev/Civilazation-riverbend-player-review/Tools/SaveInspector SaveInspector /private/tmp/riverbend-earned-reviewed-20261121/ending
```
