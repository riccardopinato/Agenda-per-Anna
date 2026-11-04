# CAP-0120 / CAP-0147 — Accessibility + reversible Today order (04/11/2026)

Core baseline App-Factory-Core@8052b45 (Master v27/Golden v28).
Sources: canonical DiaryBlock in domain_models.dart, photo viewer in diary_sketchbook.dart, existing Memories cover semantics, existing Personalization settings and Today planner view.

**CAP-0120** optional author-written image description (max 500 chars) remains in existing `DiaryBlock.altText`, with safe legacy default, serialized in ordinary JSON/backup and local JSON. A user-initiated edit in photo viewer verifies active account, current source block/media/text/revision and uses existing `saveJournal`. No trained image model, OCR-to-alt guessing, new media store or private sharing. Screen reader uses supplied alt description, else caption/photo generic. Privacy mask prevents speaking descriptions.

**CAP-0147** only TWO existing Today cards (Weekly Review and Realistic Day) can swap order through existing Personalization. Preferences persist one bounded list `todayCardOrder` through canonical `AgendaPreferences`, defaults legacy review-first, ignores unknown IDs and dedupes, reversible/reset, IT/EN/ES/FR/PT. It changes presentation ONLY, no data ownership, deletion, cloud identity, modules or entitlement. Do not infer that Golden Progressive Disclosure has become certified.

Tests cover legacy model roundtrip, source preservation and Home ordering. Physical screen-reader/focus/backup/account switch, phone layout and signed APK remain user/device gates separate from exact-head Dev/Web/AppLab CI.
