# UX Step 7 — Dodici settimane che contano (Anna's Diary)

**Stato:** UX_DRAFT_PENDING_APPROVAL / NON INSTALLABILE / NON ACQUISTABILE. Data: 10/11/2026. Factory baseline: App-Factory-Core@2953e9b50f5f43fbd5a1702cb41785a4235592a5 (Master v27, Golden Index v29).

[Prototipo HTML interattivo — 12 capitoli, dati inventati](PROTOTIPO_DODICI_SETTIMANE.html) · [Manifest statico Core anna_twelve_week_reflection_research.json](https://github.com/riccardopinato/App-Factory-Core/blob/main/contracts/template_engine_v1/examples/anna_twelve_week_reflection_research.json).

## Scelta UX sottoposta ad approvazione

1. **Scopri:** card editoriale coerente DS6 rose / Lora + Manrope; 12 tappe senza streak, punteggi, AI o compiti obbligatori. Etichetta «Concept · non acquistabile · solo privato».
2. **Le settimane:** selettore navigabile di 12 capitoli con domande **originali** e dati completamente sintetici; non rappresenta memorie, eventi o diario già presenti.
3. **Personalizza:** titolo personale, data di inizio inserita esplicitamente, intenzione facoltativa, scelta di includere la riflessione settimanale. Nessuna notifica automatica e nessuna data implicita.
4. **Riepilogo:** mostra destinazione e opzioni; solo azione **simulata**, senza scrivere un DiaryBlock. Versione futura: una normale nota privata per la prima settimana quando l'utente decide di scrivere; tappe successive aperte consapevolmente, non 12 record generati tutti insieme.
5. **Riavvio / sospensione:** le tappe non impongono calendario o regressioni; un capitolo saltato resta accessibile. L'eventuale rimozione del pack non cancellerà alcun diario.

## Invarianti Product Bible e owner canonici

- **DiaryBlock** e `AgendaStore.journals` rimangono la source of truth. Riutilizzare `lib/src/diary/diary_templates.dart`, `showDiaryTemplatePicker`, editor e `saveJournal`, senza un nuovo database, nuovo writer, nuova tab o engine di streak.
- Preservare **scope privato** predefinito, filtro account, guardie contro ritorni da editor stale e cambio account A→B→A. Non introdurre contenuto nel **Noi ♡**, nessun accesso a **Private Vault** / ciclo / password e nessuna sincronizzazione automatica.
- Identità manifest: `it.riccardopinato.anna.twelve_week_reflection`; `anna.twelve_week_reflection.v1` è solo adapter previsto, **non** codice funzionante.
- Cinque lingue prodotto IT/EN/ES/FR/PT da testare quando integrato: questo HTML è soltanto un mock IT e non prova traduzioni Flutter.
- Nessun billing, nuovo SKU o RevenueCat product. Il tier `paid_once` del manifest è un'ipotesi di prodotto ancora **research_candidate**; rituali e galleria free esistenti rimangono gratuiti.

## Gate da superare prima di implementare il template in Flutter

- Approvazione visiva e di prodotto esplicita: card, 12 tappe, tono narrativo, calendario opzionale, flusso sul giorno/diario, valore originale distinto dai rituali gratis.
- Write plan con conferma per un solo `DiaryBlock` alla volta, `installation_request_id` e receipt idempotente/owner-bound, staging + rollback contro save failure, una sola voce al retry, nessun effetto su Annulla.
- Compatibilità data civile e DST, date prima/fuori dalla finestra, locale, offline, rotazione, riapertura, backup/restore, editing/revoca del modello, account A→B→A.
- QA responsive 320/360dp, zoom test 200%, voice reader, tastiera, focus, contrasto Light/Dark, riduzione animazioni, cinque traduzioni.
- Non aprire l'editor con un salvataggio automatico, non impostare notifiche senza esplicito consenso, non assegnare automaticamente contenuto a Noi ♡. Browser preview non equivale a dispositivo fisico né AppLab/Play.

**Evidenza di questa PR:** documentazione + HTML locale con sole transizioni UI simulate, nessun accesso a rete, account, storage, database o servizi del runtime. Nessun adapter, entitlement, SKU, release o Golden/E5 è stato certificato.
