# Google Calendar diretto — configurazione assistita (azioni utente)

**Stato 03/11/2026:** PR #199 DRAFT, nessun OAuth Calendar eseguito. Non modificare account Google né condividere segreti in chat/GitHub. App in main: `1.0.0-rc.6+121`, senza modulo API diretto.

## Passaggio 1/6 — Google Cloud (tu)

Il progetto Supabase già esistente è `agenda-per-anna`, reference `pxsxlorntswypdbeerzw` (verificato attivo in sola lettura; NON equivale alla verifica di Google Cloud).

1. Apri [Google Cloud Console — API Library](https://console.cloud.google.com/apis/library) e **seleziona il progetto Google OAuth effettivamente collegato a Supabase**, non un progetto scelto per somiglianza di nome.
2. Cerca **Google Calendar API** e abilitala se non è già attiva. Segna soltanto lo stato `ABILITATA / NON ABILITATA`, senza inviare chiavi.
3. Vai in **Google Auth Platform → Branding / Audience / Data Access**. Conferma nome Anna’s Diary, indirizzi di supporto, tipo pubblico e stato test; aggiungi i test account autorizzati se Audience è External/Testing.
4. In **Data Access** configura gli scope minimi `https://www.googleapis.com/auth/calendar.events.owned` e `https://www.googleapis.com/auth/calendar.calendarlist.readonly`, distinti dal login `openid email profile`. **Non chiedere `calendar` o `calendar.events` generale** per questa V1. Gli scope sono per contenuti di calendari di proprietà, non calendari condivisi sui quali sei solo writer.
5. Controlla il **client OAuth Web esistente**: il redirect verso Supabase documentato è `https://pxsxlorntswypdbeerzw.supabase.co/auth/v1/callback`. Non creare o incollare un nuovo client secret in questa chat; Google client secret resta su Google/Supabase.
6. Controlla in Supabase Auth la *Google provider configuration* già esistente e gli allowed redirect `https://riccardopinato.github.io/Agenda-per-Anna/` e `io.supabase.annasdiary://login-callback/`. Non modificare ora la configurazione di produzione senza test di regressione login.

**Importante:** lo stato External/Testing può comportare refresh token di prova validi soltanto 7 giorni per scope Calendar. Per utenti pubblici possono servire verifica Google, privacy policy e materiale di verifica aggiuntivo. Non promettere che il collegamento rimarrà attivo indefinitamente in modalità Testing.

## Passaggio 2/6 — OAuth separato (assistente, non attivato)

- Nuovo comando volontario **Collega Google Calendar**; non allargare automaticamente gli scope a ogni login Google.
- Validare `Google subject` effettivamente autorizzato e mostrarne l'indirizzo in app prima di scegliere il calendario. Non dedurlo dal solo UUID Supabase.
- Il client OAuth deve usare un flusso con state/PKCE e callback verificato tramite il provider, mai spedire bearer token via link, query string, log o analytic.
- Per accesso offline Supabase documenta `access_type=offline` / `prompt=consent`; presenza e rotazione del `provider_refresh_token` vanno provate nel SDK effettivamente usato, non presunte.
- Sessione Supabase e credenziali Google Calendar hanno ownership, revoca e recovery distinti; **non disconnettere l'account Anna se si disconnette solo Calendar**.

## Passaggio 3/6 — HTTP e token (assistente, non attivato)

- Implementare `GcalHttpPort`, `GcalAccessTokenPort`, `GcalLinkPort` su provider verificati. Android: Keystore/envelope del Golden, namespace per account+Google subject+calendario. iOS: Keychain da verificare; Web: sessione/memoria, senza refresh token persistente non protetto.
- Non inserire token nella serializzazione `AgendaStore`, backup ZIP/TXT, SharedPreferences, database condiviso, screenshot o error log. Disconnessione deve eliminare i link e le chiavi solo di quel Google account dopo conferma.
- Timeouts, retry/backoff solo per errori idempotenti; nessun retry cieco POST, usare GET del remote ID per il recupero. Conflitti ETag 409/412 restano fail-closed.

## Passaggio 4/6 — UX opt-in (assistente, differita)

Mostrare identità Google, elenco dei calendari **owner**, scelta della destinazione, anteprima degli appuntamenti, esclusioni (Noi/Vault/note/riservati), stato Android B3, data ultimo sync e pulsante scollega. Nessuna azione di scrittura fino a verifica + consenso.

## Passaggio 5/6 — Duplicati Android B3 (assistente + tua conferma)

[Procedura di inventario e migrazione senza cancellazioni automatiche](B3_DEDUPE_AND_QA.md). Se B3 ha già scritto su un calendario sincronizzato a Google, disabilitarla non elimina gli eventi precedenti. Il primo sync API rimane bloccato fino all'inventario e alla tua scelta.

## Passaggio 6/6 — Verifiche reali e successiva autorizzazione

Solo mock e CI sul ramo oggi. Dopo Google Cloud: account tester, consenso reale, dati di prova, errori token, cambio account, DST, deduplica e collaudo Android/Web; iOS è gate separato. PR #199 rimane DRAFT / NON MERGE. Privacy #215 resta DRAFT separata e non si incorpora automaticamente.

Fonti ufficiali:
- https://developers.google.com/workspace/calendar/api/auth
- https://developers.google.com/workspace/guides/configure-oauth-consent
- https://supabase.com/docs/guides/auth/social-sign-in/auth-google
- https://supabase.com/docs/reference/dart/auth-signinwithoauth
- https://developers.google.com/identity/protocols/oauth2/production-readiness/overview
