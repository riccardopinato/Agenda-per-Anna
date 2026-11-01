# Anna's Diary — candidate 1.0.0-rc.6+116, physical acceptance

**Aggiornamento verificato (2026-11-01): ARTIFACT BUILT / PHYSICAL NOT VERIFIED.** GitHub Actions ha completato con **SUCCESS** il workflow di rilascio firmato [#41262693723](https://github.com/riccardopinato/Agenda-per-Anna/actions/runs/41262693723) sul source SHA `6380af49d2dd0e35db747e7862456b4ac6bf6a87`. Preflight versionCode monotono, configurazione firma stabile, build ARM64, preparazione identita fisica e upload artefatto: **PASS**. Artefatto GitHub disponibile: `annas-diary-light-arm64`, ID `13065409792` (ZIP 20.471.451 byte). Verificare il contenuto del manifest, APK hash, impronta del certificato e reale compatibilita con l'installazione +115 sul dispositivo prima di dichiarare **PHYSICAL PASS**. Tutti i casi V116-01…V116-12 restano **NOT VERIFIED**.

_Snapshot storico pre-build: RELEASE CANDIDATE PLANNED / APK NOT BUILT; superato dal workflow sopra._

## Identita e rilascio

- Flutter version: `1.0.0-rc.6+116` (Android `versionCode=116`, superiore al +115 installato).
- Package invariato: `com.riccardopinato.agenda_per_anna`.
- Stable signing invariato: workflow autorizzato `.github/workflows/auto-signed-arm64.yml` esegue il preflight di `Development checks` su `main` e invoca `sideload-arm64.yml` solo sullo SHA verificato, se il build number e' cresciuto rispetto al primo parent.
- Source revision: `6380af49d2dd0e35db747e7862456b4ac6bf6a87` (main esatto, validato dal workflow). Run: [#41262693723](https://github.com/riccardopinato/Agenda-per-Anna/actions/runs/41262693723). Physical manifest, APK SHA-256 e signing certificate SHA-256: **DA VERIFICARE DAL PACCHETTO**, non inferiti dalla sola esecuzione CI.
- Artifact previsto: `annas-diary-light-arm64` / `Anna-Diary-arm64-release.apk` / `PHYSICAL_CERTIFICATION_MANIFEST.json`.
- Requisito: installazione IN PLACE sopra +115, senza disinstallazione, wipe o sostituzione della firma. Dati e Cassaforte devono restare intatti.

## Test fisici richiesti per le novita

| ID | Scenario | Stato |
| --- | --- | --- |
| V116-01 | APK artefatto corretto, firma confrontata, aumento +115 -> +116 sullo stesso package, dati invariati | NOT VERIFIED |
| V116-02 | Calendario e Oggi integri, UI5/tema/ricordi/backup/ricerca senza regressioni | NOT VERIFIED |
| V116-03 | Evento privato *passato* -> azione «Conserva un ricordo» (A1) -> bozza; annulla non scrive | NOT VERIFIED |
| V116-04 | A1: Salva -> un solo ricordo nel diario, ripeti/modifica senza duplicati | NOT VERIFIED |
| V116-05 | A1: Trash/restore e privacy della nota, nessuna fuga in area condivisa | NOT VERIFIED |
| V116-06 | Evento privato -> «Prepara l'appuntamento» (A2), aggiungi note e più checklist, salva/riapri | NOT VERIFIED |
| V116-07 | A2: spunta, deseleziona, aggiungi/rimuovi voci; contenuto visibile anche nel normale editor evento | NOT VERIFIED |
| V116-08 | A2: annulla, cambio account, evento rimosso, conflitto nota; nessuna perdita di testo o scrittura errata | NOT VERIFIED |
| V116-09 | A2: evento esistente (orario, ricorrenza, reminders, categoria, stato) non viene alterato; nessuna notifica imprevista | NOT VERIFIED |
| V116-10 | A2: Trash/restore appuntamento e note/checklist; persistenza offline dopo force-close/riavvio | NOT VERIFIED |
| V116-11 | Scenari nativi di Cassaforte, QR e sincronizzazione 2 dispositivi, se ripetuti, con esito registrato per scenario | NOT VERIFIED |
| V116-12 | Cinque lingue: IT/EN/ES/FR/PT; tastiera, accessibilità, focus/text scale, schermi stretti | NOT VERIFIED |

## Record fisico

```text
date:
deviceModel:
androidVersion:
sourceSha: [da workflow +116]
runUrl:
apkSha256: [dal manifest]
certificateSha256: [dal manifest e installazione precedente]
installedBefore:
installedAfter:
scenario:
observed:
result: PASS | FAIL | BLOCKED | NOT VERIFIED
evidence: [solo log/screenshot redatti, senza dati personali]
```

L'esito generale positivo riferito dall'utente per **+115** non si trasferisce automaticamente al nuovo artefatto +116, che contiene A1 e A2. Non inferire Play Billing/RevenueCat/Google Play real purchase da test sideload.
