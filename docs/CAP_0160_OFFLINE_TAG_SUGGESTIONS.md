# CAP-0160 — Tag suggeriti offline (Anna's Diary)

**Status: source candidate only; independent of the signed +124 release.** Prepared 5 November 2026. Source baseline `main@331e81935d20de7e3d67cf59b9851bbe9bd59c0a`, App Factory baseline `App-Factory-Core@8052b45b771bf3c5694fc6dd8d037bd83233b37a` (Master v27, Golden Index v28). Related source catalog: [CAP-0160](https://github.com/riccardopinato/Idee-app-Archivi-riferimenti/blob/main/12-CAPABILITY-E-IMPLEMENTAZIONI/REGISTRO_CAPABILITY/CAP-0160.md).

## What is implemented

- Source-only offline sparse TF-IDF keyword proposal; no installed model, third-party stopword file, network, paid AI, new database, cloud writer or background job.
- Editor integration reuses the existing tags dialog and canonical `setInboxTags` / `setDiaryTags` writers. Clicking a chip only edits the temporary text field; only the user pressing **Save** can commit. Cancel leaves source tags untouched.
- Five actual localizations: IT/EN/ES/FR/PT, with localized explanation and explicit, small hand-authored function-word lists. Unsupported languages yield zero suggestions.
- Maximum 4 proposals, minimum 4 letters, maximum 32 letters; input text bounded at 4,000 UTF-16 units; corpus scan bounded at 512 distinct authorized documents. Deduplicated document frequencies, smoothed IDF, deterministic score ordering and lexical tie-break. Single-note empty-corpus fallback uses term frequency only.
- Candidate words come from the exact source note; no hallucinated or inferred labels. URL and email strings are removed before tokenization. Existing tags are excluded.
- Separate **Inbox** and **private diary** source selectors: no cross-domain corpus; only current local account's live, nonarchived canonical items; no Shared Spaces, private/password/cycle Vault, other profiles, external calendar or hidden/trashed records. Shared-only agenda filter disables candidates and editing.
- Before any canonical write, the caller verifies the same account ID, **profile-transition-only epoch** (not general sync/UI revision), source text, nonarchive state and unchanged tags. Existing source writers retain ownership.

## Limits and privacy

A TF-IDF keyword is not a reliable semantic or sensitive-data classifier. It can propose a meaningful word from a private note, but cannot guarantee that the word is not personally sensitive. Candidates are **only shown inside the note's private edit dialog**, never automatically shared, persisted, exported or sent in notifications. No automatic write of any tag occurs.

No uncontrolled indexing of entire media/voice transcripts, OCR, passwords or shared conversations. Avoid changing source authorization, login/sync, Google Direct #199, Privacy V2 #215 or the +124 signed APK.

## Gate before merge

1. All five-language negative fixtures, stopwords, deterministic ranking, one/duplicate/5000 documents and 512-source cap.
2. Isolation across guest/account B, private diary vs Inbox, archived notes and shared-only mode; account switch mid-dialog must reject stale writes.
3. Flutter widget preview + cancel behavior: no source writer calls without explicit Save.
4. Exact-head Development checks, AppLab Source Gate and dedicated Web `build-web` on PR. Resolve all review threads. Protected `main` ruleset ID 26578645 must remain active, no bypass.
5. **Physical QA PENDING**: both editors, text scaling/TalkBack, account transition and note backup/restore on user device. No new signed APK until approved release candidate and appropriate device gates.

Existing signed `1.0.0-rc.6+124` is unchanged. No new version/build number in this feature branch.
