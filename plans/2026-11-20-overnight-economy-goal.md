# Codex Goal: Riverbend Economy Lab overnight

**Owner direction:** Start the economy mechanics next without mixing them with the active graphics, animation, menu and existing onboarding review. This is an implementation handoff for a review build only, not approval to adopt the economy in ordinary games.

## Start after the current visual Goal is finished

Do not change or mark the visual Goal complete yourself. Leave graphics/menu/onboarding review gates as they are. Use a separate worktree on a new branch named `economy-lab-review`. Start from the latest verified pushed `first-era-review` checkpoint when picking this up (known at handoff: `4d63b913f6240b3c43ab6fbb0a34dad09194427c`); record the exact base. Read this and the linked plans from `main` without merging it into the review work. If an Economy Lab worktree already exists, resume that verified work rather than starting a duplicate. Never push to `first-era-review` or `main` from the lab task.

## Deliver one playable economy loop

Follow the [approved Economy Lab plan](2026-11-20-stone-age-economy-foundation.md). Add a Debug-only scenario: start with Food and Wood and no Water loop; place a hut; optionally establish Food production; scout a contiguous forest via a lab fixture if necessary; place a legal Woodcutter; reach positive Food and Wood net production. Cover depleted-stock recovery, persistence, and exact-once survey accounting. Use ordinary gameplay definitions where the plan directs, but no changes to ordinary gameplay, released onboarding, normal/Developer saves, R2-07, art, media, menus, signing, or physical-device state. Only the minimal Debug runner/entry and readouts needed to play the lab are in scope.

## Stop with evidence

Use the checked-in QA runner. Verify deterministic core in Debug and Release, Release exclusion, existing-save/mode isolation, native phone and at least one iPad profile, and normal Release entry. Report the branch/commit, results actually run, a ten-minute stock/net-rate trace, two screenshots, and any blocked checks in GitHub coordination issue #1. If native tooling or an approval blocks a check, checkpoint the completed work, state the exact gap, and do not claim the goal passed or change permissions. Do not install on a device, merge, or enable the economy outside the lab.

**Next, not part of this run:** [Map Finds](2026-11-20-stone-age-map-finds.md), after the base lab is verified and the owner has the result for review. Keep additional economy phases, the Empire roadmap, and audio deferred.
