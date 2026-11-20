# S1-Geography production activation

Authority: Dima's direct 20 November request “Activate 64×48 and Continue”, confirmed against the latest Master Development Coordination turn. This supersedes MC-003's unresolved production migration gate: all current saves are development/test data. Routine implementation choices are delegated; no additional approval round is required for this scope.

## Intent and boundaries

Make the approved additive 64×48 landscape the sole normal-game map, with the actual standard Stone Age start. Preserve original 768 terrain cells, campfire coordinates, original deposit IDs/distribution/reserves, normal footprints, economy, navigation and independent normal/developer saves. The grouped Debug scenario retains its experimental footprints privately. No second era, renderer replacement, signing/account change or economy overhaul. Preserve all FP/RD/LC/AUDIO/WND/GEO/UX/CLU/MAP-005 backlog.

## Approach and delegated choices

Promote the reviewed terrain rows into bundled production configuration; enable bounded 16×16 terrain caching in Release. Keep a private legacy configuration for regression and validating old development saves. Use a distinct new map identity. A small deterministic additive conversion preserves test progress rather than resetting it: validate the old state under its original rules, create and read back a byte-exact backup before replacement, retain all discovered cells and histories, then adopt the new identity. Recompute the completed square reveal radius as the largest square already fully known; old irregular discoveries remain permanently known. Pending timer/paid cost remain unchanged. This prevents newly added annex from being revealed by a legacy radius that previously exceeded old bounds. Do not build a general migration framework or player migration selector. Failed validation/backup leaves originals untouched; malformed games remain recoverable through existing library UI. Library metadata conversion follows the successful selected-game preparation; target files remain untouched on failed switching.

Alternatives: archive/reset all test progress is allowed after validated backups but discards useful history; a general opt-in production migration UI is unnecessary given no production users. The preservation-first bounded conversion is an engineering choice, not a new Product Owner requirement.

## MAP-001–004

Persist map identity and all original object identities through save/load, independent games, switching and relaunch. Reuse existing near-side stone source/extraction range if connectivity tests prove it sufficient; improve its readable quarry marker without increasing reserves or granting resources. Do not move original deposits.

Render opaque pale cloud cover on unknown tiles, with a readable discovered boundary. Unknown terrain/scenery/deposits/buildings must never enter the visible content or interaction layer; cloud textures are bounded and only rebuilt on discovery changes. Enforce known tile checks at session interaction entry points. Normal gameplay validation already prohibits buildings occupying unknown tiles; rendering should defend independently too.

Expeditions retain configured cost, 45-second timer, reveal step, scout requirement and existing rewards. Maximum radius derives from actual map bounds. Reveal only at completion, union discoveries permanently, reject duplicate starts without charge, preserve capped offline behavior and timers across save/reload. Full map exploration remains optional for Stone Age readiness.

## Verification and continuation

New tests: production dimensions/terrain/footprints/authentic start; backed-up transition, failure and pending expedition; near-side accessible stone discovery/extraction; hidden visibility policy; 64×48 complete optional exploration and save/library/developer isolation. Run full Debug/Release, five Release exclusions, native phone/mini/Pro geography and gesture cases; record actual performance observations without claiming physical FPS from simulator results. Update milestone/checkpoint, commit/push personal dshivrin/Civilization first-era-review, report issue #1 and exact Master chat. Then assess realistic saturated environment art integration and bounded visual pilot; no unreviewed batch artwork.
