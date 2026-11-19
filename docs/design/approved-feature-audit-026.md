# Approved feature audit — Seed 0.2.6

18 November 2026. Read the repository's active AGENTS, original foundation instructions/history, design decision register, economy/population/landscape/research/progression/playthrough notes, status ledger, 0.2 brief, individual 0.2.2–0.2.6 briefs and milestone reports. Latest human authorization is the pasted 0.2.6 brief retained in `docs/milestones/seed-0.2.6.md`. Historical stop boundaries and tuning notes are interpreted by their milestone, rather than deleting earlier items.

## Approved work still pending verification or human action

| Item | Current status and next step |
|---|---|
| Physical iPhone/iPad deployment and playtesting | Physical iPhone 17 Pro Max connected; unsigned device compile passes. No project team is configured. Dima selects intended signing team/enables required device settings, then runs the app. Requested physical iPads were not connected. See device-testing.md. |
| Physical gesture feedback | Existing tap/ghost/nudge placement, map pan/pinch and cancellation preserved. Invalid/valid placement and fast construction exercised on simulator. Pinch/multitouch, accidental touches, edge handling and comfort need physical feedback before redesign. |
| Baseline A15 60-FPS target, battery/thermals | Not verified on hardware. Newer mini A17 Pro and Pro M4 simulators cannot establish A15/M1 performance. |
| Accessibility coverage | Existing labels and 44-point actions retained/improved. Exhaustive VoiceOver/Dynamic Type behavior and device ergonomics remain unverified; this is a verification gap, not evidence of a completed accessibility audit. |
| Human pacing/enjoyment | Mechanical reachability is tested. All-optional-content automated route takes 156 simulated minutes; research costs, knowledge throughput, labor competition and discovery radii remain experimental pending playtesting. |

No additional approved Stone Age gameplay system was found missing from the documented 0.2.2–0.2.5 scope. This conclusion is limited to repository records; fresh ChatGPT instructions may add or supersede work. 0.2.6 adds isolated developer scenarios/controls and the expanded research UI while preserving that gameplay baseline. Final physical acceptance is explicitly pending.

## Proposed, unresolved or deliberately deferred — separate from approved gaps

| Item | Classification |
|---|---|
| Original graphics / terrain visual identity / final audio | Separate art workstream; proposals are not production approval. Procedural placeholders remain. |
| Four chapters, mandatory all twenty buildings, fixed 45–90-minute era | Proposed or not approved; not completion requirements. |
| Building reconstruction, repurposing, recovery, technology inheritance | Long-term product direction; mechanics unresolved, outside current implementation. Permanent upgrades are already implemented. |
| Building-object drag/drop / relocation | Subsequently requested by Dima in physical-device feedback and implemented in iteration 1; see its report. Supersedes the earlier gesture-preservation boundary. |
| Second historical age, copper extraction, additional cities/worlds, procedural maps | Deferred; geography extensibility retained, second-age adequacy cannot be verified without content/design. |
| Trade, hostile factions, warfare / actual security simulation | Deferred or undecided; current security content is non-combat foundation. |
| Monetization/purchases, backend, cloud saves, multiplayer, analytics, localization | Deferred; no such systems introduced. |
| Demographics, deaths, population decline, specializations, manufactured household consumption | Deferred; no loss-of-population mechanism added. |

The historical Seed 0.1 “deferred” list includes workforce, consumption, timers and expanded research, which were subsequently approved and implemented by 0.2.1–0.2.5. They are not still pending merely because the old document retains them. Likewise the old all-buildings-unlocked rule was superseded by 0.2.5 research gates. Save v1–v5 migration, reward history, terrain identity and frozen regression fixtures remain active guarantees.
