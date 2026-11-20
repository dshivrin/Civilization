# Continuous atmosphere review

Goal: complete the missing continuous day/dusk/night/dawn comparison and static-effects review in the existing disposable native lab. Authority: Living World Phase B; parent visual program V6. No appearance promotion or gameplay changes.

Keep the retained first-era-review branch. Use existing GameApplication presentation models and reusable QA. The prior presets remain available. Native SpriteKit updates drive appearance only; no authoritative Date, GameEngine advance, save or economy commands.

- [x] Write failing pure-model tests for continuous interpolation/wrap, readable opacity floor, invalid timestamps, no background catch-up, reduced-motion/power freeze and deterministic resume.
- [x] Implement `VisualDayCycle` (120-second review cycle, max 0.1-second visual frame delta) and `VisualLighting` (day/dusk/night/dawn keyframes, opacity at most 0.20). Keep duration a review choice, not accepted production timing.
- [x] Wire continuous lighting into the Debug-only living layer; preserve preset selection and weather nodes. Expose cycle/static controls and live review status. Static mode also suppresses existing fire/smoke and fog transitions by passing the existing reduce-motion input. Background/loading cover resets visual frame baselines.
- [x] Native test: verify live fraction advances, static/covered state does not catch up, preset selection stops automatic cycle, day/dusk/night/dawn and rain/fog remain available, normal map/camera/layout unchanged after closing.
- [x] Verify full core Debug/Release + exclusions, native review on phone/mini/Pro and Release entry. Capture new evidence separately; retain earlier archives. Review code independently, fix meaningful findings, commit/push coherent slice.

Review focus: invalid/regressing clocks must not add progress; every suspension path resets the frame baseline; continuous tint changes must not rebuild weather/agents; static fallback must not retain animated production effects. No physical metrics or art acceptance inferred from simulator evidence. Existing original media, schema, fixed footprints and R2-07 disabled are invariants.

Native integration held after direct owner feedback: finish visible onboarding walkthrough first. Pure-model tests pass; no native cycle/runtime activation is claimed.

Resume after delivered placement fix33073e9/f50a5be. Keep physical phone on33073e9 for owner testing; this slice is committed/pushed simulator review only. Add bounded(max8) proposed warm ground-light pools for visible operational civic/homes and actually active kilns; no accepted window contacts/art replacement. Fraction/status read actual tint/node properties, static mode verifies existing building SKActions removed. Presets remain, same snapshot/camera, max20%tint. Add separately archived six-state phone/mini/Pro evidence and an actual-motion recording if native tooling permits. No broader onboarding changes while owner's plan is forthcoming.

Full-cycle review adds an explicit24second preview toggle (resets visual phase only) beside the default120second cycle; this is a renderer-review convenience, not a game-day definition. A native test must observe dawn and actual wrap before accepting its untrimmed recording. Technical counters remain in accessibility diagnostics while visible status uses readable phase labels.

Final recording uses existing Center and Rain controls before starting the24second visual cycle, making world activity and weather visible. Matrix methods/runtime remain unchanged by this recording-only setup. The movie must include truthful pause/resume labeling and an observed wrap after the review fixes.

Verified: core272Debug/235Release+9Release exclusions; final matrix8112b9e six native executions across phone/mini/Pro; Release4dd8d28 one; recordingac9beb9e one with actual0.9986→0.0168wrap and retained0.8325pause.18unchanged screenshots and full1537frame recording in the atmosphere gallery. Independent findings reproduced and corrected once; no second review. Physical phone remains33073e9. Full parent V6 and owner appearance/ONGateB decisions remain open; no new roadmap work.
