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
| P200-03 | HIGH | Sensitive content may appear in Android recents/screenshots after PIN; Web/PWA has no native secure window. | Android source now holds an app-PIN secure-screen lease for the full app session; Vault/shared-password routes use independent leases and ordered native FLAG_SECURE updates, so closing one does not disable the other. Screen protection on lifecycle transitions and physical Android/Web behavior still require adversarial validation. | ANDROID SOURCE PATCHED; WEB/PHYSICAL NOT VERIFIED. KEEP BLOCKED. |
| P200-04 | HIGH | Previously exported Calendar Provider/Google events and already delivered notifications may retain original titles, even though new sensitive exports/reminders are masked. | Inventory and explicit user-approved cleanup guidance; no silent deletion of external data. | OPEN; external state cannot be proven/cleaned from source. |
| P200-05 | HIGH | Original #200 was behind `main`, including Quick Wins. | Reconciled onto the latest main in draft #215, retaining Quick Wins 2, translations/icons and current CI. | SOURCE RECONCILED; final exact-head gates/review after each security fix still required. |
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

## Incremental Android screen-disclosure hardening (draft #215)

The PIN-enabled app window now keeps an Android `FLAG_SECURE` lease while
`_PrivacyGate` is mounted. Private Vault and shared-password routes retain
separate leases; closing either route cannot release the app's protection.
Native window behavior is still NOT VERIFIED without Android physical QA.
On Web/PWA there is no equivalent native `FLAG_SECURE`: app switcher, browser
thumbnails and OS screenshots cannot be promised safe. PIN and UI concealment
are NOT encryption.

**Retroactive external disclosure (P200-04):** after marking an already
exported appointment sensitive, the user must inspect the destination Android/
Google calendar, remove or rename the pre-existing external copy if desired,
and clear already delivered notification history where supported. Do not
automatically delete external calendar events or notifications: the original
user data may be owned by other apps. The new marker only blocks subsequent
outbound publication paths that have been reviewed. Test with a real device
and an actual published/delivered historical item.

**QA acceptance (P200-03):** use two overlapping secure routes (Vault and
app PIN privacy gate) and verify that closing one leaves Android screenshots
and Recents protected; verify toggle of the app PIN and screen capture after
the last lease is released. Repeat with background/resume, biometric prompt,
keyboard, account switch and old notification history. Source tests alone are
not enough to mark P200-03 PASS.
