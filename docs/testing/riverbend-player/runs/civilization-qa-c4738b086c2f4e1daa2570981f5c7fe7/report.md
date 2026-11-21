# Civilization local QA report

**Status:** passed
**Revision:** 47e351f6599971d595bb5a04864cc0f807fd4794 (working tree modified)

| Step | Result | Tests | Seconds | Log |
|---|---|---:|---:|---|
| validate-earned-fixture | passed | — | 1.421 | [validate-earned-fixture.log](validate-earned-fixture.log) |
| build-earned-identity | passed | — | 2.147 | [build-earned-identity.log](build-earned-identity.log) |
| install-earned-identity | passed | — | 0.212 | [install-earned-identity.log](install-earned-identity.log) |

## Scope

```json
{
  "command": "prepare-earned-simulator",
  "simulator": "390CFA90-D4C9-40F9-BA4A-FE3489C20809",
  "fixture": "/tmp/riverbend-earned-reviewed-20261121/craft",
  "qa_identity": "ae56f582-d3a5-4547-9ba3-e90d5c9dd6dc",
  "configuration": "release",
  "derived_data": "/tmp/civilization-riverbend-earned-builds",
  "output": null
}
```

Counts describe executed tests, not parameterized case counts. Commands are listed below; raw logs retain tool output and failures. No human acceptance or sustained physical performance is inferred.

## Commands

```sh
swift run --package-path /Users/dima/dev/Civilazation-riverbend-player-review/Tools/SaveInspector SaveInspector /private/tmp/riverbend-earned-reviewed-20261121/craft
```

```sh
xcodebuild build -project /Users/dima/dev/Civilazation-riverbend-player-review/Civilization.xcodeproj -scheme Civilization -configuration Release -destination 'platform=iOS Simulator,id=390CFA90-D4C9-40F9-BA4A-FE3489C20809' -derivedDataPath /private/tmp/civilization-riverbend-earned-builds/release/390CFA90-D4C9-40F9-BA4A-FE3489C20809 CODE_SIGNING_ALLOWED=NO PRODUCT_BUNDLE_IDENTIFIER=com.civilization.seed.qa.earned.ae56f582-d3a5-4547-9ba3-e90d5c9dd6dc
```

```sh
xcrun simctl install 390CFA90-D4C9-40F9-BA4A-FE3489C20809 /private/tmp/civilization-riverbend-earned-builds/release/390CFA90-D4C9-40F9-BA4A-FE3489C20809/Build/Products/Release-iphonesimulator/Civilization.app
```
