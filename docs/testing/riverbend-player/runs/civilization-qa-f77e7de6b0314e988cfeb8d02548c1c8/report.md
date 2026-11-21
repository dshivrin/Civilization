# Civilization local QA report

**Status:** passed
**Revision:** 47e351f6599971d595bb5a04864cc0f807fd4794 (working tree modified)

| Step | Result | Tests | Seconds | Log |
|---|---|---:|---:|---|
| validate-earned-fixture | passed | — | 1.513 | [validate-earned-fixture.log](validate-earned-fixture.log) |
| build-earned-identity | passed | — | 31.716 | [build-earned-identity.log](build-earned-identity.log) |
| install-earned-identity | passed | — | 0.194 | [install-earned-identity.log](install-earned-identity.log) |

## Scope

```json
{
  "command": "prepare-earned-simulator",
  "simulator": "FC0EFF78-D008-4CCB-84A3-C40C0DDB3BBB",
  "fixture": "/tmp/riverbend-earned-reviewed-20261121/enclosure",
  "qa_identity": "93c8ad32-25c7-4942-a924-994b35aadbb5",
  "configuration": "release",
  "derived_data": "/tmp/civilization-riverbend-earned-builds",
  "output": null
}
```

Counts describe executed tests, not parameterized case counts. Commands are listed below; raw logs retain tool output and failures. No human acceptance or sustained physical performance is inferred.

## Commands

```sh
swift run --package-path /Users/dima/dev/Civilazation-riverbend-player-review/Tools/SaveInspector SaveInspector /private/tmp/riverbend-earned-reviewed-20261121/enclosure
```

```sh
xcodebuild build -project /Users/dima/dev/Civilazation-riverbend-player-review/Civilization.xcodeproj -scheme Civilization -configuration Release -destination 'platform=iOS Simulator,id=FC0EFF78-D008-4CCB-84A3-C40C0DDB3BBB' -derivedDataPath /private/tmp/civilization-riverbend-earned-builds/release/FC0EFF78-D008-4CCB-84A3-C40C0DDB3BBB CODE_SIGNING_ALLOWED=NO PRODUCT_BUNDLE_IDENTIFIER=com.civilization.seed.qa.earned.93c8ad32-25c7-4942-a924-994b35aadbb5
```

```sh
xcrun simctl install FC0EFF78-D008-4CCB-84A3-C40C0DDB3BBB /private/tmp/civilization-riverbend-earned-builds/release/FC0EFF78-D008-4CCB-84A3-C40C0DDB3BBB/Build/Products/Release-iphonesimulator/Civilization.app
```
