# Google Calendar — backend OAuth staging (source-only)

**Stato:** broker OAuth implementato e unit-testato, **non distribuito**. Non viene importato da `lib/`, non effettua alcun accesso a Google se non è chiamato da un host autenticato. L'app di produzione e il login Supabase restano invariati.

## Componenti

- `oauth_broker.mjs`: flusso Google Authorization Code **server-owned** con PKCE S256, state e nonce casuali, vincolo del soggetto Supabase, scadenza 10 minuti e rifiuto replay.
- `GoogleTokenClient`: POST al token endpoint Google con client secret e code verifier **solo lato server**.
- `GoogleIdTokenVerifier`: verifica crittografica RS256 tramite Google JWKS, issuer, audience, expiry, nonce e subject.
- `AesGcmTokenVault`: envelope AES-256-GCM con AAD per account+Google subject. **La chiave non va mai inclusa nel repository o nel client.**
- `oauth_broker.test.mjs`: test senza rete con provider finti, firma RSA generata durante i test, errori OAuth, protezione account, replay e integrità cifratura.
- `.github/workflows/google-calendar-oauth-staging.yml`: workflow PR dedicato ai test Node senza credenziali.

### Separazione dal prototipo Dart

Il file `oauth_staging.dart` rimane **prototipo dimostrativo non eseguito**: produce una transazione PKCE in memoria nel client. Non è utilizzabile così com'è con un callback server-side, perché il code verifier deve essere custodito e ritrovato sul **server**. Il broker Node rappresenta il percorso prescelto per un eventuale deployment Web; la futura integrazione Flutter dovrà usare l'endpoint backend `start` e **non** iniziare un proprio flusso OAuth concorrente. Prima di un uso reale il prototipo Dart va ritirato/adattato con relativi test.

## Requisiti indispensabili prima di distribuire

1. **Scegliere un vero host HTTPS di staging** in un progetto separato, valutando eventuali costi. NON usare l'endpoint Supabase di produzione né il progetto Google `My Maps Project`.
2. Creare un **host HTTP autenticato** che ricavi l'account tramite verifica server-side della sessione Supabase (non da parametri client) sia all'avvio sia al callback. Per il ritorno Android serve un flusso app→browser→backend verificato: non è ancora implementato.
3. Usare **storage persistente con TTL e atomic take** per le transazioni OAuth (state, nonce, verifier, proof) e storage account-scoped per link cifrati. Il `testOnlyInMemoryStores` è **solo per unit test** e NON è un backend.
4. Nel browser impostare il browser proof generato da `start` come cookie `HttpOnly; Secure; SameSite=Lax` e vincolarlo all'autenticazione server; niente segreti o token in URL/query, risposta Web o log. Per Android, la gestione del browser e della sessione necessita di adapter dedicato e QA.
5. Archiviare **client secret** del progetto `Anna Diary Calendar Test` e una chiave AES casuale di 32 byte in un *secret store* server-side del solo staging; mai in GitHub, Flutter, APK, backup o ChatGPT. Pianificare rotazione chiave, recovery e protezione replay.
6. Il backend deve verificare l'ID token, il Google subject e gli scope **effettivamente concessi**, senza equiparare Google `sub` al Supabase UUID. Il callback non deve mostrare token al client.
7. Ottenuto l'URL HTTPS effettivamente distribuito, registrare **esattamente quell'URL** nella sezione Redirect URI del client OAuth Web STAGING del progetto Google di test; non inventare host né copiare il redirect di produzione.
8. Prima di esportare appuntamenti: consenso separato e selezione owner-only; revisione privacy (inclusi sensibili), inventario storico Android B3 e deduplica, test dei casi Google 401/403/429, revoca, refresh token e multi-device. Nessuna cancellazione remota automatica.

## Test locali

Node.js 22:

```sh
node --check staging/google_calendar_direct/backend/oauth_broker.mjs
node --test staging/google_calendar_direct/backend/oauth_broker.test.mjs
```

Il successo dei test **non dimostra** un server deployed, OAuth funzionante, callback raggiungibile, account Google collegati, refresh persistente o eventi scritti. Non pubblicare la PR #199 e non avviare release/APK.

## Setup Cloud attestato dal proprietario (03/11/2026)

Progetto Google **`Anna Diary Calendar Test`**: Google Calendar API abilitata; OAuth External/Testing; due account autorizzati; `calendar.events.owned` e `calendar.calendarlist.readonly`; client OAuth Web STAGING creato, Client Secret custodito privatamente. **Redirect non ancora registrato.**

Progetto esistente **`My Maps Project`**: ospita il client login Google Supabase di produzione; non modificarlo.

## Fonti

- https://developers.google.com/identity/protocols/oauth2/web-server
- https://developers.google.com/identity/openid-connect/openid-connect
- https://developers.google.com/workspace/calendar/api/auth
- https://supabase.com/docs/guides/functions/development-environment
