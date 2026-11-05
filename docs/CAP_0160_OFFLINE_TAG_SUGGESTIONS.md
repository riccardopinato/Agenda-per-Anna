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

## Option A — inline suggestions (5 November 2026)

- Inbox and private Diary cards display up to four local tag proposals immediately below each note (without opening the Tags menu). The user can tap a proposal to open the canonical tag editor with that tag preselected in a **draft**; only pressing **Save** commits it. Cancel leaves the note unchanged.
- Inline suggestions are computed only from authorized local content, for the current profile, reusing the CAP-0160 privacy guards and existing tag writers; neither list rendering nor chip tap performs a write.
- Locale-aware inline header and accessible chip labels reuse the same five supported languages. Hidden/archived/shared-only and unsupported-language notes produce no inline tag chips. There is no automatic classification or persistence.
- Source and UI regressions assert visible Inbox suggestion and Cancel-is-nonwriting, plus reusable inline chip selection. Physical QA must be repeated on a new APK; the prior standalone CAP QA binary does not include Option A.

## Option A hardening (5 November 2026)

- In-card previews use fast single-note term frequencies, without scanning 512 private corpus documents for every on-screen or eagerly rendered Diary card. Opening the tag editor still offers the original full TF-IDF ranking, and clicked fast-path candidates are verified against the same authorized inline source before seeding drafts.
- When the 4,000-unit input boundary cuts through *any* non-whitespace token, exclude the complete trailing fragment (including a cutoff immediately before an email `@`). Regression: `sensitive@example.org` straddling the boundary produces no proposal.
- Rejected Inbox optimistic tag edits roll back by exact entry identity, not an index that another capture might shift while queued. No profile data, saved tags or signatures are migrated.

## Review fixes (5 November 2026)

- Account-scoped CAP writes now recheck the editor's profile-only epoch inside the serialized local mutation writer, after obtaining the local store and before deriving any account-dependent delta/sync owner. Profile activation/erasure waits for queued writes to settle before moving the canonical working set. Rejected optimistic Inbox/diary projections are rolled back before the queue barrier releases.
- Unicode-aware email stripping also covers accented address components. The 4,000-unit bound discards a truncated trailing word rather than suggesting its fragment.
- The existing tag normalizer and CAP candidate exclusion share an accent-preserving canonical-equivalence comparison key for Latin characters (IT/EN/ES/FR/PT); no dependency or wholesale diacritic removal.
- Regression tests cover accented addresses, cut words, canonical-equivalent tags, stale account writer rejection and concurrent Save/profile activation. No source scope, backup schema, APK version or signing identity changes.

## Review follow-up fixes (5 November 2026)

- Scope restoration is now published before both profile-switch and account-erasure completion notifications and native launcher sync. Android calendar and Home Widget consumers see `entryScopeReady == true` on completion; an added test watches shell/store notifications across guest → B → guest.
- Unicode email exclusion now runs before incomplete trailing-word removal. A separate bounded partial-address tail filter also prevents leaks for domains cut at the first TLD character. Boundary fixtures cover full and partial TLD matches.
- All changes are source-only; exact-head Flutter CI, review closure and physical QA remain separate required evidence. Signed `+124` is untouched.

## Gate before merge

1. All five-language negative fixtures, stopwords, deterministic ranking, one/duplicate/5000 documents and 512-source cap.
2. Isolation across guest/account B, private diary vs Inbox, archived notes and shared-only mode; account switch mid-dialog must reject stale writes.
3. Flutter widget preview + cancel behavior: no source writer calls without explicit Save.
4. Exact-head Development checks, AppLab Source Gate and dedicated Web `build-web` on PR. Resolve all review threads. Protected `main` ruleset ID 26578645 must remain active, no bypass.
5. **Physical QA PENDING**: both editors, text scaling/TalkBack, account transition and note backup/restore on user device. No new signed APK until approved release candidate and appropriate device gates.

Existing signed `1.0.0-rc.6+124` is unchanged. No new version/build number in this feature branch.
