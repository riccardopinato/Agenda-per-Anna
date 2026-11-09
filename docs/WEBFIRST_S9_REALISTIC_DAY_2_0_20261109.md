# Anna's Diary — Web-first Maxi-step 9 / Realistic Day 2.0

Data: 9 novembre 2026. Contratto di prodotto: [Product Bible](PRODUCT_BIBLE.md); task [#226](https://github.com/riccardopinato/Agenda-per-Anna/issues/226). SOLO Chat, Web-first. Nessun APK o cambio backend.

## Baseline e riuso
- Factory: `App-Factory-Core@d4ed1185d36d419228fba6b57a979cde308bd321`, `CURRENT.yaml` Master v27 / Golden Index v29. Golden pertinenti: App Shell/Responsive/Visual QA (DRAFT); CI/Web Deploy v2 (COPY-READY); Roadmap Fast + Continuous Maintenance (COPY-READY); AppLab QA (CERTIFIED PROCESS).
- Anna: `main@bee3b22b9c2e8a614efa9deeec32815102c78522` (S8 integrato, PR #284 source checks PASS). S9 conserva `RealisticDayAdvisor`, `CalendarFreeSlot`, `UnifiedAgendaEntry`, `AgendaStore`, la card già esistente, l'unico widget Home e le preferenze locali per account.
- **Già presenti prima di S9:** finestra visibile 09–21, calendario autoritativo/filtri, durata esplicita dei task come provenienza, buffer volontario 0/15/30/60, stato sconosciuto, avvisi calendari parziali, nudge opt-in, pausa 7 giorni e dismiss per giornata. Non aggiungere store, motori di preferenze, nuovi writer o nudge push.

## Difetto verificato e correzione circoscritta

Prima di S9, `RecordedTaskTime` sommava e mostrava la durata esplicita dei task, ma `findCalendarFreeSlots` considera **solo gli appuntamenti**. Quindi `usableMinutes = freeMinutes - bufferMinutes` presentava come ancora disponibile anche il tempo già impegnato da task cronometrati. La descrizione precedente «timed tasks already occupy calendar slots» era falsa rispetto al codice.

S9 conserva `freeMinutes` **come misura della disponibilità del solo calendario**, ma deriva gli slot residui sottraendo unicamente gli intervalli dei task attivi con **inizio/fine registrati**. L'unione di queste finestre viene ritagliata entro i soli slot calendario 09–21 non occupati da appuntamenti, al netto dell'ora attuale:

`bookedTaskMinutes = calendarOnlyFree - afterRecordedTasks`

`usableMinutes = max(0, calendarOnlyFree - bookedTaskMinutes - userBuffer)`

- Due task sovrapposti non vengono sottratti due volte; porzioni già occupate da appuntamenti non vengono sottratte di nuovo.
- Task senza entrambi gli orari, `start == end`, conclusi o external-event non diventano durata ipotetica: restano sconosciuti/fuori campo.
- Task che iniziano il giorno prima e finiscono dopo mezzanotte sono ritagliati entro la finestra attuale, se presenti nella vista autorizzata. La costruzione locale `DateTime` mantiene la semantica della data civile esistente e non inventa una durata cross-provider in presenza di orologi ambigui.
- Il `firstFreeSlot` dell'advisor non propone più slot occupati da task con orario noto. Rimane una **proiezione read-only**, non un salvataggio.
- Gli identificatori in conteggi/dedup vengono distinti per ambito `private:` e `shared:spaceId:`, evitando collisioni fra record visibili con lo stesso ID.
- Dopo le 21 o quando la finestra del giorno selezionato è trascorsa, si segnala `VISIBLE_WINDOW_ELAPSED`, non «calendario quasi pieno».
- UI testuale coerente in IT/EN/ES/FR/PT: tempo dopo task con orario + buffer, dettaglio minuti impegnati, distinzione da durata registrata totale. Il messaggio sui calendari esterni incompleti resta in vista.

**Nota separazione UI:** `showCalendarFreeSlots` conserva la sua semantica B2 calendar-only ed esplicita che le attività non bloccano quegli slot. Il riepilogo Realistic Day usa una proiezione più prudente, senza alterare le altre schermate o i writer di Calendar.

## Sicurezza, controllo utente e compatibilità
- Solo i `visibleEntries` conferiti dal filtro canonico possono influenzare il risultato; nessun accesso diretto a record nascosti, password, Vault o ciclo.
- Account switch: i buffer e nudge esistenti restano SHA256 per account e dispositivo, con controllo di completamento async, senza nuove chiavi o migrazioni. Nessuna conferma viene simulata: selezionare il buffer salva solo la preferenza locale.
- Nessuna rischedulazione o scrittura di task/eventi. L'interfaccia propone tempo e suggerimenti; l'editor canonico resta il solo owner di Salva.
- Calendari esterni potrebbero essere incompleti o non autorizzati: il valore non è una garanzia di disponibilità; Google Calendar Direct #199 resta bloccato, Privacy V2 #215 non cambia. Nudge off per default, pausa/ripresa reversibili.
- Nessuna API AI, modello ML, cloud, permission, entitlement, database, schema o release native.

## Matrice di regressione

| Scenario | Test automatizzato | Significato |
| --- | --- | --- |
| Appuntamenti + 2 task sovrapposti + duplicati | `webfirst_s9_recorded_capacity_test.dart` | Calendario separato; union task deduplicata |
| Slot consigliato dopo task reale | stesso | Mai suggerire task time come primo slot |
| Task 23:30 → 09:30 del giorno successivo | stesso | Solo sovrapposizione corrente 09:00–09:30 |
| Task sconosciuti/completati, input nascosti | stesso | Non inventare durate né leggere record esclusi |
| `now` 12:15, scaduto dopo 21:00 | stesso | Clipping, `VISIBLE_WINDOW_ELAPSED` |
| Appuntamenti 09–20 e task 18–21 | stesso | No double subtraction / no negative capacity |
| Sorgente e preferenze preesistenti | `realistic_day_guidance_p1_test.dart`, `realistic_day_buffer_test.dart`, `v107_realistic_day_advice_test.dart` | Contratto compatibile, senza nuovo writer |
| UI 320dp 2× nelle 5 lingue | `webfirst_s9_card_responsive_test.dart` | Card reale con fixture sintetica |
| Tap buffer 30m | stesso | Preferenza locale e task originario immutato |

### Gate e stato delle prove

S9 PR head: `flutter analyze`, full `flutter test` (inclusi test S9 e regressioni precedenti), Chrome Vault crypto, Flutter Web release, Web PR build dedicato (richiesto perché `lib/src/realistic_day_advice.dart` è cambiato), AppLab Source Gate, review senza blocker e merge se tutto verde. La pubblicazione Pages è successiva al merge su `main` e richiede `head_sha` identico per certificare la specifica release.

Senza prove nuove: PWA installate su due dispositivi, touch/screen reader, account switch live, calendari esterni reali, DST con timezone non UTC, frametime/performance e compatibilità offline sono `NOT_VERIFIED`; performance `NOT_MEASURED`; offline `DEFERRED_BY_USER`. I test CI dimostrano le invarianti dichiarate **solo in ambiente sintetico**.

## Criteri di follow-up
- Se appare un overflow, incoerenza lingua o persistenza del buffer non corretta su un dispositivo reale, raccogliere solo dati sintetici/tecnici e tracciare un issue separato.
- Verificare la parità fra calendario B2 (calendar-only) e capacità S9 (calendar + task) durante il test manuale, senza confondere i due significati.
- Issue #226 può essere chiusa come implementazione sorgente soltanto dopo exact-head CI/Pages; non dichiarare real-device certification finché non acquisita.
