# Round 2 play implementation

Owner approval f313dd2 authorizes R2-01–06; subsequent instruction requests commit/report now with human gameplay review later tonight. R2-07 normal-save activation remains gated.

| Slice | Delivery | Commit |
|---|---|---|
| R2-01 | Explicit candidate confirmation and camera gestures | 8955179 |
| R2-02 | Exact-item links and source returns | 83a4b17 |
| R2-03 | Activity-dot cleanup and clearing explanation | 19b74ec |
| R2-04 | Logical quarter-turn rotation, unchanged raster art/footprints | 2415d50 |
| R2-05 | Cached cardinal civic connectivity graph | 0bb4b78 |
| R2-06 foundation | v7 marker, validated backups and inspector | e15356f |
| R2-06 pilot | Explicit isolated review activation, service gating and review corrections | This delivery commit |

Debug review path: **Developer tools → Review this game → Path connectivity pilot**. Activation is explicit and applies only to that independent review companion. Inspect disconnected buildings and draw cardinal paths to the civic center. Original normal/developer progress remains independent. New normal games retain legacy rules.

The pilot gates ordinary services, workers, maintenance, inputs, depletion, storage/housing contribution and new scout dispatch. Founding civic services retain approved exemptions. Housing disconnection never evicts; retained overflow stays spendable; paid expeditions finish. Permanent progression and reward history are retained. Source v6 bytes are backed up and verified before v7 atomic publication; failed activation retains the old disk source and supports safe retry.

Core239Debug/207Release +8 Release exclusion probes; inspector12Debug/11Release; Python10 passed during this implementation cycle. Targeted phone/mini/Pro Debug checks and ordinary phone/Pro Release entry checks passed. Pro serial reruns executed seven Debug/one Release cases; the [execution ledger](../testing/round-2/progress.md) retains both prior failed overlapping runs and successful serial runs. Tests are isolated QA fixtures, not human gameplay acceptance or physical metrics.

[Connected review service capture](../testing/round-2/connected-review-service-phone.png). No player-save rewrite, physical install/reset, signing/account change, bridges, defenses, resource-rule expansion or artwork production. Next: report to designated Master chat and ask for building-rendering readiness/spec; owner reviews gameplay tonight. Do not activate R2-07 before human acceptance.
