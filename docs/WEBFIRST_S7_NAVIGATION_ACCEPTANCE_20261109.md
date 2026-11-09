# Anna's Diary — Web-first S7: navigazione end-to-end (real Flutter widgets)

Data: 9 novembre 2026 · revisione S8, 9 novembre 2026

## Fonte e perimetro

- Factory baseline **App-Factory-Core@2b3ae9e01764b7504980efca34f2543949dc7b89** (CURRENT Master v27, Golden Index v29). Componenti pertinenti: App Shell/Responsive/Visual QA (DRAFT, non certificato), CI/Web Deploy (COPY-READY), AppLab Source QA (CERTIFIED PROCESS).
- Anna baseline **Agenda-per-Anna@d82e2d12593683cf8bd5af8c05ee33ab19906f56**, precedente S6 green e Pages deploy.
- Partenza da navigazione originale Flutter `MainShell` con 4 page index, slot Crea centrale esclusivo, calendario come MaterialPageRoute e push per Cerca/Impostazioni/Aspetto. Non aggiungere router, writer o IndexedStack alternativi.
- Nessun codice/sistema del sync condiviso, dati locali, auth, Vault, offline, notifiche, APK o policy Android coinvolti.

## Audit cause/rischi e modifiche

| Contesto reale | Evidenza nel sorgente | Correzione | Invariante |
| --- | --- | --- | --- |
| MainShell: Oggi ↔ Messaggi ↔ Ricordi ↔ Altro | `_selectDestination` cambia pagina conservando i widget in `IndexedStack` e NON rilasciava il focus della scheda precedente | `FocusScope.of(context).unfocus()` solo quando l'indice cambia, prima di `setState` | 4 pagine, ordine, callback e stato persistente invariati; nessuna tastiera IME trattenuta intenzionalmente sulla pagina non visibile |
| Pulsante Crea centrale nel dock o rail | `_openCentralCreate` apriva la capture canonica senza unfocus preliminare | Unfocus prima dell'animazione e dell'unico `showUnifiedCapture` | Nessun secondo writer, stesso giorno e stesso entry point, nessun contenuto creato dai test |

I rischi sono verificati dalla forma del codice sorgente. I test automatici verificano navigazione reale sintetica, non sessioni PWA in browser fisico.

## Matrice S7 di verifica

| Percorso | Verifica CI | Stato dopo PR #280 |
| --- | --- | --- |
| Oggi → Messaggi → Ricordi → Altro → Oggi | Tap su dock e presenza reali tab `MainShell` | PARTIAL_SOURCE_CI_PASS_PR_280 (Messaggi aggiunto alle regressioni S8) |
| Oggi Classic → Calendario → Indietro | Route `CalendarHubScreen`, ritorno shell, nessun duplicato | SOURCE_CI_PASS_PR_280 |
| Altro → Cerca → query sintetica → Indietro | Router canonico `PersonalSearchConnectionsScreen`, ritorno Altro | SOURCE_CI_PASS_PR_280 |
| Altro → Impostazioni → Aspetto → Indietro → Indietro | 2 route distinte e ritorno allo stesso Altro | SOURCE_CI_PASS_PR_280 |
| Oggi → Crea → annullamento | Unico modal `showUnifiedCapture`, nessun writer attivato | SOURCE_CI_PASS_PR_280 |
| Desktop 900dp → rail Altro | Route reale nel shell wide senza dock | SOURCE_CI_PASS_PR_280 |
| 320–390dp / 1–2× / 5 lingue | Esistenti S2, S5, S6 più smoke S7; nessuna certificazione fisica | SOURCE_CI_PASS_PR_280 (suite 5 lingue/scale: fixture sintetiche) |
| Focus/tastiera/scroll/back/VoiceOver su 2 PWA installate | Richiede utenti e device, non simulato dal solo Flutter CI | NOT_VERIFIED |
| Prestazioni cold/warm e offline | Non misurate / offline esplicitamente rinviato | NOT_MEASURED / DEFERRED_BY_USER |

## Evidenza PR #280 e limiti di verifica S8

- La [PR #280](https://github.com/riccardopinato/Agenda-per-Anna/pull/280) è **MERGED**: head `06923c7e56c6d62e621c79825224c6f078ca9202`, commit di merge `main@7d22e5f2e5710599fdcd56c785b6ebe7bf6c33f0`.
- GitHub Actions sullo SHA *head della PR*: [Development checks #42546933657](https://github.com/riccardopinato/Agenda-per-Anna/actions/runs/42546933657) **SUCCESS**, [AppLab Source Gate #42546933648](https://github.com/riccardopinato/Agenda-per-Anna/actions/runs/42546933648) **SUCCESS**, [Web PR build #42546933645](https://github.com/riccardopinato/Agenda-per-Anna/actions/runs/42546933645) **SUCCESS**.
- **S7 post-merge / Pages exact `7d22e5f`: VERIFIED (09/11/2026).** [`Development checks #42547406861`](https://github.com/riccardopinato/Agenda-per-Anna/actions/runs/42547406861) e [`Deploy Anna's Diary Web #42547407327`](https://github.com/riccardopinato/Agenda-per-Anna/actions/runs/42547407327) sono entrambi `event=push`, `conclusion=success`, con `head_sha=7d22e5f2e5710599fdcd56c785b6ebe7bf6c33f0`. Nel run Pages i job `build-web` e `deploy` sono SUCCESS, incluso lo step `Deploy to GitHub Pages`. Prova di CI/deploy automatizzato sullo SHA esatto, non di browser/PWA/VoiceOver fisici né di verifica HTTP indipendente.
- Nuovi test S8 in `test/ds6_webfirst_s8_shell_focus_contract_test.dart` controllano focus sintetico del MainShell su cambio tab/Creazione e il percorso reale delle 4 destinazioni a 320dp; non certificano device né salvataggi.
- L'utente ha riferito sincronizzazione condivisa **online** e persistenza per contenuti provati, ma non la sua esecuzione sull'esatto SHA S7. QR, ACL, browser Back installato, VoiceOver, misure fisiche: **NOT_VERIFIED**; cold/warm: **NOT_MEASURED**; offline: **DEFERRED_BY_USER**.
- [S8 evidence + proposta S9](WEBFIRST_S8_EVIDENCE_AND_S9_PLAN_20261109.md) contiene link e gate; nessun APK/Store/AI/Google API/Privacy V2 viene sbloccato.

## Regressioni e criteri di chiusura

- Test nuovo: `test/ds6_webfirst_s7_navigation_journeys_test.dart`. I widget usano store sintetici senza dati utente reali.
- Riutilizzare suite completa Flutter (`flutter analyze`, `flutter test`, Chrome Vault crypto, Web release), AppLab Source Gate, PR Web build. Conservare l'evidenza del commit head esatto, del merge e del deploy Pages con stesso SHA.
- Non indicare `WEB_REAL_DEVICE_PASS` fino a prova A/B su smartphone. Nessuna nuova APK generata; pipeline automatica APK firmata può eseguire solo preflight e *saltare* la build con versionCode invariato.

## Checklist rapida su telefono (opzionale, non blocca S7)

Aprire Web PWA con connessione: Oggi → Calendario → Indietro, poi toccare Ricordi, Altro → Cerca → Indietro, Impostazioni → Aspetto → Indietro due volte, Crea → annulla; verificare che l'eventuale tastiera si chiuda cambiando tab, che la pagina precedente sia corretta e che i contenuti già salvati siano ancora presenti. Ripetere almeno una volta con testo 2× e con tema scuro. Non testare scritture offline né esporre dati privati in screenshot o log.
