# UI themes and motion review delivery

**Pre-integration gates implemented for review.** Owner plan at a7e38c2 plus direct “Review the plan and implement”. [Open workbench](index.html), [current UI audit](audit.md), [proposed contract](contract.md). This is a separate local HTML review model, not runtime app integration.

Three material themes share HUD/catalog/research templates: carved Stone Age stone, Bronze Egypt papyrus and Bronze Mesopotamia clay comparisons. Native source icons and original building thumbnails are preserved. Existing resource order and control meanings remain stable; appearance comparisons use sample Stone Age data, not playable later eras. Interactive search/details/filters and exact prerequisite navigation support review.

Compact event controls demonstrate750mspulse→persistent unread, separate research/goal/achievement groups, exact-result viewing, deduplication/reload safety, reduced motion and announcements. Construction belongs to selected object; loading/era transition are explicit, skippable review-only studies. Generic sunrise, title and era subtitle are separate/replacable. Internal studio name is not displayed.

Seven built-in imagegen outputs (three material textures, three loading stills, one Hut frame), exact [prompts](prompts/) and generation receipts;43native icon exports, compiled from the actual `EraIcon.swift` source through a reusable macOS tool plus native system symbols. No unavailable ChatGPT concept image was imported. [Asset manifest](asset-manifest.json) records hashes, source mapping and nominal token contrast. No new editable3D or complete animated scenery package is claimed.

Fresh isolated native audit: nine captured states on phone/mini/Pro,27raw attachments, three contact sheets. Loading/settings/error/complete accessibility/physical metrics are explicit gaps. A source-only test selector error at Games was fixed; original failures retained in QA reports. No production test result is inferred from the web mockup.

Open `index.html` directly, or serve the repository root via `python3 -m http.server 8767 --bind 127.0.0.1 --directory .` and visit `/docs/ui/themes-review/index.html`. No package install, backend or public hosting. Prototype persistence uses only `civilization-ui-review-v1` in browser localStorage; Reset affects that demo only, never game saves.

Tools: `python3 scripts/build-ui-review.py` validates assets/pins/contrast and regenerates local data; `node --test scripts/tests/ui_review.test.cjs` verifies state behavior; `swift run --package-path Tools/UIReviewRenderer UIReviewRenderer NEW_DIRECTORY` exports source icons; `--sheet SCREENSHOT_DIRECTORY NEW_PNG` lays out nine audit captures without crop. Existing `python3 scripts/dev.py test --suite ui ... --only-testing CivilizationUITests/RelocationUITests/testUIThemeAuditEvidence` reproduces native capture flow. [Verification ledger](../../testing/ui-themes-review/progress.md).

Original runtime UI, art, player files, schema, economy, signing and physical device are untouched. Media remains clean697b486/local-only; prototypes are not promoted to canonical production media. Gate2 visual acceptance and UI acceptance are separate. R2-07 stays disabled. Next: owner reviews these proposed tokens/screens/motion before a bounded native integration plan.
