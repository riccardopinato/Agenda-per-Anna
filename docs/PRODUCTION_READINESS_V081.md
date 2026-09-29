# v0.81 Release Candidate Consolidation

v0.81 is the post-v0.80 release-candidate consolidation checkpoint for Anna's Diary.

## Product boundary

Anna's Diary remains a personal diary / agenda with an optional shared **Noi ♡** space. The release does not expand into work/project knowledge management, which remains the scope of Notes-Ecosistema.

The current product architecture already covers the red-team consolidation areas through the existing Day Hub, Unified Capture, Memory Recall, Open Life Archive, Privacy Center and Notes Bridge Lite. v0.81 therefore prioritizes release confidence over adding another overlapping subsystem.

## Lightweight application policy

The release candidate keeps the app lightweight:

- no bundled LLM;
- no GGUF, ONNX, TFLite, SafeTensors, PyTorch or similar model asset in the app bundle;
- no OpenAI/Gemini/LangChain/Cactus/llama/ONNX/PyTorch/ExecuTorch/TFLite runtime dependency;
- ordinary bundled assets remain individually below the release guard threshold;
- future local intelligence requires an explicit product/size decision rather than entering transitively through a feature dependency.

Existing deterministic local capabilities such as search, OCR-derived text, Memory Recall and data projections remain valid because they do not require a bundled generative model.

## Trusted critical journey

The AppLab journey covers:

1. Calendar
2. Week
3. Today
4. Memories
5. People
6. Home
7. Open Life Archive
8. Noi ♡
9. Account
10. Trash
11. Settings / Privacy Center

The Privacy Center checkpoint verifies that the encrypted Private Vault, backup/data-safety path and account/data-rights path remain reachable in the production APK.

## Architecture contract

- AgendaStore remains the private persistence/account/cloud orchestration facade.
- Existing lifecycle, backup, sync, media, notification and shared-space engines remain authoritative.
- Memory Recall, Open Life Archive and Notes Bridge Lite remain derived/read-or-transfer projections and own no parallel persistence.
- Private Vault remains a separate local encrypted domain by design.
- No new database, backend table, sync queue or AI store is introduced by this release.

## Required release gates

v0.81 can merge only when the exact pull-request head reports success for:

1. **Development checks** — locked dependencies, analyze, full tests and Web build.
2. **Web release** — deploy/build validation.
3. **Android size audit** — production-equivalent ARM64 package and size report.
4. **AppLab Trusted Verify** — production APK, restart smoke, cumulative Maestro journey, visual/runtime and crash checks.

Pending or failed gates block merge.

## Deferred deliberately

- Full multi-language localization is not enabled as a partial/mixed-language feature. It requires a dedicated complete migration of user-facing strings and locale-aware formatting.
- A bundled local LLM is not part of the release candidate. Any future intelligence layer must demonstrate useful value at an acceptable install/runtime cost before inclusion.
