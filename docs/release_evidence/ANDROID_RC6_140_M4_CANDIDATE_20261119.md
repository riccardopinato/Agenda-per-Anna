# Anna’s Diary — rc.6+140 ARM64: M4 candidate, **NOT DEVICE CERTIFIED**

Data: 19 novembre 2026. Autorizzazione: richiesta utente di eseguire la roadmap completa dei 20 punti dopo audit 360°; **nessuna autorizzazione a cancellare dati, installare sul telefono personale, pubblicare su Play o usare account reali nei runner**.

## Provenienza e dipendenze

- Source prima della PR M4: `main@130fabd3403ea116c83064df54674c7552915056`, M1 [#367](https://github.com/riccardopinato/Agenda-per-Anna/pull/367), M2 [#368](https://github.com/riccardopinato/Agenda-per-Anna/pull/368), M3 [#369](https://github.com/riccardopinato/Agenda-per-Anna/pull/369) integrati. Dopo ogni eventuale merge verificare che sia **questo** snapshot più le sole modifiche di metadata.
- App Factory pin `6dfde2d6b6a5be6cbc898cea137f87803701814d`, Master v27 / Index v29. Principio: `SOURCE_PASS != APK_BUILT != INSTALLED != DEVICE_VERIFIED != STORE`.
- Identità proposta per source PR: `pubspec.yaml=1.0.0-rc.6+140`, `lib/app_version.dart=140`; package Android invariato `com.riccardopinato.agenda_per_anna`; ABI `arm64-v8a`, build `release`, **sideload soltanto**.
- Versione firmata precedente: +139 dal [run #44097602073](https://github.com/riccardopinato/Agenda-per-Anna/actions/runs/44097602073) con [artifact `annas-diary-light-arm64`](https://github.com/riccardopinato/Agenda-per-Anna/actions/runs/44097602073/artifacts/14334573260). Tale artifact **non** contiene le modifiche di M1–M3 e non è fonte nuova per il merge.
- Fino a costruzione riuscita: `candidate_apk_sha256 = NOT_AVAILABLE`, `actual_version_code = NOT_VERIFIED`, `signed_fingerprint_actual = NOT_VERIFIED`, `installed_version = NOT_VERIFIED`, `physical_31_case_matrix = NOT_RUN`.

## Gate automatici prima della firma

1. PR isolata: **Development checks + AppLab Source Gate** sul SHA head, mergeable, nessuna review/issue bloccante; non alterare segreti/firma/SDK/database o flussi premium.
2. Merge al **main esatto** e postmerge `Development checks` su main SUCCESS. Solo tale risultato attiva `.github/workflows/auto-signed-arm64.yml`; `release-preflight` confronta `pubspec.yaml` con primo parent e richiede buildNumber **strettamente crescente** (+139→+140), altrimenti `signed-apk SKIPPED`.
3. Richiedere **signed-apk / build SUCCESS** nel workflow chiamato `.github/workflows/sideload-arm64.yml`, con source SHA del main testato, keystore stabile e artifact `annas-diary-light-arm64`. Non considerare verde il solo preflight, né generare key nuova.
4. Artefatto: `PHYSICAL_CERTIFICATION_MANIFEST.json` deve contenere SHA-256 APK, commit sorgente, package, variante, numero versione e SHA-256 certificato osservato. Confrontare impronta di firma con lo storico **prima** della consegna come potenziale aggiornamento in-place. Registrare ID artifact, run, commit e checksum **solo dopo** osservazione reale.
5. `ANDROID_PRE-FLIGHT`: `tool/read_only_android_phone_preflight.py` e documenti [Maxi-step 3](ANDROID_MAXISTEP3_PHYSICAL_DATA_GATE_20261113.md), [Signing](../ANDROID_SIGNING.md). Non equivale a installazione o verifica backup.

## Gate fisici P0: **non eseguibili tramite sole GitHub Actions**

- Prima di toccare un dispositivo con dati non sintetici: backup **indipendente** con checksum e ripristinabilità verificata in ambiente isolato; inventario privacy-safe, attuale package/firma/versionCode, spazio e possibilità di recupero. Se un valore è ignoto: **STOP / BLOCKED**.
- Preferire telefono Android ARM64 di prova con **dataset totalmente sintetico**, prima con precedente APK **della stessa firma**, poi aggiornamento **in-place** con candidato +140, mai `uninstall`, `pm clear`, `adb install -d`, firma diversa, migrazione a ritroso o restore personale sul test device.
- Eseguire **tutti i 31 scenari** con receipt, hash e output PASS/FAIL/BLOCKED individuali (backup ZIP/JSON, foto/voce, Inbox, calendario, Vision Board, A→B→A, Insieme ACL/revoca, Vault/Keystore, notifiche, riavvio, PWA, versione installata). La CI non è una firma su quelle 31 prove.
- Non usare il sideload per affermare readiness Play/RevenueCat, acquisti, Data Safety o percentuale di rollout. Play Internal Testing è autorizzazione separata.

## Registrazione finale (da completare con risultati osservati)

| Proprietà | Stato iniziale |
|---|---|
| PR +140 exact-head Development/AppLab | NOT_RUN |
| Merge commit +140 in main | NOT_MERGED |
| Main Development SUCCESS | NOT_RUN |
| Auto signed +140 / run URL | NOT_RUN |
| `signed-apk` job e artifact | NOT_RUN |
| Source SHA nel manifest | NOT_VERIFIED |
| APK ZIP SHA-256 e APK SHA-256 | NOT_VERIFIED |
| `aapt` package, versionCode esatti | NOT_VERIFIED |
| Firma APK `apksigner verify` e SHA-256 cert | NOT_VERIFIED |
| Compatibilità con APK già installato | NOT_VERIFIED |
| Backup separato verificato | NOT_VERIFIED |
| Smartphone update in-place | NOT_PERFORMED |
| 31/31 physical acceptance | NOT_PERFORMED |
| Play / RevenueCat | NOT_VERIFIED |

**Stop conditions:** se una firma è cambiata, un secret manca, un buildNumber non è monotono, la CI non è esattamente verde, il file del backup è danneggiato o un utente non ha approvato il test sul suo telefono, non promuovere o installare. Il risultato finale può essere `APK_ARTIFACT_BUILT / PHYSICAL_BLOCKED`: è più preciso di dichiarare la roadmap terminata.
