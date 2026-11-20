# UI theme review execution ledger

Authority: owner UI plan at a7e38c2/direct implement; prepare review gates, no runtime integration. Existing first-era-review retained. Product Design audit uses fresh native captures, not prior screenshots. User-context preflight found no saved context; source project/approved plan supply the target. Browser uses available native CUA in-app surface, no external Playwright dependency.

- Native test added: isolated fresh UUID games, launch→HUD→catalog/details→research/details→civic inspector→journey→Games. Mini one-case pass in63821896..., phone final one-case pass b0e45e73..., Pro one-case pass440740af....27raw screenshots and three contact sheets inspected. First phone attempts failed Games assertions (launch identifier, then lazy offscreen row); fixed to visible active-game section. No product bug/fix inferred.
- Permanent UIReviewRenderer compiles exact EraIcon.swift through symlink, with a tool-only macOS thumbnail bridge. Initial build lacked that bridge; corrected. Initial diagnostic icon subset used two noncanonical research IDs; replaced by all20validated canonical research IDs,43total native exports. Initial output retained outside Git. No runtime source copy/edit or ad hoc swiftc binary.
- Seven generated material/loading/frame PNGs preserved unchanged, exact prompts/hashes/pins. No API/CLI fallback, source-art replacement or external museum-image import.
- Three token themes validate ordinary text pairs >=4.5:1 (nominal flat colors only); shared mockup templates preserve resource order/control semantics. Screenshot evidence is in audit; native full accessibility and composited contrast remain open.
- State tests RED2/5 for missing target-theme persistence and selected-object construction, then GREEN5/5 after adding them. Other tests cover independent unread/exact view, ID dedup/reload and failure-first persistence. No production save migration.
- Browser checked carved HUD, papyrus catalog and layout-anchor equality; further final checks/review follow.
- Ruling: preserve existing goals/journey HUD position for independent goal/achievement groups rather than invent a new achievement toolbar icon — native source has no such slot — cost is owner refinement of grouping before integration.
- Ruling: deliver review-only shared templates/tokens/model and still-layer motion, not native integration or a full cutout scenery animation package — explicit owner review gate/source availability — cost is separate accepted-asset/native lifecycle/performance work.

Completion verification/review/commit tracked below. R2-07 disabled; Gate2 art and UI Themes separate; media/player/signing unchanged.

## Final review and verification

Independent read-only reviewer found five Important issues, no Critical: automatically exposed result cards; incorrect Hut preview fallback; dark abrupt era overlay; hardcoded branding; incomplete canonical filters/Roads/context-return and phone layout. All five corrected in one pass. Exact-result content now appears only after explicit destination/result viewing; selected construction uses its actual kind; target material crossfades behind a small skippable era card; branding binds configuration; canonical security filtering, Roads study and contextual returns work.

Final browser checks: three material/screen comparisons, identical HUD anchors across themes, zero automatic outside-result cards, exact research result/summary, selected Gathering Shelter construction, security filter and prerequisite return, reduced-motion static unread/no pulse, persisted era theme, independent title/subtitle, loading skip cancels progress, console errors/warnings empty. Landscape phone852×393: document width=scroll width852, horizontal filter rail, three Roads cards, device height365. Reset demo after checks. These are browser prototype observations, not native accessibility/performance acceptance.

Final Node suite7/7 passes, including two added RED→GREEN regressions for configured catalog construction kinds and viewed-result access. Manifest builder validates7generated PNGs,43native exports,27captures and three nominal contrast themes. Native capture passes: phone /tmp/civilization-qa-b0e45e73588e47beae754742d4ca791f; mini /tmp/civilization-qa-63821896e03f467cb1d4671c9c3917f7; Pro /tmp/civilization-qa-440740af4f624f70a624744de02cec81. Each runs one actual audit test; prior failed selector attempts remain recorded. No fresh full core/Release/physical performance suite is claimed for this documentation/review-only change.

Migration safety: no production source/configuration/art/schema changes; only isolated UI audit test plus standalone review tooling/artifacts/documentation. No player/device files opened or modified. Prototype storage is namespaced and independent. Media697b486 remains local-only. R2-07 remains disabled. Commit/push recorded in Git history; visual acceptance and native integration remain next.

Latest personal-origin fetch: main advanced a7e38c2→c845b21 (Living World visual-production plan only); first-era-review unchanged. New plan copied verbatim for next separate audit; no merge. Broader20tooling-test sandbox attempt failed art-audit concurrency because neither Swift child succeeded; rerun with approved cache access follows.

Approved cache-access rerun: all20Python tooling regressions pass (8.092s); expected negative-path messages retained. Final node7/7, manifest validation and JavaScript syntax/diff checks pass. Media Git status clean at697b486.
