# Anna's Diary — App Factory Agent Contract

This file is the repository-local operating contract for coding agents working on Anna's Diary.
It does not replace `docs/PRODUCT_BIBLE.md`, `docs/ROADMAP.md`, App-Factory-Core,
the resolved Master Prompt, or applicable Golden Rules.

## 1. Factory bootstrap

Before Factory-dependent development, audit, roadmap work or substantial modification:

1. resolve `riccardopinato/App-Factory-Core/CURRENT.yaml`;
2. read the resolved Master Prompt;
3. read the resolved Golden Index and Registry;
4. load only the Golden documents relevant to the task;
5. fix that App-Factory-Core commit SHA as the Factory baseline for the work session.

Do not replace repository truth with chat memory or historical attachments.

Factory baseline adopted for this contract:
`ed6466e774a28e95f9f371cd56bbf7278428776a`
(Master v26.6, Golden Index v22).

## 2. Factory Mode

Anna's Diary adopts the canonical mode:

`ROADMAP_FAST_PLUS_CONTINUOUS_MAINTENANCE`

Delivery flow:

`baseline -> bounded branch -> minimum risk preflight -> implementation -> bounded hygiene -> focused validation -> PR early -> exact-head gates -> merge`

Maintenance findings are classified into exactly four lanes:

- `BLOCKING_NOW`: blocks roadmap delivery;
- `FIX_CURRENT_STEP`: blocks when proven introduced by the current step;
- `BACKGROUND_MAINTENANCE`: record separately, do not absorb into the active roadmap PR;
- `FUTURE`: optional refactor/product opportunity, non-blocking.

At the third materially equivalent recurrence, evaluate:
`APP-SPECIFIC | DONOR | FACTORY PROCESS | GOLDEN CANDIDATE`.
Never auto-promote a pattern.

## 3. Product authority

Product identity and scope: `docs/PRODUCT_BIBLE.md`.

Execution order and completion truth: `docs/ROADMAP.md`.

Core product constraints:

- personal-life diary + lightweight agenda + memory space;
- offline/local-first;
- extend existing canonical stores before adding persistence;
- no Notion/workspace clone;
- no mandatory AI or generative narrator;
- privacy-sensitive domains remain behind their existing boundaries;
- RevenueCat remains the billing adapter unless the Product Bible/Roadmap explicitly changes it.

## 4. Implementation discipline

- REUSE-FIRST and EXTEND BEFORE DUPLICATE.
- Prefer the smallest behaviorally complete change.
- Do not add a parallel store, sync path, router, service or compatibility layer when the existing path can be safely extended.
- Perform bounded obsolete/dead/duplicate code cleanup after substantial changes.
- Preserve migrations, backup/import compatibility and persisted enums unless evidence proves safe removal.
- Do not broaden a roadmap step into unrelated repository-wide cleanup.

## 5. Git and merge authority

Keep `main` stable.

For roadmap implementation:
- one bounded branch per step;
- open the PR early;
- resolve review feedback that is relevant to the authorized scope;
- merge autonomously when required exact-head gates are green, the PR is mergeable,
  and no blocking review or true user-action gate remains.

Do not require a redundant user approval after implementation has already been authorized.
Do not merge if the user explicitly asks to stop before merge.

## 6. Validation and artifact truth

For behavior-changing Anna's Diary roadmap steps, the standard exact-head gate set is:

- Development checks;
- Deploy Anna's Diary Web;
- Android size audit;
- AppLab Production Gate.

Use the smallest complete validation set for governance/docs-only changes.

Build green != runtime PASS.
Runtime PASS != physical-device PASS.
Physical PASS != Play/Store verification.

Prefer build-once / verify-many. Bind important artifacts to:
- source SHA;
- artifact SHA-256;
- workflow/run identity;
- signing identity when relevant.

Never hand a QA/AppLab APK to the user as an in-place update when the stable-signed
sideload artifact is required.

## 7. Current project seams

- Flutter/Dart application.
- Android package: `com.riccardopinato.agenda_per_anna`.
- Primary navigation: Today · Calendar · Memories · More.
- Today is the sole daily hub after v1.05-A3.
- Stable direct-install Android updates must use `.github/workflows/sideload-arm64.yml`.
- Web preview/deploy uses GitHub Pages.
- AppLab is trusted runtime evidence, not physical-device certification.
- Physical/store requirements remain fail-closed and must not be inferred from CI.

## 8. Completion

Before declaring a roadmap step complete:

- requested behavior is implemented;
- bounded hygiene is complete;
- relevant validation was rerun after final cleanup;
- exact-head evidence is recorded;
- documentation/roadmap truth is coherent;
- no unresolved blocker or user-action gate remains;
- completion claims use PASS / FAIL / BLOCKED / NOT VERIFIED semantics honestly.
