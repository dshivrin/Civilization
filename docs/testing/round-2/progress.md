# Round 2 execution ledger

Authority: owner approval f313dd2 and direct implementation request. Existing first-era-review checkout retained per owner instruction; no new worktree. R2-01/02/03 → R2-04/05 → R2-06 only. R2-07 awaits human pilot acceptance; no bridges/defenses/resource-rule/art changes.

- R2-01 complete: explicit preview confirmation, footprint-only drag, retained camera candidate, red/green 48-point controls below projected footprint with safe-area clamping. Original building remains stationary/translucent; roads retain their separate transactions.
- RED: /tmp/civilization-qa-067a36e141f348ebb019a4cc470e0ebc (release-to-commit), /tmp/civilization-qa-8eb20fbe7bd6482b911d9f5e50e05d66 (new-build outside drag).
- GREEN: full core211 Debug/185 Release +7 exclusions in /tmp/civilization-qa-8bd5141462f043c09a05a45017e1367d; three native phone candidate/invalid/edge cases in /tmp/civilization-qa-cb18f61a450b4874a40fb19d9dd12c96; two cases each mini/Pro in /tmp/civilization-qa-97ef37a296fd45a88ef25d9ab0007b90; final phone candidate after hiding overlapping bottom message in /tmp/civilization-qa-3aec428e24b34487ab0843681df8bc0d. Civic restart/research native phone also passed separately.
- Native landscape [capture](candidate-controls-phone.png) inspected. XCTest attachment canvas remains misframed on this runtime; live simctl capture used. One capture invocation hit host cache denial and was rerun with required approval; no product failure.
- No save-format/migration/economy/art/device change in R2-01. Tests use isolated QA identity/temporary files; no original save opened or rewritten. Commands/reports above retain actual test scope.
- R2-02/03/04/05/06 pending.
- Preflight: preview geometry is shared by R2-01 and R2-04; commit validation must read the current preview. R2-05 feeds R2-06 operating assessment; retain construction-only historical witnesses. Marker/inspector support precedes persisted pilot activation.
- Ruling: use the existing reusable QA runner and this committed ledger rather than skill-specific temporary runners; owner explicitly requires reusable infrastructure.
