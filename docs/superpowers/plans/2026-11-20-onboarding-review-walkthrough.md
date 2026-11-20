# Visible onboarding review walkthrough

Owner feedback: no onboarding guides are visible; only the cloud shape differs. Owner also explicitly requests visual refinement before normal integration. Gate B has NOT been approved.

Root cause from source: the normal HUD has no new guide (intentionally gated), and the native lab only renders one static initial card plus a manual forest reveal. The pure guide state machine is not connected to native tutorial actions. Earlier Gate A readiness language overstated this interaction.

Goal: make the entire proposed campfire → Hut → paid expedition → whole forest → Woodcutter → existing goals sequence demonstrable in a clearly labeled disposable walkthrough, accessible directly from Developer tools. Keep the original normal game, saved discoveries, pending expeditions, economy and R2-07 untouched.

- [x] Add Debug-only `OnboardingReviewWalkthrough`, owning a fresh in-memory production engine and deterministic forest proposal, with real build/placement/cost/countdown transactions. Area reveal is explicitly a proposal applied to this disposable engine only. Never use GameSession/GameLibrary/SaveStore.
- [x] Test actual hut completion rather than placement; single expedition payment, full-area reveal after duration, actual woodcutter production, invalid-placement atomicity, skip/reopen and source isolation. Add a Release API exclusion probe.
- [x] Native guide shows one actionable step, actual catalog costs and real remaining work, freely selectable valid placement, explicit confirmation/cancel, skip/reopen and handoff. Real-time review ticks pause under covers/background; explicit time advance is labeled. Add direct Developer tools entry.
- [x] Keep prior manual fog comparison separately available. Native tests follow all steps, choose/confirm actual placements, skip/reopen, verify countdown/reveal/wood production and return normal map/camera unchanged. Capture new evidence on phone/mini/Pro and keep earlier archive unchanged.
- [x] Run reusable full core/Release exclusions and scoped native regression + Release entry, independent review, commit/push and update review handoff honestly. Install only after fresh validated backup and strict pre-launch preservation.

The automatic atmosphere follow-up is temporarily held for this direct feedback. Its tested pure clock remains a separate unpublished preparation slice; no new runtime atmosphere is wired. No approval is inferred from the owner's inability to find the guide.

## Physical placement follow-up

Owner confirms the guide is useful, reports that dragging does not move the building and suggested site does nothing, and will supply a broader design plan later. No normal Gate B or appearance approval is inferred. Keep the existing branch and fix only these concrete interactions now.

- Reproduce native candidate drag incorrectly panning the camera and repeated suggestion no-op; pure tests require a different valid next suggestion without spending.
- Walkthrough gestures must share the normal scene's footprint/opaque-art hit contract, preserve the initial grab offset, keep camera stationary during candidate drag and retain invalid candidates for correction with confirmation disabled. Tapping the candidate must not relocate it. Empty-map drag remains camera pan; pinch cancels candidate drag ownership.
- Next suggested site cycles deterministically through authoritative-valid nearby candidates (woodcutters remain in reviewed forest sites); handle no/one-site results explicitly. Preserve current placement confirmation and all game data.
- Wrap the clipped title/cost labels visible in the owner's screenshot, capture actual placement state, verify the full guide plus drag/suggestion on phone/mini/Pro and normal Release entry, review, commit/push and install only after fresh validated backup and pre-launch preservation.
