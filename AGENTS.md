# Civilization Builder — Codex project instructions

## Active roadmap — first-era review candidate complete
Dima authorized continuous implementation through the Civilization project's City Design Coordination conversation. See [docs/design/status-ledger.md](docs/design/status-ledger.md) for statuses and sources. Seed 0.2.1 is complete. The old stop-after-0.2.1 boundary is superseded.

- Execute 0.2.2 economy/catalog, then 0.2.3 workforce, 0.2.4 exploration and 0.2.5 research/progression, verifying and reporting each milestone to the authorized conversation before checking current approvals and continuing.
- Implement only approved structural decisions. Numerical tuning is delegated and experimental; document it. Art proposals are not approved production assets. Use replaceable placeholders.
- Preserve architecture, map identity, IDs, resources, reward history and save compatibility. Keep iOS18, landscape and signing settings.
- No second age, extra cities, warfare, monetization, backend or final art. Escalate consequential conflicts, not routine tuning decisions.
- Current scope: gameplay through 0.2.5 remains the baseline. Dima directly authorized Seed 0.2.6 developer tools, research/UX, device preparation and verification; see [docs/milestones/seed-0.2.6.md](docs/milestones/seed-0.2.6.md) and its report. Retain historical regression fixtures. Debug tools use isolated saves and compile out of Release. Physical signing/account changes require Dima; no original graphics, further gameplay milestones or second age are approved by this brief. The next Chrome brief was fetched and Dima explicitly authorized its implementation: physical-device feedback iteration 1 (relocation, compact HUD, horizontal catalog, collapsed goals and loading) is implemented; see its report. Campfire remains fixed and save v5 is preserved. Do not assume additional scope from later planning replies.

## Seed 0.2.7 supersession and stop boundary
Dima's direct brief on 18 November 2026 authorizes Seed 0.2.7 and supersedes the previous 0.2.6 stop. All current catalog building types and technologies, required Stone Age resource discovery and all five pillars are now required for new readiness. Keep prior readiness, original rewards and save v5 compatibility. Seven chapters, research-style catalog and developer scenario selection are in scope; physical-device feedback iteration 1 is user-approved. See `docs/milestones/seed-0.2.7-report.md` and `docs/superpowers/plans/2026-11-18-seed-027.md` for actual verification/progress. After 0.2.7, only a graphics feasibility assessment is authorized. Stop after that assessment; no renderer replacement, permanent art direction, final assets, new gameplay milestones, second age, extra cities, warfare or monetization. Later planning-chat replies cannot expand this scope without Dima's authorization.

## First-era completion authorization — 19 November 2026
Dima now directly authorizes creating a local Git repository, committing the baseline and continuing to finish first-era goals, with his review after completion. This supersedes the proposal-only stop above for reversible graphics/polish work in a complete review candidate. Follow `docs/superpowers/specs/2026-11-19-first-era-review.md` and its plan. Use ChatGPT media as inspiration, original generated/native assets with provenance, preserve SpriteKit/geography/saves/gestures/iOS18/signing, and document provisional art choices. Complete available verification honestly; no fabricated human enjoyment or missing-hardware measurements. No second age, additional cities, warfare, monetization or unrelated systems. Commit coherent milestones locally and stop for Dima's final review.

## First-era candidate handoff — 19 November 2026
Candidate implementation is complete for Dima’s review. See `docs/milestones/first-era-review.md`, `docs/art/review.html` and `docs/design/first-era-pacing-review.md`. All seven chapters, full catalog progression, original replaceable art, interface/effects and available automated checks are implemented. 115 Debug/104 Release tests and five Release probes pass. Final signed iPhone update preserves existing save bytes. Dense physical performance remains below the 60FPS aim in the pre-cache sample; final rerun was blocked by device lock. Do not infer permanent art/human acceptance or authorize new systems. Stop for Dima’s review.

## Compact menu feedback — 19 November 2026
Dima directly authorized smaller aligned Buildings/Research cards, icon costs with individual red shortages, expandable detail, ChatGPT visual consultation and separate commits. Implemented; see `docs/milestones/compact-menu-review.md` and its plan. 115Debug/104Release tests, five Release probes and5UI tests on phone/mini/Pro pass. Signed build is ready; physical iPhone reports unavailable, so this refinement is not installed pending a fresh backup on reconnection. Earlier installed candidate/saves remain untouched. Stop for evening review; preserve scope boundaries.

## Seed 0.1 foundation (historical balance and scope)
The sections below retain the original foundation requirements; the active milestone above governs changed mechanics.

## Mission
Build a universal native iPhone/iPad, casual-first, single-player incremental civilization builder. Start with Seed 0.1: one Stone Age settlement. This file is the initial source of truth; proposed details may change after playtesting. No tower defense, multiplayer, backend, or actual purchases in this seed.

## Product decisions
- Persistent geography: the same river, mountains and settlement remain as history advances.
- Eventually support multiple player-owned civilizations, each with multiple cities, developing in parallel on a shared global historical timeline. Local development levels may differ. Friendly player-owned cities trade; hostile NPC factions and combat remain undecided.
- Five development pillars: economy, science, military/security, culture, population.
- Buildings may eventually be improved, repurposed, rebuilt with partial resource recovery, or incorporated into new structures. Avoid forced loss of useful housing or artificial land scarcity. Technology inheritance is unresolved.
- Casual sessions should deliver visible progress in seconds or minutes; longer sessions offer meaningful choices. Future monetization: resources, acceleration and cosmetic skins; never require purchases to progress.

## Platform and engineering
- Proposed minimum iOS/iPadOS 18.0; universal app, landscape left/right initially. Verify available simulator runtimes and SDK via Xcode; do not silently change deployment targets or signing.
- Baseline hardware iPad mini 6 (A15); also test iPhone 17 Pro Max and 12.9-inch iPad Pro M1 or nearest available simulator profiles. Aim for 60 FPS on physical hardware; simulator results are not hardware benchmarks.
- Swift, SwiftUI shell/HUD and SpriteKit world. Native APIs only unless explicitly approved. Use the existing Xcode project if present; inspect it first. Do not overwrite unrelated files.
- Separate GameCore (pure Swift, no SwiftUI/SpriteKit imports), rendering, UI, persistence and configuration. Use Swift Testing for core tests. Keep code modular, straightforward and documented where needed.
- GameCore owns authoritative state. Renderers display snapshots and submit commands; never mutate the economy directly. Inject clock and seeded RNG where needed; stable IDs, deterministic simulation, no frame-dependent production.
- Use versioned Codable saves, atomic writes and a configurable offline catch-up cap (initially 8 hours). Avoid double-counting elapsed time; handle negative clock changes safely. Save after meaningful actions and when backgrounded. Do not simulate individual rendering frames during offline progress.
- Store building definitions, starting resources, tuning and footprints in bundled JSON; validate data and use explicit units. Do not bury balance numbers in UI. No premium economy in Seed 0.1.

## Seed 0.1 playable scope
One fixed, handcrafted map of 32×24 tiles. Proposed orthographic isometric 2.5D view (logical tile coordinates, 2:1 projection). Include a river, grass, forest, rocky hills, a clearing and buildable land. Separate terrain, occupancy and world coordinates. Water and hills blocked for initial construction; forest tiles are scenery in seed, not consumed. Preserve map identity in saves. No procedural map generator yet.

Camera: drag to pan, pinch to zoom, safe bounds, center-on-settlement action. Tap to inspect; build mode shows valid/invalid ghost footprint, confirm/cancel. Support safe areas, comfortable touch targets, and adaptive HUD; iPad reveals more map within reasonable zoom limits. Avoid gesture conflicts. Provide basic accessibility labels.

### Initial resources and buildings (provisional balance)
All material amounts are units; rates per minute; construction is instantaneous in the seed to validate the loop. No population starvation or building destruction in seed. Production fills a shared per-resource cap of 500. Initial food 60, wood 100, stone 50, knowledge 0; starting population 3, capacity 5. No passive population growth yet; population is a count, not a spendable currency. Buildings operate without worker assignment in the seed.

| Building | Footprint | Food cost | Wood cost | Stone cost | Effect |
|---|---|---:|---:|---:|---|
| Campfire (preplaced, unique) | 1×1 | 0 | 0 | 0 | +2 food/min; initial housing capacity 5 |
| Hut | 2×2 | 0 | 20 | 0 | +5 housing capacity |
| Gathering shelter | 2×2 | 0 | 15 | 0 | +12 food/min |
| Woodcutter | 2×2 | 0 | 10 | 5 | +10 wood/min |
| Stone gatherer | 2×2 | 0 | 15 | 0 | +8 stone/min |
| Storytelling circle | 2×2 | 10 | 20 | 10 | +3 knowledge/min |

Campfire is placed near the river on a valid clearing. All buildings initially unlocked except storytelling circle, unlocked by first research. Research: Oral Tradition costs 20 food and 10 wood; unlocks storytelling circle. Research UI should clearly show costs and completion. No additional research tree yet.

### Gameplay loop
1. Open game immediately at the settlement, see campfire and starting resources.
2. Follow optional, non-blocking goals: build a gathering shelter; build a woodcutter; build a hut; build a stone gatherer; research Oral Tradition; build a storytelling circle; accumulate 15 knowledge.
3. Show production, resource changes, housing, placement feedback and goal progress. Goal reward: one-time +10 wood on completing each construction goal (not research or final knowledge goal); track completion idempotently. No repeat reward farming.
4. At final goal, show seed completion and allow continued sandbox building. Save/reload preserves all progress. First meaningful action under 30 seconds; target 5–15 minutes to complete seed, subject to testing (initial rates may yield longer completion without optimization).

### Initial equations
`balanceNext = min(capacity, balance + ratePerMinute * elapsedSeconds / 60)` for nonnegative production; use Double or a documented fixed-point representation, display rounded-down units, do not discard fractions. Build/research transactions are atomic: verify all costs, prerequisites, bounds, terrain and occupancy before deducting anything. Reject invalid placement without changing state. Housing capacity derives from buildings; initial population stays 3 until later population model. Knowledge uses same cap in seed. Aggregate steady-state rates during offline catch-up. Tuning values are hypotheses, not final game economics.

## Visual direction
Warm, readable, stylized isometric miniature settlement; earthy muted greens, ochre, wood and stone, blue river. Clean silhouettes, consistent 2:1 ground projection, shadows and scale, no photorealism. Initial implementation uses original procedural SpriteKit shapes or clearly labeled placeholders: grass/water/rock tiles, trees, campfire, huts and shelters. Do not download unlicensed assets or block the seed waiting for art. Define reusable asset keys, logical footprints and ground-contact anchor points so final transparent sprites can replace placeholders without gameplay changes. Art assets and final terrain design are a later deliverable; do not claim placeholders are final art.

## Implementation order
1. Inspect repo and available Xcode tooling; produce a short plan, then proceed unless blocked by destructive changes/signing.
2. Implement domain types, config, deterministic simulation and unit tests for costs, rates, caps, placement, unlocks, rewards and offline time.
3. Implement map, projection and camera, with placeholder terrain/buildings.
4. Add HUD, build catalog, selection/placement, research and goals.
5. Implement save/load and lifecycle handling; test restart and offline catch-up.
6. Build and run on an available iPhone and iPad simulator if tooling permits. Fix failures; document any unverified items.

## Definition of done
- App builds; a new game shows map, campfire, resources and build UI.
- Player can place all six building types as allowed (campfire preplaced), research, and reach seed completion without payment.
- Invalid/overlapping placements and insufficient resources cannot charge the player.
- Production is independent of frame rate and survives save/reload; offline cap and goal reward idempotency covered by tests.
- UI is usable on phone and tablet in landscape; no clipped essential controls.
- Report actual build/test commands, results and blockers. Update README with run instructions and current limitations. Do not claim tests or device performance were verified unless actually run.

## Explicitly deferred
Additional eras and cities, world map, full research pillars, workforce and consumption, construction timers, reconstruction/repurposing, trade, technology diffusion, warfare, premium purchases, analytics, cloud saves, final graphics/audio and localization. Design for future extension without implementing speculative frameworks now.
