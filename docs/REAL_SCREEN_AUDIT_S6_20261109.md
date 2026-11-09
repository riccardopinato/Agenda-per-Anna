# Anna's Diary — Web-first S6: audit mirato delle schermate realmente usate

Data: 9 novembre 2026 · Canale: Flutter Web/PWA · Esecuzione: solo Chat

## Baseline, vincoli e metodo

- App Factory centrale già fissata nella sessione: `riccardopinato/App-Factory-Core@a6d7ff36db7f70b03ccfdf02fa265049d31ae2f1`; CURRENT Master v27 / Golden Index v29.
- Repository di partenza: `Agenda-per-Anna@9f2c308099aef9ed584395e96c94afe53d648352` (S5, Pages e CI PASS).
- Audit sul codice reale delle schermate esistenti e test Flutter che istanziano i widget **realmente usati**, con dati sintetici. Non sono screenshot delle PWA fisiche né sessioni di browser automation su telefoni.
- Invarianti: niente refactor orizzontale, riscrittura UI, duplicati dei writer/route, modifiche a search core, Vault, autenticazione, dati utenti, sync condiviso, offline, migrazioni o APK.

## Matrice dei risultati

| Superficie | Evidenza sorgente | Problema circoscritto | Intervento S6 | Gate di accettazione |
| --- | --- | --- | --- | --- |
| Altro → Impostazioni → ricerca categoria | `lib/src/screens/settings_hub.dart`: `TextField(textInputAction: search)`, `ListView`, `_open` | Il submit Cerca non rilasciava il focus; lo scroll manteneva la tastiera, riducendo risultati visibili; la navigazione poteva mantenere focus della ricerca | `onSubmitted` unfocus, `keyboardDismissBehavior.onDrag`, unfocus prima del push; nessuna modifica a `_matches` o a destinazioni | Test widget su schermata Impostazioni a 320dp/2×, query e apertura Aspetto |
| Altro → Cerca | `lib/src/search_connections_domain.dart`: striscia filtri di altezza 46dp fissa e `DropdownButton` in `Row` non vincolato | Con font ingranditi e traduzioni lunghe il controllo poteva eccedere la striscia e l'ordinamento monopolizzare la larghezza, causando rischio di clipping/overflow | Altezza della striscia derivata da `MediaQuery.textScaler` con limite; select ordinamento `Flexible` e `isExpanded`, testo opzioni con ellissi; filtri/ranking invariati | Test widget della schermata Cerca a 320dp/2× in IT/EN/ES/FR/PT, nessuna eccezione di layout |
| Impostazioni → Aspetto e colori | `lib/src/screens/appearance_colors.dart`: `Row` con due `Expanded` per Annulla/Applica in fondo al `ListView` | Le etichette potevano restringersi troppo in 320dp / font 2×; trascinando il contenuto con la tastiera HEX aperta la tastiera restava presente | Riutilizzo delle stesse azioni esistenti: colonna se disponibile < 310dp o testo grande, riga originale altrimenti; dismiss-on-drag nel ListView | Test widget vero Aspetto 320dp/2×, Annulla e Applica presenti, nessun nuovo writer |

Le criticità sono **dedotte da vincoli di layout verificati nel codice**, non da screenshot/test fisici dell'utente; nessun reclamo runtime è stato attribuito impropriamente. Non cambiare copy, tap semantics o percorsi salvo quanto sopra.

## Esclusioni dopo audit

- Oggi/Calendario/Ricordi: già beneficiari delle correzioni S2/S5 alle primitive editoriali; **nessuna nuova regressione provata in questo audit**, quindi non sono stati riscritti.
- Navbar principale/+Crea: lasciata invariata dopo gate S5.
- Spazio condiviso: test utente bidirezionale online e persistenza riferiti positivi; nessun intervento ai dati/sync. Offline è `DEFERRED_BY_USER`.
- Cassaforte privata: fuori scope, non aprire o serializzare contenuti durante la QA.

## Stato delle prove

- `SOURCE_IMPLEMENTED` dopo commit; `FLUTTER_WIDGET_PASS / PR_WEB_PASS / APPLAB_PASS / MAIN_CI_PASS / PAGES_PASS` solo dopo ciascun esito reale, con SHA e run ID.
- `REAL_DEVICE_PWA_QA = NOT_VERIFIED`: da provare su due telefoni, nelle cinque lingue e con caratteri grandi. `PERFORMANCE_COLD_WARM = NOT_MEASURED`; nessun miglioramento FPS/TTI dimostrato.
- Test automatizzato nuovo: `test/ds6_webfirst_s6_real_screen_audit_test.dart`.

## Prossimo controllo manuale sintetico

Su PWA installata: impostare testo grande, aprire Altro → Impostazioni, cercare “palette”, confermare ricerca dalla tastiera, scorrere e aprire Aspetto; tornare, aprire Altro → Cerca, passare tra filtri e ordinamenti; aprire Aspetto fino ai pulsanti finali. Confermare assenza di overflow/clipping, tastiera chiusa quando previsto e azioni raggiungibili. Ripetere con lingue/frasi lunghe senza usare dati personali per gli screenshot.
