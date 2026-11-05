# Anna's Diary — main branch protection (administrator import)

Factory baseline: `riccardopinato/App-Factory-Core@8052b45b771bf3c5694fc6dd8d037bd83233b37a` (Master 27 / Golden Index 28).
Prepared 5 Nov 2026; tracked by [#236](https://github.com/riccardopinato/Agenda-per-Anna/issues/236).

## Verified current state

- `GET /repos/riccardopinato/Agenda-per-Anna/branches/main` returned `protected: false` on `main@905146ad615dad6bf963e1b09b2d2ca66a50d355`.
- `GET /repos/riccardopinato/Agenda-per-Anna/rulesets` returned an empty list at preparation time.
- Exact pull request [#242](https://github.com/riccardopinato/Agenda-per-Anna/pull/242), head `786a3152fecdb2400f691d67d82c53f48e91424c`, had **successful** GitHub Actions check runs with these exact job-context names:
  - `check` — Development checks workflow;
  - `build-web` — Deploy Anna's Diary Web (PR preview build only);
  - `UI5 source and visual-flow contracts` — AppLab Source Gate.
- Each of these jobs was reported by GitHub Actions app `integration_id: 15368`.
- **Important:** `build-web` is path-filtered in `.github/workflows/deploy-pages.yml` on PRs. Docs-only PRs do **not** receive a `build-web` status. Requiring it globally would deadlock documentation changes. The universal `check` job already runs a Web release build on every PR.
- `Compile Android Calendar bridge` is PATH-TRIGGERED, so **do not require it for every PR**. `deploy` is SKIPPED on PRs and must **not** be required. `CodeRabbit` can be SKIPPED and isn't a mandatory reviewer.

## Prepared file and what it does

Import [ANNA_MAIN_RULESET_IMPORT.json](ANNA_MAIN_RULESET_IMPORT.json) **using a GitHub repository administrator account**. Storing this JSON in the repository is documentary only: it is **NOT automatically applied**.

The JSON enforces:
- target `refs/heads/main`, ACTIVE;
- PR required before merging; every review conversation resolved;
- GitHub Actions `check` and `UI5 source and visual-flow contracts` required on **every PR**, from integration ID 15368; the always-on `check` includes Web release build. Dedicated `build-web` is checked manually when triggered, but not globally required;
- strict up-to-date required-status-check policy (new main changes may require a PR branch refresh and fresh checks);
- no direct force pushes and no deletion of `main`;
- no bypass actors;
- **zero mandatory human approvals**, deliberately preserving the owner's already authorized exact-head green-gate automatic merges. Repository maintainers may separately opt into one or more reviews later; that would alter the approval workflow and require an available reviewer.

## Admin action (only the owner can do this)

1. Save the JSON file locally (use the downloadable artifact or repository Raw → Save).
2. Open [GitHub repository rulesets](https://github.com/riccardopinato/Agenda-per-Anna/settings/rules).
3. Select **New ruleset → Import a ruleset** and choose the JSON file.
4. **Before creating**, verify only `main` is targeted; it is ACTIVE; no bypass actor is configured; exactly TWO required checks appear (`check`, `UI5 source and visual-flow contracts`). Do not accidentally require conditional `build-web`, `deploy` or path-scoped Android checks.
5. Click **Create**. GitHub's admin settings change is separate from any source PR merge.
6. Verify [repo rules](https://github.com/riccardopinato/Agenda-per-Anna/rules), `GET /repos/riccardopinato/Agenda-per-Anna/rulesets`, and effective branch rules. Test on a harmless PR that requires the three checks. Do **not** test by making an actual direct push to production or by disabling controls.
7. Mark issue #236 complete only after GitHub confirms active enforcement. `branches/main protected:true` can help but a successful ruleset API and actual enforcement take precedence if branch metadata omits rulesets.

## Operational caveats

- A successful PR source gate is not runtime/device, screenshot-baseline, or Store QA. For Web-impacting changes, the dedicated path-filtered `build-web` must also pass as a project merge gate, even though the GitHub ruleset cannot require it for all PRs.
- Strict required checks means the user-authorized autmerges happen **after** the PR branch is up-to-date and all required checks pass; failures, unresolved review threads, stale checks or missing statuses block merge.
- The default `Android integration smoke` workflow remains a deliberate on-demand emulator QA lane, not a required check on all commits.
- Existing signed APK `+124` is unchanged; no Play release, OAuth activation, Secrets or live Supabase changes.
- Do not activate/merge Privacy V2 #215 or Google Calendar Direct #199 under this governance step.

## Exit status

`PREPARED_FOR_ADMIN_IMPORT`. **NOT PROTECTED** until the admin import and active enforcement are observed and verified.
