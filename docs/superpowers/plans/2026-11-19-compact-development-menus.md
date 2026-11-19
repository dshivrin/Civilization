# Compact building and research menus

Dima's direct screenshot feedback authorizes implementation and review this evening. Using writing-plans and inline executing-plans; no intermediate approval pause. Existing first-era gameplay/art candidate remains the baseline.

Design: compact aligned cards show a48point picture, two-line name, status, resource icon/amount chips and44point primary/Details controls. Secondary descriptions/prerequisites/recipes/benefits expand inline individually; summary/cost/action baselines remain consistent when collapsed. Icon costs turn red individually on shortfall and expose resource name, required/stored/missing counts to accessibility. No purchases or simulation changes. Keep category counts, constructed/researched indicators, locked reasons and existing drag selection. Compact categories free vertical space; all scroll regions take available height and clip at their own bounds. At accessibility text sizes use a wider single-column layout and allow natural height rather than truncate text.

Alternatives: always-expanded cards cause current density/misalignment; a separate detail sheet adds navigation. Choose inline expansion consistent with Dima's request; keep primary action independent from details. Minor sizing choices are implementation decisions subject to evening review.

- [x] Step1: record feedback, request ChatGPT visual guides, add failing interaction coverage for both compact/expanded menus, deficits and alignment; commit spec/tests.
- [x] Step2: shared compact card, icon costs and category/grid spacing; integrate buildings, prove behavior, commit.
- [x] Step3: integrate research with same components, verify expansion/research and costs, commit.
- [ ] Step4: all core/Release regressions, Release probes, phone/mini/Pro interactions and live screenshot review; signed iPhone backup/install/preservation when connected. Record ChatGPT guides and real limits; commit report and stop for review.

Verification: UI regression asserts default collapsed state, expansion/collapse restores detail, neighboring summaries align, cost accessibility signals shortages and locked actions stay disabled. Existing UI suite retains placement and gestures. No tests that mirror view implementation. Review actual screenshots at compact phone/tablet sizes. Final independent read-only branch review per executing-plans, fix concrete findings once. No second age/extra cities/warfare/monetization/renderer changes.

Step1 red: new UI regression fails on missing building Details control. Step2 builds and passes building collapsed/expand/collapse plus neighboring action alignment; regression proceeds to expected missing research Details control. Shared costs expose required/stored/missing counts. Commit shared controls/buildings before research integration.

Step3 green: compact/expanded research and exact deficit/locked-state UI test passes. Developer Early deliberately has500Knowledge; changed shortage test to a unique temporary fresh normal save, avoiding artificial edits or real user data. ChatGPT guide received and retained at docs/art/chatgpt-compact-menu-guide.md. Proposed dimensions/panel variants are suggestions; inline details and separate44point actions retain native touch usability.

Ruling after live phone capture: move Details beside the header and costs beside the action; use44point native controls with compact custom surfaces rather than padded system buttons. Normal grid minimum280points gives2phone columns and3tablet columns, reducing cost wrapping. Candidate cards are roughly122points, taller than ChatGPT’s provisional76–96point suggestion to retain separate accessible44point actions and readable status. Native captures verify two visible rows on phone instead of a long information panel. No fixed clipping of details or DynamicType text. Multiple independent expanded cards remain possible; a persistent tablet side panel is deferred as an optional guide variant.
