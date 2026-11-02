# Privacy UX #200 — security assurance assessment (2026-11-02)

**Decision: BLOCKED — NOT CERTIFIED. Keep PR #200 DRAFT and DO NOT MERGE.**

This review is restricted to UI-disclosure control of optional `isSensitive`
markers on personal agenda items and shared entries. It does **not** audit
Android Keystore/Vault cryptography, server-side access controls, E2EE or
confidentiality of all private-life records. The sensitive marker is stored
as ordinary JSON and is not encryption. This report is evidence of a
source-level review and mitigations, **not** a physical/device security pass.

## Source-level findings (evidence is code, not real-device behavior)

| ID | Severity | Finding | Mitigation | Evidence/status |
| --- | --- | --- | --- | --- |
| P200-01 | HIGH | `TrashScreen._displayTitle` printed `TrashEntry.title` even for deleted sensitive appointments; restore/purge text also contained titles. | `isSensitiveTrashEntry` masks title and deletion timestamp, PIN-challenges sensitive restore/purge/bulk-empty. | Draft branch `lib/src/screens/trash_screen.dart`, `lib/src/discreet_privacy.dart`, focused unit/widget tests. SOURCE PATCHED; exact-head CI pending. |
| P200-02 | HIGH | Backup ZIP and open-export ZIP contain the trash payload; the previous export dialog checked only active `store.items`. Deleted sensitive records could bypass PIN/unencrypted-export warning. | `hasSensitiveLocalExportData` checks active items AND sensitive personal items in trash; export confirmation also requires stable account scope after the dialog. | `lib/src/store/backup_domain.dart`, `lib/src/screens/backup_settings.dart`, `test/privacy_discreet_home_test.dart`. SOURCE PATCHED; exact-head CI pending. |
| P200-03 | HIGH | A sensitive reveal can remain visible in a foreground route or Android app-switcher screenshot after PIN; native screenshot protection and background auto-mask have not been demonstrated end-to-end. | Require lifecycle-driven concealment/screenshot policy + physical Android/Web evidence without breaking the existing Private Vault. | OPEN; physical integration NOT VERIFIED. |
| P200-04 | HIGH | Previously exported Calendar Provider/Google events and already delivered notifications may retain original titles, even though new sensitive exports/reminders are masked. | Inventory and explicit user-approved cleanup guidance; no silent deletion of external data. | OPEN; external state cannot be proven/cleaned from source. |
| P200-05 | HIGH | The draft branch is behind `main` (including newer daily quick wins); direct merging can conflict or regress disclosure pathways. | Reconcile to latest `main` without overwriting newer source changes; rerun full exact-head CI/review. | OPEN: PR mergeability currently dirty. Main already contains quick-win fail-closed compatibility fix #209. |
| P200-06 | MEDIUM | Deferred shared photo upload lacks full `isSensitive` propagation; the current draft denies sensitive photo replacement as fail-closed workaround. | Preserve marker through the queue, cache, remote payload and retry, then test with two accounts; until then keep replacement disabled. | OPEN; per-device/offline concurrency NOT VERIFIED. |
| P200-07 | MEDIUM | Backup/export files are intentionally readable and contain sensitive personal data if user authorizes export. | PIN + explicit warning; prohibit claims of encrypted backup or E2EE; verify the warning/accessibility on device. | Source warning implemented; external file handling NOT VERIFIED. |
| P200-08 | MEDIUM | App PIN reveal path uses a local PIN verifier; brute-force throttling and biometric/lifecycle edge cases are not certified as part of this feature. | Security review of PIN attempts, device biometric failure/revocation, foreground/background and account switch. | OPEN. |
| P200-09 | MEDIUM | Shared-entry commentary, search, archives, previews, widget and semantic labels have multiple entry points; source masking covers identified paths but cannot exclude all runtime leaks without dynamic adversarial testing. | Add multi-device and accessibility/screen-reader traversal, media and deep-link tests; inspect every displayed source field. | PARTIAL SOURCE COVERAGE; physical NOT VERIFIED. |

## Tests and remaining acceptance gates

- Source unit/widget tests for flagged record roundtrips, UI tiles, Cestino title
  masking, export gate including trash, archive exclusion, and ordinary
  unmarked behavior: **await exact-head Development checks**.
- Source compilation & Android Calendar native bridge on the **reconciled**
  PR source: NOT VERIFIED. Previously successful CI on an older head does not
  count for this draft head.
- Physical Android: background/resume, app switcher screenshots, FLAG_SECURE
  interactions with Vault, PIN and biometrics on success/failure, notification
  history and channel/OEM effects: NOT VERIFIED.
- Two real devices / distinct signed-in accounts: marker propagation, cached
  feed and search, stale screens, concurrent edits, unlink/revocation and
  deferred photo upload: NOT VERIFIED.
- Export/import: backup ZIP/open archive/TXT containing active + trashed
  sensitivity flags, cancel/deny PIN, physical file sharing, restore marker
  retention: NOT VERIFIED on a real device.
- Existing Android calendar publications, Google calendar entries and
  previously delivered push notifications: NOT RETROACTIVELY REVOKED.
- Accessibility: screen reader/semantics, text selection, long-press menus,
  deep links and OS previews: NOT VERIFIED.

## Integration/release policy

No auto-merge, no signed release, no Play publication and no claim of
`PHYSICAL PASS` until all HIGH findings are closed with evidence for the
same source SHA/APK and remaining scope limitations are clearly accepted.
The user-attested general Android +120 pass is for a different, earlier
artifact and does not certify this privacy draft. All source/CI evidence
must be re-established after resolving main-branch conflicts.
