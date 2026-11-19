# Seed 0.2.2 — Buildings and Economy

Status: APPROVED FOR IMPLEMENTATION. Retrieved from City Design Coordination, 17 November 2026. Continuous roadmap supersedes the former stop-after-0.2.1 boundary. Numerical values are EXPERIMENTAL tuning; approved structural choices are below. Original art remains PROPOSED / separately designed.

Approved catalog (20): campfire, hut, gathering shelter, hunting lodge, fishing shelter, woodcutter, stone gatherer, farm, animal pen, storehouse, toolmaker, tannery, pottery workshop, storytelling circle, healer's hut, shrine, burial ground, scout camp, watchtower, palisade. Preserve original IDs.

Approved resources: food, wood, stone, water, flint, clay, animal hides, stone tools, leather, pottery; knowledge and culture. Copper is a future deposit only, not extractable this age. Recipes: wood + flint → stone tools; hides → leather; clay + wood → pottery. Automatic extraction, recipes, continuous maintenance, permanent upgrades, geographical advantages, renewable/finite deposits and per-resource capacity are approved. No negative balances, deaths, debt, deterioration or abandonment. Survival production must remain recoverable during shortages.

Independent verification: manufacturing/maintenance, depletion/recovery, fair competing consumers, online/offline partition equivalence, upgrades/cost atomicity, save migration and fresh-game chain accessibility, phone/tablet builds. UI needs categories, all resource breakdowns, recipes, upgrades and operating/shortage status. Placeholder art only.

Implementation choices (DELEGATED / EXPERIMENTAL): finite flint/clay/stone deposits and renewable forest/water/hides; stone gatherer modes for stone/flint/clay; fishing shelter collects water; shared shortage allocation is proportional within dependency tiers (not array order), fed by upstream production at empty stocks. Rates integrate to depletion/construction/growth events, never rendering frames. Upgrades preserve IDs and consume configurable costs; storage and output benefits depend on operational level. No worker allocation/exploration/full research tree in this stage.
