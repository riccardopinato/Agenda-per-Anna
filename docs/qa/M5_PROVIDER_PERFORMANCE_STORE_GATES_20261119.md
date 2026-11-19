# M5 — Performance, Supabase e Google Play: stato verificato e gate esterni
Data: 19/11/2026 · **READ-ONLY AUDIT + OPERATOR GATES, non Store approval, non device PASS**.
App base `main@2395ca6f78ff35a9d65f59f6809b4be7d11fcee6` (`1.0.0-rc.6+140`, candidato sideload M4). Factory baseline `6dfde2d6b6a5be6cbc898cea137f87803701814d`; M1 [#367](https://github.com/riccardopinato/Agenda-per-Anna/pull/367), M2 [#368](https://github.com/riccardopinato/Agenda-per-Anna/pull/368), M3 [#369](https://github.com/riccardopinato/Agenda-per-Anna/pull/369). L'eventuale build M4 **non** corrisponde a Store IAP testing.

## A20-18 · Provider Supabase — solo osservazione, rischi ancora attivi

Verifica diretta in lettura eseguita il 19/11 sul progetto `agenda-per-anna` (ID `pxsxlorntswypdbeerzw`, regione `eu-central-1`, PostgreSQL 17.6.1, `ACTIVE_HEALTHY`):
- **Security Advisor:** `extension_in_public` warning: `pg_net` in schema `public`; `auth_leaked_password_protection` warning: controllo password compromesse disabilitato. **Entrambi rimangono WARN aperti**. [Issue owner #182](https://github.com/riccardopinato/Agenda-per-Anna/issues/182), [rimedio Auth](https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection), [lint schema extension](https://supabase.com/docs/guides/database/database-linter?lint=0014_extension_in_public).
- **Performance Advisor:** 14 lints `unused_index` di livello INFO. Non è autorizzato eliminare indici sulla base del solo contatore; potrebbero servire a codepath rari, inviti, foreign key, push/cron o dati più grandi.
- **Public tables:** 16 rilevate, `rls_enabled=true` su ciascuna. La configurazione RLS abilitata **non dimostra** che tutte le policy siano prive di IDOR/BOLA o che invito/revoca siano corretti; per questo rimangono i gate M2 su due utenti.
- **Migration history live:** contiene `owner_shared_space_rename_v109`, `shared_password_hardening_v086`, `web_push_cron_hardening_v044` e `shared_space_avatar_v139` come ultimo change osservato al 17/11. Non assumere che 29 file SQL locali corrispondano one-to-one agli identificatori del database; fare mapping di naming/versioni prima di dedurre drift.
- **Immutabilità:** nessuna query mutante, nessuna credenziale estratta, nessuna modifica Auth/pg_net/cron/Realtime, nessuna lettura dei record privati. Per la risoluzione aprire un piano di change in staging con rollback, dipendenze Web Push + cron e approvazione esplicita; rivalutare lint dopo.

**Esito A20-18:** `PROVIDER_CHECK_VERIFIED_READ_ONLY`; `PROVIDER_SECURITY_FIXES_OPEN`. Non dichiarare `SECURITY_PASS`.

## A20-16 · Benchmark Android: protocollo replicabile, non numeri inventati

| Caso | Fixture e condizione | Cosa raccogliere | Esito |
|---|---|---|---|
| PERF-01 Startup | primo avvio guest, cache fredda, stesso APK fisico | p50/p95 avvio, OS/ABI e memoria | NOT_MEASURED |
| PERF-02 Oggi ↔ Calendario | 50 impegni e 30 attività sintetiche, ripetere 5 volte | frame p50/p95, frame persi, jank e tempi nav | NOT_MEASURED |
| PERF-03 Ricordi foto | 20–30 media JPEG sintetici di taglie diverse, swipe/zoom | memory peak, image decode, frame jank, no crops involontari | NOT_MEASURED |
| PERF-04 Vision Board | 10 elementi/mixed canvas, pinch/pan e ritorno | frame time, persistenza e gesture latency | NOT_MEASURED |
| PERF-05 2 client/Sync | due account sintetici, offline/reconnect controllato | latency ACK server, queue sizes, UI sync truth; no secrets | NOT_MEASURED |
| PERF-06 Power & long session | uso ripetuto 10+ min, device spare, sfondo/foreground | RAM retained, battery impact, plugin lifecycle leak | NOT_MEASURED |

Raccogliere in **Flutter profile mode** (non widget-test o emulazione di frame budget), con SDK, OS, device class, commit source, artifact SHA-256 e lingua/tema invariati; tre o più ripetizioni confrontabili. Usare DevTools Performance, Flutter Timeline e metriche Android native; redigere report senza seriali, token, foto o testi reali. Nessuna soglia p95 arbitraria promossa a PASS: definire benchmark target con evidenza iniziale e test di regressione sullo stesso device. I widget tests di layout M3 **non** misurano GPU/jank del telefono.

## A20-20 · Google Play e RevenueCat: fonti aggiornate 19/11/2026

1. **Target API:** policy Google Play attuale richiede Android 16 / **API 36** per nuove app e aggiornamenti ordinari dal 31 agosto 2026: [requisiti ufficiali](https://support.google.com/googleplay/android-developer/answer/11926878?hl=it). Il progetto dichiara target 36 in [V100-E](../V100_E_DISTRIBUTION_STORE_READINESS.md), da **verificare nell'AAB build reale** prima di upload; non sostituire con APK sideload.
2. **Store artifact:** CI Android release AAB con stesso package, firmatario/upload key ufficiale, versionCode crescente nel manifest AAB, Play App Signing, mapping/ProGuard symbols, scanner e test su un **Internal Testing** track. Non caricare né pubblicare nulla durante questo documento.
3. **RevenueCat:** l'app usa `premium` entitlement e Offering correnti, `purchases_flutter`; il sideload QA M4 usa `ANNA_STORE_RELEASE=false` e `ANNA_PREMIUM_PREVIEW=true`. Questo percorso **non prova** autenticazione di acquisti Play e non deve essere presentato come tale. Per build Store: `ANNA_STORE_RELEASE=true`, `ANNA_PREMIUM_PREVIEW=false`, key Android public corretta, CustomerInfo per concessione, no override Preview. [Configurazione prodotti](https://www.revenuecat.com/docs/projects/configuring-products), [SDK Flutter](https://www.revenuecat.com/docs/getting-started/installation/flutter).
4. **Internal Testing:** partecipazione tester tramite link Play, account incluso in License Testing, prodotto/base plan mappati a Offering/entitlement, acquisto sandbox e restore con **lo stesso Google account**. Verificare acquisto, rinnovo/scadenza e restore, anche account switch; non inferire dal RevenueCat Test Store che l'integrazione fatturazione Google sia pronta. [Play test](https://support.google.com/googleplay/android-developer/answer/9845334?hl=en), [RevenueCat Google Play troubleshooting](https://revenuecat.github.io/codelabs/troubleshooting/google-play/), [restore purchases](https://www.revenuecat.com/docs/getting-started/restoring-purchases).
5. **Data Safety e privacy:** usare [matrice locale](../PLAY_STORE_DATA_SAFETY.md), riconciliare SDK finali (Supabase/Firebase/RevenueCat), dati condivisi, contenuti salute (ciclo) solo in Vault, retention, account deletion sia in-app che online, URL privacy/erasure attivi e dichiarazioni verificate nel Play Console. [Play Data Safety form](https://support.google.com/googleplay/android-developer/answer/10787469), [account deletion](https://support.google.com/googleplay/android-developer/answer/13327111).
6. **Health apps declaration:** l'app include un **cycle tracker**, per cui l'operatore deve completare la dichiarazione Play salute e classificare correttamente le funzionalità pertinenti; eventuale disclaimer non-dispositivo-medico e normativa applicabile **solo secondo descrizioni reali**. [Dichiarazione Health apps](https://support.google.com/googleplay/android-developer/answer/14738291?hl=it), [norme servizi salute](https://support.google.com/googleplay/android-developer/answer/16679511?hl=it).
7. **Policy e disponibilità:** offerte Premium solo se verificate su Play con dati di test; controllare app publishing access/consenso e test in Italia. **Nessun upload AAB/Play release, acquisto, pagamento o alterazione RevenueCat effettuato**.

## Chiusura per evidenza
| Gate | Stato oggi | Si chiude quando |
|---|---|---|
| A20-16 performance Android | **NOT_MEASURED** | trace profilo + baseline + risultati ripetuti su hardware controllato |
| A20-18 provider inventory | **READ_ONLY_VERIFIED** | già conclusa la sola verifica di inventory; advisories ancora OPEN |
| A20-18 provider security | **OPEN (2 WARN)** | change approvata, test in staging + advisors live clean/risk accepted |
| A20-20 source docs / checklist | **PREPARED** | questo documento + Product Bible + policy confermati sull'AAB reale |
| A20-20 Store API/AAB | **NOT_VERIFIED** | artifact AAB, manifest, firma, track di test verificati |
| A20-20 RevenueCat purchase/restore | **NOT_VERIFIED** | veri receipt sandbox Google Play + CustomerInfo/entitlement |
| A20-20 Privacy/Data Safety/Health Console | **OPERATOR_GATE** | dichiarazioni salvate e approvate nel Play Console |

**Decisione permanente del titolare:** il consolidamento di Anna ha precedenza su nuove feature. Il presente documento non crea un nuovo progetto, non modifica Vault, non cambia provider/configurazioni e non promuove lo stato Store.
