# Civilization local QA report

**Status:** passed
**Revision:** 47e351f6599971d595bb5a04864cc0f807fd4794 (working tree modified)

| Step | Result | Tests | Seconds | Log |
|---|---|---:|---:|---|
| validate-earned-fixture | passed | — | 1.615 | [validate-earned-fixture.log](validate-earned-fixture.log) |
| build-earned-identity | passed | — | 20.444 | [build-earned-identity.log](build-earned-identity.log) |
| install-earned-identity | passed | — | 0.232 | [install-earned-identity.log](install-earned-identity.log) |

## Scope

```json
{
  "command": "prepare-earned-simulator",
  "simulator": "390CFA90-D4C9-40F9-BA4A-FE3489C20809",
  "fixture": "/tmp/riverbend-earned-20261121-b/enclosure",
  "qa_identity": "9920c31f-b53b-4165-b6ab-c7278bfd165c",
  "configuration": "release",
  "derived_data": "/tmp/civilization-qa-builds",
  "output": null
}
```

Counts describe executed tests, not parameterized case counts. Commands are listed below; raw logs retain tool output and failures. No human acceptance or sustained physical performance is inferred.

## Commands

```sh
swift run --package-path /Users/dima/dev/Civilazation-riverbend-player-review/Tools/SaveInspector SaveInspector /private/tmp/riverbend-earned-20261121-b/enclosure
```

```sh
xcodebuild build -project /Users/dima/dev/Civilazation-riverbend-player-review/Civilization.xcodeproj -scheme Civilization -configuration Release -destination 'platform=iOS Simulator,id=390CFA90-D4C9-40F9-BA4A-FE3489C20809' -derivedDataPath /private/tmp/civilization-qa-builds/release/390CFA90-D4C9-40F9-BA4A-FE3489C20809 CODE_SIGNING_ALLOWED=NO PRODUCT_BUNDLE_IDENTIFIER=com.civilization.seed.qa.earned.9920c31f-b53b-4165-b6ab-c7278bfd165c
```

```sh
xcrun simctl install 390CFA90-D4C9-40F9-BA4A-FE3489C20809 /private/tmp/civilization-qa-builds/release/390CFA90-D4C9-40F9-BA4A-FE3489C20809/Build/Products/Release-iphonesimulator/Civilization.app
```
