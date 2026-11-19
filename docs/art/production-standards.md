# First-era candidate art production standards

19 November 2026. Dima authorized integrated candidate implementation and reviews the result afterward. Art direction remains replaceable, not permanently accepted.

## Media and source boundaries

[City Design Coordination media brief](chatgpt-first-era-brief.md) covers every world area, all20building silhouettes, icons, menus/loading and effects. All its image-search examples are external inspiration, not licensed app assets. None were copied into the product. Three original concept alternatives are retained in `concepts/`; A supplies the warm miniature / stylized architectural realism candidate and loading panorama. B (illustrated history) and C (architectural maquette) remain alternatives.

All20transparent building originals were generated through the built-in image_gen tool, one distinct request per building, using conceptA only as style reference. Exact prompts, tool and source paths are in `provenance.json`. Originals are retained under `sources/buildings/`; native `sips` downsampling produces512pxworld sprites and144pxthumbnails without altering original sources. The app ships downsampled files under `Civilization/Art`, not high-resolution source files. This is a raster production pipeline: **no editable 3D models are claimed**. A later3Dsource pipeline would require separate modeling work; stable IDs/manifest keep that choice reversible.

Research/resource/pillar icons are original code-native vector illustrations in EraIcon.swift, with20distinct research motifs,12resource mappings and5pillar mappings. Shared motifs across domains retain semantic continuity. WorldDetails.swift supplies deterministic original grass/soil, trees/canopies/shrubs, faceted hills, reeds/riverbank/shallow edges and fog borders. No downloaded fonts, artwork or external libraries. Standard system typography remains for native readability.

## Consistency

- Natural ochre thatch, weathered warm timber, wattle/clay, gray stone, muted greens and blue water; upper-left light.
- Orthographic2:1ground projection and fixed geography retained. No new river/hill/forest tiles or resource locations.
- Building identity and logical footprints remain in GameCore; art-only files/dimensions/contact anchors live in the separately validated ArtCatalog. Campfire1x1; other current types2x2.
- Full alpha is preserved, padding is transparent, and alpha-only masks reject transparent silhouette hits before the existing logical-footprint fallback. Art may overhang a footprint visually, without changing occupancy.
- Catalog thumbnails derive from actual world sprites. Research and resource icons avoid books/modern objects; status text/checkmarks/locks remain independent of color.
- Menu layout,44pointcontrols, resource popovers, collapsible chapter summary/full detail, drag/pan/pinch and inspection accessibility are retained.

## Construction, movement and effects

Construction starts with a faint form/foundation feedback, exposes a timber scaffold in the middle, and reveals the finished sprite with a progress bar. Placement receives a short fading ring; ghosts are never simulation buildings. Existing IDs/recipe/priority/timers remain authoritative. No final-sprite substitution changes production or reward timing.

Fire glows and a maximum12smoke wisps are bounded; at most24water ripples run on revealed water. Production indicators derive from one cached read-only actual economy overview per state and require positive recipe output/productivity; housing/storage do not pretend to produce. Static ground/scenery is flattened to one texture and source nodes released after discovery changes. Static building nodes survive ordinary simulation ticks, avoiding animation restart/reallocation. Reduce Motion disables ambient effects; background and full-screen menus suspend map rendering; developer pause freezes actions while keeping the paused map drawable for inspection/placement. No per-frame economy simulation, unbounded emitters, inhabitants, weather, day/night or audio systems.

## Budgets and validation

`swift scripts/verify-art.swift` validates every sprite/thumbnail, alpha coverage and resolution. Current20pairs consume about21MiB theoretical decodedRGBApixels; this excludes GPU copies, mipmaps, loading image, terrain cache and render targets. EraArt caches/downsamples on demand and caps the UIImage cache at32MiB. The world texture dictionary is bounded by the twenty catalog kinds plus resource icons. `scripts/render-art-board.swift` regenerates the review board.

Local opt-in Debug render diagnostics (`CIVILIZATION_RENDER_METRICS=1`) report frame samples/p95 and process memory; they compile out of Release, never persist in saves and are not uploaded. Simulator measurements must be labelled simulator; they do not establish A15/M1physical60FPS, battery or thermals. Dense device work is performed only with available hardware and safe isolated saves.

## Review decisions and costs

Ruling: keep SpriteKit and raster sprites for this candidate rather than rewrite the renderer — preserves tested interactions and reduces integration risk; a future freely rotating3Dcamera would require additional work. Ruling: use native original vector terrain/icon sources instead of another large bitmap set — keeps small assets crisp and memory bounded; Dima may prefer a more painterly terrain treatment after review. Ruling: keep economy tuning unchanged after the tested90minute capacity-investment route — preserves baseline and meaningful staffing choices; discoverability/enjoyment still needs human review.
