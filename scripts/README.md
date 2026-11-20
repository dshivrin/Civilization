# Reusable local engineering tools

Use `python3 scripts/dev.py --help` before creating another temporary QA, save-validation or preservation script. Python standard library, Xcode and SwiftPM are sufficient; no mandatory package install, CI service, signing change or Fastlane dependency.

Run from any directory using the script's absolute path, or from the repository root as below. Relative input/output paths are resolved from the caller's directory. Existing output directories are never reused or overwritten; omit `--output` for a unique `/tmp/civilization-qa-*` report directory. Private backups must remain outside the repository. Generated data stays local unless explicitly selected for publication.

## Toolchain inventory

```sh
python3 scripts/dev.py doctor
```

Reads Xcode/Swift versions and required/optional executable availability. It does not install tools, inspect accounts/signing or select/connect a physical device. Use XcodeBuildMCP for available native capabilities; direct inventory fallback is `xcrun simctl list devices available` or `xcrun devicectl list devices` when needed.

## Existing tests, one report

```sh
# Full core Debug + Release and nine developer API exclusion probes.
python3 scripts/dev.py test

# Deliberately scoped regression: report retains the exact filter/configuration.
python3 scripts/dev.py test --suite core --configuration debug --filter normalEntryMetadata

# Explicit simulator and suite. Repeat --simulator and --only-testing for a matrix.
python3 scripts/dev.py test --suite ui --configuration release \
  --simulator SIMULATOR_UDID \
  --only-testing CivilizationUITests/NormalEntryUITests
```

Native tests use the separate `com.civilization.seed.qa` app identity, never erase simulators or reset production data, and default to the ordinary entry suite. Core defaults to both configurations. Release exclusion probes run only when both core configurations pass in this invocation. Native build caches persist under `/tmp/civilization-qa-builds/<configuration>/<simulator>`; `--derived-data PATH` selects another cache root. Reports/result bundles stay in a new per-run directory. Run matrices serially when sharing the same cache; separate cache roots support independent runs.

Reports retain exact argv, source revision/dirty state, filters, destinations, test counts, durations, exit codes, logs and native `.xcresult` bundles. An empty/misspelled selection fails even if the tool exits zero; missing explicitly requested native cases also fail when other cases run. Counts are test declarations, not parameterized case counts. Interrupting a step stops the remaining matrix. A failing step remains in the report; core configurations otherwise both run so failures can be compared.

`NormalCompletionUITests` needs a separately prepared legitimate earned-save container. The runner refuses to run that suite blindly. Follow [S1-PLAY fixture provenance](../docs/milestones/s1-play.md); it does not add a Release fixture import or modify a player's data. No simulator result establishes human acceptance or physical FPS/thermal/battery performance.

## Production save validation, without mutation

```sh
python3 scripts/dev.py validate-saves '/tmp/private backup/Civilization'
```

The permanent local SwiftPM [SaveInspector](../Tools/SaveInspector/Package.swift) packages GameCore resources automatically; do not compile/copy another ad hoc `swiftc` validator. It validates normal/current/legacy/grouped developer saves and isolated review copies, recognized `.bak` files, library metadata and every registered slot using production APIs. It selects each file's original configuration to avoid geography conversion writes, does not restore a session or apply offline time, rejects symlinks/unknown maps/damaged or missing registered saves, and checks all source bytes before/after. Reports contain relative paths, map IDs, counts and hashes, never save bodies or resource stocks. Run via the CLI (Debug inspector) for grouped developer geometry; the standalone Release inspector intentionally lacks that Debug API.

The inspector validates explicit v7 operating-rule markers and their pre-connectivity backups, and reports each file’s rule identity without activating or advancing it. Legacy normal saves remain on their original rules.

The inspector can also be run directly:

```sh
swift run --package-path Tools/SaveInspector SaveInspector /tmp/private-backup/Civilization
```

## Save-preserving device backup

```sh
# Review exact commands without device access or file creation.
python3 scripts/dev.py backup-device --device DEVICE_UDID --bundle com.civilization.seed \
  --output '/tmp/civilization-private-backup-unique' --dry-run

# Explicit read-only backup. Choose a NEW directory each time.
python3 scripts/dev.py backup-device --device DEVICE_UDID --bundle com.civilization.seed \
  --output '/tmp/civilization-private-backup-unique'
```

The real command copies only `Library/Application Support/Civilization` twice into separate local `data/` and `verification/` folders, compares exact hashes, then production-validates the copy. If the app saves between copies, the command fails and retains both copies; close the app through the authorized workflow and retry in a new directory. It never stops/launches/installs an app, writes to the phone, changes signing, deletes or resets saves. Existing host permission boundaries still apply; scripts do not confer new permissions. Review the successful report before a separately authorized install.

## Before/after preservation

```sh
python3 scripts/dev.py compare-saves /tmp/before/Civilization /tmp/after/Civilization

# Explicitly allow added files and additive library/selection changes only.
python3 scripts/dev.py compare-saves /tmp/before/Civilization /tmp/after/Civilization --allow-new-games
```

Strict mode requires identical file sets and bytes. Additive mode retains every old file byte and library entry, permitting index selection/additions. Neither mode proves new files are valid: run `validate-saves` on both backups for that. Empty/no-normal-save trees and aliases fail; source trees are never changed. A changed original developer/normal/backup file still fails in additive mode. Reports contain hashes and relative paths only; they do not upload backups.

## Toolkit regression checks

```sh
python3 -m unittest discover -s scripts/tests -v
swift test --package-path Tools/SaveInspector
swift test --package-path Tools/SaveInspector -c release
```

Local CI integration, screenshot baselines, automated image comparisons and in-game diagnostics remain future proposals. Reuse these commands rather than duplicating their implementation when those workstreams are authorized.

## Read-only building art audit

Reuse the existing native validator; no Pillow/image-processing dependency or new QA runner:

```sh
swift scripts/verify-art.swift
swift scripts/verify-art.swift --audit-output NEW_DIRECTORY \
  --media-root /Users/dima/dev/Civilization-Media
```

The optional audit reserves a new output directory exclusively and rejects destinations inside the resolved media root, including symlinked parents. It validates a known asymmetric PNG coordinate fixture, measures all20masters/world exports/thumbnails, checks source/registry/export hashes, and writes `inventory.json`, a standalone HTML/SVG footprint atlas, and actual-map river fixtures. It never changes source art, configuration, saves or the media repository. Alpha bounds describe silhouettes, not semantic ground contact; atlas and river map are diagnostics, not in-game screenshots or human visual acceptance. Standard Swift cache access is required within host permissions. See [Gate 1 audit](../docs/art/building-gate-1/audit.md).


## Gate 2 review gallery data

`swift scripts/verify-art.swift --inspect-images IMAGE.png ...` prints read-only native alpha/bounds/hash records without enforcing the historical512/144runtime limits on new review masters. It does not edit pixels or remove backgrounds.

`python3 scripts/build-art-gallery.py` verifies the preserved Gate 2 receipts, prompts, PNG hashes and Gate 1 seed hash, then regenerates review-only `manifest.json` and `gallery-data.js`. The gallery uses local files and can open directly; serving the repository root over loopback also works. Its silhouette framing, yard joins and bridge deck endpoints are proposals, never gameplay/save or runtime art changes. See [review scope](../docs/art/building-gate-2/README.md).

## UI themes and motion review tools

`python3 scripts/build-ui-review.py` verifies seven generated review assets, prompt/reference receipts,43native icons and pinned sources,27native captures and nominal token contrast; regenerates review data/manifest. `node --test scripts/tests/ui_review.test.cjs` checks prototype event/persistence/construction/era behavior.

`swift run --package-path Tools/UIReviewRenderer UIReviewRenderer NEW_DIRECTORY` exports existing native EraIcon source via symlink plus SF Symbols using a macOS-only bridge. The same tool accepts `--sheet SCREENSHOT_DIRECTORY NEW_PNG` to lay out nine unmodified native captures. Outputs must be new; existing output is never overwritten. Build cache access remains host-controlled.

Use `python3 scripts/dev.py test --suite ui` with its documented destination arguments and `--only-testing CivilizationUITests/RelocationUITests/testUIThemeAuditEvidence` for the isolated nine-screen capture flow. Export its XCTest attachments with xcresulttool. [Review workbench and scope](../docs/ui/themes-review/README.md); no runtime integration or save migration.

## Native visual review archive

`python3 scripts/build-native-visual-gallery.py --capture phone=EXPORTED_ATTACHMENTS --capture mini=EXPORTED_ATTACHMENTS --capture pro=EXPORTED_ATTACHMENTS --output docs/testing/native-visual-program/captures/NEW_RUN` validates all21required XCTestPNGcaptures and four concept/prompt hashes, copies original bytes into a new directory and regenerates a local review gallery. Use existing `xcrun xcresulttool export attachments` on passed per-profile result bundles first. The builder rejects missing/duplicate captures and existing output; no image transforms, player saves or network. Generated pose sheets remain review-only and unregistered; browser RGBA compositing supersedes the raw viewer fringe assessment.

Use `--render-only --output EXISTING_ARCHIVE` to validate its pinned21images and regenerate HTML after metadata changes; PNGs/manifest remain untouched. Preserve raw generated PNGs and check alpha through actual browser/native compositing: the raw preview can display misleading colors in transparent pixels. [Native review handoff](../docs/testing/native-visual-program/README.md).


`python3 scripts/build-native-visual-gallery.py --walkthrough --capture phone=EXPORTED_ATTACHMENTS --capture mini=EXPORTED_ATTACHMENTS --capture pro=EXPORTED_ATTACHMENTS --output docs/testing/native-visual-program/captures/NEW_WALKTHROUGH_RUN` uses the same new-directory/hash-preserving archive contract for the four interactive onboarding guide captures per profile and builds `walkthrough.html`. `--walkthrough --render-only --output EXISTING_ARCHIVE` validates its12pinned captures. This does not promote the guide into normal games.
