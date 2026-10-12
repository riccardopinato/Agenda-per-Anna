# Anna's Diary — v1.00-D6 Functional Regression & Navigation Completion

Baseline: `main @ 5916cb9af0200703f7dc8a87b994d99c0488c0a7` after v1.00-D5.

Factory baseline: App-Factory-Core `fa3c0679de393f1cb13c2fed2be314d1a1269353`, Master v25.1.

## Purpose

D6 closes the functional-regression step requested by the D4 audit after optional identity was repaired in D5.

It does not add a new domain, router, store, database or persistence path. The goal is to prove that the D5 entry change did not make already-complete product areas unreachable.

## Regression contract

The final D6 head must preserve:

- device-only entry and restart behavior from D5;
- Home / Month / Week / Today through the existing `MainShell`;
- the single `showUnifiedCapture` path and its note/voice/photo/inbox/task/event/birthday/person actions;
- Home access to canonical Search, Inbox, Life Archive, Backup, Noi ♡, Account & sync and Settings;
- Explore as a navigation-only surface over Shopping, Workout, Memories, People and Life Ecosystem;
- optional account semantics: opening Account & sync from guest mode must not replace or merge the current guest working set.

## Runtime coverage

`.maestro/journey/d6-functional-navigation.yaml` extends the AppLab journey after the existing D5/D2/runtime checkpoints.

It returns from Trash to Home and verifies real navigation into:

- Search and connect;
- Inbox;
- Explore;
- Shopping list;
- Workout;
- Life Ecosystem;
- Account & sync;

then returns to a deterministic Home state.

Existing AppLab checkpoints continue to cover Month, Week, Today/Capture, Memories, People, Backup, Life Archive, Noi ♡, Account and Trash. D6 deliberately reuses those journeys rather than duplicating them.

## Automated guards

`test/v100d6_functional_regression_navigation_test.dart` prevents accidental removal or duplication of the canonical shell destinations, Explore targets and Unified Capture entry path, and requires the D6 AppLab journey to remain registered.

## Completion rule

D6 is complete only when Development checks, Web, Android size audit and AppLab Trusted Verify are green on the same final PR head.

D6 does not elevate physical/native evidence. That remains v1.00-D7.
