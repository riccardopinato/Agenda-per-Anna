# Anna's Diary — release candidate +115 / collaudo fisico

**Stato al 2026-11-01: ARTIFACT BUILT / PHYSICAL NOT VERIFIED.** Questa checklist aggiorna il riferimento operativo al build reale `+115` senza alterare o cancellare i precedenti verbali della v1.08 `+112`. Non dichiara avvenuto nessuno dei test.

## Provenienza dell'APK

| Campo | Valore verificato da sorgente/Actions |
| --- | --- |
| Product/variant | Anna's Diary / stable-signed ARM64 sideload |
| Version | `1.0.0-rc.6+115` |
| Package | `com.riccardopinato.agenda_per_anna` |
| Source SHA built | `31b66ba96d66a3ca3984a3c19061c4f1bfc9f9c7` |
| Workflow | [Build lightweight ARM64 sideload APK #41248307448](https://github.com/riccardopinato/Agenda-per-Anna/actions/runs/41248307448) · success |
| Artifact expected | `annas-diary-light-arm64`, `Anna-Diary-arm64-release.apk` e `PHYSICAL_CERTIFICATION_MANIFEST.json` |
| Manifest artifact SHA-256 | **DA LEGGERE DAL MANIFEST**, non inferire |
| Signing certificate SHA-256 | **DA LEGGERE DAL MANIFEST E CONFRONTARE COL TELEFONO**, non inferire |
| Current main after signing workflow commit | `fbfc9dc445590fd8652cc7414bebbcd2865c6074` (`versionCode` invariato +115) |
| Automatic signed workflow on current main | [#41249818053](https://github.com/riccardopinato/Agenda-per-Anna/actions/runs/41249818053), preflight PASS, `signed-apk` SKIPPED per `+115 -> +115`; **nessun APK di fbfc9dc** |

**Precondizioni:** usare l'APK originale del run indicato, non un rebuild con chiavi diverse. Registrare versione dell'app realmente installata prima del test. Eseguire backup verificato, non disinstallare, non cancellare cache/storage per forzare il PASS; se la firma installata non corrisponde al certificato del nuovo APK, STOP e `BLOCKED`. Non creare dati personali fittizi nell'account dell'utente. La v1.08 precedente descriveva update `+111 -> +112`, non applicarla letteralmente al `+115` corrente.

## Matrice fisica

| Scenario | Test / comportamento atteso | Evidenza |
| --- | --- | --- |
| P115-01 | Aggiornamento in place dalla versione stabile realmente installata; package/signature corrispondono, dati/diario/media preservati | NOT VERIFIED |
| P115-02 | Cold start, ripristino app, Oggi / Messaggi / Ricordi / Altro + Calendario | NOT VERIFIED |
| P115-03 | Calendario mese/settimana/giorno; selezione e timeline eventi senza alterare dati | NOT VERIFIED |
| P115-04 | `+Crea`: azioni testo, foto, allenamento, voce, sketch, più menu e modelli | NOT VERIFIED |
| P115-05 | Salvataggio controllato di un vero contenuto consapevole; persistenza dopo riavvio e Trash senza cancellazione involontaria | NOT VERIFIED |
| P115-06 | Ricordi, ricerca globale, filtri, Then & Now, mappe con veri media/luoghi e fallback legittimi | NOT VERIFIED |
| P115-07 | Inbox: crea categoria anche vuota, rinomina, filtra, riavvia, archivia/ripristina e account switching | NOT VERIFIED |
| P115-08 | QR 24h camera/scanner, invito riutilizzabile, join e ruolo owner/non-owner su due utenti reali separati | NOT VERIFIED |
| P115-09 | Cassaforte privata, PIN/biometria, lock su background/restart, no fuga screenshot/ricerca/export | NOT VERIFIED |
| P115-10 | Offline, riconnessione e sync privato/condiviso senza conflitti o duplicati inattesi | NOT VERIFIED |
| P115-11 | Notifiche native e Web Push (se configurato), permessi negati, consegna reale e OS restriction | NOT VERIFIED |
| P115-12 | Tema rose + HSV, font Manrope/Lora, 10 schermate approvate, text scaling, reduced motion, contrasto, rapid tap, fluidita dispositivo | NOT VERIFIED |
| P115-13 | Premium/RevenueCat acquisti e restore **solo se esiste canale Play Internal Testing valido**, non simularne l'esito | NOT VERIFIED |
| P115-14 | Backup/import/export: con dati di prova controllati e senza restore distruttivi sul telefono personale | NOT VERIFIED |

## Record per singolo test

```text
date:
sourceSha: 31b66ba96d66a3ca3984a3c19061c4f1bfc9f9c7
artifactSha256: [dal manifest]
signingFingerprint: [dal manifest e dispositivo]
installedVersionBefore:
installedVersionAfter:
deviceModel:
androidVersion:
scenarioId:
observed:
result: PASS | FAIL | BLOCKED | NOT VERIFIED
screenshotsOrLogs: [redatti, senza dati sensibili]
notes:
```

L'artefatto firmato successivo richiede Flutter `versionCode > 115` e nuova correlazione sha/signer/byte. Non trasferire risultati +115 ad APK ricostruiti. Per qualunque mismatch P115-01, data loss, regressione Cassaforte, access control o crash critico: `BLOCKING_NOW`, fermare la promozione release e creare issue/PR correttiva isolata.
