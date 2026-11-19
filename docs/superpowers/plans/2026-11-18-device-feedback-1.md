# Seed 0.2.6 device feedback iteration 1

**Goal:** Implement the fetched physical-device feedback at Dima's explicit instruction.
**Spec:** docs/milestones/seed-0.2.6-device-feedback-1.md.
**Architecture:** Authoritative atomic relocation in GameCore; preview-only drag state in GameSession; UIKit long-press recognizer coordinated with pan/pinch. Compact SwiftUI HUD, horizontal building cards, small goals disclosure and asynchronous restore with renderer-ready loading overlay. Existing native stack and save v5 retained.

## Constraints and choices
No Git metadata/worktree available. Retain all 88 Debug/80 Release regressions, signing/iOS18/landscape, map identity and original placeholders. Campfire remains the immutable map anchor (existing validation/exploration depend on it). Any other building can move, including construction in progress; no cost or timer reset. Self-overlap is valid; other occupancy, full footprint discovery, terrain and fishing's water requirement are enforced. No other age is introduced. User explicitly said implement after reviewing the brief; proceed inline without another design gate.

## Tasks
- [x] Add failing relocation tests: self-overlap, free movement with zero resources, atomic invalid inputs/extreme coordinates, immutable campfire, metadata/timers/rewards, geographic bonus/rate changes, fishing river rule and save roundtrip.
- [x] Share site validation between placement and relocation; add engine command and session begin/update/finish/cancel preview lifecycle. Tests verify invalid/cancel/background keep original state and valid commit persists once.
- [x] Add long-press drag preserving finger-to-origin offset; pan waits for long-press failure, movement cancels long-press so ordinary pan stays responsive; pinch cancels relocation; no simultaneous camera/drag. Fade original during preview, show ghost geometry, retain tap-based accessible Move action and confirm/cancel fallback; remove arrows.
- [x] Compact icons/count HUD with simulation-backed source count, sources, gross/use/net/cap popup. Horizontal catalog cards/categories. Goals collapsed by default; future era identity change expands via a small tested disclosure state.
- [x] Async off-main restore/catch-up with synchronous initializer retained for tests. Native storyboard launch screen and in-app loading until renderer's first prepared frame; no artificial delay. Test new/frozen/corrupt restoration paths.
- [x] Run full Debug/Release suites and release restrictions, build/run phone/mini/Pro; capture before/after and exercise key interactions. Independent correctness review and fix confirmed findings. Update report, instructions, README and ledger, including physical-device limits.

## Review focus
No state mutation while dragging or failed placement; self-overlap; pan/tap/long-press/pinch cancellation; save during preview; no relocation reward farming; gross source counts exclude inactive/shortage buildings; restore preserves corrupt saves and wall-time rules; renderer-ready loading must always dismiss.

Verified 98 Debug/90 Release tests, four API restriction probes, simulator Debug/Release and signed/unsigned device builds. Focused XCTest long-press + camera drag + pinch passes in explicit landscape. Review completed, async activation regression fixed. Physical update installation is a separately blocked approval step; no claim of completed physical touch/performance testing.
