# CAP-0152 — Bounded fuzzy search for Anna's Diary (04/11/2026)

Core baseline: `riccardopinato/App-Factory-Core@8052b45b771bf3c5694fc6dd8d037bd83233b37a` (Master v27, Index v28).
Source: `lib/src/approved_search_policy.dart` + `test/cap0152_fuzzy_fallback_test.dart`.

## Execution scope
- Existing `AgendaStore.personalSearch` remains sole source/ACL owner and exact keyword results ALWAYS take precedence. Fallback only if no exact result.
- No new packages, index, embeddings, network, database or persistence. Searches small bounded query (3–80 chars, 2+ token chars, max 6 tokens) and at most 5000 distinct authorized candidates, then returns at most 25 ranked title matches.
- Deterministic edit-distance threshold (1 edit if token <5, else 2); prefilter reuses source search with starting characters. It can miss some valid misspellings, especially when both first characters are wrong; never infer that missing match means absent content.
- Existing kind filter, archive handling and current account are passed into source retriever before fuzzy comparison. Vault is not indexed.
- Test cases: correct original match, typo, no false exact-title duplicate, wrong kind exclusion, one-character rule, invalid/overlong query.
- **Gates:** exact-head Development Checks, Web and AppLab Source Gate; physical small-device and 500/5000 corpus benchmarks separately. This implementation makes no p95/latency claim or Golden promotion.
