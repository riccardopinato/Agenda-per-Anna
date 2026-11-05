# Anna's Diary — CAP-0151 bounded private extractive summaries

**Scope:** weekly/monthly and place/person summaries from source sentences in private diary notes. This is an **extractive lexical MVP**, not full TextRank graph ranking.

- Every quote is an exact source substring with testable UTF-16 start/end offsets and an entry opening the canonical source memory.
- No generative AI, cloud processing, new datastore, Vault access, shared-space corpus, automatic persistence or rewriting of saved diary content.
- Current calendar week is a rolling seven-day window including today; month is the current calendar month. Place and person filters use canonical linked metadata.
- Hard limits: up to 200 latest source notes, 12,000 UTF-16 units/note, 8 sentences/note, 600 candidate sentences, 4 displayed quotes. A partial coverage notice is visible when the document budget is hit.
- Tests verify literal source/citation identity, negations untouched, archived exclusion, date/place/person filtering, deterministic ordering and bounded limits across 5 languages.
- Full CAP-0151 TextRank, full multilingual linguistic segmentation, live E2E Android QA, larger performance benchmarking and provider/store acceptance remain separate.
- Domain source is read-only, local and recomputed on private account scope revision; it must not be interpreted as a generated biographical statement.

Gate: exact-head Flutter analyze/test/Web release + AppLab Source Gate and review before merge. No APK signing or Play publish by this step.
