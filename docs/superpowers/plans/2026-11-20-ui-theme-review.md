# UI themes and motion review implementation plan

**Spec:** plans/2026-11-20-ui-themes-animations-loading-branding.md at a7e38c2; direct owner “Review the plan and implement”. Execute the pre-integration gates only. Existing first-era-review retained. UI Themes is separate from Gate2 building-art acceptance.

**Goal:** Fresh current-screen/accessibility audit, reusable era/region token contract, HUD/catalog/research review mockups and compact event/loading/construction/era-transition prototypes. Existing code is the visual/interaction target; user approved carved Stone Age, papyrus Egypt and clay Mesopotamia comparisons. No new product direction/flow is invented.

**Approach:** Reuse isolated XCTest screenshots for grounding; compile existing EraIcon via a macOS review-only SwiftPM renderer, without copying/replacing runtime source. Create a separate local HTML review workbench with generated material/loading imagery, shared tokens and controls. Native app integration is deferred until visual approval.

- [x] Capture and inspect launch/HUD/catalog/research/inspector/journey/games on phone and mini through scripts/dev.py; record accessibility/code limits, transient/loading/settings gaps honestly.
- [x] Generate/preserve three material textures and three lightweight loading-scene review images using built-in imagegen; exact prompts/hashes/provenance. Native icons preserve existing semantic mappings.
- [x] Implement validated theme/brand/motion token data; shared HUD/catalog/research across three themes, stable controls and resource ordering; configuration-independent placeholder brand and era subtitle.
- [x] Implement review-only compact completion demo: per-destination unread, exact-result viewing clear, event-ID deduplication/reload safety, reduced motion and announcements. Existing goals/journey icon hosts goal/achievement groups rather than adding a new toolbar position. Larger era transition is explicitly visual-only and state-first/idempotent; staged construction tied to selected building/progress; loading generic mark then era/region art, indeterminate progress when real progress absent.
- [x] Verify token contrast, layout invariance, notification persistence/deduplication/reduced motion, browser phone/tablet variants and screenshots. One independent final review, fix substantive issues, commit/push. No R2-07, save migration, runtime asset/UI integration, physical install, later-era gameplay or building-art promotion.
