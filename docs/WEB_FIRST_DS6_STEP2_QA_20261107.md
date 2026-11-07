# Anna's Diary — Web-first DS6 / Step 2 visual and performance QA

Date: 7 November 2026
Owner decision: use the installed Chrome PWA of Flutter Web for the fast daily feedback loop on two devices. Android stable-signed APKs are periodic/on-demand, not built for every visual change. **This changes the work cadence, not the evidence requirements or privacy boundaries.**

## Canonical sources and evidence
- Factory baseline (fixed for this session): `riccardopinato/App-Factory-Core@3481a8190a5db5965bb22f84832094268d05be98` — Master v27, Golden Index v28.
- App source entering Step 2: `main@3105c47efc2047f53f001e46ec584fa35304a7c3`, `1.0.0-rc.6+129`.
- Web: <https://riccardopinato.github.io/Agenda-per-Anna/> — previously successful Pages workflow `42381022178` on that SHA.
- Existing signed +129: built at `cb8c3d0`; it does not contain the subsequent one-line greeting ticker. A new Android build requires a new monotonically higher versionCode and the normal same-signing-key release checks.
- Product contract: `docs/PRODUCT_BIBLE.md`; DS6 ten approvals: `docs/DS6_PREMIUM_EDITORIAL_10_10_20261107.md`.
- Existing C2 matrix `.maestro/applab-visual-matrix.json` and issue #237: **70 approved baseline PNGs and 70 candidate PNGs are NOT VERIFIED**. Widget/source tests do not count as screenshot approvals.

## Step 1 disposition: PROCESS ADVANCED, NOT PHYSICALLY CERTIFIED
The owner authorizes moving on to Step 2 without blocking UI improvements on the pending Android physical matrix. Label Step 1:
`WEB_FIRST_ACCEPTED / CONTINUOUS_OBSERVATION`, **not** `PHYSICAL_DEVICE_VERIFIED`.

Retain separately:
- two distinct authenticated users/devices, shared-space join and QR 8-character/24-hour server rule, ACL, cache and account switching;
- PIN/biometric/Keystore/FLAG_SECURE, native notifications and other Android-only capabilities;
- encrypted Vault/private data, shared E2EE, full backup/restore and in-place APK upgrade;
- real RevenueCat/Play purchase proof if a store release is requested.

**Two PWA devices test cross-device Web behavior, NOT Android-native or store behavior.**
Never use PWA storage as the only independent backup of important private entries.

## Web-first delivery loop
1. Make one bounded change on a branch using current main; no second database/router/owner. Preserve Classic and Vault invariants.
2. Run exact-head Flutter analyze/tests + Web release build and AppLab Source Gate; resolve review/gate failures.
3. Merge only after protected-main gates are green. GitHub Pages automatically deploys when app/Web input files change; docs-only or test-only PRs may legitimately have no new Pages deployment.
4. Verify Pages deployment conclusion and source identity. **A successful merge is not proof that the new Web UI is already visible.**
5. The owner and Anna open the installed PWA, return to Oggi, and check real behavior. Existing installed/running PWAs may need **close/reopen or refresh** to load new code; do not auto-reload an open editor with unsaved work. If still stale, use `update-recovery.html` after confirming pending drafts are saved.
6. Capture only observation statuses, with route, device/browser, viewport, date, source/deploy ID and description. No user-authored diary data, real passwords, account identifiers, Vault captures, push tokens or private screenshots in GitHub artifacts.
7. Build a new Android APK only on a deliberate native/periodic QA or release gate with higher versionCode. Never relabel the older +129 APK as the new Web commit.

## Step 2 matrix — real ten-screen DS6 paths
Status vocabulary: `SOURCE_PRESENT` / `WIDGET_QA` / `WEB_USER_PASS` / `WEB_USER_FAIL` / `NOT_VERIFIED`. These are **per-scenario**, not one blanket release status.

| DS6 | Web-first experience to inspect | Current evidence and remaining check |
| --- | --- | --- |
| 1 Oggi | One-line greeting ticker, right-side Calendar/Classic icons, space reclaimed below, daily cards, first interaction | Source/widget tests exist; actual device readability, long name, 320dp, browser/PWA refresh NOT VERIFIED |
| 2 Calendario | Month/week/day, dates/markers, collapsed timeline 07:00–22:00, +Crea selected day | Source tests; verify tap and scroll/keyboard on real PWA |
| 3 Ricordi | Real-media vs text-only hero, Timeline, Map, collections/year and original records | Source exists; Web layout/performance with large personal media NOT VERIFIED |
| 4 Altro | Reachability of Search/Inbox/Vault/Explore/Backup/Cloud/Settings and conditional warnings | Source/widget routes; scroll/large text/guest vs authenticated account on Web to verify |
| 5 Impostazioni | Five palettes, custom HSV square/Hue, light/dark/system, intensity, persistence after reopening | Source exists; inspect Web pointer/touch, text contrast and persisted theme |
| 6 Messaggi/Spazi | Same server-issued 8-character code / 24h, manual join/QR, member vs owner | Two-account Web smoke useful; native camera/backend expiry and ACL authority independently gated |
| 7 Crea | Canonical actions, date ownership, animations 416/544/100ms, Reduce Motion | Source tests; touch/IME/quick taps on Web NOT VERIFIED |
| 8 Inbox | Pinned, category multi-tag (max 12), rename, archive/trash, search and keyboard | Source tests; reopen/restart, two accounts and offline pending states on Web to verify |
| 9 Cassaforte | Route from Altro only; original visual/security untouched | **Never capture Vault screenshots**; do not equate Web crypto support with Android protection |
| 10 Cerca e collega | One-character visible titles, longer match evidence, combined filters, include archive, sort | Source tests; check mobile keyboard/results and large-history latency on Web |

### Viewports and rendering dimensions
- 320×640 narrow phone; 360×780 phone with **1.6× system text**; 390×844 standard; 800×1100 tablet preview; 900×1100 to cross the current 840dp navigation rail breakpoint.
- Check light/dark/system, rose/lilac/sage/peach/sky/custom HSV, EN/IT/ES/FR/PT, Reduce Motion, on-screen keyboard and gesture insets.
- Check loading, empty, recoverable error and offline/degraded states. No false `synced` labels when backend not confirmed.
- No clipping, inaccessible buttons, tap overlap or sensitive content in general search/notifications/widgets.
- Current tests: `test/ds6_web_first_step2_responsive_test.dart` (synthetic empty account; real Flutter widget shell/More quick actions plus static route wiring); original `test/ds6_*.dart`, `test/v107_c2_visual_regression_matrix_test.dart` and `test/v100_golden_core_cleanup_test.dart`.
- **Widget test PASS does not imply screenshot comparison, browser Lighthouse, frame timing or physical PASS.**

## Performance budgets and measurement plan
Use a real Chrome/PWA browser with DevTools Performance (do not inject tracking of personal data):
- **startup**: record cold and warm Web load, connection type and viewport; first interactive content must have no indefinite spinner;
- **motion/scrolling**: inspect long greeting ticker, Calendar list and Memories scroll for visible stutter; compare with Reduce Motion;
- **memory**: record browser tab memory before/after navigation/large media and whether performance recovers after closing modal/route;
- **search**: record results latency on representative authorized history and compare cold/warm requests; avoid exposing data in performance traces;
- **offline**: distinguish opening an already loaded PWA from truly cached/offline launch; do not claim offline availability when required assets or cloud state are missing;
- **asset size**: record Web build output and transferred bytes on a normal browser; APK size is a separate native metric.
Exact numeric budgets should be baselined on observed devices before being treated as pass/fail gates. The existing 10,000-memory Flutter projection test has its own fixed 10s test-environment budget.

## Reporting by both testers (small, practical)
For each issue or meaningful PASS, record:
`tester=owner/partner (no personal identifiers); device/browser; PWA or browser tab; viewport if known; route; expected; observed; status; source/deployment revision if visible; reproducibility`.
Do not submit real diary screenshots or security-sensitive values to a public issue. If only a subjective impression is available, record `USER_FEEDBACK`, not `PERFORMANCE_CERTIFIED`.

## Step 2 first live source finding — P1 Search first-open error

The new real-widget More → Search regression exposed a concrete first-open crash
(`Unsupported operation: Cannot modify an unmodifiable list`) when the canonical
`personalSearch('')` returns its documented empty `const []`. The DS6 derived
`approvedPersonalSearch` then attempted `sort` on that immutable instance.

Bounded correction: copy canonical search results to a writable, ephemeral
`List<PersonalSearchHit>` before one-character filtering, optional fuzzy
fallback and sorting. The original source query, permissions, ordering rules,
storage, Vault exclusion and user data remain unchanged. Added direct regression tests
for blank/whitespace, zero-hit one-character and unmatched queries. The first
synthetic More → Search navigation attempt revealed the bug; the final widget
suite retains the reliable More entry-point and source-wiring assertions while
tap-through browser navigation remains an independent live PWA check. **SOURCE FIX MERGED / WEB DEPLOYED:** [PR #270](https://github.com/riccardopinato/Agenda-per-Anna/pull/270) is merged; [Flutter checks #42402256538](https://github.com/riccardopinato/Agenda-per-Anna/actions/runs/42402256538) and [Pages #42402256546](https://github.com/riccardopinato/Agenda-per-Anna/actions/runs/42402256546) completed successfully on exact source `dc601002`. Real More → Search interaction in installed PWA, account isolation and latency remain **NOT VERIFIED**.

## Next engineering follow-ups
1. **Already merged:** source QA and first-open Search fix (#270) with exact-head CI/Web PASS. **Next:** two real installed-PWA More → Search tap-through runs, empty query, single-character results, editor save/reopen and account switch; do not collect personal data in public issues.
2. Use Web-first user observations to identify **bounded** DS6 polish changes; implement one screen/related group at a time, ship directly through Pages.
3. Obtain independent synthetic screenshot provenance for issue #237 separately (existing 70-pair Android matrix remains pending); consider a dedicated, safe Web/PWA capture track only if it can run without real account data.
4. Review source/layout hotspots if actual Web measurements show jank, slow load, excessive memory, or overflow. Do not refactor large stores preemptively.
5. Periodic Android native +130 or later when explicitly requested, preserving existing stable signing identity; never block routine Web cosmetic work on this periodic artifact.
