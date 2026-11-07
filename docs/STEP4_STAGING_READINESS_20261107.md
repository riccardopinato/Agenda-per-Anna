# Anna's Diary — Step 4 | Staging rehearsal / readiness, 7 novembre 2026

**Esito: PREPARAZIONE DOCUMENTALE COMPLETA; REPLICA/STAGING BACKEND NON CREATA; TEST DI MIGRAZIONE NON ESEGUITI.** Nessuna modifica SQL, auth, cron, pg_net, segreto o dati di produzione.

## Riscontri live solo metadata

| Ambiente | PostgreSQL | Public tables / RLS | pg_net / pg_cron | Funzione reminder |
| --- | --- | --- | --- | --- |
| Produzione `agenda-per-anna` | 17.6 | 16 / 16 | pg_net 0.20.4 in public, pg_cron 1.6.4 in pg_catalog | Presente, SECURITY DEFINER; cron attivo ogni minuto |
| `anna-calendar-staging` (OAuth) | 17.11 | 0 / 0 | Nessuna delle due installata | Assente |

Non riusare/alterare lo staging OAuth come backend Web Push di produzione: **non è rappresentativo** e resta dedicato alla PR Google Calendar #199 (DO NOT MERGE). La password-leak protection è disabilitata in produzione; organizzazione Supabase su piano **Free**, mentre [Supabase richiede Pro](https://supabase.com/docs/guides/auth/password-security) o superiore. Provider effettivamente abilitati (Email/Google) non rilevati dalle API disponibili: non dedurre da codepath client.

## Cost gate

Il preventivo restituito da Supabase per **una branch di sviluppo** è `0.01344` per ora (valuta non esposta nella risposta del provider); il costo può accumularsi finché resta attiva. **Non creare una branch, progetto o upgrade senza consenso esplicito al costo**. Un ambiente local Docker/CLI potrebbe invece essere un'alternativa, ma setup, estensioni e delivery non sono ancora verificati qui.

## Rehearsal tecnico richiesto prima di qualsiasi change produzione

1. Fissare snapshot SHA applicativo, lista e ordine delle migrazioni, versioni PostgreSQL/pg_net/pg_cron, definizioni senza segreti di funzioni e job, dipendenze e grants. Riprodurre esattamente la catena `cron.job → public.invoke_annas_diary_web_push_reminders() → net.http_post()` nello staging dedicato.
2. Creare dati **sintetici** e account A/B isolati: tabelle e RLS, inviti, subscription/revocation e payload innocui; non clonare contenuti personali, token, email o Vault.
3. Confrontare il comportamento pre-change: job ogni minuto, coda HTTP, esiti 2xx e failure simulato, retry idempotente, servizio Web Push di test; non chiamare endpoint di produzione.
4. Verificare dal provider la procedura **per la versione effettiva** di pg_net. `extrelocatable=false` impedisce un semplice `ALTER EXTENSION SET SCHEMA`. La reinstallazione richiede gestione dell'interruzione, dipendenze e può eliminare coda e risposte: eseguire drop/create **solo su staging isolato** con backup/ripristino dimostrato.
5. Rieseguire schema grants/RLS, `SECURITY DEFINER` con search_path controllato, funzione cron, test delivery, advisor security/performance. Validare l'assenza di esposizioni anon/auth e che i consumer usino `net.http_*` qualificato in modo corretto.
6. Simulare rollback e fail-safe con cause di fallimento (HTTP timeout/errore, migrazione interrotta, permessi, coda piena). Registrare esiti verificabili, tempo di ripristino, checksum delle definizioni e change window.
7. Solo dopo PASS staging, consenso specifico e finestra di manutenzione pianificare eventuale change di produzione. Prima del change riverificare **live** coda e risposta (i precedenti 0 pending/360 retained erano istantanei), creare checkpoint e verificare reminder dopo la modifica.

## Gate separati

- Protezione password compromesse: **BLOCKED_BY_PLAN_FREE**. Nessun acquisto implicito. Continuare controllo lunghezza/password e MFA secondo policy approvata; convalidare login/recovery su account sintetici se cambia la configurazione.
- 14 indici classificati unused: **INFO / NON ELIMINARE** senza statistiche rappresentative, query plan e audit FK.
- Due account/RLS e due PWA: evidenza del backend ≠ navigazione browser, né Android nativo.
- Privacy V2 PR #215 e Google Calendar Direct PR #199: **DO NOT MERGE**.

## Criteri per sbloccare Step 4

Ambiente rappresentativo con fixture anonime, piano costo autorizzato o locale, prove pre/post, zero cambi involontari di dati, test delivery osservabile, rollback riuscito e approvazione del change. Fino ad allora: **STAGING_NOT_READY / PRODUCTION_CHANGE_BLOCKED**.
