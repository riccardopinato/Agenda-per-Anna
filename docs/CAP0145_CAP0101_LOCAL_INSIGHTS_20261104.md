# CAP-0145 / CAP-0101 — private read-only Anna insights, 04/11/2026

Source: lib/src/diary/diary_memories.dart and lib/src/weekly_review.dart.
No new domain, database, analytics telemetry, trained model, permissions, backup schema or package.

- CAP-0145: one optional Memories-calendar icon opens a local 12-month frequency grid counting only current-account authorized, non-archived user-created memory blocks. Records are used only while the sheet is visible. Hidden Home privacy or account switch suppresses the grid. Zero means no memory **recorded**, never no activity or mood inference. IT/EN/ES/FR/PT labels, accessible per-day descriptions.
- CAP-0101: extend existing WeeklyReviewSummary (dated private tasks) with a null-when-empty completion percentage. Review step 0 shows completed/pending/older-overdue counts separately and a rate with a documented denominator. Hide all private metrics when the privacy mask is active. No new business dashboard or habit scoring.

QA direct tests: duplicate IDs, archival exclusion, months outside window, null vs zero; task counts, carry-over and null denominator. Full Development/Web/AppLab exact-head gates, phone/large-text/voiceover and privacy/account switch remain distinct. No Golden E5 or physical certification claimed.
