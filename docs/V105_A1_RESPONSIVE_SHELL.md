# v1.05-A1 — Responsive Shell Foundation

## Goal

Make Anna's Diary feel native on both mobile and wider Web/desktop surfaces
without mixing this step with the upcoming information-architecture redesign.

## Factory baseline

- App-Factory-Core: `4cc0b94467b94ab6fabe2c927fcc58afff49e39a`
- Master: v26.6
- Golden Index: v19

## Implemented

- Mobile/narrow surfaces keep the existing Material `NavigationBar`.
- Widths >= 840 px use a persistent `NavigationRail`.
- Widths >= 1180 px expand the rail and show destination labels persistently.
- The four current destinations remain exactly the same:
  Home, Month, Week and Today.
- The current selected destination is preserved when the window crosses
  responsive breakpoints.
- Existing Web deep links for `?today=1` and `?capture=1` remain unchanged.
- Existing destination test identifiers remain stable on mobile; wide-shell
  identifiers are added separately.

## Why this is bounded

The audit roadmap calls for a future IA change to
`Today · Calendar · Memories · More` with Capture promoted separately.
A1 intentionally does not perform that change yet. Responsive behavior and
navigation semantics are separated so each can be tested and reverted
independently.

## Acceptance

- `flutter analyze` and complete test suite PASS;
- Web release PASS;
- Android size audit PASS;
- AppLab trusted runtime PASS on the same exact head;
- no persistence, backup, sync or entitlement changes;
- current four navigation destinations remain reachable.
