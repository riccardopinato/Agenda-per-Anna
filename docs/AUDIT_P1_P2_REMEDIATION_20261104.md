# Anna's Diary — remediation P1/P2 audit (4 November 2026)

Scope: repository-level corrections after the cross-functional audit. Only Chat; no Google API activation, no Privacy V2 merge, no Play release.

## P0: user acceptance (not fabricated device evidence)

The owner explicitly instructed on 4 November 2026 to **accept the +123 physical P0 gate generally**. Record the release decision as `USER_ATTESTED_GENERAL_PASS`, not `R0–R13 TECHNICALLY VERIFIED`. No logs, model/OS identity, certificate fingerprint observed on-device, timings, two-device evidence or store purchase logs were supplied. The +123 **signed** artifact was actually built by GitHub Actions [#41871951662](https://github.com/riccardopinato/Agenda-per-Anna/actions/runs/41871951662), from `main@20b0d2c7375f4e33e0009e04e82c666cf07a3128`, artifact ID `13346141160`.

## P1 fixes

1. **GitHub Pages rerun artifact mismatch:** `build-web` now exposes the exact uploaded artifact name as a job output and `deploy` consumes that output. The old deploy job fabricated a name with its own `github.run_attempt`, which changed on reruns of failed jobs while the successful build was not rerun. Source fix is in `.github/workflows/deploy-pages.yml`; a new successful push/main deploy is still required to close operational evidence.
2. **Android smoke test:** removed assertions for superseded Home/Mese/Settimana/Oggi navigation; uses current UI5 four-tab identifiers, central +Crea semantics, and an isolated synthetic store/media fixture. The smoke run remains **manual** and is not represented as device QA.
3. **P1 issue #226 / PR #233:** isolated change in the existing PR corrects its `prefer_const_constructors` analysis failure. The PR must pass its own exact-head CI and review, then merge independently; the broader duration/opt-in scope remains open.
4. **Privacy V2:** [PR #215](https://github.com/riccardopinato/Agenda-per-Anna/pull/215) stays DRAFT/BLOCKED with owner-authorized source-only phases; **do not merge** for this audit.
5. **GitHub branch protection:** `main` was returned as `protected=false` by GitHub. The available app connection does not provide admin controls to change repository branch rules. Owner must configure GitHub Settings → Rules → Rulesets (or Branch protection), requiring PRs, up-to-date check(s) and reviews with no unrestricted bypass, then verify effective enforcement. This cannot be claimed fixed via a documentation-only commit.

## P2 fixes and remaining external evidence

1. **AppLab catalog:** removed nonexistent `lib/src/screens/privacy_center.dart`, replacing it with actual settings/backup surface. Replaced nonexistent `lib/src/storage/**` with current persistence modules. Added regression test that validates catalog flow and file/directory paths.
2. **Release documentation:** updated `PRODUCT_BIBLE.md`, `ROADMAP.md` and the +123 QA checklist to identify the actual signed +123 commit/run and distinguish owner general acceptance from technical proof.
3. **Visual baseline:** `CAP-0069` comparator is source-merged, but there are no approved real 70 baseline/candidate PNG pairs. We cannot invent screenshot evidence. Capture synthetic-data UI screenshots from the controlled Maestro matrix, approve source/test device/locale/theme variants, then run comparator.
4. **Supabase advisory #182:** `auth_leaked_password_protection` is an Auth plan/admin control; enable and validate only when authorized/available. `pg_net` installed in public is non-relocatable; **do not drop/recreate live** without a tested, backed-up migration and push/cron recovery. Index advisory notices are information, not a reason to drop indexes. Nothing in this PR changes live DB, users or secrets.
5. **Performance:** search engine has bounded 5,000-row regression coverage and cap; median/worst frame and memory metrics still require controlled runtime fixtures. CI code counts are not device timings.
6. **RevenueCat/Play, iOS, dual-device, Google Direct:** Store/internal testing and platform-specific certification remain independent. [Google Direct #199](https://github.com/riccardopinato/Agenda-per-Anna/pull/199) stays staging-only/locked.

## Release rules

This hardening is primarily workflow/test/documentation. It does not modify product state or public API, and does not bump Flutter `versionCode`; the signing auto-trigger should therefore **SKIP**. Prior +123 APK stays the installable signed artifact until a separately versioned release passes its gates. Source PASS does not substitute for device or Store PASS.

## Checklist of honest statuses

- App source / old +123 signing: **PASS**, exact historical commit and workflow.
- Owner's general +123 P0 acceptance: **USER_ATTESTED_GENERAL_PASS**.
- Web deploy: **PENDING** until successful new main run after merge.
- Android emulator smoke: **NOT VERIFIED** until manually dispatched on exact main.
- GitHub branch protection: **ADMIN ACTION REQUIRED**.
- 70 screenshot baselines, store purchases, detailed Vault/cross-device checks: **NOT VERIFIED**.
- Full Privacy V2 #215 and Google OAuth #199: **INDEPENDENT DRAFT GATES / DO NOT MERGE**.
