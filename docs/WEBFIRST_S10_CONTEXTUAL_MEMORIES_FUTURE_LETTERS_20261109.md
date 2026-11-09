# Anna's Diary — Web-first Maxi-step 10: Ricordi contestuali + Lettere al futuro

Data: 9 novembre 2026. Modalità: **SOLO Chat**, Flutter Web-first, sviluppo su branch e PR, nessun APK, nessun nuovo provider, database o API AI.

## Baseline

- **Factory CURRENT**: `riccardopinato/App-Factory-Core@d4ed1185d36d419228fba6b57a979cde308bd321`; Master v27, Golden Index v29, Registry v2.
- **Anna**: branch S10 da `Agenda-per-Anna/main@f4b2baf95e062777da4ad23c0e40bbf8ed8cb6c1`, preservando S9 integrato e UX/template in corso.
- **Autorità**: `AGENTS.md`, `docs/PRODUCT_BIBLE.md`, `docs/ROADMAP.md`. Golden consultati: CI/Web Deploy (COPY-READY), AppLab Source QA e Code Hygiene (CERTIFIED PROCESS), Entity Lifecycle/Trash e Release Reality (DRAFT, non promossi).
- **Ammissione prodotto**: richiesta utente S10 + issue [#224](https://github.com/riccardopinato/Agenda-per-Anna/issues/224) per Ricordi contestuali; idea `AD-NL26-03` Lettera futura proveniente da catalogo PROPOSTE, ora autorizzata **solo in questo perimetro personale**. Nessuna approvazione automatica di altre idee, nuove CAP o Golden.

## Analisi di origine (non riscrivere)

La funzione **Ricordi contestuali** era già integrata e collaudata come sorgente in [PR #241](https://github.com/riccardopinato/Agenda-per-Anna/pull/241):
- `ContextualMemorySelector.choose` usa esclusivamente `DiaryBlockReference` forniti dal chiamante e motivazioni esplicite `anniversary/person/place`;
- massimo **due** suggerimenti, deterministici e diversificati, opt-in disabilitato di default; quota giornaliera hash per account, sospensione 7 giorni, esclusione permanente reversibile, niente notifiche.
- UI in Ricordi `Per te` Classic/Editorial DS6; nessuna seconda sorgente, nessuna sincronizzazione condivisa implicita.

La funzione **Lettere al futuro** era già nel diario canonico in [PR #218](https://github.com/riccardopinato/Agenda-per-Anna/pull/218):
- `future_letter_v1` su `DiaryBlock(type: note)` in `AgendaStore.journals` (giorno futuro), max 10.000 caratteri;
- data a scelta, lettura anticipata con conferma, Cestino già canonico e conservazione nel normale backup privato;
- la data **non costituisce blocco cifrato** e il contenuto resta leggibile dal diario ordinario. Nessuna promessa di consegna crittografica o notifica push.

## S10-A — Ricordi contestuali: tutela e spiegabilità

- **No cross-feature leak:** lettere con tag `future_letter_v1` non entrano nei suggerimenti contestuali, nemmeno dopo scadenza; la lettera si gestisce solo con la superficie di prodotto prevista. Conservati filtri `archived`, date future, tag health/cycle/Vault/credential e esclusioni.
- **Collegamenti autentici:** il motivo `person` è ammissibile solo se il `personId` esiste ancora tra le persone del profilo attivo. Il motivo `place` resta legato al riferimento di luogo effettivamente salvato nel blocco; niente sentiment analysis o nuove inferenze.
- **Cambio account:** tracciato sia owner hash sia `accountScopeEpoch`, che cambia anche dopo ciclo A→B→A. La UI rimane nascosta durante scope non pronto/shared-only e scarta risposte asincrone di uno scope precedente. Preferenze persistenti account-scoped e hash-only immutate.
- **Spiegazione esistente:** data sorgente + ragione localizzata in IT/EN/ES/FR/PT; tap verso la schermata del giorno sorgente, non teaser del testo senza consenso. Il massimo resta due al giorno e l'opt-in resta off.

## S10-B — Lettere al futuro: riuso e controllo accessi

- **Un solo writer:** `savePersonalFutureLetter` usa ancora `AgendaStore.saveJournal`, ora con `Cap0160TagEditGuard` e `accountScopeEpoch`. Salvataggi da dialoghi vecchi A→B→A non entrano nel profilo sbagliato, né in modalità shared-only. Salvataggi falliti non vengono dichiarati riusciti.
- **Risoluzione prima di leggere:** `currentPersonalFutureLetter` verifica che l'ID esista nello stesso journal corrente, non sia archiviato, sia nota/tag corretti, e che il profilo sia disponibile. Dopo conferma di apertura anticipata l'identità viene ricontrollata.
- **Redazione live:** il dialog di lettura reagisce alle notifiche canoniche del negozio; su cambio profilo/rimozione record mostra soltanto `non disponibile`, non il testo della precedente lettera.
- **Unica lista:** `personalFutureLetters` non espone lettere archiviate o in modalità shared-only, usa ancora gli stessi journal e nessuna tabella.
- **Ritorno in app:** la schermata Lettere distingue `In attesa della data` da `Pronta da leggere`; `Ricordi > Per te` mostra una sola tile neutra **solo quando almeno una lettera è pronta**. Non mostra contenuto, titolo personalizzato o dati sensibili nella card. Tap apre la schermata esistente, non legge automaticamente la lettera.
- **Form di scrittura:** pulsante Save disabilitato su testo vuoto/salvataggio in corso, segnala fallimenti in modo non sensibile; non aggiunge sottosistemi di notifiche native. Testo, data e Cestino seguono i path canonici.
- **Privacy boundary:** le lettere non vengono rese condivise; eventuale sincronizzazione privata resta quella preesistente di `AgendaStore`, senza destinatari, mail, Cloud Functions o nuove autorizzazioni. La data è un promemoria **in-app**, non un timer di consegna affidabile a dispositivo spento.

## S10-C — Matrice QA

| Invariante | Evidenza automatica richiesta |
| --- | --- |
| Esclusione `future_letter_v1`, riferimenti persone eliminati, archived/sensitive/future | `test/webfirst_s10_contextual_future_letters_test.dart` + `contextual_memory_p2_test.dart` |
| Determinismo/limite 2 e ragioni date/person/place | Suite contextual originale e nuovo test |
| Guest → B → guest con vecchia form | Test `Cap0160TagEditGuard` e persistenza canonica |
| Nota futura visibile in lettera, non in shared-only/archived | Test journal canonico e record resolver |
| Lettura in corso + switch account | Widget test dialog/visibilità del testo |
| IT/EN/ES/FR/PT | Test label e vecchie fixture locali |
| Lettera pronta nello stesso archivio Ricordi | Tile neutra `s10-future-letters-due` + preview senza testo |
| PWA, browser fisici, account sync tra dispositivi, performance, offline | NOT_VERIFIED / NOT_MEASURED / offline DEFERRED_BY_USER |

## Gate di chiusura

Per PR #S10 servono sullo **stesso head SHA**: Development checks (Flutter analyze, suite completa, Web Vault crypto, Web release), Deploy Anna's Diary Web PR build (perché cambia `lib/**`), AppLab Source Gate, review senza blocker, branch aggiornato/mergeable. Eseguire merge squash solo dopo PASS di tutti i gate. Main-push CI e Pages vanno attestati separatamente sul commit di merge; PR Web build **non** vale come prova di Pages production.

**Non certificato automaticamente**: PWA installate su due dispositivi, accessibilità screen reader, Web browser con account switch reale, sync/backups reali, performance, notifiche push o offline PWA. Privacy V2 [#215](https://github.com/riccardopinato/Agenda-per-Anna/pull/215) e Google Calendar [#199](https://github.com/riccardopinato/Agenda-per-Anna/pull/199) restano indipendenti DRAFT/BLOCKED. Nessun APK/AAB/Store.

## Prossimo Maxi-step

S11 candidate: template personali e Vision Board nel Diario/Sketchbook già canonici, previa ammissione per-app/visual approval, conservando privacy e ownership. Non implementato in S10.
