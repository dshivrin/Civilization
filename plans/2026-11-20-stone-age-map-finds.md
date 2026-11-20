# Goal: Stone Age Map Finds — useful things to do while waiting

**Owner direction, 20 November 2026:** Add the proposed tracks and berries as a small prototype. Tune the feel and rewards after playtest. This is a follow-up to the [Riverbend Economy Lab](2026-11-20-stone-age-economy-foundation.md), not a change to ordinary games or permission to interrupt ongoing visual work.

## Codex goal

Once the base ten-minute lab passes its own checks, add two optional, persistent map interactions in that Debug-only profile. During a real construction or expedition wait, a player can notice a find on already revealed terrain, tap it, and do something useful without spending resources. The main route must still complete if the player ignores both.

| Find | Interaction | Initial prototype tuning |
|---|---|---|
| Wild berries | Inspect a patch and choose **Gather**; show the exact Food reward before confirming. | +3 Food, at most one patch in the first lab run. If capacity would block the reward, keep the patch intact and explain why. |
| Fresh tracks | Tap to inspect. **Observe** marks a reachable wildlife clue on already revealed terrain, without revealing a new area or unlocking a building. If the scenario has an existing Hunting unlock and a valid active inventory, optionally offer **Hunt** instead for the stated payout. | Observe-only is sufficient for the ten-minute lab. In an optional Hunting-enabled lab fixture, test +3 Food or +1 Hide as scenario-configured rewards, not a hidden random drop. Never award a locked Hide resource or create a Meat resource. Choose only one outcome per find. |

Defer riverbank finds, general spawners, timed wildlife simulation, trade, and production integration. Ambient wildlife in the [Living World plan](2026-11-20-living-world-environmental-animation.md) is separate. Use review markers or existing approved assets; do not depend on replacing art.

## Execution

1. Read `AGENTS.md`, `scripts/README.md`, the Lab plan and the [approved exploration onboarding plan](2026-11-20-first-settlement-exploration-onboarding.md). Pin the working lab commit and keep this follow-up in the authorized review workspace. Verify the ordinary and Economy Lab routes still pass independently.
2. Place both prototype finds with stable lab-local IDs at deterministic, reachable, unoccupied sites on revealed terrain. Surface the first during the first actual build or expedition wait, on a legal visible site. If a site becomes blocked, choose a legal fallback without minting a new reward or exposing fog. Preserve resolved/unresolved state over save/reload. No real-time expiry, streak, repeat-tap farming, or need to remain online. If varied appearances are tested later, seed the type/site once, expose the reward before the choice, and cap how often payouts occur.
3. Tap opens a compact, dismissible action with the actual outcome. Don't steal camera focus or intercept active placement, pan, or zoom. Never route around research, grant a region reveal, or make a find the only escape from an empty Food/Wood state. Keep guaranteed recovery independent. Apply result and mark resolved atomically; rejected/failed writes must not consume the find or permit a duplicate payout. No advertising, purchases, tradeable credit, or premium reward. If trade eventually exists, pickup rewards must not increase export-eligible surplus.
4. Add regression coverage for tap and dismiss, both valid interactions, hidden or occupied sites, storage full, locked Hunting, save/reload before and after resolution, duplicate activation/retry, and a completion route that ignores all finds. Verify Release exposes no feature and ordinary, developer, and Round 2 saves remain unchanged. Reuse `python3 scripts/dev.py` and the established native test targets. Keep R2-07 off.
5. Deliver a short iPhone/iPad review capture showing a real wait and a find without tutorial handholding. Record what players noticed, whether the reward led to a useful choice, and whether the interaction distracted from the map or outperformed ordinary production. Report actual tests, commit and tunable values. Stop for review before adding more find types, adjusting the normal economy, or integrating with the native visual redesign.

**Done for review:** Two distinct optional finds work in the lab. A player can ignore them, discover both without blocking normal controls, and reload without losing or duplicating them. No branch merge, physical installation, production rollout, or change to existing saves.
