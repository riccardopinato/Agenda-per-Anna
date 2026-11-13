# Anna's Diary — rc.6+130 signed ARM64 physical QA candidate

**Data: 13 novembre 2026. Stato iniziale: SOURCE PR ONLY — non ancora firmato, scaricato, installato o certificato.**

- Base sorgente prima della PR: `main@15793bc392925f6c8361aa26ba8f688f34081d7f`, Maxi-step 3 [31-case matrix](ANDROID_MAXISTEP3_PHYSICAL_DATA_GATE_20261113.md) e [read-only preflight](../../tool/read_only_android_phone_preflight.py) integrati.
- Versione Flutter proposta: `1.0.0-rc.6+130`, superiore alla sorgente `+129`; package invariato `com.riccardopinato.agenda_per_anna`; ABI candidate `arm64-v8a`. L'Android ABI-specific `versionCode` deve essere letto dal **vero APK** (per i precedenti split ARM64 il codice era buildNumber+2000).
- Sorgente firmata precedente accertata: [run +129 #42317437509](https://github.com/riccardopinato/Agenda-per-Anna/actions/runs/42317437509), su source commit `cb8c3d0dc99062dbc9e9f5c70af4759838947d15`; job `signed-apk / build` SUCCESS, artifact `annas-diary-light-arm64` ID `13551876983`, ZIP SHA-256 `b491f3a60ee37a5cc4d03ba34e6126bbe2b216896b3f29a302cb5c9624729498`. Questo vecchio +129 **non include** i cambiamenti di `main` successivi al 7 novembre. Non usare la sua esistenza come prova dell'APK +130.
- L'ultimo workflow auto-firma della base precedente [#43434093799](https://github.com/riccardopinato/Agenda-per-Anna/actions/runs/43434093799) non ha creato un nuovo APK perché `signed-apk` SKIPPED per `versionCode` invariato.

## Solo dopo gate PR exact-head e merge

1. Richiedere `Development checks` SUCCESS sul nuovo `main` exact SHA, con suite completa, Web e test Python preflight; più `AppLab Source Gate` e review senza blocker sull'HEAD della PR.
2. Il workflow esistente `.github/workflows/auto-signed-arm64.yml` dopo il `push main` è autorizzato a firmare soltanto un nuovo buildNumber, tramite signer stabile e secret protetti. Non eseguire una build release direttamente dalla PR e non creare nuovi secret/keystore.
3. Verificare che il run riporti `release-preflight SUCCESS` **e** `signed-apk / build SUCCESS`, mai `SKIPPED` scambiato per un artifact. Estrarre URL, artifact ID, source SHA, ZIP/APK SHA256, package, APK versionCode e SHA-256 del certificato; confermare la stessa identità di firma delle versioni già firmate.
4. Registrare i dati osservati in una receipt separata PR dopo il build; non precompilare gli esiti. La CI non implica smartphone testato.

## Gate prima dell'installazione fisica

- **Non installare automaticamente**. Prima servono un dispositivo Android ARM64 controllato, la versione effettiva installata, un backup indipendente la cui ripristinabilità sia stata verificata, un inventario prima/dopo e il consenso del proprietario.
- Usare `tool/read_only_android_phone_preflight.py` in locale per comparazione preliminare di versione e certificato dell'APK candidato; lo script non conferma la firma dell'app installata, backup o dati.
- Installazione solo come aggiornamento **in-place** (stesso package/firma, Android versionCode crescente): mai `pm clear`, uninstall, forced downgrade `-d`, re-sign, import distruttivo o upload dei dati personali a CI.
- Eseguire la [matrice completa Maxi-step 3](ANDROID_MAXISTEP3_PHYSICAL_DATA_GATE_20261113.md) e registrare tutti i casi P0 con prove. La verifica Play/Internal Testing resta HUMAN_GATE separata e non avviata.

**All'apertura di questa PR:** `artifact +130 NOT VERIFIED`, `physical backup NOT VERIFIED`, `update NOT PERFORMED`, `31/31 scenarios NOT VERIFIED`, `X10-032 PLANNED`. Nessuna pretesa di release Store o Golden.
