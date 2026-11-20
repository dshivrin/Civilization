# ROUND-2-PLAY — Connected Settlement and Placement Review

Date: 2026-11-20
Status: APPROVED DESIGN DIRECTION; IMPLEMENTATION REQUIRES RECONCILED TASK BREAKDOWN
Reconciliation: [proposed task breakdown and owner decisions](../docs/design/proposals/2026-11-20-round-2-play-reconciliation.md), prepared for scope review; not implementation approval.
Source: owner's second Stone Age 10× isolated-save playthrough and screenshots.
Repository: dshivrin/Civilization

## Owner-approved rule: strict operational path connectivity
Stone Age operational buildings may be placed/constructed before connection, but cannot produce resources or deliver ordinary services until connected to the settlement's path network. The founding civic center's essential food (+2/min), water (+3/min) and housing (+5) provisions remain independent of roads, level and cultural staffing. This rule supersedes the current purely decorative-road behavior for affected buildings, but preserve decorative road styles and prior save history. Explicitly specify and test exceptions for paths, bridges, gates, civic center, unfinished buildings and non-operational decorations during reconciliation; do not invent new economic penalties.

## Findings from human playthrough
- Completed seven chapters and Bronze readiness while most of 64×48 territory remained unexplored and roads unused; settlement can be tightly clustered with no geographic logic.
- Resource-related buildings can be placed far from the forest/hills/deposits they depend on; storage can appear without local extraction.
- A blue/cyan dot appears beneath buildings; investigate render/anchor/debug overlay.
- Building rotation unavailable.
- During candidate placement/relocation, navigation is impeded; owner wants bottom-of-preview RED X cancel and GREEN check confirm, removing redundant confirm/cancel from inspector menu. Map pan/zoom must remain usable.
- Goal/research/building links open broad screens but fail to scroll to and highlight exact item; locked prerequisite search may return no results. Exploration missing-research links need same direct navigation.
- Upgraded Campfire/Gathering Place/Council Circle has no visible stage differentiation; defer artwork to coordinated media/graphics milestone, including sprite footprint and UI sizing.
- Palisade can be placed as a disconnected fragment; owner expects enclosure of inhabited buildings, a gate and watchtower on/adjacent to perimeter.
- Unexplained brown central zone/terrain overlay; investigate purpose and communicate or remove.
- Buildings can be placed across a river without a bridge or reachable connection.
- Full exploration of all 3,072 tiles should not be required; however, exploration of relevant resource areas and a connected outpost should be meaningful to era progression.

## Design inspiration and principles
- Anno-style operational path/service network; Banished-style local resource geography; Against-the-Storm-style purposeful frontier discoveries; Kingdoms-and-Castles-style infrastructure-led expansion. Inspiration only, no copying artwork or proprietary implementation.
- Proposed loop: explore a chosen frontier -> identify resource location -> establish local production -> connect with paths/bridge -> expand village and defenses.
- For small-screen usability, connectivity is one network to the civic center rather than an individual road between each building pair. Proposed rule: valid access point adjacent to any accessible building side; exact road graph, service ranges and exceptions require technical reconciliation.
- Permit pre-planning: disconnected buildings remain placed and show clear inactive state plus actionable path guidance; no retroactive destruction of saved structures.

## Proposed milestones (names/versions provisional; reconcile with existing CLU, MAP, S1 and UX backlog)
1. Placement & navigation: confirm/cancel controls at candidate, independent map gestures, rotation including 1×1 visual orientation and non-square footprint rotation, fix blue dots, direct research deep links with filter clearing, scroll and highlight, identify brown terrain.
2. Geography & infrastructure: terrain/deposit proximity rules, production-vs-storage dependencies, connected paths, Stone Age bridges, river bank access and operational connectivity; clear UI explanation and deterministic graph tests.
3. Settlement planning: meaningful perimeter/gate/watchtower validation, residential layout, exploration-driven outposts and Stone Age chapter/readiness predicates.
4. Deferred visuals: distinct civic stages, sprite anchors/sizing and environment assets through Civilization-Media. Do not block logical work on unapproved art.

## Safety and migration
- Reconcile existing save v6, older supported versions, completed chapter/objective/reward history, isolation of normal/developer/review copies and 64×48 map.
- Preserve all placed buildings, roads, resources and achievements; no silent deletion or retroactive loss of already-earned era readiness.
- New connectivity rule should affect future production without rewriting past transactions. Existing saves with disconnected buildings must remain loadable and clearly explain inactivity; provide a safe transition policy before enabling in normal saves.
- Founding provisions must remain functional even with zero road tiles to avoid a softlock. Consider availability of starter path material and riverbank resources on generated maps.
- Revisit seven-chapter progression to validate achievable geography, resource access and road requirements; require relevant discovered resource sites/outpost, not total map reveal.
- Keep exploration and defense details as proposals until their exact criteria/costs/rewards are approved; no surprise combat or later-era features.

## Codex handoff
Read this plan alongside DESIGN_BASELINE.md, DESIGN_DECISIONS.md, DEVELOPMENT_ROADMAP.md, DESIGN_SYNC.md, plans/GAME-LOOP-01.md, current CLU/MAP/S1 design documents and actual source/tests. Produce a concise reconciliation with precise task IDs, dependencies, migration policy, acceptance tests and any owner decisions still needed. Owner has approved strict road operational gating and founding provision exemption, NOT arbitrary new balance numbers or implementation of every proposed system. Do not start broad feature implementation until the reconciled scope is approved. Use reusable QA tooling and isolated review saves; never overwrite normal progress. Commit/push reconciled plan and report short Git SHA and blockers.
