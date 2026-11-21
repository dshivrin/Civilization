# Stone Age HUD and Menus — 21 November 2026

Goal: a coherent, ordinary-player Stone Age interface. Product source `b1255f38d524a47061949fd1eadbadc3f966676f`. Exact predecessor/remote `3f27d1e711096bc22cc400f354bb627cbb9e9535`. Personal branch `riverbend-stone-age-hud-review` only.

## Ordinary player delivery

New Game/Continue has a compact resource ledger, consistent Goals home with the current objective, a labeled Build/Research/Explore dock and a Settlement menu for Center, existing buildings and Games. Contextual Goals remains one tap away during Explore, inspection, placement and roads. Phone inspectors sit at the bottom; iPad inspectors sit at the side. The ordinary Move action stays below scrolling inspection details, with its minimum hit area inside the button label. Candidate Confirm/Cancel/Rotate remains above the HUD and empty-map pan/pinch remains native. Clear-map and contextual status feedback remain visible.

Shared warm-gray stone surfaces, engraved borders, restrained gold and stable icon meanings tie the HUD to the actual catalog and research menus. Catalog selection/search/category/scroll and exact material/supplier/research return stacks remain intact. Explore opens the exact expedition technology and returns to the same panel/scroll context. Shared primary actions use dark ink on gold and minimum44-point label hit regions; actual founding, catalog and Move targets are asserted natively. The enabled nominal ink/accent ratio is10.007:1, not a whole-app accessibility claim. No detached mockup or Developer Tools delivery path.

An original temporary sunrise/horizon mark is generated from native CoreGraphics paths by `scripts/render-temporary-app-icon.swift`. Its opaque 1024×1024 PNG is wired through Assets.xcassets/AppIcon in both app configurations. Native Home Screen captures show the actual installed QA app on phone and iPad, and tapping it returns to ordinary entry. The adjacent blank XCTest runner icon is a separate Apple test harness.

## Verification and preservation

[Exact verification](../testing/stone-age-hud/verification.json) · [34 original full-display captures](../testing/stone-age-hud/index.html) · [28 unchanged runner receipts](../testing/stone-age-hud/run-index.json) · [review/failure record](../testing/stone-age-hud/review.md) · [owner launch](../testing/stone-age-hud/README.md). **348 Debug / 255 Release + 23 exclusion probes passed; 20 final native case executions passed, 0 failures/skips (9 phone Release + 9 iPad Release + 2 compact Debug).** The final Release matrix ran clean product b1255f3. The passing Debug worktree sources were committed unchanged as that product. Core receipt adc4c2c has the exact same complete SwiftPM package tree (`60470363bbc5d813a5ab364565625173af9e48a1`); the equivalence is pinned separately. Real 1× survey waits measured 61.852031 seconds on phone and 62.512843 seconds on iPad. Tests use simulator-only `com.civilization.seed.qa`, ordinary public New Game/Continue and real-time actions; no environment fixture, grant or speed control is needed for these cases.

167 protected source/config/art/rendering/persistence/fixture/runner files match the exact predecessor blobs. Authoritative engine/economy/seven-chapter story, geography, save formats and legacy progress logic are unchanged. GameSession differs only in its displayed ordinary welcome/Continue copy, directing players to Goals and accurately describing pause-on-close. Prior linked worktrees are retained. No owner saves, physical device, signing, media repository, main merge or deployment is involved.

Independent review found missing contextual Goals and missing main-map feedback. Both were reproduced RED and corrected with native regressions; the latter also checks a real unexplored-terrain tap. The unreachable inherited phone overlay was removed. Earlier expected-RED, accessibility/scroll/minimum-hit-target and renderer failures remain disclosed separately from final passes. Two agent-interrupted matrices are retained without pass credit. An inconsistent incremental run that omitted a new assertion is explicitly excluded; final native runs use a frozen clean source and new build roots. The preliminary multi-profile matrix was run during active edits and is not used as pinned final evidence.

## Owner launch and limits

Open this managed checkout’s Civilization.xcodeproj, choose Civilization and an iPhone or iPad simulator, then Run → New Game or Continue. The final test simulators are Stone Age HUD iPhone (iPhone16Pro/iOS18.6) and Stone Age HUD iPad (iPad mini A17Pro/iOS18.6); compact Debug/Release checks also use iPhone SE3. Xcode’s default normal bundle and the runner’s QA identity have independent saves.

This is simulator/software verification, not human enjoyment, final material/art acceptance, VoiceOver usability certification or physical performance acceptance. XXXL is verified larger text, not the maximum/accessibility Dynamic Type sizes. The existing provisional building art and deferred performance findings remain. No Bronze gameplay or next goal is implemented or queued. Dima must personally play this ordinary Stone Age build and explicitly approve Bronze later.

## Source and branch receipt

The exact source blob manifest,167 protected predecessor blobs, icon provenance and all28 runner report/log sets are under docs/testing/stone-age-hud. Archive statuses are15 passed and13 failed; these include six expected RED regressions, five other accessibility/target failures and two interrupted matrices. Only the named final required reports provide the final pass counts. Raw local xcresult bundles remain at their original recorded paths; screenshots retain native EXIF orientation and exact bytes. Original baseline permission/renderer failures are not acceptance.

Personal remote push verification is recorded in the final documentation receipt linked from the [pinned handoff](2026-11-21-stone-age-hud-handoff.md). No main merge or additional goal is implied.
