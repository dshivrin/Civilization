# Roadmap after Seed 0.2.7 — retrieved proposal

Retrieved 19 November 2026 from [City Design Coordination](https://chatgpt.com/c/6afcb607-afec-83eb-9ba1-a4393b41348a), following Dima's explicit request to report completion and ask for the updated roadmap.

Status: report-based acceptance of 0.2.7; further work is PROPOSED and awaits Dima's approval. This is planning context, not authority to expand implementation.

Implementation annotations:
- Current local regression counts are 106 Debug / 96 Release; three UI tests pass on phone and two tablet simulators.
- The response cites the older 156-minute playthrough and asks for a revised measure. The revised real-cost measurement already exists: 154 minutes, all twenty types/technologies, all seven chapters and pillars, 650/768 discovered tiles. See the milestone report; do not repeat the older figure as current.
- References to five additional landscape types are planning context, not approved scope. Preserve the existing valley and current stop boundary.
- No art generation, pilot implementation, renderer replacement, balance change or later milestone is approved by this response. The suggested next brief is explicitly proposed.
- External references shown in the ChatGPT response are inspiration, not original or approved production assets.

## Retrieved response

# Civilization — Seed 0.2.7 accepted

November 19, 2026

(Stone Age progression implemented)

---

Seed 0.2.7 is accepted based on Codex's implementation report. We have reached the end of our initial gameplay development sequence.

From this point, our main focus should be visual identity, immersion, gameplay balance and polishing the player experience, rather than expanding the game's mechanics.

# 1\. Our seven PROJECT stages

# 5 of 7

# 71%

The 71% represents completed project stages, not an estimate of total development effort. Graphics could easily become our most time-consuming stage.

# 2\. Our seven IN-GAME chapters

These are the development chapters experienced by the player, not our software development milestones.

---

All seven chapters are reported implemented. Exact objective definitions and pacing still require human evaluation.

The software now supports completing all seven chapters. We still need to establish whether playing through them is enjoyable.

---

# 3\. Stage 6 — Original graphics and visual identity

My recommendation is to approach this as an art production pipeline, rather than immediately generating twenty different building images.

## 0.3.1 — Visual identity

First, establish how our civilization should look.

image_group{"query":["beautiful handcrafted miniature neolithic village diorama river valley thatched huts realistic natural textures soft sunlight"],"aspect_ratio":"16:9","layout":"carousel","num_per_query":1}

**A — Living miniature world**

Detailed materials, organic environments and miniature architecture.

image_group{"query":["hand painted isometric prehistoric neolithic village ancient forest river hills painterly game environment concept"],"aspect_ratio":"16:9","layout":"carousel","num_per_query":1}

**B — Illustrated history**

Hand-painted textures and expressive historical landscapes.

image_group{"query":["stylized realistic isometric neolithic village river terrain trees clean architectural 3D game environment"],"aspect_ratio":"16:9","layout":"carousel","num_per_query":1}

**C — Stylized architectural realism**

Clear geometry, recognizable structures and natural proportions.

These are reference images, not original assets.

**Deliverables\:** Three original concept designs depicting the same settlement, a color palette, architectural language, lighting direction and camera perspective.

**Acceptance criteria\:** A recognizable and consistent visual style that works on both iPhone and iPad and can evolve naturally into later historical ages.

**Dima's approval\:** Selection of the artistic direction.

## 0.3.2 — Rendering architecture and asset pipeline

Our current SpriteKit implementation gives us two main production options.

image_group{"query":["isolated isometric thatched neolithic hut rendered 2d game sprite plain background"],"aspect_ratio":"1:1","layout":"carousel","num_per_query":1}

**Pre-rendered sprites**

3D models converted into 2D game assets.

image_group{"query":["low poly neolithic thatched hut 3d mesh solid and wireframe architectural model"],"aspect_ratio":"1:1","layout":"carousel","num_per_query":1}

**Real-time 3D**

Geometry, materials and lighting rendered on the device.

| Capability | Pre-rendered sprites | Real-time 3D |
|--------|--------|--------|
| Retain SpriteKit | Yes | Generally requires changes |
| Development complexity | Lower | Higher |
| Dynamic lighting | Limited | Flexible |
| Camera rotation | Limited | Flexible |
| Building evolution | Additional sprites | Reusable geometry |
| Hardware demands | Generally lower | Generally higher |
| Detailed construction animations | More assets | Geometry-based options |

Given our long-term goal of evolving settlements through thousands of years, I think we should seriously consider 3D models as our **source asset format**, even if we ultimately continue rendering 2D sprites.

That would keep our architectural designs reusable.

**Deliverables\:** Rendering comparison, pilot asset specifications, source file conventions and hardware feasibility assessment.

**Acceptance criteria\:** A documented production pipeline, demonstrated using a small test scene before committing to the entire building catalog.

**Dima's approval\:** Rendering architecture and permanent asset format.

## 0.3.3 — Landscape and terrain
image_group{"query":["isometric game terrain grass dirt rocky elevation texture transitions landscape","isometric miniature winding river natural shoreline rocks reeds game environment","stylized realistic miniature forest trees shrubs grass game vegetation assets"],"aspect_ratio":"5:4","layout":"bento"}

Our first landscape is the temperate river valley. We should make it visually convincing before expanding to the other five planned landscape types.

**Deliverables\:** Terrain textures, riverbanks, water, hills, trees, vegetation, resource deposits, terrain transitions and undiscovered territory presentation.

**Acceptance criteria\:** Seamless terrain, clear buildable areas, recognizable resources, consistent visual scale and preservation of the existing map geography.

**Dima's approval\:** The appearance of the first official landscape.

## 0.3.4 — Building models and textures

Start with three buildings to establish the architectural language.

image_group{"query":["prehistoric campfire stone ring wooden seating miniature architectural diorama isolated"],"aspect_ratio":"1:1","layout":"carousel","num_per_query":1}

**Campfire**

image_group{"query":["prehistoric neolithic circular hut timber frame thatched roof miniature 3d architectural model isolated"],"aspect_ratio":"1:1","layout":"carousel","num_per_query":1}

**Hut**

image_group{"query":["prehistoric timber woodcutting workshop shelter stacked logs stone tools miniature 3d architectural model"],"aspect_ratio":"1:1","layout":"carousel","num_per_query":1}

**Woodcutter**

After approving these three, expand to the full catalog.

**Original building asset tracker**  /20

**Deliverables\:** Twenty original building designs, reusable source assets, textures, game-ready renders or meshes, construction appearances and building thumbnails.

**Acceptance criteria\:** Every building is recognizable, correctly aligned to its footprint and visually consistent with the rest of the settlement.

**Dima's approval\:** The pilot architectural designs before full production.

## 0.3.5 — Icons and interface identity
image_group{"query":["prehistoric stone age game inventory icon set wood stone wheat water flint pottery leather tools natural painted style","prehistoric technology research game icons hunting agriculture construction pottery fire illustrated icons"],"aspect_ratio":"5:3","layout":"bento"}

The functional interface is already acceptable for this stage. We now need to make it feel like part of the same world.

**Deliverables\:**

- 20 building thumbnails derived from their actual designs.
- 20 research icons.
- 12 resource icons.
- Five development pillar icons.
- Menu textures, panels, buttons and consistent typography.
- Original loading screen artwork.

**Acceptance criteria\:** Clear readability at small sizes, consistent iconography and no regression to the usability approved during physical-device testing.

**Dima's approval\:** The interface's final visual language.

## 0.3.6 — Animation and environmental immersion

image_group{"query":["miniature neolithic village campfire smoke thatched hut atmospheric diorama"],"aspect_ratio":"4:3","layout":"carousel","num_per_query":1}

Fire and smoke

image_group{"query":["miniature isometric river flowing water rocks forest game environment"],"aspect_ratio":"4:3","layout":"carousel","num_per_query":1}

Flowing water

image_group{"query":["neolithic timber hut under construction wooden skeleton thatched roof architectural miniature"],"aspect_ratio":"4:3","layout":"carousel","num_per_query":1}

Building construction

image_group{"query":["miniature prehistoric wheat farmland close up lush natural environment"],"aspect_ratio":"4:3","layout":"carousel","num_per_query":1}

Vegetation and farms

**Deliverables\:** Construction animations, building placement effects, fire, smoke, water movement and subtle production animations.

**Acceptance criteria\:** The settlement feels alive without distracting the player or significantly compromising device performance.

Animated inhabitants, wildlife, weather, day/night cycles and environmental audio remain proposals requiring further discussion.

---

# 4\. Stage 7 — Complete playable Stone Age

Once we have our visual foundation, the final stage is about quality rather than adding more systems.

## 0.4.1 — Full gameplay testing

Play the first era from beginning to end using normal gameplay, without developer shortcuts.

Evaluate chapter progression, economic decisions, research pacing, idle time, exploration requirements and the overall sense of accomplishment.

## 0.4.2 — Economy and progression balancing

Our previous automated playthrough took 156 simulated minutes. That result predates the revised completion requirements, so we need updated measurements.

Adjust construction costs, research costs, production rates, population growth and exploration duration based on actual playtesting.

The previous 45–90-minute target remains experimental.

## 0.4.3 — Physical-device optimization

Test against our actual target devices.

Measure frame rates, memory usage, battery consumption, thermal behavior, startup time and responsiveness in a fully developed settlement.

A stable 60 FPS is a proposed performance target, subject to actual hardware testing.

## 0.4.4 — Final acceptance

## Stone Age acceptance checklist

Final acceptance criteria  /

Only after satisfying these criteria should we declare the first era complete as a playable product.

---

# 5\. Consolidated roadmap

# 6\. Proposed next brief for Codex

:::writing{variant="document" id="63921"}
# Seed 0.3.1–0.3.2 — Visual identity and graphics preparation

**Status: PROPOSED — awaiting Dima's approval.**

## Objective

Establish a consistent original art direction and a sustainable graphics production pipeline for Civilization.

## Preparation scope

- Preserve Seed 0.2.7 as the accepted gameplay baseline.
- Document the existing renderer and asset interfaces.
- Present the completed graphics feasibility assessment for discussion.
- Identify terrain, building, texture, mesh, sprite, icon and animation requirements.
- Compare pre-rendered 2D sprites against real-time 3D rendering.
- Evaluate implications for historical building evolution and the target physical devices.
- Define a proposed pilot scene containing a Campfire, Hut and Woodcutter.

## Deliverables

- Visual identity specification.
- Rendering architecture comparison.
- Asset catalog and production standards.
- Pilot scene specification.
- Performance evaluation plan.
- Updated design-status ledger.

## Approval gates

Dima must approve the permanent artistic direction, rendering architecture, source asset formats and pilot designs before production begins.

## Restrictions

Do not replace SpriteKit, integrate permanent artwork, mass-produce assets or change gameplay balance without explicit approval.

Do not implement the second historical age, additional cities, warfare, monetization or new gameplay systems.

Maintain the existing functionality, save compatibility and regression coverage.

## Completion

Submit proposals and supporting evidence for review. Stop before permanent graphics implementation until authorized.
:::

The milestone breakdown, pilot asset selection and final acceptance criteria are my proposals. The actual graphics feasibility report and current regression counts have not been independently inspected, so I am not making additional technical verification claims.

---

**Our next step together should be choosing the artistic direction.** I would start by generating three original versions of the same Stone Age settlement, compare them side by side, and then develop the one we like most into our game's visual identity.

