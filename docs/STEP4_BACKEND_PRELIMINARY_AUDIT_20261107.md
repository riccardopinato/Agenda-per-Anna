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


## Follow-up live — 7 novembre 2026 | Dipendenze pg_net e gestione rischio

**Risultato:** READ_ONLY_DEPENDENCY_MAPPING_COMPLETE / PRODUCTION_CHANGE_NOT_PERFORMED. Rilevazione puntuale tramite Security/Performance Advisor e query SQL **solo metadati/conteggi** (nessun contenuto utenti, URL di push, token, segreto o corpo HTTP consultato). Questo follow-up non attesta test end-to-end.

| Elemento | Evidenza live | Conseguenza |
| --- | --- | --- |
| pg_net | Versione `0.20.4`, installata in `public`, `extrelocatable=false` | Non eseguire `ALTER EXTENSION pg_net SET SCHEMA`: relocation diretta non supportata |
| pg_cron | Versione `1.6.4`, installata in `pg_catalog`; **1 job attivo ogni minuto** | Il job chiama `invoke_annas_diary_web_push_reminders`; mantenere operatività del reminder |
| Funzione Web Push | `SECURITY DEFINER`; chiama `net.http_*` | La catena cron → funzione → pg_net è una dipendenza di produzione, non una estensione inutilizzata |
| Execute sulla funzione reminder | `anon=false`, `authenticated=false` | Buon controllo di accesso diretto, ma non sostituisce audit dei ruoli, del body e di ACL end-to-end |
| Coda pg_net | **0 richieste pendenti** al momento del campionamento | Snapshot non persistente: riesaminare immediatamente prima di ogni eventuale intervento |
| Risposte pg_net | **360 risposte conservate** al momento del campionamento | Una ricreazione elimina le risposte: analizzare impatti diagnostici/retention; non pubblicare payload |
| Schema `extensions` | Esiste già | Destinazione documentata dal provider, non motivo sufficiente per procedere |
| Advisor | 2 WARN security invariati; 14 INFO index invariati | Nessun indice rimosso, nessun livello di certificazione promosso |

**Documentazione provider verificata:** [Supabase pg_net](https://supabase.com/docs/guides/database/extensions/pg_net) (aggiornata 3 novembre 2026): il warning per installazione in `public` non si risolve con un semplice spostamento perché l'estensione non è relocatable. Il provider descrive una rimozione/ricreazione nel nuovo schema, con perdita di richieste pendenti e risposte conservate; **non è una procedura eseguita o approvata in questo audit**. [Password security](https://supabase.com/docs/guides/auth/password-security) (aggiornata 1 ottobre 2026): protezione password compromesse disponibile dal piano Pro. Piano effettivo e modalità email/password non verificati; non assumere che il warning sia eliminabile gratuitamente.

### Gate di remediation (non eseguiti)
1. **Preflight:** confermare piano Auth, provider email/password, flussi di recovery; verificare compatibilità con prodotto, test di account sintetici e costo; abilitazione della password protection solo con change autorizzato e test successivi.
2. **Isolamento:** approntare uno staging **rappresentativo** con versioni, migration, pg_net, funzione di reminder, cron, dati sintetici, endpoint push di test, permessi e log redatti. L'attuale `anna-calendar-staging` è uno staging OAuth e **non è stato certificato come clone** dell'ambiente Web Push.
3. **Rollback e change window:** esportare definizioni (non segreti), garantire backup/restore indipendente, enumerare dipendenze, interruzioni temporanee, oggetti extension-owned, coda/risposte e cron. Preservare evidenze non sensibili delle risposte necessarie prima di eventuale drop. Niente `CASCADE` indiscriminato.
4. **Test staging prima dell'eventuale produzione:** riprodurre procedura ufficiale di re-installazione `pg_net` nel nuovo schema, confermare che funzione cron e `net.http_*` continuino a funzionare, osservare esiti push/errori e rieseguire gli advisor; testare fallimento, ripristino e rollback.
5. **Produzione solo dopo gate espliciti:** finestra di manutenzione approvata, coda verificata vuota nel momento effettivo, compatibilità del job e controllo delivery, baseline prima/dopo, checkpoint di rollback e osservabilità. Non trasformare una procedura documentata in consenso implicito al change.
6. **Indici e ACL:** mantenere tutti i 14 indici fino a misurazioni rappresentative; continuare la matrice RLS/ACL di due account e il test PWA su due dispositivi separatamente. RLS ON non equivale a pen test.

**Stato finale Step 4:** mappatura live della catena pg_net completata, rimedi di sicurezza e QA end-to-end ancora APERTI; nessun cambiamento a Supabase o ai dati utente.
