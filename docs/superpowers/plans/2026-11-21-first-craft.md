# Riverbend First Craft Implementation Plan

**Goal:** One Debug-only gather → craft → spend route, on exact Goal3 base 21a3568159cb04fd5ef34fb5ca6f69fd6c0a019c.
**Architecture:** Add optional craft metadata to the existing isolated v1 Lab envelope. Derive gathering mode, unlocked caps and lasting Woodcutter benefit from it. Use the existing atomic candidate save before UI publication. No ordinary engine/save/schema, renderer, signing, device or main changes.
**Spec:** Goal4 coordinator instruction; docs/milestones/2026-11-21-one-craft-handoff.md; origin/main plans/2026-11-20-riverbend-next-codex-goals.md E3 and economy foundation.

## Decisions and acceptance

- Unlock free Toolmaking opportunity only after the Food/Wood checkpoint and operational Stone gatherer. The same revealed outcrop identifies a Flint seam; one gatherer switches Stone5/min ↔ Flint4/min, never both.
- One paid 60s batch costs 2 Wood +2 Flint, grants 1 Tool. A full output rejects before debit. Reserve output during a single active batch; no repeated start, no automatic recurring craft or tool upkeep.
- One project: spend 3 Tools once for sharpened Woodcutter equipment, output6→8Wood/min. Full price is 3 Tools, no hidden currencies. UI retains a permanent completion/readout. Recipe and project costs, source and effect precede commitment.
- Unlocked Flint/Tools base24 each; completed Stockyard+24 each; Granary never craft, Stockyard never Food; Knowledge/Culture unchanged. Before unlock Flint/Tools retain dormant24 and stay hidden in inventory.
- Old envelopes decode absent craft metadata as locked. Validate active timer and unlock prerequisites. Failed writes/retry/reload must preserve stock, batch and benefit exactly once.

## Tasks

- [x] Tests first: craft unlock, exclusive rates, caps, insufficient/full guards, timed output, project spend, duplicate/reload, malformed metadata and failed atomic writes. Run focused RED with checked-in runner.
- [x] Implement model in RiverbendEconomyLab.swift; add Debug/Release exclusion. Run focused GREEN plus existing E0/E1/E2 model routes.
- [x] Expose source/mode, full recipe cost/timer, permanent project output in EconomyLabView.swift. Add actual craft/spend/relaunch native route using existing controls, isolated identities and attachment capture.
- [x] Full Debug/Release core+exclusions; phone+iPad all four economy routes; ordinary Release entry. Archive original runner reports/logs and screenshots with source hashes; deterministic balance trace.
- [x] Fresh independent whole-branch review; fix important findings with RED→GREEN and required reruns. Commit product and evidence, push only economy-first-craft-review, verify exact remote SHA. Deliver short Goal5 handoff; stop.

## Review focus

Fractional full output; failed save at batch finish and project spend; mode switches during batch; close/reload mid-timer; Stockyard completion across one large time step. Each belongs to model tests, with real native mid-batch/relaunch and permanent benefit checks.

## Ledger

- Base and origin predecessor verified identical; clean detached managed worktree. Branch creation initially denied shared Git metadata by sandbox; authorized retry succeeded. No earlier checkout altered.
- Direct instruction supplies implementation authorization; no routine design/playtest pause. Inline execution, with one fresh review at end.

- Ruling: keep inherited dormant24 caps while locked: GameConfiguration rejects zero caps. No new ordinary validation rule. Locked materials cannot be produced/spent or loaded nonzero. Cost if wrong: internal capacity differs from a literal zero-cap lock; no player-facing capacity grant.

- Model: initial sandbox cache denial, missing-API RED and one test accessor typo retained. Zero-cap trial failed all27 model tests on existing positive-cap validation; dormant-cap ruling corrected this. Focused27 GREEN; final308Debug/235Release+16exclusions GREEN.
- Independent review: no blocking correctness findings. Added direct mode-switch-during-batch and unlocked-Flint-mid-Stockyard assertions for its two coverage gaps; both pass in final full core.
- Toolkit: sandbox cache-dependent3 failures retained; authorized retry42pass/3media skips (45discovered). No tool behavior change.

- Native: original phone Stockyard scroll-hit failure retained. Corrected helper now reaches explicit source/project/timer captures; phone craft and iPad complete4-case matrix pass. Remaining phone regression matrix still running at this ledger point.
- Final deterministic trace includes actual58→66Wood in60seconds with Stockyard headroom after project; required full308Debug/235Release+16exclusions rerun passes.

- Final native matrices:4phone/4mini passed, ordinary native Release1passed.18original captures archived and visually inspected representative source/cost/wait/improvement views. Product commit e8a1e360725c0deb32dc125669f78f6d2257bb78 matches all source pins. Evidence/AGENTS/handoff closeout follows, then exact remote push verification; no Goal5 work here.
