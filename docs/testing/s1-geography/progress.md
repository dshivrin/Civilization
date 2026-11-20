# S1-Geography execution ledger

Plan: docs/superpowers/plans/2026-11-20-s1-geography.md; specification committed 03557f8 before product changes. Existing first-era-review branch retained per Dima; no new worktree/session/Goal.

- Production-default/backup regressions observed RED, then GREEN. New bundled map is 64×48, one campfire; original 768 terrain cells and normal footprints preserved.
- Small development transition validates legacy data and creates/read-verifies original bytes before replacement. No reset or data deletion. Radius recomputed from existing full-square knowledge; every known cell retained, new annex hidden, timer/resources unchanged. This is the spec's delegated preservation choice.
- Quarry access at18,16 shares valley-stone identity/reserve/radius; connectivity and actual depletion checked. Cloud visibility uses full footprint and session interaction guards.
- Full Release caught actual sparse-road interpolation failure because RoadGeometry retained a Debug-only64×48bound. Promoted same bound; full169Release then GREEN. No road-rule change.
- Full187Debug GREEN15.489s; full169Release GREEN1.729s; five Release compiler exclusions GREEN.
- Independent whole-change review found no Critical/Important defects. Deferred minor: old non-grouped developer scenario's originalScenarioState retains old map ID and can show Modified developer state after conversion; gameplay/persistence intact.
- Native phone/mini navigation and independent games passed. First new coverage assertion failed on localized3,072format; locale-independent assertion reruns all pass. Pro native3case suite and Release simulator app build pass.
- XCTest attachment framing is invalid portrait/black canvas on this simulator host (known historical issue); final visual QA must use actual simctl landscape captures.
- Goal API currently returns null; no duplicate native Goal created. Existing session and checkpoint retained.

- Final native affected gesture regressions GREEN: phone long-press17.997s, road draw/erase19.406s, road pinch12.800s; mini13.902s/17.976s/11.457s. Geography/save/navigation totals: six affected phone and mini cases, three Pro cases.
- Final real45second expedition/relaunch GREEN: phone58.145s, mini56.409s, Pro57.214s. Pro navigation42.448s/independent saves37.484s.
- Actual landscape screenshot inspected and committed; native XCTest malformed image canvases excluded. Simulator render metric samples saved separately, median59.4FPS/max45.9MiB, not hardware acceptance.
- Environment assessment and one review-only concept prepared; exact prompt/provenance retained, generated edges/UI not exact, never imported into runtime. Human visual review remains before broad/runtime artwork.
