# Seed 0.2 — First Settlement

Source: Civilization project, “City Design Coordination”, approved instruction retrieved 17 November 2026: https://chatgpt.com/c/6afcb607-afec-83eb-9ba1-a4393b41348a

## Approved stage: 0.2.1 Simulation Foundation
Extend the functional Stone Age settlement with population growth, food consumption, gross/net resource production, configurable storage, efficiency modifiers, timed construction, technology prerequisites/effects/unlocks, chronological simulation, and versioned save migration. Keep the existing architecture, 32×24 geography, stable IDs, resources and earned rewards. Expose mechanics with minimal UI changes and the existing placeholder art. All tuning is provisional JSON configuration.

Five future development pillars remain Economy, Science, Military and Security, Culture, Population. Do not implement speculative future systems merely to represent a pillar.

Acceptance: retain Seed 0.1 regression coverage; deterministic tests for new mechanics; preserved/migrated old saves; construction and population progress survive relaunch; offline events occur in correct chronological order with the same eight-hour cap; no bootstrap deadlock; build/run on phone and tablet. Report results to the source conversation, then stop. Seed 0.2.2 requires further approval.

## Proposed larger milestone (not approved content to implement now)
The planning conversation proposes twelve total buildings, ten technologies, four development chapters, natural landscape presentation, production art, and later physical-device playtesting. Additional proposed buildings are hunting lodge, fishing shelter, farm, toolmaker, storehouse and sanctuary. Research branches and final content will be reconciled with the five pillars separately. Proposed chapter progression reaches 5, 10, 20 then 30 inhabitants; first-era duration is provisionally 45–90 minutes. These catalog, progression, art and duration choices remain open. Stage 0.2.1 does not commit them.

Proposed values: one food/person/minute; one person per 120 eligible seconds; at least 20 food and positive net food plus free housing for growth; Social Order interval 90 seconds. No starvation deaths or worker assignment. Proposed construction ranges: basic 10–20 s, production 20–45 s, advanced 45–90 s. Toolmaker's proposed 20% bonus and storehouse's proposed +250 capacity belong to future content; the foundation supports analogous data-driven technology effects for verification.

Art remains a separate deliverable requiring approved direction: twelve building sprites, reusable construction stages, terrain and river transitions, vegetation and rocks, smoke/fire/water effects, resource and research icons. All must share 2:1 projection, scale, lighting, transparency and ground-contact anchors. No downloaded assets or final-art overhaul in this stage.

Non-goals: additional eras/cities/civilizations, trade, diplomacy, warfare, individual citizen simulation, final catalog/tree, final art/audio, multiplayer and monetization.

## Implementation decisions for 0.2.1
- Keep the six existing buildings. Campfire stays operational at start; new construction deducts costs and reserves its footprint immediately, with benefits/rewards only on completion. Existing v1 buildings migrate as operational.
- Durations: hut 15 s; gathering shelter/woodcutter/stone gatherer 20 s; storytelling circle 30 s, configured per definition.
- Growth accumulates eligible time and pauses while housing, food reserve or positive net food is missing. Construction and growth events at the same instant complete construction first, then growth, then award goals. Timers store remaining simulated seconds, so time beyond the offline cap never secretly completes construction.
- Oral Tradition remains the zero-knowledge bootstrap. A small provisional foundation research list adds Stone Tools (economy; +20% wood/stone) and Social Order (population; 90 s growth), both requiring Oral Tradition. This exercises multiple branches and modifiers without committing to the final research tree.
- Rates, consumption and capacity aggregate over all Resource cases; ResourceAmounts uses a keyed Codable representation so new enum resources do not require new arithmetic paths. No speculative resource registry.
- Keep the save filename, upgrade envelope to v2, validate before overwriting, and preserve an original v1 backup when writing the first migrated save. No reward regrant, forced demolition or map reset.
- Preserve original instantaneous/no-consumption tests against a frozen v0.1 configuration fixture. Add tests against the current v0.2 rules; do not weaken old assertions to mask changed behavior.
