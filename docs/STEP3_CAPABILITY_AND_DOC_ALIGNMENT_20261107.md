# Anna's Diary — Step 3 | Allineamento capability e documentazione

**Data:** 7 novembre 2026. **Stato:** AVVIATO, primo crosswalk verificato; riconciliazione del registro canonico NON ancora chiusa.

## Source of truth
- Factory Core: [989c5123](https://github.com/riccardopinato/App-Factory-Core/tree/989c5123c62c07d1dd85a3c520f0d04b7fe3f543), CURRENT.yaml Master v27, Golden Index v28.
- App: [dc601002](https://github.com/riccardopinato/Agenda-per-Anna/tree/dc601002c3308b6579c30945867638b84ad35de9), CI + Web Pages PASS. Flutter Web/PWA usata come canale principale.
- Catalogo: [1a57e339](https://github.com/riccardopinato/Idee-app-Archivi-riferimenti/tree/1a57e3393b2c74fa61f815864220d4a71f9a6777); [rapporto 74 associazioni](https://github.com/riccardopinato/Idee-app-Archivi-riferimenti/blob/main/12-CAPABILITY-E-IMPLEMENTAZIONI/AUDIT_ANNA_STEP3_RECONCILIAZIONE_2026-11-07.md).
- Ambito prodotto: Product Bible, senza nuove approvazioni implicite.

## Quadro attuale del catalogo
74 associazioni Anna: **8 già integrati, 52 da verificare, 14 da valutare**. Questi numeri sono lo stato dei derivati del registro, NON quantità di feature mancanti. Prove aggiornate sono riportate nel crosswalk; il JSON canonico e le viste derivate devono essere aggiornati insieme in un follow-up protetto.

| CAP | Implementazione app rilevata | Stato del contratto completo |
| --- | --- | --- |
| CAP-0152 fuzzy | Fallback bounded nel motore esistente; test cap0152 | PARZIALE: grapheme/Unicode, alias/luoghi, ACL due account da validare |
| CAP-0160 TF-IDF | Motore locale 5 lingue, draft/save/account guard; test dedicati | PARZIALE rispetto alla CAP generalizzata che contempla anche DE; Web/consumer QA da completare |
| CAP-0015 Search | Filtri/sort/evidenza e fix bug query vuota #270, CI PASS | Browser tap/input e performance con archivio reale da verificare |
| CAP-0025 Responsive | Test real Flutter 320–900dp PASS | Split-view, accessibilità e screenshot fisici non certificati |
| CAP-0069 Visual QA | Comparator e matrix CI | 70 baseline + 70 candidate screenshot approvate assenti |
| CAP-0067 Release | Web main @ dc601002, APK ARM64 +129 storica | Web e APK non sono lo stesso SHA; Android fisico separato |

## Perimetro e priorità
- **Non duplicare:** fuzzy, tagger, ricerca, Inbox, shell, media, localizzazione, sync, calendari, backup.
- **Non promuovere:** screenshot tool PASS -> visual PASS; source/CI PASS -> physical PASS; donor -> Certified Golden; prova di una CAP -> tutte le 74 CAP.
- **Conservare:** 5 lingue effettive IT/EN/ES/FR/PT; Android/Google Calendar Direct #199 e Privacy V2 #215 non autorizzati al merge.
- **Idee future e non approvate:** CAP-0093 checklist da note, CAP-0147 home reversibile, CAP-0120 alt-text; non implementare prima di una decisione di prodotto.

## Sequenza per completare lo Step 3
1. Inserire nel JSON canonico prove app-scoped di SOURCE_PARTIAL e delta FULL per CAP-0152/0160 senza falsi DEVICE.
2. Rigenerare tutto con scripts/build_catalog.py e scripts/build_status_views.py nel repo catalogo; verificare --check/test prima del merge.
3. Incrociare le 74 associazioni con test, codice attuale e prove reali man mano ottenute; conservare gli storici.
4. Tenere Step 2 APERTO: UI/visual/performance Web, due PWA; nessun APK continuo.
5. Registrare audit Step 4 separato in STEP4_BACKEND_PRELIMINARY_AUDIT_20261107.md. Nessuna migrazione o interruzione del servizio.

**Esito di questa PR:** solo chiarezza documentale, nessuna modifica al motore applicativo, ai dati o al backend.
