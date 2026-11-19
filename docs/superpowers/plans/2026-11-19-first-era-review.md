# First-era review implementation plan

Spec: docs/superpowers/specs/2026-11-19-first-era-review.md
Architecture: SpriteKit render adapter consumes a replaceable visual manifest and bundled art, never mutating GameCore; SwiftUI shares thumbnail/icon/theme components. No save-schema/gesture/platform/signing changes. Execution stays in this checkout on branch first-era-review, with main preserving the baseline. Dima requested review after completion.

- [x] 1. Initialize local Git; preserve Seed027 baseline commit 9e8e2cd; create review branch.
- [ ] 2. Retrieve ChatGPT media/design guidance; inventory reference coverage and all required assets. Generate three original visual concepts; document provisional candidate and sprite/native-icon pipeline, anchors, formats and licensing/provenance.
- [ ] 3. Implement/test asset manifest and loader with placeholders as fallback; generate/validate pilot campfire/hut/woodcutter, integrate world sprites and actual catalog thumbnails; preserve silhouette/footprint hit testing and drag previews.
- [ ] 4. Complete all twenty building visuals and thumbnails; cohesive terrain, riverbanks/water, hills/trees, deposits and fog; original loading artwork. Store exact prompts/provenance, preview all assets and verify alignment/readability at device zoom.
- [ ] 5. Implement twenty research, twelve resource and five pillar icon identities, reusable menu surfaces/typography; restrained construction/placement/fire/smoke/water/production effects with reduce-motion behavior and resource bounds. Verify no simulation changes from animation.
- [ ] 6. Exercise complete normal-cost chapters and alternative choices/recovery; assess 154-minute serial knowledge bottleneck; document/verify any tuning against frozen prior fixtures. No unsupported claim of human enjoyment.
- [ ] 7. Run all Debug/Release regressions and API probes, phone/mini/Pro visual and interaction checks, signed device build, isolated physical verification/performance if available. Backup/validate before any authorized update and verify save preservation. Record physical limits.
- [ ] 8. Independent final review per requesting-code-review, fix important defects with regression evidence, commit final candidate, update README/AGENTS/design ledger/report/media inventory and present review package. Stop for Dima's review.

Review focus: asset load failure/fallback; transparent sprite hit bounds and tall occlusion; unchanged anchors under drag/zoom; bounded animations/reduce-motion/background lifecycle; original reward/readiness history and normal-save isolation; small-screen icon legibility; honest physical performance and model-source claims.

## Progress
- Initial baseline commit: 144 files; no remote configured. Existing .gitignore excludes build caches, user settings and .DS_Store.
- Art source note: ChatGPT's previous response contains image-search queries for inspiration, not approved source assets. Requested fuller cross-game media descriptions through the connector; reply pending.
