# Retrieved decorative-road brief

Source: [City Design Coordination](https://chatgpt.com/c/6afcb607-afec-83eb-9ba1-a4393b41348a), turn `33289db9-249d-454c-b5b4-8b71fb93090a`, message `687607db-1eb3-4916-95b2-56ce7ee56c34`, retrieved19November2026. Full connector-returned text (9484characters), no image attachments. This is assistant design input based on reported work, not independent repository/hardware inspection or new human approval. External image-search/prototype widgets are reference metadata, not imported assets.

Reconciliation: agree with current approved road scope and three independent Draw/Replace/Remove modes. Retain committed explicit Confirm/Cancel and atomic invalid-stroke rejection for this iteration instead of the assistant's proposed release commit/skip-invalid behavior. These are implementation choices made visible to Dima, not superseded human requirements. Larger-size/NPC/media stages remain deferred.

---

# Seed 0.5.2 — Decorative roads

The building geometry foundation is accepted based on the implementation report. Moving directly to decorative roads is a sound decision. We do not need to activate larger building footprints before implementing roads.

Keeping the current dimensions avoids introducing unnecessary migration risks before first-era human acceptance.

## 1\. Updated development status

(Geometry foundation delivered)

---

Current baseline: ed23e2e · first-era-review · clean working tree

## 2\. Road types

Retain the three previously approved decorative road styles.

image_group{"query":["realistic miniature neolithic village narrow trodden grass footpath warm natural sunlight"],"aspect_ratio":"4:3","layout":"carousel","num_per_query":1}

**Trodden path**

Flattened grass and exposed earth.

image_group{"query":["realistic miniature prehistoric village compacted dirt road natural brown earth texture"],"aspect_ratio":"4:3","layout":"carousel","num_per_query":1}

**Dirt road**

Clearly defined compacted earth.

image_group{"query":["realistic primitive irregular flat stone path embedded in earth ancient village miniature"],"aspect_ratio":"4:3","layout":"carousel","num_per_query":1}

**Stone road**

Rough natural stones embedded in soil.

All three styles should be available without research, construction costs or maintenance. Upgrading a road means replacing its surface, not increasing its economic benefits.

These images are external inspiration, not production assets.

## 3\. Interactive road design reference

The following prototype demonstrates the intended placement, material replacement, removal and mixed-style connections.

- Trodden
- Dirt
- Stone
Current selection unavailable.

- Draw
- Replace
- Remove
Current selection unavailable.

road tiles · No resource cost  [Clear]

Tap open tiles to edit. Buildings and undiscovered territory are protected. This is a simplified top-down design demonstration; the game retains its existing projection.

## 4\. Connection and rendering rules

Each road tile derives its connection mask from the presence of neighboring road tiles, regardless of material.

All 16 four-direction connection masks, including isolated tiles, dead ends, corners, junctions and intersections.

Three materials multiplied by sixteen masks give 48 logical visual combinations.

I recommend reusable original procedural textures for this stage rather than producing 48 permanent illustrations.

| Media property | Proposed implementation |
|--------|--------|
| Ground projection | Match current renderer |
| Scale | One logical map tile |
| Anchor | Existing terrain-tile anchor |
| Transparency | Transparent road edges |
| Layer | Above terrain, below buildings |
| Lighting | Consistent with existing landscape |
| Texture generation | Cached, reusable combinations |
| Provenance | Original procedural candidate assets |

Parallel road tiles should create visibly wider surfaces rather than two unrelated narrow tracks. This requires particular attention to texture continuity.

## 5\. Consequential conflicts and safeguards

There are no architectural blockers to implementing roads now, but several interactions must be specified.

| Conflict | Recommended resolution |
|--------|--------|
| Building placed over a road | Reject placement until road is removed |
| Building relocated onto roads | Same occupancy validation |
| Road dragged through a building | Skip invalid tiles without altering buildings |
| Road crosses unexplored territory | Reject undiscovered tiles |
| Mixed road materials | Connect using common geometry |
| Future footprint expansion | Never silently delete roads or resize buildings |
| Existing saves | Load with an empty road layer where road data is absent |
| Road editing versus camera movement | Explicit road editing mode |
| Future NPC navigation | Expose road queries without implementing NPCs |

For the initial implementation, I recommend a drag preview that commits on release. Cancelling or initiating a pinch gesture discards the uncommitted preview.

This is a proposed interaction detail, not a previously approved requirement.

---

# 6\. Implementation brief for Codex

:::writing{variant="document" id="59231"}
# Seed 0.5.2 — Decorative roads

**Status: Authorized by Dima's instruction to move on, within the previously approved decorative-road scope.**

## Prerequisites

- Use ed23e2e as the implementation baseline.
- Preserve the current production building footprints.
- Reconcile the road specification with the canonical design documents and commit it before implementation.
- Record operational defaults as implementation decisions rather than recovered human approvals.

## Approved requirements

- Three road styles: trodden path, dirt road and primitive stone road.
- Free, decorative, single-tile placement.
- Parallel placement for wider roads.
- Continuous drag placement.
- Automatic four-direction connections with sixteen masks.
- Persistent placement, removal and material upgrades.
- No economic effects or first-era progression requirements.

## Operational defaults

- Roads occupy discovered, open, buildable land only.
- Roads and buildings cannot overlap.
- Different road materials connect.
- Draw, Replace and Remove are explicit editing modes.
- Draw does not overwrite existing roads.
- Replace changes the material of existing road tiles.
- Remove deletes only roads.
- Every road tile retains its selected material.
- Invalid tiles are skipped during a stroke.
- Preview edits before committing on release.
- Cancellation and pinch gestures discard uncommitted changes.

## Core and persistence

- Store road data independently from buildings.
- Use stable logical tile coordinates and road-style identifiers.
- Derive connection masks from neighboring road occupancy.
- Validate edits before committing.
- Update affected tiles and adjacent connections.
- Preserve existing saves and version compatibility.
- Legacy saves without road data load with no roads.
- Reject invalid or overlapping road data safely.
- Do not activate larger building footprints or rotation UI.

## Interface

- Provide a dedicated Roads entry point outside the twenty-building catalog.
- Show three material selectors and Draw, Replace and Remove modes.
- Provide clear valid/invalid placement feedback and cancellation.
- Preserve camera pan, pinch zoom, building construction and relocation.
- Keep roads out of research, achievements and era completion requirements.
- Provide accessible controls and understandable editing-mode indicators.

## Rendering

- Retain SpriteKit and existing geographical projection.
- Use original replaceable procedural candidate textures.
- Support all sixteen masks for all three styles.
- Connect mixed materials and visually accommodate parallel placement.
- Cache reusable textures and update local regions rather than rebuilding the map.
- Keep permanent artwork and mass media production outside this milestone.

## Acceptance criteria

1. All sixteen connection masks are correctly calculated and rendered.
2. Fast and diagonal drag strokes produce gap-free four-connected roads.
3. Draw, replacement and removal behave independently.
4. Mixed materials connect without changing neighboring material selections.
5. Parallel roads visually form wider surfaces.
6. Buildings, undiscovered tiles and invalid terrain remain protected.
7. Construction and relocation reject road overlaps.
8. Cancellation and pinch gestures cause no unintended edits.
9. Road edits survive save/reload.
10. Historical saves remain compatible.
11. Resources, production, research, workforce and progression are unaffected.
12. Legitimate first-era completion remains achievable without placing any roads.
13. Existing core, UI and Release-exclusion regressions pass.
14. Phone and tablet simulator editing flows are verified.
15. Rendering overhead is assessed and physical-device limitations are documented.

## Deliverables

- Committed canonical specification.
- Road implementation and regression coverage.
- Phone and tablet screenshots demonstrating all three materials, corners, intersections, mixed surfaces and wide roads.
- Save compatibility and performance assessment.
- Milestone report and updated status ledger.

## Restrictions

No NPC implementation, road economic effects, research gates, additional building types, larger footprint activation, permanent media replacement, second era, additional cities, warfare, monetization, backend or renderer rewrite.

Stop after the decorative road milestone and report completion.
:::

## 7\. Remaining decisions

The following do not need to block decorative roads.

- Exact building dimensions and legacy footprint conversion.
- Permanent road artwork and texture resolution.
- NPC navigation and device-specific population budgets.
- Historical insolvent-save recovery (Q-PLAY-1).
- Human first-era comprehension, pacing and artistic acceptance.

Physical deployment and final hardware performance verification also remain outstanding.

I have not independently inspected the repository, executed its tests or retrieved original image files. The implementation brief is based on the reported baseline, previously established road requirements and explicitly identified proposed operational defaults.

**Proceed with Seed 0.5.2. Roads should make the settlement feel more personal and organized, without making the first era any harder to understand or complete.**

