Retrieved 19 November 2026 from City Design Coordination at Dima's explicit request. Proposed design defaults, not authority for new scope. Existing original art is reused. Text extraction includes the SVG guide; interactive canvas content is not captured by the connector.

# Seed 0.4 — Building and research menu refinement

**Status: Authorized for implementation before the evening review.**

Both menus should feel like compact catalogs rather than collections of large information panels. The player should be able to quickly identify what is available, what they can afford and what is preventing further development.

Use the existing original building artwork and research icons prominently, without allowing them to dominate the interface.

## 1\. Shared visual language

Both menus should use the same reusable card components.

| Element | Compact card | Expanded card |
|--------|--------|--------|
| Name | Always visible | Visible |
| Building or research image | Small | Larger |
| Resource costs | Icons and quantities | Costs, stocks and deficits |
| Availability | Status indicator | Detailed explanation |
| Description | Hidden | Visible |
| Prerequisites | Lock indicator | Full requirements |
| Production and benefits | Hidden | Visible |
| Action | Compact button | Full-width button |

Cards should be compact by default every time the catalog is opened.

## 2\. Building menu — landscape iPhone

The recommended layout is a two-column catalog with a compact category navigation bar. On wider phones, accommodate three columns if the content remains readable.

The following is an interactive layout guide. Tap a building card to expand its details.

## Buildings

8/20 constructed

Interactive design example. Images are external visual references; quantities and progress are illustrative, not gameplay configuration.

The compact arrangement should allow the player to see substantially more buildings without scrolling.

## 3\. Research menu — landscape tablet

Use the same visual hierarchy, but take advantage of the larger display. On tablets, an expanded card can appear in a persistent detail panel alongside the catalog.

# Research

8/20 completed

---

Knowledge cost

Unlocks

Prerequisites

Interactive tablet layout concept. Technology symbols, costs and descriptions are illustrative.

On iPhone, research should use the same compact card grid as buildings, with expandable details instead of a permanent side panel.

## 4\. Card states

All four states must be distinguishable without relying exclusively on color.

A constructed building remains available for additional construction where gameplay permits it. A completed technology cannot be purchased again. These are different states and must not share the same disabled-action logic.

# 5\. Dimensions and spacing

Use these as starting SwiftUI dimensions in points, not fixed pixel sizes.

| Component | iPhone landscape | iPad landscape |
|--------|--------|--------|
| Catalog columns | 2–3 | 3–4 |
| Compact card height | 76–88 pt | 80–96 pt |
| Artwork thumbnail | 44–52 pt | 52–64 pt |
| Card padding | 8 pt | 10–12 pt |
| Gap between cards | 6–8 pt | 8–12 pt |
| Building/research name | 13–14 pt | 14–16 pt |
| Cost text | 12–13 pt | 13–14 pt |
| Resource icon | 14–16 pt | 16–18 pt |
| Expanded description | 14 pt | 15–16 pt |
| Minimum touch target | 44 pt | 44 pt |

```svg
<svg viewBox="0 0 340 174" width="100%" xmlns="http://www.w3.org/2000/svg"><rect x="16" y="21" width="308" height="112" rx="8" fill="#85966e" fill-opacity=".12" stroke="#84956e" /><rect x="28" y="33" width="78" height="78" rx="5" fill="#84956e" fill-opacity=".23" stroke="#84956e" /><path d="M37 70 L67 42 L97 70Z" fill="#ac9667" /><path d="M43 70 H91 V91 H43Z" fill="#90714e" /><path d="M61 74 H74 V91 H61Z" fill="#504232" /><text x="119" y="49" fill="currentColor" font-size="15" font-weight="600">Building name</text><rect x="120" y="64" width="13" height="13" rx="2" fill="#94724d" /><text x="140" y="75" fill="currentColor" font-size="13">25</text><circle cx="178" cy="70" r="7" fill="#969b94" /><text x="190" y="75" fill="#db6262" font-size="13">40</text><text x="119" y="95" fill="#db6262" font-size="11">Missing resources</text><path d="M298 47 L304 53 L310 47" fill="none" stroke="currentColor" stroke-width="1.7" /><g stroke="currentColor" stroke-width=".8" opacity=".5" fill="none"><path d="M28 119 V145 M106 119 V145 M28 140 H106" /><path d="M16 18 V7 M324 18 V7 M16 11 H324" /><path d="M109 35 H116" /></g><g fill="currentColor" font-size="10"><text x="170" y="8" text-anchor="middle">Flexible card width</text><text x="67" y="156" text-anchor="middle">Thumbnail</text><text x="205" y="153" text-anchor="middle">Aligned text and cost row</text></g></svg>
```

Component alignment guide, not to scale.

Keep thumbnails, names, cost rows and state indicators aligned across cards. Do not let longer titles or additional resource costs produce an uneven catalog.

Support Dynamic Type and switch to fewer columns or taller cards when necessary.

# 6\. Implementation and acceptance instructions

:::writing{variant="document" id="81372"}
# Seed 0.4 — Compact catalog refinement

**Status: Authorized for implementation.**

## Shared components

- Reuse compact and expanded card components across building and research menus.
- Use existing original building thumbnails, research icons and resource icons.
- Preserve category navigation, progress indicators and the current visual identity.
- Default to compact cards with aligned artwork, names, costs and status indicators.
- Adapt column counts to available landscape screen width.

## Resource costs

- Display actual catalog costs using resource icons and quantities.
- Highlight only individually insufficient resources in red.
- Show required quantities, available stocks and exact deficits in expanded details.
- Update affordability as the simulation changes.
- Provide accessible resource names, quantities and availability descriptions.

## Expanded details

- Allow individual cards to expand or open a detail panel.
- Prefer one expanded selection at a time.
- Show descriptions, prerequisites, production, benefits, unlocks and relevant construction or research information.
- On tablets, consider a persistent selected-item detail panel.
- Keep completed and locked entries inspectable.

## Actions

- Distinguish inspecting a card from initiating construction or purchasing research.
- An explicit Build action must enter the existing drag placement flow.
- Preserve placement, cancellation, relocation and zoom behavior.
- Research purchases retain their existing validation and transaction behavior.
- Previously constructed repeatable buildings remain buildable.
- Completed research cannot be purchased again.

## Verification

- Check compact and expanded layouts on landscape phone and tablet profiles.
- Verify available, unaffordable, locked and completed states in both catalogs.
- Verify mixed affordability across multiple resources within one card.
- Verify live affordability updates and exact deficit calculations.
- Test long names, multiple resource costs, scrolling and accessibility.
- Preserve category progress, gameplay rules, saves and regression coverage.
- Verify catalog selection through successful drag placement.

## Handoff

Provide before-and-after screenshots of compact and expanded menus on phone and tablet.

Report actual verification results, outstanding limitations and any implementation decisions that deviate from these guides.

No additional gameplay scope, artwork redesign, renderer changes or economy changes are authorized by this refinement.
:::

The layouts, dimensions and expansion behavior above are proposed implementation defaults. All sample imagery is external inspiration; Codex should use the original artwork already integrated into the first-era candidate.

**The objective for the evening review is a denser, cleaner and more consistent interface without losing any existing functionality.** Actual verification remains pending Codex's implementation report.
