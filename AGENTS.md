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

Factory baseline for UI5 implementation resolved through central `CURRENT.yaml`:
`632a66dce4aa00e8e1700b0a3e4dfc7ea008197c`
(Master v27 modular ACTIVE, Golden Index v23, resolved 31 Oct 2026).
Prior releases retain historical evidence, including former v26.8 baseline SHA
`b5573840caaf0e92bd7719b7471d49a8e34995c1`.
For successive steps of the same UI5 session keep the resolved SHA fixed.

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

For behavior-changing Anna's Diary roadmap steps, automatic exact-head source gates are:

- Development checks (analyze, tests and Web release build; no APK);
- Deploy Anna's Diary Web;
- AppLab Source Gate (repository-local code and visual-flow contract validation; no external AppLab APK runner).

Android size audit, Android emulator integration, and Store/AAB builds remain
**manual workflow_dispatch actions only**. By explicit user authorization, the
**stable-signed ARM64 sideload APK** is now automated for release candidates:
`.github/workflows/auto-signed-arm64.yml` listens only to a successful
`Development checks` run from a trusted `main` push, requires a strictly
increased Flutter `versionCode` compared with that commit's first parent,
then calls the existing stable-signing `sideload-arm64.yml` with the exact
CI-tested commit SHA and inherited protected signing secrets. All other pushes,
PRs, failed CI and unchanged build numbers skip signing. The original
`workflow_dispatch` remains available for deliberate retries.
Never compile signed APKs on a PR and never publish to Play automatically.
An APK build is not an AppLab merge prerequisite. Source merge is distinct
from installable release: mark runtime/visual/physical verification NOT VERIFIED
until explicitly performed on the exact APK using a real-device review.

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
- Primary navigation: Today · Messages · central (+) Create · Memories · More; Calendar is a dedicated route from Today.
- Today is the sole daily hub after v1.05-A3.
- Stable direct-install Android updates use `.github/workflows/sideload-arm64.yml`, invoked automatically only through the new release preflight or manually for a retry.
- Web preview/deploy uses GitHub Pages.
- AppLab's external APK-building runner is not invoked by Anna's Diary.
- The repository-local AppLab Source Gate checks source contracts only; it is not runtime evidence.
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
