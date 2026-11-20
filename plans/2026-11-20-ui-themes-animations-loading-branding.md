# Goal: UI themes, menus, animations, loading screens, and temporary branding

**Owner approval:** 2026-11-20. Design work may proceed independently; do not interrupt the active gameplay/art run, enable R2-07, merge branches, or replace runtime assets without review.

## Temporary branding (approved)
- Working title: **CIVILIZATION** only as a replaceable placeholder, not final branding.
- Temporary mark: neutral sunrise over a horizon, independent of any specific era or region.
- Studio: internal **Studio Placeholder**; do not show it to players.
- Era subtitle appears separately (e.g. **STONE AGE**).
- All text, mark, app icon, splash/loading composition and studio identity must be independently configurable/replacable. Do not invest in a final logo or identity or imply the working name is cleared for commercial use.

## Permanent interface structure
- Keep navigation, screen layout, interaction patterns, button locations, icon meanings, accessible typography and resource display stable across era/region changes.
- Theme appearance is determined by **era material** + **region ornament/color/background**, with shared UI components and icons. Stone Age: carved stone (not leather). Bronze Age: leather where culturally appropriate; Egyptian regional variants can use papyrus, Mesopotamian variants clay; modern era: digital/tablet appearance. Historically appropriate combinations should be researched, not applied universally.
- Build screens: main menu, HUD, construction catalog, building inspector, research, contextual guidance/tutorial, milestones, saves/settings, dialogs. Support landscape iPhone/iPad mini/iPad Pro, safe areas, contrast, VoiceOver and reduced motion.
- Guidance should provide actionable links to relevant research/building; avoid blocking or repetitive tutorials. Construction and selection progress bars must be correctly associated with selected object.

## Animations
- Era completion: smooth skippable transition from old to new era/region material, keeping permanent controls stable; state saved before playback; no duplicate replay on reload.
- Building construction: stage-dependent progress, not an unrelated looping timer; completion dust/scaffolding clear; building upgrades become taller while retaining identical logical footprint and anchors.
- Research, chapter, reward, milestone, palisade, bridge, neighborhood, resource updates: coherent event-driven motion with clear priority, modest duration, performance budgets and reduced-motion fallbacks.
- Loading: **permanent generic game mark first**, then era subtitle and region-specific animated scenery. For first era, prototype settlement founding, river life and fortified mountain village; lightweight layered effects (fire/smoke/water/birds), real progress when measurable, relevant short tips, seamless transition into game. Ordinary menu transitions must not trigger full loading screens.
- Keep animation logic separate from gameplay state; do not slow startup or block interaction unnecessarily.

## Production gates
1. Audit current SwiftUI/SpriteKit UI, assets, transitions, screens and accessibility. Preserve existing functionality and saves.
2. Prepare a reusable design-token/theme contract and first three **reviewable mockups**: gameplay HUD, building catalog and research screen. Include Stone Age reference-temperate plus Bronze Age Egypt/Mesopotamia comparisons without implementing later-era gameplay.
3. Prototype generic logo/loading screen and an era material transition, plus staged construction and completion animation.
4. Present previews and asset registry/provenance for owner approval before integrating.
5. Only after approval, integrate accepted UI components, animation assets and screenshot/performance tests. Keep rollback/fallback and independent asset source in Civilization-Media repo.

## Acceptance
- Brand placeholders replaceable through configuration.
- No change to permanent icon meaning or navigation across themes.
- Era/region visuals distinct, historically sensible, and accessible.
- Loading/animation does not falsely report progress or corrupt state.
- R2-07 remains disabled pending separate owner approval.

## Approved compact completion notifications — supersedes large ordinary-event celebrations

Owner approved the icon-adjacent notification concept shown in the ChatGPT reference mockup (2026-11-20). For **ordinary research, goal and achievement completions**, do **not** display full-screen celebrations, modal popups, large banners or intrusive reward animations.

- Research: pulse/glow around the existing research icon for ~0.5–1 second, then retain a small unread indicator at the icon.
- Goal: short checkmark/pulse at the goals icon, then persistent unread indicator.
- Achievement: subtle icon glow, then persistent unread indicator.
- Multiple events: keep independent unread state for each destination, without overlapping or repeated animations.
- Tap the icon to open the relevant screen and view exact results/rewards; clear the indicator when the relevant new item is viewed (not merely on animation completion).
- Preserve event idempotency across save/load, reduced-motion static indicators, VoiceOver announcement and sufficient non-color-only cues.
- **Era completion remains a special larger transition**. Chapter completion should default to compact treatment unless separately approved.
- Keep permanent icon positions, icon identities and layout unchanged across eras/regions.

Reference: user-approved six-panel HUD concept illustrating normal → brief glow/check → persistent dot. The image is in the ChatGPT conversation, **not** guaranteed available as a GitHub/media file. Codex should recreate/validate against actual HUD rather than claiming the image was imported.
