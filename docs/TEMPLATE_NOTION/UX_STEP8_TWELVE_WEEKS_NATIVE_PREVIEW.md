# Dodici settimane che contano — Flutter concept preview (Step 8)

Authorization of 10 November 2026 covers an amendable UX direction and subsequent **bounded non-commercial preview work**, not Premium distribution, purchases, SKU or a new data model.

- Reuses the existing `showDiaryTemplatePicker` discovery surface and a standalone Flutter `TwelveWeeksConceptPreview`. Does not alter the six free presets.
- Original twelve prompts and selectable weeks 1–12, localized in IT/EN/ES/FR/PT. Configurable unsaved title, optional civil date and intention, weekly reflection preference; clear simulated summary.
- Ephemeral state only: no `DiaryBlock`, `saveJournal`, `applyDiaryTemplate`, `Noi`, `Vault`, shared scope, reminder, cloud, RevenueCat or external asset access. The concept cannot return a `DiaryTemplatePreset`.
- Unit/widget test `test/twelve_weeks_native_concept_preview_test.dart`: navigation, confirmation button disabled until checked, no selected diary template from concept interaction.
- Product Bible and the paid manifest remain unchanged. `catalog_status=research_candidate` and `rights_status=first_party_pending_review` are not promoted.
- This is not a new journaling template or installed Premium pack; explicit in-app creation/persistence stays disabled.

**Before activation of actual writing:** Product Bible admission for a clear private diary use case; optional start date and DST civil-date verification; a user-confirmed single-block write via canonical `AgendaStore.saveJournal` with owner/account epoch protection, idempotent request receipt, rollback on failed persist, backup/export/import and A→B→A tests. Full 320/360dp, accessibility, five-language, browser/device and AppLab gates remain NOT VERIFIED until executed on the exact source SHA. No APK/Play release is authorized in this step.
