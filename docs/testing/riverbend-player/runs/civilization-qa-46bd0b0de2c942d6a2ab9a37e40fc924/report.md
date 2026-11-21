# Civilization local QA report

**Status:** passed
**Revision:** 47e351f6599971d595bb5a04864cc0f807fd4794 (working tree modified)

| Step | Result | Tests | Seconds | Log |
|---|---|---:|---:|---|
| validate-earned-fixture | passed | — | 6.238 | [validate-earned-fixture.log](validate-earned-fixture.log) |
| build-earned-identity | passed | — | 2.859 | [build-earned-identity.log](build-earned-identity.log) |
| install-earned-identity | passed | — | 0.242 | [install-earned-identity.log](install-earned-identity.log) |

## Scope

```json
{
  "command": "prepare-earned-simulator",
  "simulator": "E118C061-9C37-4E18-9B03-A633E7240149",
  "fixture": "/tmp/riverbend-earned-reviewed-20261121/craft",
  "qa_identity": "a2b8f07d-f46b-4844-b5ed-a0311f3bd810",
  "configuration": "release",
  "derived_data": "/tmp/civilization-qa-builds",
  "output": null
}
```

Counts describe executed tests, not parameterized case counts. Commands are listed below; raw logs retain tool output and failures. No human acceptance or sustained physical performance is inferred.

## Commands

```sh
swift run --package-path /Users/dima/dev/Civilazation-riverbend-player-review/Tools/SaveInspector SaveInspector /private/tmp/riverbend-earned-reviewed-20261121/craft
```

```sh
xcodebuild build -project /Users/dima/dev/Civilazation-riverbend-player-review/Civilization.xcodeproj -scheme Civilization -configuration Release -destination 'platform=iOS Simulator,id=E118C061-9C37-4E18-9B03-A633E7240149' -derivedDataPath /private/tmp/civilization-qa-builds/release/E118C061-9C37-4E18-9B03-A633E7240149 CODE_SIGNING_ALLOWED=NO PRODUCT_BUNDLE_IDENTIFIER=com.civilization.seed.qa.earned.a2b8f07d-f46b-4844-b5ed-a0311f3bd810
```

```sh
xcrun simctl install E118C061-9C37-4E18-9B03-A633E7240149 /private/tmp/civilization-qa-builds/release/E118C061-9C37-4E18-9B03-A633E7240149/Build/Products/Release-iphonesimulator/Civilization.app
```
