# Anna’s Diary — Google Calendar Direct STAGING v1

**Status: PREPARATO SU BRANCH SEPARATO — NON INTEGRATO / NON ATTIVO.**

Branch: `staging/google-calendar-direct-prepared-v1`. Versione base: `main@88efdfa9a688f35585cf2760d131f7a6b0b9deb2`, APK corrente `1.0.0-rc.6+117`.

## Cosa è disponibile

- `calendar_staging.dart`: client Google Calendar API v3 tramite porte iniettate (HTTP, access token provider, archivio link), esportazione monodirezionale di appuntamenti, gestione eventi all-day e a orario tramite IANA timezone, update PATCH condizionale su etag, ID remoti deterministici e marker privati.
- `agenda_projection_staging.dart`: conversione controllata dei soli `AgendaItem` privati e appuntamenti, massimo 200 entro un anno; esclusi `SharedEntry`, attività, note, allegati, diario, ricordi e Vault.
- `test/google_calendar_staging_test.dart`: test locali deterministici con token e API **simulati**, nessuna chiamata a Google.
- Guardie esplicite: consenso Google, B3 Android disattivata, verifica preventiva dei precedenti export Android; nessuna cancellazione remota automatica, niente import canonico, niente sincronizzazione ciclica o in background.
- Google OAuth necessario in futuro: `calendar.events.owned` + `calendar.calendarlist.readonly`, preferenza minima per calendari di proprietà dell'utente. Per scrivere su calendari condivisi non posseduti potrebbe servire il più ampio `calendar.events` (decisione futura separata).

## Cosa è volutamente ASSENTE

- Nessun import dai moduli `lib/` di produzione: `lib/main.dart`, `lib/cloud_sync_service.dart`, `pubspec.yaml` e `tool/prepare_android_platform.py` non vengono modificati.
- Nessuna autorizzazione, rete, accesso al tuo Google Calendar o salvataggio token effettuati.
- Nessun provider token/refresh adapter collegato a Supabase, nessuna implementazione definitiva del trasporto HTTP cross-platform e nessuna persistenza sensibile attiva.
- Nessun toggle impostazioni, background job, account linking, gestione revoca utente o modifica delle attuali rotte di login. Non si considera integrata o pronta per produzione prima del collaudo su device.
- Nessuna garanzia di idempotenza assoluta tra dispositivi: Google raccomanda ID personalizzati ma documenta possibili collisioni non sempre rilevate in sistemi distribuiti.

## Decisione architetturale

**V1 proposto:** Anna’s Diary → Google Calendar (soli appuntamenti privati, unidirezionale); calendario Google → Anna’s Diary come proiezione read-only separata. La fonte canonica resta `AgendaStore`.

La B3 Android attuale scrive su `Calendar Provider`. Se la destinazione è un calendario Google, Android potrebbe aver già creato eventi su Google: **disattivare B3 non rimuove gli eventi già esportati**. Prima di accendere la via Google diretta, confrontare gli eventi preesistenti e decidere esplicitamente se lasciarli, collegarli o escludere il periodo storico. Il parametro obbligatorio `existingAndroidExportsReviewed` blocca il writer finché questa verifica non è stata confermata nel flusso applicativo. Non assumere che il marker Android corrisponda automaticamente a quello Google: sono distinti.

## Attivazione futura — azioni tecniche da completare

1. **Google Cloud, intervento utente:** selezionare il progetto OAuth già usato per Supabase; abilitare `Google Calendar API`; aggiungere gli scope minimi sopra indicati alla schermata consenso (o verificare i permessi effettivamente necessari); aggiungere gli account tester mentre l'app è in modalità test.
2. **OAuth, intervento assistente + consenso utente:** definire una richiesta di autorizzazione Calendar separata dal normale login di Anna; `openid email profile` non basta. Testare `providerToken`, `providerRefreshToken`, `access_type=offline` / `prompt=consent` secondo la versione Supabase in uso. Verificare refresh, revoca, cambio account, deep link, navigazione Web e ritorno Android. Trattare i token Google separatamente dalle sessioni Supabase; vietato salvarli in chiaro, log o SharedPreferences.
3. **Transport & secure link store, intervento assistente:** realizzare `GcalHttpPort` per Web/Android/iOS e `GcalAccessTokenPort` con refresh/expiry/revoca; implementare `GcalLinkPort` su storage cifrato/segregato per account e calendario. Prevedere timeouts e retry/backoff limitato per 429/5xx. Le porte presenti in questo staging sono interfacce, non provider live.
4. **Configurazione UI, intervento assistente:** impostazioni opt-in con scelta esplicita Google Calendar, stato permessi, anteprima dei cambiamenti, diagnosi e comando Disconnect. Non cambiare login Google standard né avviare B3 e Google direct contemporaneamente.
5. **Migrazione Android B3, assistente + approvazione utente:** inventario eventi Android già sincronizzati a Google, dry-run con quantità/duplicati, scelta sicura prima di inviare gli stessi appuntamenti tramite API diretta. Non cancellare eventi esistenti senza consenso.
6. **Validazione:** test offline + API sandbox/test account, identità account e time zone DST, retry, confitti ETag/409/412, cancellazioni esterne, revoca token, connessione instabile, cambio calendario, browser, device Android. Verificare l'APK firmato e almeno un ciclo sul telefono. Eventuale verifica Google per pubblicazione estesa resta un gate separato.

## Contratti di sicurezza del prototipo

- Fail-closed quando manca consenso, B3 è ancora abilitata o gli export precedenti non sono stati riesaminati.
- Eventi Google riconoscibili da `extendedProperties.private.annasDiarySourceHash`, senza esporre ID locale/account in chiaro. ID remoto deterministico `ad` + digest SHA-256; legame account+calendario+ID appuntamento.
- Prima del PATCH fare GET e verificare marker+ETag contro collegamento locale; `If-Match` sul PATCH; non sovrascrivere modifiche remote o eventi di altri utenti.
- Se il server ha già creato l'evento ma il salvataggio locale fallisce, il GET tramite ID deterministico recupera solo un evento con marker **e contenuto compatibile**; conflitto altrimenti.
- Non introdurre `events.delete`, aggiornamento di `AgendaStore` da Google, import di elementi condivisi, calendari di terzi non autorizzati o sincronizzazione bidirezionale.
- Google account di destinazione **non deducibile** dal solo ID Supabase: l'account Google autorizzato deve essere mostrato e confermato nell'app nella futura integrazione.

## Fonti provider (verifica 1 novembre 2026)

- Google scopes: https://developers.google.com/workspace/calendar/api/auth
- Events insert e ID personalizzati: https://developers.google.com/workspace/calendar/api/v3/reference/events/insert
- Extended properties private: https://developers.google.com/workspace/calendar/api/guides/extended-properties
- Supabase Google OAuth/token provider: https://supabase.com/docs/guides/auth/social-sign-in/auth-google
- Supabase Flutter OAuth: https://supabase.com/docs/reference/dart/auth-signinwithoauth

## Merge policy

**NON UNIRE questo branch/PR a `main` ora.** Il materiale è conservato come prototipo di integrazione dormiente per una successiva richiesta esplicita. I test CI su branch sono evidenze di compatibilità sorgente, non una certificazione Google Calendar reale. Un merge futuro richiederà una PR di attivazione distinta con token/permessi, audit sicurezza, test esatti, no duplicazione Android e QA fisica.
