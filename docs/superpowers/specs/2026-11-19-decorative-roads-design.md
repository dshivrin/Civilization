# Decorative roads — bounded implementation design

Authority: Dima’s direct “Report to ChatGPT and move on” after geometry deliveryed23e2e, plus approved road direction in the synchronized human brief. Report sent to City Design Coordination; its reply is design input, not a permission gate. Continue inline on first-era-review, commit coherent steps. Preserve first-era understanding/completion and all135Debug/124Release regressions.

## Scope and implementation choices

Deliver trodden path, dirt road and primitive stone road as free decorative single-tile overlays, all available from an explicit Roads tool. Parallel strokes allow width. No rates, transport bonus, workforce, research gate, pillar/goal/catalog requirement, NPCs or monetization. Current building dimensions/art remain unchanged; larger-size activation/legacy conversion stay separate.

Alternatives considered: activate unapproved larger dimensions first (unnecessary for roads using shared effective occupancy); direct-draw resource mutations on every drag update (cannot cancel); preview then explicit atomic Confirm (chosen). This is a reversible decorative stage using existing geometry, not a final art selection.

Operational defaults (Codex choices within the authorized stage): only discovered grass/clearing; no roads under occupied buildings or on protected forest/hills/water; no bridges. Buildings/relocation require explicit road removal first. All styles connect, independent of material. Painting a selected style explicitly changes existing road tiles after confirmation (upgrade/downgrade free); Erase removes, empty valid tiles no-op. No automatic clearing/replacement through ordinary building commands. Help text explains these rules. Q-RD-1/2 are resolved for this stage by this documented choice; not misattributed as recovered human wording.

## Domain/persistence

RoadStyle Codable cases trodden/dirt/stone. RoadTile holds logical tile/style separately from buildings. GameState optional roads:[RoadTile], nil old saves means empty and is not normalized without editing. v5 envelope unchanged; validate at most map area, unique tiles, discovered open terrain and no building overlap before rendering. Each edit validates entire bounded stroke first, then updates/sorts y/x atomically; invalid edits leave all state unchanged. No evaluateGoals or spend in road commands; no silent grant/reset or legacy rewrite.

Connection protocol: logical north(y−1)=1, east(x+1)=2, south(y+1)=4, west(x−1)=8; no diagonals. Stored styles/tiles only, masks derived from neighbor occupancy. Four-connected deterministic grid traversal fills gaps between drag samples, bounded by map dimensions and map-area stroke size. Repeated/backtracked cells are deduplicated. Persist after Confirm, discard preview on Cancel/tool switch/build/research/navigation/background/developer-scenario switch. Same-style application/removing absent cells idempotent.

## Session/UI/gestures

GameSession owns nonpersistent road tool, ordered/deduplicated draft and validation. Roads toolbar button replaces no essential control; compact button/expandable panel offers3styles,Erase,Clear stroke,Confirm,Done. Draft updates never save or change economy. Confirm clears draft but keeps road mode for further strokes. Tap adds a tile; one-finger drag paints in road mode, otherwise existing pan/build/relocate behavior unchanged. Long-press relocation disabled only while road mode active. Pinch clears pending stroke while keeping selected road tool and zooms; leaving road mode restores pan. Background discards draft and saves only committed state. Road preview shows invalid cells red and valid mint, count and explanatory error. Roads remain optional, clearly labeled decorative/free/no era requirement.

## Rendering/media

Separate SpriteKit road layer above ground/below buildings, original replaceable procedural path/dirt/stone strokes, no generated final assets. One road node per tile with a small16mask path, distinct material colors. Compare cached road tile/style map; redraw only changed cells and four neighbors (also on discovery change). Draft layer cached independently and never replaces persisted styles. Reuse existing2:1projection. No whole terrain/building redraw for a road edit. Bound nodes to map area; measure simulator nodes/memory where available, no hardware60FPSclaim.

## Acceptance

All16masks including edge/T/cross/isolated/mixed-material/removal; continuous4-connected gap-free stroke; atomic mixed-valid/invalid/fog/terrain/building rejection, bounds/malformed duplicate saves, old nil save round-trip. No resources/rates/population/requirements/history drift from road commands, legitimate era can finish with no roads and after road edits. Save/reload retains per-tile styles/removals; edit idempotency. Session cancel/confirm/tool change/pinch/background and fresh normal save isolation tested. Phone/mini/Pro verify road draw→confirm→change style→erase, cancel draft, old building drag/long-press/pan/pinch, compact catalogs and full first-era UI tests. One final independent review; signed/Release builds and developer restrictions. Physical install only with fresh validated backup when device available. Report/commit actual evidence and limitations; stop before NPCs/art-size activation.
