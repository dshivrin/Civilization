# Automated Stone Age playthrough

Verified 19 November 2026 by `freshStoneAgeCompletesThroughRealResearchAndProduction`. This is a deterministic GameCore playthrough with actual bundled costs, construction timers, worker allocation, production, research gates and exploration. No resources, technologies or achievements were granted for debugging. It is not a human enjoyment or pacing test.

The scenario purchases every catalog technology and builds every type as required by Seed 0.2.7, as well as all five pillars and required resource territories. The scenario waits in 60-second chunks, so checkpoints can be later than the exact moment a construction or cost becomes ready.

| Simulated time | Action/checkpoint |
|---|---|
| 1–4 minutes | Gathering shelter, woodcutter, stone gatherer and hut constructed |
| 4 minutes | Oral Tradition researched |
| 5 minutes | Storytelling circle constructed |
| 10–11 minutes | Fishing researched; fishing shelter constructed |
| 12 minutes | Second hut constructed |
| 16–19 minutes | Hunting, hunting lodge and two extra gatherers for flint/clay |
| 24–25 minutes | Stone Tools researched; toolmaker constructed |
| 30–31 minutes | Leatherworking researched; tannery constructed |
| 36–38 minutes | Pottery researched; pottery workshop and storehouse constructed |
| 58–143 minutes | Remaining technologies purchased, including all branches |
| 144–151 minutes | Remaining buildings and security structures constructed |
| 154 minutes | All five achievements complete; population 15, 23 placed buildings, 20 technologies, 650 discovered tiles (of 768) |
| 155 minutes | Completed save reloaded and another hut constructed; completion remained recorded |

The test exports a normal v5 save when `CIVILIZATION_PLAYTHROUGH_SAVE` is set:

```sh
CIVILIZATION_PLAYTHROUGH_SAVE=/tmp/civilization-completed-stone-age-v5.json \
  swift test --package-path Packages/GameCore \
  --filter freshStoneAgeCompletesThroughRealResearchAndProduction
```

That exported save was restored into the dedicated **Riverbend Fresh Verification** simulator for rendering verification. Its previous test settlement was backed up in `/tmp/civilization-isolated-before-completion-preview.json`. Only the saved clock was rebased from the injected historical test epoch to current wall time, preventing an unrelated eight-hour catch-up during preview. No balances, research, buildings or achievements were changed. The actual app showed **STONE AGE READY** and enabled continued building. Screenshot: `docs/screenshots/seed-025/phone-completed-playthrough.jpg`.

## Balance findings

Knowledge throughput is the dominant wait in this deliberately serial strategy. The 154-minute complete-era route exceeds the planning chat's experimental 45–90-minute readiness target; that historical target is not an acceptance threshold, and the new complete-era rule now requires this content. Additional storytelling capacity, staffing priorities, optional technology order and research costs need human playtesting before balance changes. The test proves reachability and persistence, not an optimal completion time.

## Seed 0.2.7 verification

Current regression asserts every catalog type is operational, every catalog technology researched, every chapter complete and all five pillar records present. Completion is at 9240 seconds with 15 inhabitants and 23 placed building instances. Exploration stops at 650 tiles, proving full discovery and future copper identification are unnecessary. Save/reload and a subsequent hut construction preserve readiness and reward history. Export from this run: `/tmp/civilization-027-playthrough.json`. No tuning was changed to make the run pass. This 154-minute serial strategy is reachability evidence, not a promised casual completion time.
