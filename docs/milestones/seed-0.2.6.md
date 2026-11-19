# Seed 0.2.6 — Developer Tools, UX and UI

## 1. Authorization

Dima has authorized continued development.

Seed 0.2.5 remains the completed gameplay baseline. Introduce an intermediate milestone focused on developer productivity, physical-device testing, usability and interface improvements.

Preserve existing gameplay mechanics and regression coverage.

## 2. Developer mode

Create a dedicated in-game developer panel, available only in debug builds.

Support three predefined settlement scenarios:

### Early settlement
- Population: 3–5.
- Basic buildings.
- Minimal research.
- Sufficient starting resources to test construction.

### Developed settlement
- Population: approximately 20–30.
- Multiple production buildings.
- Active manufacturing chains.
- Partially completed research.
- Partially explored territory.
- Active workforce allocation.

### Late Stone Age
- Population: approximately 50–70.
- Established economy.
- Most technologies researched.
- Most territory explored.
- Four completed pillars and one remaining completion objective.

All scenarios must use valid game state and consistent technology, building and achievement dependencies.

Developer saves must be isolated from normal gameplay saves.

## 3. Developer controls

Implement the following debugging capabilities:

- Load any predefined settlement.
- Reset the developer settlement.
- Add resources.
- Increase population within valid housing limits.
- Unlock individual or all technologies.
- Reveal territory.
- Advance simulation time.
- Pause simulation.
- Control simulation speed.
- Enable fast construction.

Fast construction must take three seconds per building, allowing Dima to observe construction animations.

The three-second override must not modify normal gameplay balance or invalidate existing simulation tests.

Developer controls and shortcuts must not be available in release builds.

## 4. Research interface redesign

Replace the existing limited research window with a dedicated, substantially larger research interface.

On iPhone, use a near-full-screen or full-screen presentation. On iPad, use the available landscape space effectively.

Organize technologies into the five established categories:

- Economy
- Science
- Population
- Culture
- Military and Security

Each category must show its research progress.

Each technology must clearly communicate:
- Name and description.
- Research cost.
- Prerequisites.
- Unlocked buildings.
- Gameplay benefits.
- Research availability.
- Completion status.

Distinguish researched, available, unaffordable and prerequisite-locked technologies.

Allow easy navigation between categories without losing context.

Display overall research progress separately from Stone Age readiness.

## 5. General UX improvements

Review the existing interface on both phone and tablet.

Prioritize:
- Resource HUD readability.
- Building catalog navigation.
- Building selection and inspection.
- Construction feedback.
- Workforce and production status.
- Upgrade interactions.
- Exploration controls.
- Civilization progression visibility.
- Touch target sizes.
- Consistent navigation and dismissal behavior.
- Reduced unnecessary screen obstruction.

Use responsive layouts rather than simply enlarging the phone interface for tablets.

Capture before-and-after screenshots.

## 6. Building interaction

Prepare the current building placement and drag-and-drop interactions for physical-device testing.

Verify gesture handling, camera movement, pinch-to-zoom, placement previews, invalid placement feedback and cancellation.

Do not permanently redesign the gesture model until Dima provides feedback from physical devices.

## 7. Physical-device deployment

Assist Dima with running the application on his actual iPhone and iPads.

Target devices:
- iPhone 17 Pro Max.
- iPad mini 6 (A15).
- iPad Pro 12.9-inch (M1).

Maintain iOS/iPadOS 18.0 compatibility.

Document signing and deployment steps. Do not change the user's Apple developer account configuration without permission.

## 8. Verification

Preserve all 79 existing regression tests.

Add automated tests for developer scenarios, save isolation, valid scenario states, construction overrides and release-build restrictions.

Verify phone and tablet layouts.

Maintain existing persistence, simulation and migration guarantees.

## 9. Scope restrictions

Original graphics production remains a separate workstream.

Do not copy artwork or proprietary interfaces from existing games.

Do not implement additional historical ages, warfare, additional cities or monetization.

Do not treat developer-mode settings as approved production balance.

## 10. Continuation

Report each completed submilestone to this project conversation. Continue authorized work while maintaining the design-status ledger.

Review all existing design documentation and identify approved features that remain unimplemented. Report these separately from proposed and deferred features.

Do not silently discard earlier roadmap items.

Stop for consequential design decisions or technical blockers, not routine implementation details.