# Dodici settimane che contano — Step 9 source QA + guarded writer design

**Date:** 2026-11-10. **Factory:** `App-Factory-Core@ee72dbb1b0de2cd71bc4aac42c350853c6915159`, Master v27, Index v29.

**Scope:** original, optional, private diary reflections; source-level pilot only. UX approval is provisional; `rights_status=first_party_pending_review` and central `catalog_status=research_candidate` remain unchanged. No billing, entitlement, Premium Store, shared space, reminders, new database, export format, signed APK or release.

### Canonical ownership and safety

- `TwelveWeeksDraftPlan.prepareText()` makes a bounded Markdown draft, never a diary record.
- `TwelveWeeksDraftWriter.saveConfirmed()` is an **unconnected writer adapter**: explicit `userConfirmed`, alphanumeric/underscore/hyphen request receipt, guard captured from `Cap0160TagEditGuard(store)` on editor opening, canonical `AgendaStore.saveJournal(scopeGuard: ...)`, single user-owned `DiaryBlockType.note`, no changes to other blocks.
- Stable request ID becomes the block's idempotency receipt; exact repeat returns the existing block; differing text is rejected, never overwritten. In-flight requests cannot double-commit within the adapter. Rollback on failed persist is owned by `saveJournal`, not duplicated.
- Shared-only or unresolved account scopes fail closed. Account switch epoch A→B→A must be tested on real or orchestrated profile transition before UI activation; existence of guard unit tests is **not** end-to-end proof.
- Date selection is a **civil date**, normalized to local midnight by the writer; never synthesize a reminder or timer. Created timestamp remains actual local time. DST/backup/export/reopen remain manual acceptance gates.
- The active preview still only simulates. The adapter is NOT called from the preview or template picker, so current free templates and existing journal-save flows remain unchanged.

### QA

Added tests: `test/twelve_weeks_guarded_draft_test.dart` (validation, consent, shared scope, replay/conflict, preservation/reload) and `test/twelve_weeks_responsive_qa_test.dart` (320 / 360 / 600 dp, 1x / 2x: wizard navigation only; long-body final confirmation at 2x remains manual/physical QA). Preview uses `Wrap` for navigation and announces simulation completion through a semantics live region.

Manual **NOT VERIFIED** matrix: five locales; 320dp 2x reader and keyboard; original private entry untouched; cancellation and return; A→B→A; concurrency/fault-injected persistence; export/import/restore; Vault and Noi boundary; optional civil-date and DST; physical Android + browser PWA. Record exact SHA, locale/OS, redacted screenshots and result per case. CI PASS ≠ physical QA PASS.

### Admission decision gate

The Product Bible may admit **noncommercial, private source preparation** only. Activation of writing is gated on: first-party rights review, explicit editor UX approval and product differentiation from the six free presets, account-switch/replay/fault injection tests, save failure retry and account isolation, backup parity, AppLab exact-head gates. The current `research_candidate` must not be promoted by merely merging this PR.
