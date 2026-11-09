# Anna's Diary — Web-first Maxi-step 8: S7 evidence closure + S9 readiness

Data: 9 novembre 2026. Ambito: SOLO Chat, Flutter Web-first, source/docs/regressioni sintetiche; nessun APK, nessuna modifica alla produzione Supabase, al Vault, ai dati o al billing.

## Baseline e authorità
- Factory: `riccardopinato/App-Factory-Core@2b3ae9e01764b7504980efca34f2543949dc7b89`, CURRENT Master v27 / Golden Index v29.
- Product: `docs/PRODUCT_BIBLE.md`, `AGENTS.md`, `docs/ROADMAP.md`.
- Branch S8 originato da `Agenda-per-Anna/main@5d7dfa8475d7cdbfa766a451c7198ba4f796385b`; i successivi documenti/template Notion restano preservati.
- Golden consultati: CI/Web Deploy v2 (COPY-READY); AppLab QA v1 (CERTIFIED PROCESS, source-only); App Shell/Responsive/Visual QA v1 (DRAFT); Release Reality/Physical Validation (DRAFT); Roadmap Fast + Continuous Maintenance (COPY-READY).

## S7: prove separate per livello

| Livello | Sorgente | Evidenza | Stato |
| --- | --- | --- | --- |
| PR implementazione S7 | [#280](https://github.com/riccardopinato/Agenda-per-Anna/pull/280), head `06923c7e56c6d62e621c79825224c6f078ca9202` | merged su `main@7d22e5f2e5710599fdcd56c785b6ebe7bf6c33f0` | MERGED |
| Development checks PR S7 | head `06923c7` | [run 42546933657](https://github.com/riccardopinato/Agenda-per-Anna/actions/runs/42546933657) | SUCCESS |
| AppLab Source Gate PR S7 | head `06923c7` | [run 42546933648](https://github.com/riccardopinato/Agenda-per-Anna/actions/runs/42546933648) | SUCCESS (SOURCE ONLY) |
| Web PR build S7 | head `06923c7` | [run 42546933645](https://github.com/riccardopinato/Agenda-per-Anna/actions/runs/42546933645) | SUCCESS; non è certificazione di Pages production |
| Post-merge Development CI e Pages S7, *esattamente* `7d22e5f` | push main | Gli identificativi/risultati degli specifici due run push non sono stati recuperabili dalla superficie connessa: la query disponibile per workflow per commit espone solo run PR; la semplice presenza del sito non prova lo SHA deployato | NOT_VERIFIED — reperire run ID e confrontare `head_sha` |
| PWA installate su due telefoni, keyboard/back/a11y/5 lingue | Test manuali A+B | Nessuna nuova evidenza device/version/browser/risultato per S7 | NOT_VERIFIED |
| Cold/warm, frame/scroll, screen reader | Misurazione fisica | Nessun campione tecnico affidabile S7 | NOT_MEASURED |
| Shared online e persistenza | Riferito dall'utente, test pre-S7 non vincolato a SHA | Preservare `USER_REPORTED_MANUAL_PASS`; non estendere a QR, privacy ACL o nuovo S7 | USER_REPORTED_MANUAL_PASS parziale |
| PWA offline start/edit/resync | Richiesta dell'utente | Non provare né bloccare gli step Web-first | DEFERRED_BY_USER |
| APK, Android nativo, Play/iOS | Fuori scope S8 | Nessuna build o distribuzione autorizzata per S8 | NOT_EXECUTED |

## Regressioni S8
- Nuovo `test/ds6_webfirst_s8_shell_focus_contract_test.dart`: FocusNode sintetico nel FocusScope della **MainShell reale**; cambio destinazione e apertura `+Crea` rilasciano il focus; la capture viene annullata senza scritture.
- Secondo widget test: le quattro destinazioni reali `Altro → Ricordi → Messaggi → Oggi` a 320dp conservano un'unica shell/dock senza eccezioni di framework.
- I test S2-S7, cinque lingue, responsive/2×, Chrome Vault e Web release rimangono nella suite canonica. Un widget test non è una tastiera fisica, un test Browser PWA installata o una prova dei dati utente.

### Gate della PR S8
PR head esatto: Development checks (analyze, full Flutter tests, Chrome Vault e Web release), AppLab Source Gate e review senza blocker. Il workflow dedicato `Deploy Anna's Diary Web` è **path-filtered** (`lib/**`, asset, Web push, config): per una PR di soli test/documentazione come S8 il relativo `build-web` è **NOT_APPLICABLE**, non FAIL e non un controllo universale obbligatorio. Se un file Web di prodotto viene modificato, il workflow dedicato deve invece riuscire sullo SHA esatto prima del merge (vedere `docs/governance/ANNA_MAIN_PROTECTION_RUNBOOK.md`). Solo dopo merge controllato. La prova post-merge su `main` richiede Development checks e Pages SUCCESS sullo **stesso nuovo SHA**, separatamente dalla fonte della PR. Non scrivere PASS prima dei risultati reali. La pubblicazione Web deve essere tracciata da run/commit; nessun deploy manuale bypass.

## Accettazione PWA S7/S8 ancora aperta
Seguire `docs/STEP2_PWA_TWO_DEVICE_ACCEPTANCE_20261107.md` con test sintetici, PWA installate e due dispositivi, annotando modello/OS/browser, SHA effettivo visibile, lingua, light/dark, dimensione viewport e risultato:
- A/B: avvio Web, Oggi/Calendario/Indietro, Altro/Cerca/Indietro, Impostazioni/Aspetto/Indietro×2, Ricordi e tab Messaggi; tastiera non resta sopra la schermata dopo cambio tab.
- A/B: `+Crea` si apre una sola volta, Annulla non crea dati; verifica layout 320/360/390dp e testo 1×/2×, RTL solo se supportato dal prodotto.
- A/B: test IT/EN/ES/FR/PT, dark e palette personalizzata; screen reader/tastiera; target interattivi e back browser.
- Tre campioni cold/warm solo con fixture e strumenti privacy-safe, senza dichiarare baseline/threshold non stabiliti.
- Offline W09 rimane `DEFERRED_BY_USER`. QR inviti/scadenza, ACL, notifiche iPhone, Google API #199 e Privacy #215 restano gate separati.

## Maxi-step 9: proposta esecutiva (NON implementata in S8)

**Target**: [issue #226 Realistic Day](https://github.com/riccardopinato/Agenda-per-Anna/issues/226), P1 aperta; preservare il motore esistente `lib/src/realistic_day_advice.dart`, la finestra visuale 09–21, `AgendaPreferences`, Calendar read-only e gli owner canonici di task/eventi.

**Invarianti**: solo suggerimenti locali/deterministici; nessuna AI/API/cloud; niente secondo scheduler, nuovo store o reschedule automatico. Non attivare Google Calendar Direct #199 né Privacy V2 #215. L'esclusione Vault, cycle, shared/non-authorized records, revoca e account switch è obbligatoria.

### S9-A — Dati e contratto
Leggere i modelli reali di durata/ora per task e appuntamenti. Usare durata soltanto se registrata; marcare `UNKNOWN_DURATION` se mancante e non inferire durata dal conteggio di attività. Preferenza facoltativa per buffer con default non invasivo, account-aware e reversibile.

### S9-B — Calcolo sicuro
Derivare intervalli espliciti e buffer locali, controllare sovrapposizioni reali, fuso/DST, eventi oltre mezzanotte e il calendario esterno parzialmente visibile. In caso di informazioni insufficienti: mostrare incertezza e non giudicare la giornata `libera`.

### S9-C — UX e agency
Anteprima di suggerimenti motivati, azione `ignora` / `rimanda` facoltativa; nessuna scrittura prima di conferma esplicita. Riusare le card editoriali DS6, modalità Classic e localizzazioni esistenti.

### S9-D — Test
Fixture per durate note/sconosciute, buffer zero/non zero, sovrapposizioni, mezzanotte, DST, filtro privato/condiviso/esterno, account switch e cancellazione. Test widget 320–900dp/1×–2×, cinque lingue, no salvataggio implicito, suite completa e gates exact-head.

### S9-E — QA e rilascio
Rilevare eventuali regressioni reali su Web e valutare QA manuale; PR protetta e Pages sul commit finale. Non aprire automaticamente nuove autorizzazioni cloud, non distribuire APK, non promuovere stati di sicurezza o runtime senza evidenza.

**Fuori S9**: Vision Board, template Notion, mini-planner Noi, ML addestrato, modifiche a Vault, billing, OAuth e sync. Sono ricerche/step indipendenti, non condizioni per la giornata realistica.
