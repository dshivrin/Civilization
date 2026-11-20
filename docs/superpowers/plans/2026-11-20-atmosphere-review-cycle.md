# Continuous atmosphere review

Goal: complete the missing continuous day/dusk/night/dawn comparison and static-effects review in the existing disposable native lab. Authority: Living World Phase B; parent visual program V6. No appearance promotion or gameplay changes.

Keep the retained first-era-review branch. Use existing GameApplication presentation models and reusable QA. The prior presets remain available. Native SpriteKit updates drive appearance only; no authoritative Date, GameEngine advance, save or economy commands.

- [x] Write failing pure-model tests for continuous interpolation/wrap, readable opacity floor, invalid timestamps, no background catch-up, reduced-motion/power freeze and deterministic resume.
- [x] Implement `VisualDayCycle` (120-second review cycle, max 0.1-second visual frame delta) and `VisualLighting` (day/dusk/night/dawn keyframes, opacity at most 0.20). Keep duration a review choice, not accepted production timing.
- [ ] Wire continuous lighting into the Debug-only living layer; preserve preset selection and weather nodes. Expose cycle/static controls and live review status. Static mode also suppresses existing fire/smoke and fog transitions by passing the existing reduce-motion input. Background/loading cover resets visual frame baselines.
- [ ] Native test: verify live fraction advances, static/covered state does not catch up, preset selection stops automatic cycle, day/dusk/night/dawn and rain/fog remain available, normal map/camera/layout unchanged after closing.
- [ ] Verify full core Debug/Release + exclusions, native review on phone/mini/Pro and Release entry. Capture new evidence separately; retain earlier archives. Review code independently, fix meaningful findings, commit/push coherent slice.

Review focus: invalid/regressing clocks must not add progress; every suspension path resets the frame baseline; continuous tint changes must not rebuild weather/agents; static fallback must not retain animated production effects. No physical metrics or art acceptance inferred from simulator evidence. Existing original media, schema, fixed footprints and R2-07 disabled are invariants.

Native integration held after direct owner feedback: finish visible onboarding walkthrough first. Pure-model tests pass; no native cycle/runtime activation is claimed.
