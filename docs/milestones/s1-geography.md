# S1-Geography — production 64×48

20 November 2026. Core/persistence **181b0a8**; rendering/native integration **56f4124**; [specification](../superpowers/specs/2026-11-20-s1-geography-design.md), [plan](../superpowers/plans/2026-11-20-s1-geography.md). Implementation and automated verification are distinct from human visual acceptance and sustained hardware performance.

Dima's direct instruction confirms every existing save is development/test data. This supersedes the production migration gate in MC-003 and earlier sizing proposals. The implementation uses a small backed-up additive conversion, preserving useful test history rather than resetting it. No general migration UI/framework, deletion, uninstall or save reset was introduced.

## Delivered

- **MAP-001:** Normal games now use the reviewed64×48additive landscape, stable new identity `river-clearing-64x48-v1`, original768terrain cells/campfire coordinates/deposit identities and unchanged standard footprints. New games start with one campfire, standard resources/population and no roads. No32×24normal selection exists; private legacy data remains for validation/regression. The grouped64-building Debug fixture retains its separate identity/footprint experiments.
- Existing development states validate under original rules, then their source bytes are atomically backed up and read back before replacement (`.pre-geography-64x48.bak`). Existing backup mismatch aborts conversion without touching originals. All buildings/roads/resources/reserves/research/rewards/known cells remain. The completed square radius is recomputed from existing knowledge so the annex stays concealed; irregular historical discovery remains known. Paid pending expedition time is retained. Library entries adopt the new map identity; files convert lazily. Failed target opens preserve target bytes. Independent normal/developer companions remain separate.
- **MAP-002:** Reachable quarry access at18,16is on the settlement side. It draws from original `valley-stone` at27,4with unchanged12,000unit capacity and40tile extraction radius. Both work faces share one reserve; no new reserve or resource grant. Connectivity and actual stone-gatherer depletion tests pass. A readable Quarry marker and known-site coordinates identify access. Hidden work-face coordinates are filtered from UI.
- **MAP-003:** Opaque pale cloud cover replaces dark unknown ground. Unknown terrain/scenery are omitted entirely; visible buildings require their full footprint known; deposits render only known sites. Session tap/inspect/relocation guards and renderer hit filtering prevent hidden interactions. Reduced-motion uses static clouds. Bounded16×16ground/scenery caching now runs in Release as well as Debug, rebuilding only on discovery/motion changes. [Actual landscape capture](../screenshots/s1-geography/phone-standard-start.png).
- **MAP-004:** Expeditions retain10food/45seconds,2tile reveal steps and established scout requirement/rewards. Map-derived cap46reaches all3,072tiles. Discoveries union permanently only on completion; duplicate starts do not charge; pending timers and completed discoveries survive relaunch/save/switch. Full exploration is optional: ordinary guided full-era routes still complete at704discovered tiles. Legacy offline/clock/reward regressions remain green.

Navigation scene reuse and equivalent-simulation optimizations are reused. Release tests caught a remaining Debug-only road interpolation bound: promoting the approved64×48bound restores gap-free sparse road strokes in production. No road economy/interaction rule changed.

## Actual verification

| Check | Result |
|---|---|
| Full core Debug |187tests passed,15.489s |
| Full core Release |169tests passed,1.729s |
| Release developer API exclusions |All five compile probes pass |
| Release simulator app build |`xcodebuild build`, Release, generic iOS Simulator, unchanged project settings, succeeds |
| iPhone17Pro Max simulator |Independent-game create/switch/relaunch36.606s; grouped preview/resume/normal-return and first pan/pinch pass; real expedition/default/relaunch58.145s |
| iPad mini A17 Pro / iOS18.6simulator |Independent games and grouped navigation pass; final real expedition/relaunch56.409s |
| Large iPad Pro13M4 / iOS18.6simulator |Independent games37.484s, grouped navigation42.448s, real expedition/relaunch57.214s; full selected suite succeeds |
| Independent review |No Critical/Important defects; one minor label issue deferred below |

Native coverage is scoped to geography, independent saves and affected gestures, not a newly rerun full21case/profile suite. Initial coverage assertion failed because SwiftUI localized3,072; locale-independent assertion passed on rerun. First full Release road failures were reproduced and corrected before final green suite. XCTest image attachments use a malformed portrait/black canvas on this host; excluded from deliverable evidence in favor of inspected native landscape simctl capture.

[Short simulator performance samples](../testing/s1-geography/render-performance.json): median59.4FPS, maximum45.9MiB,62render nodes during standard-start expedition/relaunch runs. Concurrent builds/simulators affect these short samples. These are **not physical hardware FPS, thermal, battery or sustained performance acceptance**. No new physical iPhone install/launch/save-copy operation is claimed; previous physical size/navigation acceptance remains valid for that earlier product.

Commands: `swift test --package-path Packages/GameCore`, same with `-c release`; `python3 scripts/verify-developer-release.py`; native `xcodebuild test -project Civilization.xcodeproj -scheme Civilization -configuration Debug -destination 'platform=iOS Simulator,id=<profile>' -derivedDataPath /tmp/civilization-geography-<profile>-build -only-testing:CivilizationUITests/RelocationUITests/<case> CODE_SIGNING_ALLOWED=NO`. Terminal logs remain under `/tmp/civilization-geography-*`; concise evidence/ledger is committed in [testing](../testing/s1-geography/progress.md).

Additional affected gesture checks pass: phone long-press17.997s, road draw/erase19.406s, road pinch12.800s; mini13.902s/17.976s/11.457s. This makes six affected cases on phone and mini and three on Pro, across scoped runs.

## Remaining acceptance and continuation

Human production cloud/quarry/art/enjoyment review and sustained physical hardware measurements remain open. Minor deferred: some old non-grouped developer companions can show “Modified developer state” after identity conversion because their original scenario snapshot retains the legacy identity; gameplay and persisted progress remain intact. No unverified visual acceptance is implied.

Next authorized stage has started with [environment integration assessment](../art/2026-11-20-environment-integration-assessment.md). Existing realistic/saturated target, native renderer, media provenance and small-pilot human visual review govern it. Media repository remains unchanged/local-only697b486; no batch artwork or footprint rescaling. All FP/RD/LC/AUDIO/WND/GEO/UX/CLU and MAP-005backlog preserved. Same Codex session/checkpoint; Goal API returnsnullin this runtime, and no duplicate Goal/session/automation was created.

## Publication receipts

Pushed through10b8536to personal dshivrin/Civilization first-era-review. [GitHub issue#1 actual report7034942171](https://github.com/dshivrin/Civilization/issues/1#issuecomment-7034942171). Native results handover submitted successfully to designated Master Development Coordination chat6aff4440-ac14-83eb-b7bd-1f2d8bd9a0a9; send receipt alone is not a designer/human acceptance claim. No private save contents uploaded.

## Physical iPhone installation —20November2026

At Dima's direct installation request, signed current product56f4124was built with unchanged signing/account settings, strict codesign verified, installed and launched successfully on his connected iPhone. Fresh backup production-validates normal5buildings/15roads and grouped developer64buildings/566roads. All3library/save files are byte-identical before first launch. Post-launch production validation confirms normal64×48identity with original buildings/roads/IDs/research/discovery histories preserved, exact on-device pre-Geography backup, unchanged developer bytes and original legacy selection/no extra game. Ordinary offline economy/time may advance. [Preservation metadata](../testing/s1-geography/device-install.json); private backups remain local under /tmp/civilization-geography-device-{before,after,launched}. No reset/uninstall/signing change or final-art integration. Human touch/cloud/art/enjoyment review and sustained hardware metrics remain open.
