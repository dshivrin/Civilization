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
# Full core Debug + Release and thirteen developer API exclusion probes.
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


`python3 scripts/build-native-visual-gallery.py --walkthrough --capture phone=EXPORTED_ATTACHMENTS --capture mini=EXPORTED_ATTACHMENTS --capture pro=EXPORTED_ATTACHMENTS --output docs/testing/native-visual-program/captures/NEW_WALKTHROUGH_RUN` uses the same new-directory/hash-preserving archive contract for the four interactive onboarding guide captures per profile and builds `walkthrough.html`. `--walkthrough --render-only --output EXISTING_ARCHIVE` validates its12pinned captures (15when `--include-placement` is supplied to both archive and render-only commands). This does not promote the guide into normal games.

Add `--include-placement` to `--walkthrough` when archiving the native candidate drag/pan/pinch regression capture; older12-image archives retain the original command and remain unchanged.


`--atmosphere` selects the six continuous-lighting/static-weather comparison captures on each of the same three profiles and builds `atmosphere.html`. Use a new capture directory; `--atmosphere --render-only --output EXISTING_ARCHIVE` validates its18pinned PNGs. It is separate from walkthrough/placement modes. If `clips/atmosphere-provenance.json` exists, its source/watch-copy hashes must match before rendering the recorded-cycle section. No normal appearance or save changes are implied.

`--construction` archives five actual-work walkthrough stages per profile (15unchanged PNGs) and builds `construction.html`. It is separate from atmosphere/walkthrough modes. Pause review time and labeled3second steps drive only the disposable engine; they do not alter normal build timing or saved progress.

`python3 scripts/build-art-gallery.py --directions` validates the separate gathering-shelter direction study: four preserved source views, exact native-report/prompt/reference/output digests, alpha32and unchanged seed/20runtime assets. It rejects Python optimization, missing/changed views and aliased outputs, stages manifest/browser data before publication and restores the old pair on a failed replace. No image transforms or runtime export. [Scope, prompts and review gallery](../docs/art/building-direction-review/README.md).

`--villagers --qa-report PASSED_THREE_PROFILE_REPORT.json` archives eight magnified provisional poses per profile (24unchanged PNGs) and builds `villagers.html`. Each source must have a distinct device matching its profile and passed QA destination. The builder re-exports the report’s result bundles to verify source image bytes/device/timestamps before publication; do not supply screenshots from an earlier failed run. The report is copied and hash-pinned with every capture. `--villagers --render-only --output EXISTING_ARCHIVE` validates the pinned captures and copied report without needing temporary result bundles. This is motion review, not accepted realistic character artwork.

For selective destination retries, use `--profile-report phone=REPORT --profile-report mini=REPORT --profile-report pro=REPORT` instead of `--qa-report`. Each selected destination step must have nonzero executed tests and pass, and its actual result bundle must match the images. Original reports (including other-device failures) are copied unchanged and their aggregate status is explicit in every capture record. This never promotes a failed/zero-test device step; it avoids repeating already verified destinations merely to obtain a single green aggregate report.

`swift scripts/verify-art.swift --inspect-atlas IMAGE.png COLUMNS ROWS` measures original top-left integer cells without editing the PNG. `python3 scripts/build-art-gallery.py --villager-atlas` validates raw candidates, prompts, references and native reports and atomically publishes one review data file. Failed margin checks remain visible; no frame alignment or runtime promotion. `node --test scripts/tests/atlas_review.test.cjs` exercises actual viewer lifecycle callbacks, including a negative control; browser/OS event delivery remains separately observed. Serve only the self-contained `docs/art/villager-atlas-review` directory if local HTTP is needed. [Study and limitations](../docs/art/villager-atlas-review/README.md).


## Riverbend Economy Lab (Debug review only)

Developer tools → Open separate Food and Wood lab runs `riverbend-economy-lab-v1`.
It uses `Application Support/RiverbendDebugLabs/riverbend-economy-lab-v1/lab.json`,
independent of Games/Normal/Developer/Round2. The existing Debug UI-library identity
adds a separate test namespace. Corrupt/failed files stop the Lab without resetting it.
No physical install, production activation or ordinary Water migration is authorized.

Use `python3 scripts/dev.py test` for all core configurations and13exclusions;
`--suite ui --configuration debug --simulator UDID --only-testing CivilizationUITests/RelocationUITests/testEconomyLabGestureRouteAndReload`
for the real playable route, map gestures and reload. Run serially per simulator/cache.
Export XCTest screenshots using `xcrun xcresulttool export attachments`.
The Lab's60second survey uses the existing whole-forest adapter against real terrain,
not production area exploration. Time pauses on dismissal; no offline catch-up.

## Riverbend Map Finds (Goal 2, Debug lab only)

The same separate Lab now adds deterministic berries (+3 Food, Gather once) and
Observe-only deer tracks during its first actual construction wait. Tap a map
marker with placement inactive; Dismiss leaves it untouched. Full Food capacity
keeps the entire berry patch. Find state uses the existing lab transaction file;
no ordinary save file or schema is involved.

`python3 scripts/dev.py test` now runs14Debug-present/Release-absent probes.
Add `--only-testing CivilizationUITests/RelocationUITests/testMapFindsWaitDismissGatherObserveAndReload`
to the documented Debug UI command for construction-wait inspection, dismissal,
unresolved reopen, Gather/Observe, completion and resolved app relaunch. Keep
`testEconomyLabGestureRouteAndReload` as the separate ignore-both gesture route.
Run both on a phone and iPad; ordinary Release entry remains an independent check.

## Riverbend Stone and Storage (Goal 3, Debug lab only)

After the original Food/Wood checkpoint, **Reveal nearby Stone outcrop** is free.
The revealed-land outcrop is a deterministic Lab fixture with no depletion in
this slice. Existing Stone gatherer costs10Wood, supplies5Stone/min at full
staffing, and stays beside its reachable source. Growth to population5 supplies
the third full field slot; earlier production exposes workforce limitation.

One existing storage family offers one Granary (14Wood+4Stone; +60Food only) and
one Stockyard (18Wood+6Stone; +60Wood/+60Stone, never Food). Base cache remains
Food60/Wood60/Stone40. Capacity starts at completion; stock/cap/contribution are
shown explicitly. No upgrade/removal/disconnection or craft chain is exposed.
Future unlocked craft materials start24 with Stockyard +24; Goal3 unlocks none.

Add `--only-testing CivilizationUITests/RelocationUITests/testStoneStorageRevealCollectSpendAndReload`
to the existing phone+iPad Debug matrix. Retain both Goal1/Goal2 cases above and
ordinary Release entry. Full core now includes15Debug-present/Release-absent
probes, including storage specialization. Same separate v1 envelope/atomic store;
old Lab envelopes remain readable, ordinary library/save schemas stay unchanged.

## Unified Riverbend player verification

Ordinary New Game now uses the distinct `riverbend-player-64x48-v1` profile.
Supported earlier large games retain their original configuration. The normal
path contains no developer controls, grants, speed controls or review comparisons.
Historical Debug UI regressions explicitly request the legacy temporary QA entry;
ordinary Riverbend cases always launch directly through New Game / Continue.

Run `python3 scripts/dev.py test` for full core Debug/Release and 23 Debug-only
API exclusions. Presentation-only pose vocabulary, real-work stages and opaque fog
geometry are shared by Release; comparison controllers remain Debug-only.

For the real ordinary opening, mandatory roads, gestures, real 60-second whole-forest
survey and Continue, select
`CivilizationUITests/NormalEntryUITests/testRiverbendOrdinaryOpeningAndContinue`.
Keep `testNormalEntryPersistenceWithoutDeveloperHooks` for independent New Game slots.
The optional `--qa-identity UUID` selects an independent simulator-only bundle under
`com.civilization.seed.qa.earned.UUID`; it never targets production. Native runs are
serial within each matrix and disable parallel XCTest clones.

Synthetic earned-state snapshots can be exported by running the public-command
Release regression `riverbendPlayerCraftStorageEnclosureEarnedRoutePersists` with
`CIVILIZATION_RIVERBEND_EARNED_EXPORT=NEW_DIRECTORY`. Its `craft`, `enclosure` and
`ending` folders contain only a primary, index and `qa-earned.json` receipt. Model
time is simulated and reported; exported wall-clock alignment changes only
`lastUpdated`, preserving earned stocks, progress and timers. This is not a real
native playthrough of the entire model duration.

Prepare one snapshot in a **fresh UUID identity**, on an explicit booted simulator:

```sh
python3 scripts/dev.py prepare-earned-simulator --simulator UDID   --fixture NEW_DIRECTORY/craft --qa-identity UUID
python3 scripts/dev.py test --suite ui --configuration release --simulator UDID   --qa-identity UUID --prepared-earned-container   --only-testing CivilizationUITests/RiverbendEarnedUITests/testRealCraftStorageFindsAndRelaunch
```

The preparation validates only synthetic files with the read-only production
inspector, refuses any existing target identity or destination, builds unsigned,
installs only into the simulator and verifies copied hashes. No app-side fixture
import is added to Release. Use separate UUIDs and `enclosure`/`ending` snapshots
for `testEnclosureGateAndSameGameContinue` and
`CivilizationUITests/NormalCompletionUITests`. Never use owner saves as fixtures.
Tool receipts distinguish native real survey/Tool waits from model time. No native
result establishes physical performance or human acceptance.
