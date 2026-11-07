# Anna's Diary — Step 2 | Protocollo collaudo due PWA, 7 novembre 2026

**Status: NOT EXECUTED / REAL_DEVICE_EVIDENCE_PENDING.** Questo protocollo non costituisce evidenza di PASS. Sorgente Flutter Web app `dc601002c3308b6579c30945867638b84ad35de9` (Pages [PASS](https://github.com/riccardopinato/Agenda-per-Anna/actions/runs/42402256546)); documentazione a commit più recente non cambia i byte della Web app. Factory per questa esecuzione `8ff583e598b2e55bb4edc44e8f42b243a967b710`, Master v27/Golden Index v28.

## Requisiti e preparazione

- Due dispositivi reali con la **PWA installata** e due account di prova distinti, se i test condivisi sono autorizzati. Non pubblicare email, nomi, token, foto, documenti, Vault o contenuti reali in issue/CI.
- Prima del refresh controllare bozze/scritture in sospeso. Chiudere e riaprire la PWA solo dopo conferma del salvataggio.
- Annotare per ciascun test: tester A/B; device model/browser/iOS-Android; viewport o scaling; data; modalità rete; route; risultato PASS/FAIL/BLOCKED; riproducibilità e versione Web visibile. Un test effettuato in una tab Chrome non vale per la PWA installata.
- Usare solo contenuti sintetici chiaramente riconoscibili; non inserire dati personali. Test su Android nativo, iOS Web Push, Vault/biometria e RevenueCat rimangono gate separati.

## Test set prioritario (eseguirli su A e B)

| ID | Scenario | Atteso / condizioni di fallimento |
| --- | --- | --- |
| W01 | Apri PWA da chiusa, visita Oggi e Altro | Nessun loading infinito; layout e dock accessibili; nessun testo troncato |
| W02 | Altro → Cerca con indice vuoto o query vuota | Nessuna eccezione o blocco; prompt/filtro e input usabili (fix #270) |
| W03 | Cerca `c`, `cena`, refuso `cenna` su dati sintetici | Solo titoli ammessi in ricerca a un carattere; ordine/risultati coerenti; nessuna voce Vault |
| W04 | Inbox: crea, etichetta, rinomina, riapri e filtra | Dati riaperti integri dopo riavvio e distinzione per account |
| W05 | Crea → Evento sul giorno selezionato, riapertura calendario | Data corretta, nessun writer duplicato, gesture/tastiera non coprono Salva |
| W06 | Ricordi, Timeline, Mappa e anno con media sintetici | Scroll e immagini stabili, nessun contenuto non autorizzato |
| W07 | Aspetto: palette standard/HSV, tema chiaro/scuro, testo grande | Persistenza dopo riapertura; contrasti adeguati, niente overflow |
| W08 | Spazio condiviso: codice scaduto / valido tra due account sintetici | Server owner corretto, revoca rispettata; nessun accesso cross-space |
| W09 | Offline breve, scrittura locale, ritorno online | Stato sync veritiero; riconciliazione senza duplicati o perdita; non fare logout mentre dati in sospeso |
| W10 | Salvataggio e riapertura dei contenuti dopo restart PWA | Persistenza verificata; se sync fallisce, diagnostica accurata |

## Performance riproducibile (non raccogliere tracce con dati privati)

Registrare, per A e B separatamente, **3 campioni cold** (PWA chiusa e riaperta) e **3 warm** (navigazione interna) per apertura Oggi, Cerca/risultati, Ricordi con media sintetici e calendario. Per ogni campione rilevare dispositivo, browser/versione, stato rete, tempo a contenuto interattivo, reattività dopo scroll e eventuali blocchi. I dati mancanti sono `NOT_MEASURED`; nessuna soglia arbitraria determina PASS fino a una baseline concordata. Annotare memory snapshots solo con fixture sintetiche e nessun dato di contenuto.

## Verifica responsive e sicurezza minima

Quando possibile: 320×640, 360×780 con 1,6× font, 390×844, 800×1100, 900×1100; light/dark, una palette personalizzata, reduced motion, tastiera, ruotazione. Privacy: testo Vault non deve emergere da Cerca, notifiche o screenshot generali. Test Web non certifica Keystore/FLAG_SECURE Android.

## Evidenza da compilare (senza dati riservati)

`date | source/deploy | A/B | device/browser | test_id | expected | observed | PASS/FAIL/BLOCKED/NOT_VERIFIED | repro | perf_ms_if_measured`

Un test non eseguito resta **NOT_VERIFIED**. I risultati soggettivi sono `USER_FEEDBACK`, non `PERFORMANCE_CERTIFIED`. Nessuna pubblicazione di screenshot della Cassaforte.
