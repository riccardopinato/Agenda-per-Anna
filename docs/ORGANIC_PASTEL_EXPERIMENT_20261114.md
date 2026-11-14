# Organic Pastel — Esperimento di design, non approvazione di prodotto

**Stato: CANDIDATE / PREVIEW ONLY**. L'utente ha chiesto una prova
riuso-first da confrontare con l'immagine originale prima di decidere se
conservare il nuovo stile. Nessuna autorizzazione a merge o deploy produzione.

## Reference / source
- Riferimento grafico: concept Organic Pastel Diary (14/11/2026),
  quadrante alto-sinistro, due schermate Oggi e Messaggi.
- Design-App: `UI-UX/PER_APP_STILI_2026-11-13.md`.
- App Factory Core: `c5adc147046beb7024629466d10eeb799c3c2619`,
  Master v27, Golden Index v29.
- Anna's Diary base: `a1f61b5d572ab6d0f6750a03bf00bf2c0a2a615a`.
- DS6, Product Bible, original routes, writers, privacy, 5 languages,
  system/light/dark, HSV and reduced motion remain authoritative.

## Parallel implementation lanes on one isolated branch
1. **Visual foundation:** a native CustomPainter with original layered
   hills, sun, grass and botanical corner leaves; semantic colors and
   a reusable accessible seven-day strip. No network, remote assets,
   SVG dependency, photographs or fake diary records.
2. **Oggi:** insert authentic scenic strip and real selected-week navigation
   into the existing PlannerScreen editorial path. Preserve greeting, diary,
   all canonical planning cards, date-selection callbacks, focus, records,
   personal memory and Classic reversible mode.
3. **Messaggi + dock:** quieter group hero, natural paper-style Cards and
   decorative non-person avatar; preserve real group names, owner/member
   indicators, unread counts, access, renaming, QR, Supabase, login and
   Personalizza module toggle. Original Create action remains single owner.
4. **QA:** source/widget tests, exact-head Flutter analyze/test/Web build,
   accessibility and screenshot gate. Do not claim "pixel perfect" or
   real-device acceptance without measured screenshots.

## Explicitly out of scope
- No Vault source or internal screen changes.
- No changes to `AgendaStore`, account, Supabase, schema, sync, backups,
  writers, invites or memberships.
- No changes to actual user media.
- No APK/AAB or production Web/Play publication.
- **DO NOT MERGE** without explicit post-review user go-ahead.

## Manual decision gate
Compare actual Flutter screenshots at 390×844 against the supplied reference
and at 320×640 for overflow; test IT/EN/ES/FR/PT, textScale,
dark/HSV/custom palettes, RTL where relevant, and saved shared groups.
Record KEEP / REVISE / REJECT, with a reversal path to existing Classic mode.

## Revisione mirata — Liquid Pastel Glass dock
- Solo la barra inferiore Organic Pastel e il pulsante Crea centrale.
- Quattro capsule con tinti salvia/pesca/lavanda/cielo mescolati al
  ColorScheme del dispositivo (anche HSV e dark); superficie translucida,
  gradienti speculari, bordo riflettente, ombre di elevazione e animazioni
  ridotte quando richiesto dal sistema.
- Bolla Crea sollevata, con riflesso e feedback di pressione. Lo stesso
  callback `_openCentralCreate` rimane l'unico proprietario di Capture.
- La Classic resta invariata. Nessuna nuova dipendenza, asset remoto,
  preferenza o modifica dati.
- Gate ancora aperto: collaudo visuale su 320dp, 390dp, testi grandi,
  dark/HSV, IT/EN/ES/FR/PT e approvazione esplicita prima del merge.

### Liquid Pastel Glass — revisione UX su feedback
- Rimosso dal tasto centrale il riflesso orizzontale bianco, oltre al
  BackdropFilter specifico della bolla: il colore opaco sfumato evita di
  mostrare la linea del dock attraverso il pulsante.
- Le quattro destinazioni non sono più capsule con bordo e ombra, ma
  sfumature radiali senza margini visivi netti, fuse nella superficie del dock.
  Solo la destinazione attiva ha un colore più concentrato.
- Restano invariati touch target, callback, route e la variante Classic.
- Gate invariato: test CI su commit esatto, screenshot di confronto e decisione
  KEEP / REVISE / REJECT prima di qualsiasi merge.

## Prova top hero — immagine full-bleed + saluto personale
- Solo variante Organic Pastel / vista Oggi; Classic e Messaggi restano invariati.
- La watercolor già inclusa in app occupa la larghezza disponibile senza
  margini e raggiunge l'estremo superiore del viewport; niente bordo/radius.
- Dissolvenza a doppia estremità verso lo stesso colore del canvas; titolo
  e due azioni originali in sovrimpressione con safe inset Android/iOS.
- Il saluto rimane `approvedTodayGreeting(languageCode,
  preferences.displayName, hour)`: nessun nome dedotto o nuova persistenza.
- La nuova testata scorre assieme alla home, non rimane uno sfondo fisso.
  Tutte le altre card mantengono il gutter orizzontale di 20dp.
- Per la comparazione, screenshot Flutter con nome **Giulia** sintetico;
  nessun account o contenuto personale importato.
- Invariati l'Organic dock approvato provvisoriamente, i dati, le route,
  il tasto centrale Crea e il veto al merge/deploy fino al review visuale.
- Verificare 320/390dp, status insets, fontScale e 5 lingue (fallback
  senza nome incluso) prima dell'eventuale approvazione KEEP.

## Revisione hero — qualità e collasso durante lo scroll (14/11/2026)
- Diagnosi verificata: il WebP decorativo originale è **360 × 120 px**
  (RIFF/WebP VP8, rapporto 3:1), perciò il vecchio `BoxFit.cover` in
  una testata alta 232dp lo ingrandiva e ritagliava sensibilmente.
- Ora il panorama occupa un'altezza derivata dalla larghezza
  `availableWidth / 3`, dunque conserva proporzioni e inquadratura
  senza zoom verticale; la zona alta è riempita da un cielo CustomPainter
  disegnato alla risoluzione fisica dello schermo.
- Hero a scorrimento coordinato: `CustomScrollView`,
  `SliverPersistentHeader(pinned: true)` con estensione di
  `topInset + 232` → `topInset + 132` (100dp di compressione).
  Il saluto locale + nome profilo e le due azioni rimangono visibili
  e ancorate alla safe area; tutte le card scorrono sotto.
- Il ListView originale della modalità non Organic conserva padding,
  comportamento e navigazione. Dock, Create, contenuti, storage e sync
  sono invariati.
- QA: controllo 320/390dp, colore/scuro, testo ingrandito e tap originali,
  più screenshot Flutter espanso/compattato con un nome sintetico.
- Asset effettivamente integrato: nuovo acquerello originale offline
  `AnnaOrganicPastelWatercolor.bytes` WebP **576 × 192**, **10.9 KB**,
  sostituisce il precedente 360 × 120 di circa 3.5 KB. Il painter
  rimane fallback di sicurezza; test RIFF/VP8 verifica le dimensioni.
- Distinguere il vero incremento dei pixel sorgente dall'eliminazione
  dell'upscaling: sono due correzioni complementari.
- PR in bozza, **DO NOT MERGE** senza confronto e via libera dell'utente.
