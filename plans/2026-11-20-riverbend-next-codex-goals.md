# Codex handoff: Riverbend economy, UX and visual goals

**Goal:** Turn the first ten-minute Economy Lab into a first-era review build, and prove the realistic, high-saturation visual direction in one actual scene before expanding asset production.

**Architecture:** Economy goals are sequential on a review line. The graphics goal has its own context and worktree and can run alongside them when Mac resources allow. Combine verified work in a separate integration review build. All new economy mechanics stay behind the isolated Debug lab until a separate adoption decision.

**Spec:** Read the [current Economy Lab handoff](2026-11-20-overnight-economy-goal.md), [economy foundation](2026-11-20-stone-age-economy-foundation.md), and [Map Finds spec](2026-11-20-stone-age-map-finds.md). Read current `AGENTS.md`, `DEVELOPMENT_ROADMAP.md`, and `scripts/README.md` at each start. For graphics, use the [Living World plan](2026-11-20-living-world-environmental-animation.md), latest review checkpoint and current artwork evidence.

## Run order and fresh contexts

`E0 → E1 → E2 → E3 → E4`. Start `V1` in parallel after the active visual goal yields a stable checkpoint and an independent worktree is available. Combine E3 and V1 in E4 if both are verified; otherwise deliver the economy review without waiting for unaccepted graphics, then do the combined capture when V1 is ready.

- Use **one fresh Codex context window and one explicit Goal per ID**. Start each from the exact verified predecessor SHA, not from the previous transcript. E0 is the current handoff, not a duplicate goal. Do not send a queued instruction into an active context as a substitute for opening a fresh one.
- At the end of each goal, commit/push only to the designated review branch, and save a short Git handoff in `docs/milestones/`: goal ID, base and delivery SHA or pinned evidence, exact tests/results, known issues, what stayed unchanged, and next allowed goal. A blocked prerequisite stays blocked; do not silently skip native checks or advance dependent work from a partial delivery.
- Reuse `python3 scripts/dev.py` and the current simulator setup. Add focused regression coverage before changing behavior. No new tools, signing changes, device installs, physical save access, or permission changes. If environments contend for a simulator/cache, run serially or isolate the targets and derived data.
- Keep Normal New Game/Continue, production saves, Developer and Round 2 review modes, R2-07, and production assets/onboarding unchanged. No edits to real saves, no forced upgrades, no ads/purchases/audio roadmap/Empire-era work. No force-push or merge to main. Verified review branches may be combined in E4; that is not human acceptance or production activation.

## E0 · Base Economy Lab — existing goal

**Goal:** Deliver the playable Food and Wood loop exactly as scoped in the current handoff. Prove hut → contiguous forest survey → legal Woodcutter → positive Food and Wood, with no lab Water loop, free bounded recovery and persistence. Verify the lab is absent in Release and ordinary modes are unchanged. Stop at the existing review/handoff gate; no duplicate E0 work.

## E1 · Map Finds

**Goal:** Make a real construction or expedition wait playable without adding a required chore.

- Use two deterministic, persistent finds on revealed land: berries grant the stated small Food reward; deer tracks offer Observe. Hunting is optional and only follows the already approved fixture rules; no new meat item, paid reward, or ambient wildlife engineering.
- A full stockpile or failed save must not consume the reward. Reopening, retrying and relaunching cannot issue it twice. Keep the ordinary route and guaranteed recovery independent of both finds.
- **Done:** Native review captures show a real wait and a find. Automated checks cover ignoring both, full stock, retry, persistence, invalid or hidden locations and Release/normal-mode isolation. Stop and push the new verified checkpoint.

## E2 · Stone and storage

**Goal:** Give Stone a clear first use and make storage limits understandable, without complicating the opening.

- Keep the original ten-minute route completable before Stone. A revealed outcrop introduces Stone and an existing or lab-scoped gathering path. Surface one useful sink, a civic upgrade or storage project, with its cost and a reachable source. No mandatory Stone before hut, food recovery or Woodcutter.
- Prototype one storage family with two roles: **Granary** increases Food capacity only; **Stockyard** increases Wood, Stone and later craft-material capacity, never Food. Use the approved foundation’s candidate numbers as the initial lab fixture unless a documented test exposes a balance problem. Keep the base cache usable; distinguish current amount, cap, and building contribution in the lab readout.
- **Done:** A player can reveal, collect, spend and store Stone. Tests prove both capacity effects independently, predictable behavior at capacity, safe reload/accounting and unchanged E0/E1 routes. No new art requirement; stop at the review checkpoint.

## E3 · One craft chain

**Goal:** Teach gather → craft → use through one visible payoff instead of a crafting catalog.

- Reuse the approved foundation’s Wood-and-Flint-to-Tools direction; introduce Flint with this opportunity, not at New Game. Limit the pilot to one recipe and one clear use. Prefer a single targeted work/construction improvement with costs and benefit shown before the player commits; if following an existing project hook, document which one. Tools are a spent project input, not recurring upkeep. Keep the opening and recoveries independent of crafting.
- **Done:** The player sees where to get the inputs, completes one craft and spends it to see the promised effect. Verify insufficient stock, full storage, retry and reload, and no doubled charge, output or benefit. Save one native walkthrough and the balance trace. Defer additional recipes and currencies.

## V1 · One realistic, saturated Riverbend scene

**Goal:** Show the desired look in one native in-game scene, not in a detached mood board, before generating a family of assets.

- Fork a separate visual review worktree from the latest verified visual checkpoint. Pick one representative view: riverbank, forest edge, hut, campfire, and visible ground contact. Establish natural proportions, coherent daylight/shadows, and richer terrain and foliage color with clear buildings, paths and controls. High saturation should not read as neon or obscure what is tappable.
- Show a matched before/after at the same camera, time and zoom, on phone and iPad. Include one short actual gameplay recording with existing motion and one readability check for selected-building/build or resource affordances. If changing an asset, retain source/provenance and keep it review-only. No catalog-wide replacement, map geometry changes, or production appearance acceptance.
- **Done:** The scene is inspectable in the app and backed by matched evidence. Report what works, what still looks artificial or unreadable, and which visual decisions need owner review.

## E4 · First-era review and integration

**Goal:** Produce a coherent first-era gameplay review that exposes the real UX issues, without turning prototypes on for ordinary games.

- Create a review integration worktree. Bring in tested economy changes and relevant verified visual work without rewriting the source branches. If integration or art acceptance is blocked, report the conflict and keep the branches independently runnable. Do not promote V1 to the normal renderer.
- From a fresh isolated campaign, play from the first hut through the existing Stone Age/Bronze-readiness goal where supported. Record progression, real wait points, blocked costs, dead ends, and whether the next useful action is obvious. Focus only on the reviewed paths: make the next action and cause of a block visible without searching several menus; favor direct links, compact alerts, and existing presentation components. Do not redesign every screen.
- **Done:** Record fresh, delayed and depleted-stock paths; demonstrate normal Release entry and ordinary save isolation; provide a short phone/iPad review with exact commits, tests, and unresolved UX/art decisions. Distinguish reached readiness from playable Bronze. Stop for owner playtest rather than merging to main, installing, or declaring the look finished.
