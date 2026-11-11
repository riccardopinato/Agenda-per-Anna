# S14 — Anna's Diary · Vision Board: pacchetto operativo di collaudo due PWA

**Preparato:** 11/11/2026. **Factory:** App-Factory-Core `ee72dbb1b0de2cd71bc4aac42c350853c6915159` (Master v27, Golden Index v29).
**Repository sorgente al bootstrap:** `Agenda-per-Anna@6d2e33f2a0d6f78b51d0c8b38c32f0528a235638`.
**Stato:** `TEST_PLAN_READY`; **zero nuovi risultati fisici**. Non dichiarare `PHYSICAL_PASS`, `PWA_CERTIFIED` o deploy `VERIFIED` senza prova reale.

## Autorità e ambito
- Matrici canoniche esistenti: [S13 16 casi](WEBFIRST_S13_VISION_BOARD_PWA_ACCEPTANCE_20261110.md), [S11-E 14 casi](WEBFIRST_S11E_VISION_BOARD_HARDENING_PWA_QA_20261110.md), [due PWA generale](STEP2_PWA_TWO_DEVICE_ACCEPTANCE_20261107.md), [issue #297](https://github.com/riccardopinato/Agenda-per-Anna/issues/297).
- Questo pacchetto **non sostituisce** le matrici: materializza i 30 identificatori in un unico ledger strutturato, ne verifica completezza/formato e dà ordine di esecuzione. Le sovrapposizioni tra S13 e S11-E sono intenzionali; registrare prove per entrambe, o riferirsi alla stessa evidenza solo se l'azione e il setup coincidono realmente.
- Nessun codice Flutter modificato, nessuna nuova funzionalità, APK, Play, modifiche ad account, Vault, cloud, schema, offline-PWA o media degli utenti.
- URL configurato: https://riccardopinato.github.io/Agenda-per-Anna/. Il commit sorgente del branch **non** prova da solo il commit servito da Pages o installato su A/B. Acquisire workflow Pages release e identificatore visibile, se disponibile; altrimenti scrivere `BUILD_IDENTITY_NOT_VERIFIED`.

## Preparazione sicura (prima di agire)
1. Due telefoni **reali**, indicati solo `A` e `B`, con PWA installata (non una semplice scheda browser). Annotare modello/OS/browser-versione/modalità installazione, timezone Europe/Rome e stato connettività.
2. Usare **due profili di test distinti** e note, nomi, date, foto JPEG/PNG e ricordi **sintetici**. Mai usare diario reale, foto personali, Vault, credenziali o dati di Anna. Non pubblicare account ID, QR, token o password.
3. Chiudere editor e salvare eventuali modifiche **prima** di refresh. Conservare backup privato testato prima di prove di Cestino/restore. Ripristinare su profilo di test isolato, mai sopra dati personali.
4. Sul sito confermare deploy Pages del codice applicativo effettivamente richiesto; annotare `deployedBuildSha` **solo se verificato**. Il merge del presente pacchetto documentale non genera per definizione una nuova build runtime.
5. Copiare [template evidence JSON](qa/vision_board_two_pwa_template.json) in un **file locale privato**. Non committare risultati contenenti dati personali, screenshot, media o backup. Usare solo riferimenti redatti o hash non sensibili.

## Ordine esecutivo e arresti
**Fase A — release/preflight:** S13-01, PWA-01/02; controllare PWA A/B, identità release, nessuna bozza pendente. Se la build non è identificabile, segnarlo e non promuovere la certificazione.

**Fase B — P0 isolamento e recupero:** S13-02/06/08/09/10/11/12, PWA-05/06/07/08/09/14.
- Preparare una board con 30 fotografie sintetiche e un ricordo collegato; registrare conteggi, ID applicativi **di prova** e hash dei file **solo in registro privato**.
- Ripetere A→B→A con editor aperto, cambio filtro Personale→Solo condiviso, Cestino e ripristino. La board di A non deve apparire in B né in Noi ♡, e una callback vecchia non deve scrivere.
- Prova media GC: aprire due editor, importare in bozza, annullarne uno, salvare l'altro; chiudere/riaprire. Nessun media mancante o asset orfano attribuito impropriamente.
- Backup ZIP/JSON: verificare file esterni, hash/associazioni e restore su profilo vuoto; provare una copia intenzionalmente corrotta con contenuti sintetici. Deve essere rifiutata senza dati parziali presentati come completi.
- **Se uno di questi scenari fallisce, classificare `BLOCKING_NOW` e sospendere l'accettazione.** Non aggirare un fallimento cancellando lo storage della PWA.

**Fase C — operatività/UX:** S13-03/04/05/07/13/14/15, PWA-03/04/10/11/12. Provare gesture, pan/zoom estremi, testo/frecce, 320/360/390dp/tablet, 5 lingue IT/EN/ES/FR/PT, light/dark, keyboard e screen reader effettivo. La Vision Board è monoscena; il vecchio Sketchbook mantiene pagine.

**Fase D — misure reali:** S13-16 (30 foto) e PWA-13 (20 foto) su A/B: annotare cold/warm open, durata salvataggio, frame time/jank e memoria solo se effettivamente misurati; nessuna soglia fittizia o PASS generico.

## Scheda prova e validatore
Ogni scenario del JSON precompilato ha: `id`, `status`, `priority`, `devices`, `action`, `expected`, `observed`, `testedAt`, `testerRef`, `evidenceRefs`, `testedOn` (dispositivi realmente provati), `metrics`.
Stati ammessi: `NOT_VERIFIED`, `NOT_MEASURED` (solo performance), `BLOCKED`, `FAIL`, `PASS`.
- Un `PASS` richiede una descrizione osservata, data ISO UTC/offset, riferimento operatore, almeno un riferimento di prova non sensibile e `testedOn` con **tutti i dispositivi obbligatori** (campo `devices` canonico non modificabile). Per le due prove performance richiede anche metriche **finite e positive** `coldMs`, `warmMs`, `saveMs`, `memoryMiB`; `NaN` e infinito non sono validi.
- `BLOCKED` e `FAIL` richiedono `observed` e `testerRef`; mai convertire automaticamente in PASS.
- `python3 tool/validate_vision_board_pwa_evidence.py docs/qa/vision_board_two_pwa_template.json` verifica il **template**, non l'avvenuto collaudo.
- `python3 tool/validate_vision_board_pwa_evidence.py /percorso/privato/risultati.json --require-complete` verifica solo la **completezza formale** di un ledger passato da operatori reali. Il tool **non può autenticare foto, build PWA, dispositivi o esecuzioni fisiche** e non concede alcuna certificazione.
- I test di schema sono `python3 -m unittest tool/test_visual_vision_board_pwa_evidence.py` (in CI tramite discovery `test_visual*.py`). Non sono test PWA.

## Evidenza, privacy e decisione
Per ogni caso: timestamp, A/B, app/build verificata, precondizioni sintetiche, azione, atteso, osservato, PASS/FAIL/BLOCKED, prova sicura e riproduzione. Se non è stato provato, mantenere `NOT_VERIFIED`/ `NOT_MEASURED`.
- Screenshot: oscurare ID, URL privati, dati personali, foto vere e token. I file di backup restano privati; non allegare binari con contenuti sensibili alla issue.
- Una differenza PWA installata vs browser tab è evidenza diagnostica, non un PASS.
- Aprire PR correttive per FAIL P0/P1 riproducibili; aggiornare la [issue #297](https://github.com/riccardopinato/Agenda-per-Anna/issues/297) con soli ID, stato, SHA verificato e link a prova redatta.
- Condizione chiusura: casi P0/P1 eseguiti, blocchi risolti e rieseguiti, verificatore umano responsabile, prova release reale, nessuna dichiarazione indebita di offline-PWA o APK.

**Livello raggiunto con questo commit:** pacchetto di test e validatore di evidenza predisposti. `PHYSICAL_DEVICE_VERIFIED` resta **NOT_VERIFIED**.
