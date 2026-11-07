# Anna's Diary — Step 4 | Audit preliminare sicurezza/backend

**Data:** 7 novembre 2026, controllo live in sola lettura. **Stato:** PRELIMINARY_AUDIT_COMPLETE / REMEDIATION_NOT_AUTHORIZED.

## Baseline
- Factory Core: 989c5123c62c07d1dd85a3c520f0d04b7fe3f543; Master v27 / Golden Index v28.
- App: Agenda-per-Anna@dc601002c3308b6579c30945867638b84ad35de9; PWA Pages distribuita. Native APK +129 precedente.
- Backend: Supabase progetto agenda-per-anna, regione eu-central-1, ACTIVE_HEALTHY, PostgreSQL 17.6.1.
- Metodo: advisor security/performance/health, metadata-only SQL su pg_class/pg_policy/pg_proc/pg_extension, ispezione degli stati repository. **Nessuna tabella di contenuti personali è stata interrogata. Nessun DDL/DML/migrazione/configuration change.**

## Evidenza live e significato
| Verifica | Risultato osservato | Confine |
| --- | --- | --- |
| Tabelle public | 16/16 con RLS abilitata | RLS ON non prova correttezza per ogni operazione, role o account |
| Policy | Ogni tabella public elencata ha >=1 policy; nessuna policy unrestricted PUBLIC/ALL trovata dal controllo metadata | È un check strutturale, non una matrice di attacchi cross-account o prova ACL end-to-end |
| Funzioni public | 19, di cui 1 SECURITY DEFINER (invoke_annas_diary_web_push_reminders) | Metadata check: non EXECUTE per anon né authenticated; esaminare grants effettivi/dependency cron prima di modificare |
| Estensioni | pg_net in public; pg_cron in pg_catalog | pg_net genera un warning: non spostare senza studio dei job/web-push |
| Security Advisor | 2 WARN: extension_in_public, auth_leaked_password_protection | Non sono prova di compromissione |
| Performance Advisor | 14 INFO unused_index | Non eliminare automaticamente: statistiche/traffico/fk/cron e write costs da analizzare |
| Health Advisor | Nessun lint | Non equivale a carico reale, delivery push o sincronizzazione certificata |
| Push/browser | Web Push implementata nel codice | Consegna PWA in foreground/background dopo aggiornamento e autorizzazioni Web NON verificata fisicamente |

## Priorità delle azioni, separate dallo Step 2
1. **P1 — Auth leaked passwords**: verificare se email/password è attivo e se il piano Supabase permette HaveIBeenPwned leaked-password protection (docs: Pro e superiori). Abilitare solo tramite change controllato, seguito da verifica login/account recovery e regressione client; non modificato ora.
2. **P1/P2 — pg_net in public**: mappare dipendenze di cron/net e grants, predisporre piano di staging/rollback, testare Web Push reminder e scheduler in staging; nessuna ALTER EXTENSION indiscriminata.
3. **P1 — Sync/ACL due account**: scenari owner/membro su spazi separati; join QR, inviti 8 caratteri/24 ore, revoca accesso, cambio account, offline retry, duplicati e conflitti. Usare solo account/fixture di test. Due PWA servono per comportamento Web, non certificano Android nativo.
4. **P2 — Web Push**: consenso, subscribe/unsubscribe, permessi, service worker, background, reinstall/update PWA, error handling, false success statuses; non inviare contenuto privato in log di audit.
5. **P2 — Performance**: raccogliere query plans/latency/indici realmente usati dopo un carico rappresentativo, senza disattivare FK/index o alterare produzione in base alla sola etichetta unused.
6. **P1 — Backup/segregazione dati**: restore su dati sintetici, ACL e possibili scenari device/account, e protezione Vault Web distinta da Android biometria/FLAG_SECURE.

## Decisioni di sicurezza
- Privacy V2 PR #215 e Google Calendar Direct PR #199 restano DO NOT MERGE finché gate autonomi non autorizzati.
- Nessun dato personale, credenziale, token, URL privato, screenshot Vault o payload condiviso va pubblicato nei report o nei test.
- Per modifiche su RLS/Auth/cron/extension serve branch/migration con preflight staging, test e rollback; nessun cambiamento diretto a produzione in questa fase.
- Le misure di performance su dispositivi browser sono nello Step 2 e restano OPEN.

## Fonti tecniche
- Supabase advisor live e metadata SQL, eseguiti in sola lettura il 7 novembre 2026.
- [Supabase password security](https://supabase.com/docs/guides/auth/password-security)
- [Supabase database lint extension_in_public](https://supabase.com/docs/guides/database/database-linter?lint=0014_extension_in_public)
- [Golden Release Reality draft](https://github.com/riccardopinato/App-Factory-Core/blob/989c5123c62c07d1dd85a3c520f0d04b7fe3f543/golden/release/GOLDEN_RELEASE_REALITY_PHYSICAL_VALIDATION_v1_DRAFT.txt)
- [Golden AppLab QA](https://github.com/riccardopinato/App-Factory-Core/blob/989c5123c62c07d1dd85a3c520f0d04b7fe3f543/golden/release/GOLDEN_APPLAB_QA_CERTIFICATION_v1.txt)

**Esito:** baseline sicurezza iniziale incoraggiante, due WARN operativi reali e scenari Web/native non attestati; nessuna evidenza di esposizione account, ma non è un penetration test.
