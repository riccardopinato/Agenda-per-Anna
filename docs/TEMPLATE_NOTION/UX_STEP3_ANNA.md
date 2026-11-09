# Anna's Diary — Maxi-step 3 / Rituali gentili

Native Flutter UX extends existing DailyRitualCard and Settings using a read-only, localized preview of the REAL morning/evening DiaryTemplatePreset seeds. Entry points: Today (when either ritual enabled) and Settings (always available, including disabled defaults).

Configuration remains in existing AgendaPreferences / Settings switches and time picker; notification permission remains explicit and the existing reconcileDailyRitualReminders flow is authoritative. Only startDailyRitual on the existing Today card creates a standard private DiaryBlock, with same-day idempotent tag. No second writer, database, sharing, Vault, streak, reminder or Premium integration.

Five existing product locales en/it/es/fr/pt. Source tests enforce reuse and localization keys. Run exact-head development/Web/AppLab source gates before merge. Runtime, physical device, permission handling and signed release NOT VERIFIED until separately tested.

Factory baseline d4ed1185d36d419228fba6b57a979cde308bd321.
