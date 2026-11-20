# Proposed theme, branding and motion contract

Status: review proposal, not an activated app schema. [Machine-readable tokens](theme-tokens.json) and [workbench](index.html). Shared components retain positions/meanings while era/region appearance changes.

## Materials and layout

Base material follows era; regional ornament/color/background is a separate layer. Stone Age uses carved stone. The two Bronze comparison exceptions use Egyptian papyrus and Mesopotamian clay; other culturally appropriate Bronze contexts may use leather. These are interface metaphors, not claims that every historical object used one material. Papyrus's Egyptian writing role and the use of clay/cuneiform are grounded in [The Met: Papyrus in Ancient Egypt](https://www.metmuseum.org/essays/papyrus-in-ancient-egypt) and [The Met: Amarna Letters](https://www.metmuseum.org/essays/the-amarna-letters); the latter also shows why a universal Egypt=papyrus rule would be simplistic. No museum image was copied. Generated textures are newly made review samples.

Keep resource order/identity, icon meanings, navigation and button anchors invariant across themes. Catalog/research retain source categories, costs, search, details, prerequisite links and no-purchase navigation. Adapt phone horizontal filter rails vs tablet sidebars by size, not region. Safe-area insets,44pointminimum touch target and type expansion are layout inputs. Native Dynamic Type/VoiceOver/landscape lifecycle remain integration work; the web Larger Text toggle is a review aid, not a native compliance claim.

Tokens separate panel/ink/muted/accent/onAccent/error/focus, texture, typography/layout, brand and motion. Texture sits at18%opacity under readable panel surfaces; text colors are not baked into raster materials. Flat-token body/secondary/button/error combinations validate at least4.5:1. This follows the ordinary-text target in [W3C contrast guidance](https://www.w3.org/WAI/WCAG22/quickref/#contrast-minimum); composited textures, alpha-disabled controls, icon detail and physical rendering still require pixel/native verification. Do not present nominal token checks as whole-app WCAG certification.

## Replaceable temporary branding

Title=CIVILIZATION, generic sunrise/horizon mark, independent era subtitle. Mark is a replaceable native symbol review placeholder; no final logo or naming clearance is claimed. Internal Studio Placeholder is not displayed to players. Title/mark/era/location/app-icon mapping must be separate config fields when integrated. Review title and mark visibility can change without changing era text or structure. App icon/signing and native bundle resources remain untouched.

## Compact completion state

Research pulses at its existing icon for750ms then keeps an unread indicator. Goals and achievements retain independent unread destination groups; the current HUD has no separate achievement icon, so their review proposal aggregates counts at the existing goals/journey icon. No new toolbar position is invented. Markers include count/check and accessible text, not color alone. Ordinary research/goal/achievement and default chapter completions do not auto-open banners, modals, full-screen celebration or large reward art. User-initiated exact-result panels are allowed.

Events require stable IDs; commit event/unread state before visual feedback. Duplicate IDs do nothing. Animation completion, clicking an unrelated icon or opening a destination does not clear unread; viewing that exact new result does. All destinations retain independent records across reload. Rehydration shows static indicators without replay. VoiceOver-equivalent polite live announcements identify new results in the review model; native UIAccessibility announcements remain to implement after review.

The workbench injects a namespaced localStorage adapter for prototype state only; no GameState/SaveStore connection. Failed writes do not consume events or era IDs. Seven pure Node tests cover independence, deduplication, reload, failed writes, selected-object construction and target-theme persistence. The prototype ledger is not a proposed player save-format migration. A production event-ID/source/recovery schema needs a bounded integration plan.

## Motion, construction and loading

Respect system reduced-motion preference plus review override: no pulse, ambient transform or transition crossfade; retain static unread and selected progress/result. [W3C C39](https://www.w3.org/WAI/WCAG22/Techniques/css/C39.html) documents the web preference technique. Do not infer native Reduce Motion behavior solely from this web implementation.

Construction is keyed to the selected review object (the actual selected catalog kind), not a global looping timer. Each selectable catalog kind retains independent progress.0–35%foundation silhouette;35–80%frame;80–100%finishing;100%complete with frame removed. The authored review frame is Hut-only; other kinds disclose an opacity study and does not pretend the hut scaffold is its mesh. Source sprites/occupied ground are unchanged; stage boundaries and anchors are proposals. Progress sliders simulate selection-specific work; no real construction or reward is performed.

Era completion is the exceptional larger transition: commit target theme and transition ID before playback, skippable1200ms maximum, no repeated animation after reload, same controls throughout. It changes only review appearance; Bronze gameplay remains unavailable. Failure to persist blocks playback. Ordinary menu navigation never invokes a full loading screen.

Loading study shows generic mark first, then independent era subtitle and one of three review scenes. When actual work progress is unavailable, use an indeterminate indicator and descriptive stage text, never a fake percentage. Timing is explicitly a demonstration, not measured launch work. Skip cancels scheduled preview stages. Scenery uses one bounded still-image layer with a gentle transform/opacity study, separate title/mark/status layers. True cutout fire/smoke/water/bird layers, GPU/memory budgets and physical startup profiling remain unimplemented; do not advertise them as delivered animations.

Proposed production budgets: no more than3simultaneous transient UI animations;750mscompact cue,1200msera crossfade; static reduced-motion alternatives. Validate actual frame/memory/thermal results before adopting these budgets. Rendering timers must not mutate economy or slow meaningful user commands.

## Review and integration boundary

Approve mockup materials, contrast/readability, existing-anchor layout, compact grouping/clearing behavior, brand placeholders and motion timing before native integration. Then specify native shared components, event persistence/recovery, full-screen accessibility states, accepted media exports/fallbacks and screenshot/performance matrix. Do not automatically integrate these review assets or add later-era gameplay, R2-07, defense/bridge mechanics or Gate2 building art.
