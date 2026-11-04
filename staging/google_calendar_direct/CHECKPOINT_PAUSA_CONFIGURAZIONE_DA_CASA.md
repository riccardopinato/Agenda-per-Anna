# Anna's Diary — Google Calendar STAGING — Checkpoint sospensione

**Decisione del proprietario: 03/11/2026.**
**STATO DEL 03/11: sospeso; ripresa del 04/11 documentata separatamente.**

**AGGIORNAMENTO 04/11:** il proprietario ha ripreso la procedura e confermato i quattro secrets inseriti. La preparazione del backend prosegue soltanto su branch non distribuito. Consulta [STATUS_2026-11-04.md](STATUS_2026-11-04.md) per lo stato successivo. La conferma dei secrets NON autorizza OAuth reale, redirect, deploy attivo, merge o release.

Questa fase riguarda credenziali, segreti di cifratura e abilitazione OAuth reale.
Non eseguire ulteriori operazioni di configurazione dei segreti, attivazione OAuth,
registrazione dei redirect Google, test con account reali o deploy di funzioni
OAuth attive prima di una nuova richiesta esplicita del proprietario.

## Ultimo stato verificato

- Repo: `riccardopinato/Agenda-per-Anna`.
- PR [#199](https://github.com/riccardopinato/Agenda-per-Anna/pull/199):
  **OPEN / DRAFT / DO NOT MERGE**, branch
  `staging/google-calendar-direct-prepared-v1`.
- Ultimo head di sviluppo con gate completi:
  `ace7afe73d0a54a7c14cea262f8ccb77143eb63e`;
  Development checks, AppLab Source Gate e Google Calendar OAuth staging
  security tests **SUCCESS** sul medesimo commit.
  Questo checkpoint documentale genera un commit successivo; verificare
  esiti CI e SHA aggiornati prima di dichiarare ulteriori PASS.
- Supabase produzione: `agenda-per-anna`,
  `pxsxlorntswypdbeerzw`; **non modificare** il provider Google esistente.
- Supabase staging: `anna-calendar-staging`,
  `pdanpljacyozslrutsor`, organizzazione
  `fzieziuyodhojemtzeya`, regione `eu-central-1`.
  Supabase ha preventivato **0 USD/mese** prima della creazione.
- In staging sono state applicate le migrazioni per le tabelle private
  `gcal_stage.oauth_pending`, `gcal_stage.oauth_completions` e
  `gcal_stage.oauth_links`, con RLS attiva e nessun accesso
  `anon`/`authenticated`. Ultimo controllo: **tutte vuote**.
- Supabase Edge Function `gcal-oauth-callback`: **ACTIVE v1, ma BLOCCATA**,
  restituisce 503 per operazioni OAuth e non legge codici né token.
- `index_ready.mjs`, il router HTTP, il flusso a due fasi, gli adapter SQL
  e i test sono **solo sorgente sul branch**, non distribuiti come backend OAuth
  attivo. Non confondere PASS dei test mock con verifica HTTP end-to-end.
- Google Cloud TEST: `Anna Diary Calendar Test`, progetto
  `anna-diary-calendar-test`; Calendar API attiva, OAuth External/Testing,
  2 tester (proprietario e Anna), scope `calendar.events.owned` e
  `calendar.calendarlist.readonly`, Web client
  `Anna's Diary Calendar STAGING` creato.
  Il proprietario ha conservato il Client Secret privatamente.
  **Redirect OAuth non registrato**. Nessun consenso/test Google reale.
- Nessun APK, merge, Google Calendar write, upgrade a pagamento o release
  autorizzati da questo checkpoint.

## Da riprendere SOLO da casa — sequenza operativa

- [ ] 1. Aprire [Supabase staging — Edge Function Secrets](https://supabase.com/dashboard/project/pdanpljacyozslrutsor/functions/secrets).
  Verificare di essere nel progetto `anna-calendar-staging`, NON produzione.
- [ ] 2. Configurare `ANNA_GCAL_STAGING_WEB_CLIENT_ID` con il **Client ID**
  del client Web Google STAGING; il Client ID non è un segreto ma va usato
  solo nell'ambiente corretto.
- [ ] 3. Configurare `ANNA_GCAL_STAGING_WEB_CLIENT_SECRET` con il **Client Secret**
  già salvato privatamente. **Non incollare il valore in chat o su GitHub.**
- [ ] 4. Recuperare dal progetto Supabase di produzione la chiave
  **publishable/legacy anon** (non `service_role` né secret) e configurare
  `ANNA_GCAL_PRODUCTION_PUBLISHABLE_KEY` solamente nei segreti Edge
  del progetto di staging.
- [ ] 5. Generare sul PC di casa **32 byte crittograficamente casuali**,
  codificarli in Base64, inserire il risultato in
  `ANNA_GCAL_STAGING_AES256_KEY_BASE64`. Esempio PowerShell locale:

      ```powershell
      $b = New-Object byte[] 32
      $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
      $rng.GetBytes($b)
      $rng.Dispose()
      [Convert]::ToBase64String($b)
      ```

  Incollare direttamente in Supabase, **mai in chat, GitHub, log, screenshot o APK**.
- [ ] 6. Concludere revisione tecnica e runtime QA (Deno/Postgres,
  validazione sessione Supabase, TLS, scambio code, permessi, revoca/refresh,
  limiti traffico e privacy). La configurazione dei segreti da sola
  **non autorizza l'attivazione**.
- [ ] 7. Solo dopo approvazione separata per test OAuth reale:
  distribuire e verificare la callback HTTPS completa di staging, quindi
  registrare **esattamente il suo URI effettivo** nel Google Cloud TEST.
  **Non usare** `https://pxsxlorntswypdbeerzw.supabase.co/auth/v1/callback`
  e non registrare oggi la callback bloccata.
- [ ] 8. Collaudare con i due account Google autorizzati e il dispositivo
  fisico, account switch/replay/scadenza, B3 storico e nessun duplicato.
  L'export Google resta disattivato finché privacy, selector owner-only e
  approvazione prodotto non saranno conclusi.
- [ ] 9. Solo con nuova autorizzazione esplicita e tutti i gate superati,
  valutare una PR separata di integrazione/rilascio. **PR #199 resta Draft**.

### Interruttore da NON impostare

`ANNA_GCAL_STAGING_ENABLE=approved-for-live-oauth-testing`

Non configurare questa variabile e non attivare l'OAuth reale durante la pausa.

## Istruzioni per la ripresa

Quando il proprietario scriverà **«Riprendiamo Google Calendar di Anna's Diary dal checkpoint di casa»**:
1. rileggere questo checkpoint e lo stato reale di PR #199 e staging;
2. confrontare l'ultimo head e i CI, senza presumere che siano invariati;
3. fornire istruzioni guidate, **un passaggio alla volta**, per il pannello
   Supabase e Google Cloud; non chiedere mai di inviare valori segreti;
4. verificare sicurezza, prezzi e gate prima di qualsiasi deploy attivo;
5. mantenere tutto in **SOLO Chat**, senza Work.

Riferimenti:
- [Roadmap generale](../../docs/ROADMAP.md)
- [Contratto OAuth a due fasi](supabase/TWO_PHASE_OAUTH_CONTRACT.md)
- [Stato Supabase staging](supabase/README.md)

**Questo checkpoint non autorizza attività in background o completamento automatico.**
