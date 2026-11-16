# Anna's Diary — Oggi: Diario + La mia settimana (16 novembre 2026)

Source baseline: `main@c1fae9226ddd0460890ddc03dc7c0872076beabb`, App Factory fixed baseline `App-Factory-Core@c5adc147046beb7024629466d10eeb799c3c2619` (Master v27 / Golden Index v29); no Factory re-bootstrap between consecutive tasks.

Owner-approved visual direction: two **equal-size cards side by side** on Organic Home, left **«Il mio diario»**, right **«La mia settimana»**, with concise **genuine stored diary-day counts**, and **«Ricordi da rivivere» directly below when authentic memories exist**. The page must remain vertically scrollable, more compact than the previous Weekly Review full-width card; respect 320px phones and 160–200% text, light/dark, IT/EN/ES/FR/PT, hideHomeDetails, selected-day toolbar, reduced motion and Classic mode. Weekly action opens the existing `WeeklyReviewScreen` and local data flow. No second data store, backend, AI or fabricated user content; do not revive duplicate Impegni/Attività tiles or top calendar icon.

Delivery authorized by owner: new **stable-signed arm64 APK** with monotonic Flutter `versionCode` +135 after exact-head CI and merge. Existing sideload APK +134 signer/package must be retained. Web Pages deploy after merge. Signed APK, checksum, run SHA and physical QA status must be distinguished. No Play publishing or destructive device operations. Record blocked items in standing issue #329.

## Implementazione e gate di accettazione

- `lib/src/editorial_today_home.dart`: nuova projection-only UI a due card uguali; `annaTodayAnnotatedDayCounts` legge i `DayJournal` canonici e usa il getter condiviso `DayJournal.hasContent` per escludere record vuoti/archiviati. Non viene aggiunta persistenza.
- `lib/src/planner_views.dart`: 2 card tra Accesso rapido e teaser autentico «Momenti da ricordare», seguite dalla preview Impegni reali; skip della grande `WeeklyReviewHomeCard` solo in modalità Editorial, Classic invariato.
- `lib/src/weekly_review.dart`: accesso al `WeeklyReviewScreen` canonico, archivio e impostazioni reminder preservati; cinque lingue; ripristino della riconciliazione reminder sul mount Editorial.
- `test/editorial_hybrid_today_real_data_test.dart`: contatori dalle date reali e blocchi archiviati, privacy, tap due CTA, dimensioni uguali e matrici responsive light/dark/font.
- `test/organic_pastel_visual_capture_test.dart` e relativa workflow: screenshot Flutter della vera Home vuota e con fixture sintetiche, anche col teaser e con il layout compattato.
- Source version `1.0.0-rc.6+135`; APK stable-signed via main workflow solo dopo exact-head CI. Separare PASS sorgente/CI/artefatto da installazione fisica PENDING.
