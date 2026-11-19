# Graphics feasibility for 0.3 — proposal only

Assessed 19 November 2026 after Seed 0.2.7. This document does not approve a renderer replacement, permanent art direction, final assets or additional gameplay. No graphics assets were generated or substituted.

## Existing implementation

`Civilization/Rendering/WorldView.swift` hosts a SpriteKit `SKView` in SwiftUI, requests 60 FPS and translates tap, pan, pinch and long-press input into GameApplication commands. `SettlementScene.swift` draws procedural `SKShapeNode` placeholders. Static ground is rasterized in an `SKEffectNode`; scenery, deposit markers, buildings and previews use separate layers. Buildings are redrawn from authoritative snapshots; their node names come from JSON `assetKey`, IDs are attached for hit testing, depth follows tile x+y, and the footprint center supplies the ground-contact anchor. `IsometricProjection.swift` delegates to pure `MapGeometry`: 64×32 ground diamonds and a fixed camera orientation. There is no texture atlas, mesh importer or 3D scene today. HUD and research/building menus are independent SwiftUI views.

GameCore, save v5, geography, occupancy and placement are already separate from presentation. This is a useful boundary for any future art pipeline. Building silhouettes and preview hit regions need validation when art changes; transparent image rectangles must not create unexpectedly large touch targets.

## Options

| Approach | Fit with current app | Benefits | Costs / risks |
|---|---|---|---|
| Model in 3D; render offline to transparent 2D sprites | Strongest fit; SpriteKit remains | Consistent camera/light/scale; reusable models; inexpensive runtime; thumbnails from same source | Fixed view; more frames for animations/rotations; baked shadows can conflict with scene shadows; texture memory |
| Real-time 3D using RealityKit | New rendering adapter, SwiftUI shell/GameCore retained | Camera freedom, continuous lighting, modular models and animation | Rework projection, picking, previews, depth, camera limits, loading and terrain; CPU/GPU/thermal cost; separate prototype needed |
| Custom Metal renderer | Technically possible, largest project | Direct batching, mesh and shader control | Own rendering lifecycle, material system, asset tooling and profiling; no present requirement justifies it |
| 2D texture terrain and sprite scenery | Incremental SpriteKit change | Better ground variety while preserving identity, coordinates and controls | Seam filtering, coastline transitions, repetition and overdraw; limit tile variants |

Assessment: a small approved comparison prototype using offline 3D renders is the lowest-disruption next experiment. This is an engineering recommendation, not an approved visual style or a decision to adopt it. Real-time 3D warrants a separate proof of camera/picking/terrain and hardware performance before any migration. Apple now marks SceneKit deprecated and recommends RealityKit for new substantial work; do not start a new long-lived SceneKit dependency on the strength of older tutorials. [Apple SceneKit documentation](https://developer.apple.com/documentation/scenekit), [WWDC25 migration discussion](https://developer.apple.com/videos/play/wwdc2025/288/).

## Terrain textures and meshes

For SpriteKit, keep logical tiles and current river/hills/forest coordinates. Prepare a small compatible ground-tile set with edge transitions, coherent light direction and reusable scenery overlays. Pack related textures into atlases and preload before the first playable frame; Apple's documented atlas path reduces texture changes/draw overhead. Reassess the existing rasterized ground cache after adding textures: a very large offscreen surface can cost more memory than tiled sprites. No need to mesh terrain just to improve ground appearance. [Apple texture atlases](https://developer.apple.com/documentation/spritekit/about-texture-atlases), [texture loading](https://developer.apple.com/documentation/spritekit/texture-initializers).

For real-time 3D, a chunked static mesh could derive positions/material regions from the same handcrafted terrain, with water separate. Keep tile occupancy authoritative and map identity unchanged; visual heights must not silently add slopes, inaccessible land or gameplay terrain. Start with static meshes and few materials. RealityKit supports lower-level meshes and textures for dynamic terrain, but updating geometry every frame is unnecessary for this valley and adds complexity. Availability and material support must be verified against the iOS18 deployment floor in a future prototype. [Apple interactive geometry example](https://developer.apple.com/documentation/realitykit/generating-interactive-geometry-with-realitykit).

## Building files, thumbnails and iconography

- Authoring source: retain editable model files, material sources and provenance; `.blend` would be an offline authoring choice, not an app dependency or approved new runtime library.
- Sprite delivery: transparent PNGs grouped into `.atlas` folders or asset catalogs, with stable asset keys, logical footprint, normalized contact anchor, nominal tile scale, padding, shadow convention, view and animation metadata. Render using one calibrated orthographic camera; an initial 45° azimuth / 30° elevation is a hypothesis for matching 2:1 ground, to verify with a footprint overlay. Do not change gameplay footprints to fit art.
- 3D delivery: evaluate USD/USDZ for Apple-native loading. Validate the subset of materials, animations and texture formats on iOS18; modern Apple documentation includes features newer than that baseline. USDZ is a delivery package, not a replacement for editable originals. [Apple USD authoring guidance](https://developer.apple.com/documentation/usd/creating-usd-files-for-apple-devices).
- Thumbnails: derive smaller, tightly cropped transparent views from the same building source; give them their own UI size/contrast tests. Full-resolution world textures should not be loaded just to display small catalog cards. A future optional thumbnail key should remain distinct from world asset keys and gameplay IDs.
- Research: define an icon key per technology, a shared grid, stroke/contrast rules and a small set of readable metaphors for the five pillars. Reuse approved objects such as tools or pottery where the meaning is clear. Current SF Symbols remain replaceable placeholders. Color alone must not convey researched/locked/affordable states.

## Reuse and historical evolution

Reuse geometry/material modules for walls, roofs, fences, containers and props across buildings. Keep silhouette differences readable at world zoom. Preserve an immutable gameplay building-kind ID; visual variants and levels can map to the same logical definition. A future evolution pipeline could retain foundations and add visible modules rather than erasing a building's history. That is an asset-organization option only: no future-era buildings, repurposing rules or inheritance mechanics are authorized here. Keep world sprites, thumbnails and research crops traceable to their source models and licenses.

## Performance and acceptance experiment

No FPS, battery or thermal benchmark was performed for hypothetical assets. The target remains 60 FPS (about 16.7 ms per frame) on physical A15 iPad mini 6, plus phone and M1-class iPad verification. Current A17/M4 simulator profiles cannot prove those results. Profile CPU and GPU separately, frame pacing, peak/resident memory, startup, sustained thermals and input during dense-settlement pan/zoom.

A decoded 1024×1024 RGBA8 image is 4 MiB before mipmaps/overhead; twenty unique images are about 80 MiB. At 2048×2048 that becomes 320 MiB. PNG file size is not resident texture cost. Atlases, reuse and selective preloading help, but do not remove pixel memory. Real-time 3D trades some sprite variants for mesh/material/shader/lighting costs; it cannot be called faster without measuring. Limit transparent overdraw, texture resolution, material count, shadows and animated objects; prefer static geometry where possible. [Apple SpriteKit texture performance](https://developer.apple.com/documentation/spritekit/maximizing-texture-performance), [RealityKit performance](https://developer.apple.com/documentation/realitykit/improving-the-performance-of-a-realitykit-app).

If separately approved, compare a campfire, hut and one production building plus a riverbank patch using the same source geometry, in SpriteKit baked-sprite and a small real-time 3D test. Measure a dense copy scene, not just an isolated attractive model. Validate tile anchors, object overlap, transparent picking, dragged ghosts, loading, UI thumbnails and memory on physical targets. Show the alternatives to Dima before extending the art set or changing the production renderer.
