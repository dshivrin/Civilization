# Confirmed starter-material soft lock — approved prevention

19November2026. Found during first-era playability review; **approved by Dima’s explicit “Yes” to the reserve-protection question; implemented; see docs/milestones/first-era-playability.md**. The guided route establishes producers and completes, but unrestricted alternative spending can become unrecoverable under current rules.

## Reproduction

From ordinary starting100wood, repeat gathering-shelter construction before a woodcutter. Seven shelters cost105wood, offset by the original one-time10wood construction reward, leaving5wood. No building makes wood. Woodcutter costs10wood/5stone. Waiting, changing priorities, moving buildings, or following other research cannot produce the missing wood. Current seed has no refund/manual gathering command. No normal save was modified to establish this observation.

## Recommended minimal prevention

Protect catalog-derived construction reserves until primitive wood/stone production can be established. Current missing suppliers cost10wood/5stone for Woodcutter and15wood for StoneGatherer: combined25wood/5stone illustrates their costs, not a mandatory fixed reserve. The implementation searches viable supplier orders:20wood/5stone still suffices if wood is established first. Costs/outputs come from definitions rather than hardcoded constants.

Before a build/research/upgrade cost is paid, check whether a source for each non-campfire construction material already exists (including legitimate pending construction and selectable producer modes). If a transaction would spend the materials needed to establish still-missing suppliers, explain which supplier to build first and reject atomically. Constructing a supplier removes its own reservation from that check. No new resource grants, rewards, costs, rates, era requirements or mandatory fixed tutorial sequence. Repeat buildings remain available once a source exists or sufficient reserve remains. Normal save format staysv5; legacy fixtures retain their original rule contract through explicit configuration/versioning, not changed assertions.

Dima explicitly approved this spending-safety rule after reviewing the question/proposal. It prevents new traps; it does not invent funds for already-stranded historical saves. Such saves need an explicitly approved recovery/refund/manual-foraging policy, not a covert grant or reset.

## Alternatives and acceptance

Keep unrestricted spending with prominent explanation (preserves freedom but leaves the soft lock), or design manual emergency gathering/refunds (new gameplay/reward contract requiring separate scope). Do not silently alter starting resources or make collectors free.

Acceptance: tests must reproduce the seven-shelter trap first, verify atomic rejection before insolvency, cover research/upgrade bypasses, allow actual source construction, preserve pending/mode-switched sources, save/reload, old fixtures and all existing regressions. UI must distinguish reserved material from actually missing material and point to the source. Legitimate normal/efficient guided routes and all twenty catalog entries remain achievable without grants.
