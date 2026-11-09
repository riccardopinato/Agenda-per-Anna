# Anna's Diary — Template catalog / Step4 native free preview

- Scope: upgrade existing `showDiaryTemplatePicker` (called from Unified Capture and the Diary editor). The free localized native catalog shows its six original, existing `DiaryTemplatePreset` items.
- On tap, **read-only preview dialog** shows actual `seedText` and original `mediaHint`; only explicit `Use in diary` returns the selected preset to the existing editor. The editor remains responsible for confirmation and canonical `DiaryBlock` persistence.
- No install state, purchase history, Premium SKU, new purchase flow, persistence schema, cloud, sync, Vault, Noi, or new diary writer. Morning/evening settings and notification consent remain as-is.
- The flow is free. The existing diary, memory and ritual features are not paywalled. Five product locales en/it/es/fr/pt.
- Run exact-head Development checks, Web release and UI5 source gate. Audit accessibility/narrow widths, rejection/cancel, private backup/account isolation and signed device QA separately. Physical device, Store and billing remain **NOT VERIFIED**.
- Factory baseline `d4ed1185d36d419228fba6b57a979cde308bd321` (Master v27 / Index v29).
