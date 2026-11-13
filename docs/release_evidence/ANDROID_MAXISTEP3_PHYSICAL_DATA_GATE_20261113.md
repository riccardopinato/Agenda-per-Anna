# Anna's Diary — Maxi-step 3: gate fisico, backup verificato e matrice dati completa

**13 novembre 2026 | STATO: PIANO/PROTOCOLLO PRONTO; ESECUZIONE FISICA NOT VERIFIED.**

- **Factory baseline:** `riccardopinato/App-Factory-Core@c5adc147046beb7024629466d10eeb799c3c2619` (Master v27, Golden Index v29).
- **Anna source esaminato:** `main@c9da767a14eae5ef0f82ee39e61853f2e24f0057` (PR #312 merged, post-merge Development [run #43426938558](https://github.com/riccardopinato/Agenda-per-Anna/actions/runs/43426938558) SUCCESS).
- **Sorgente del precedente collaudo:** [Maxi-step 1 / PR #311](https://github.com/riccardopinato/Agenda-per-Anna/pull/311) e [Maxi-step 2 / PR #312](https://github.com/riccardopinato/Agenda-per-Anna/pull/312). Solo originali +127/+128, ARM64 APK `versionCode=2127/2128`, stessa impronta firma `31BE63155C831F062238179EC9B8F19D1C16A925BED1D526BC7E6A4712C62DC3`.
- **Ultimo auto-sign main [run #43427535538](https://github.com/riccardopinato/Agenda-per-Anna/actions/runs/43427535538):** `release-preflight SUCCESS`, `signed-apk SKIPPED`, **zero nuovi artifact** in quel run. Un workflow SUCCESS **non** equivale a nuovo APK firmato. Nessuna ipotesi sull'installato personale.
- **Raccordo programma 10x:** [57-task crosswalk PR #164](https://github.com/riccardopinato/Idee-app-Archivi-riferimenti/pull/164), X10-032 `PLANNED / HUMAN_GATE`. Questa PR non dichiara `DEVICE_VERIFIED`, `PLAY_READY` o nuovo Golden.
- **Contratto prodotto:** [DS6 +129 Physical Acceptance](../DS6_129_PHYSICAL_ACCEPTANCE.md), [Product Bible](../PRODUCT_BIBLE.md), [Release Reality Golden draft](https://github.com/riccardopinato/App-Factory-Core/blob/c5adc147046beb7024629466d10eeb799c3c2619/golden/release/GOLDEN_RELEASE_REALITY_PHYSICAL_VALIDATION_v1_DRAFT.txt). Questo protocollo espande la matrice dati, non sostituisce la checklist DS6.

## 1. Decisione prima del test

Il test precedente su API35 con una sola categoria sintetica **non** dimostra backup, note, foto, audio, Vault, calendario, sync, QR o update su telefono ARM64. I relativi domini restano `NOT VERIFIED`.

**P0: STOP finché non esiste un backup indipendente verificato**, fino a prova di identita' dello specifico APK installato e di quello da installare. Non eseguire `adb install -d`, `pm clear`, uninstall, re-sign, ripristini distruttivi o import di backup di persone reali su device/emulator usa-e-getta.

Scelta di esecuzione:
1. Preferire un **telefono spare ARM64 dedicato** con account/dataset interamente sintetici: pre-update inventario, backup, upgrade in-place, verifica post-update e recupero.
2. Solo **dopo** questi gate, passare a un telefono personale con backup verificato e consenso esplicito del proprietario. Non estrarre contenuti privati, token, selfie, Vault, password, cifrature, né push-backup reali in GitHub Actions.
3. Per la versione corrente **non creare automaticamente** un nuovo APK o incrementare il versionCode in questa PR documentale. Un candidato successivo richiede source commit, CI, firma stabile, hash, archiviazione e confronto con l'APK già installato.
4. Play Internal Testing/billing sono gate separati, con approvazione del proprietario e prova su Play Console. Non includerli nella certificazione fisica sideload.

## 2. Receipt minime senza dati personali

Ogni prova eseguita registra **ID**, data ISO, Android/OEM, telefono spare o personale (senza seriale/IMEI), account `guest/test` o `personal` senza indirizzi, `source_sha`, `run_url`, APK `sha256`, `versionCode` effettivo, fingerprint certificato, stato `PASS | FAIL | BLOCKED | NOT_VERIFIED`, riproduzione/evidenza privata facoltativa. Non salvare contenuti testuali o nomi reali. I test non eseguiti restano `NOT_VERIFIED`, e i gate P0 bloccanti sospendono installazione/restore.

**Esempio struttura receipt** (senza esiti inventati):

```json
{
  "test_id": "DAT-01",
  "scope": "physical_spare_android",
  "status": "NOT_VERIFIED",
  "device_model": null,
  "android_version": null,
  "previous_apk_version_code": null,
  "candidate_apk_version_code": null,
  "source_sha": null,
  "candidate_apk_sha256": null,
  "signing_certificate_sha256": null,
  "backup_sha256_verified": null,
  "observed_at": null,
  "evidence_url": null
}
```

## 3. Matrice completa per dominio

Gli ID seguenti sono scenari QA di Anna, **non** nuovi ID X10 e non modificano la coda centrale. Stato iniziale di ogni riga: **NOT VERIFIED**.

| ID | Priorita' | Dominio | Esecuzione | Criterio PASS | Stato |
|---|---|---|---|---|---|
| PRE-01 | P0 | Preflight / dispositivo | Rilevare telefono, versione Android, account, ABI, package e versione installata | Manifest dispositivo e installed package confrontati senza dati personali | NOT VERIFIED |
| PRE-02 | P0 | Preflight / manifest | Recuperare solo APK originale esatto, source SHA, ZIP e APK SHA-256, firma/cert fingerprint, versionCode | Provenienza verificata, package/cert compatibili, versione candidate superiore | NOT VERIFIED |
| PRE-03 | P0 | Preflight / backup | Creare backup indipendente prima di installare su dispositivo con dati personali | File esiste fuori dall'app; dimensione, checksum, percorso sicuro e data verificati | NOT VERIFIED |
| PRE-04 | P0 | Preflight / verifica backup | Verificare formato, integrita' e leggibilita' del backup in ambiente isolato, mai ripristino distruttivo sul telefono principale | Manifest/media e hash validi; prova di restore isolato quando supportato; altrimenti BLOCKED | NOT VERIFIED |
| PRE-05 | P0 | Preflight / inventario | Annotare per dominio conteggi e ID pseudonimizzati sul dispositivo, senza esportare note o segreti | Snapshot pre-update completo, privato e confrontabile; no dati privati in GitHub | NOT VERIFIED |
| PRE-06 | P0 | Preflight / disponibilita' | Verificare spazio, batteria e rollback non distruttivo / forward-fix documentato | STOP se backup, identita' o recovery non sono dimostrabili | NOT VERIFIED |
| UPD-01 | P0 | Update reale | Installare in-place solo se tutti i PRE PASS, senza uninstall, pm clear o install -d | Stesso package/firma, Android versionCode aumentato e dati mantenuti | NOT VERIFIED |
| UPD-02 | P0 | Cold start / restart | Aprire, arrestare e riaprire app dopo aggiornamento e riavvio OS | Nessun reset onboarding/identita', nessun crash o perdita visibile | NOT VERIFIED |
| DAT-01 | P0 | Inbox / categorie | Confrontare categorie originali, tag attivi/archiviati e rinomina dopo update/restart | Tutte le categorie e referenze persistono, inclusa categoria sentinella | NOT VERIFIED |
| DAT-02 | P0 | Inbox / note | Confrontare note Inbox con tag, pin, stato e testi (senza divulgarli) | Conteggi, collegamenti, contenuto e ordinamento persistono | NOT VERIFIED |
| DAT-03 | P0 | Diario / blocchi | Confrontare entry per giorno e blocchi note/diario con ID persistenti | No duplicati, no spostamento data, proprieta' corretta | NOT VERIFIED |
| DAT-04 | P0 | Foto / media | Verificare foto originali, thumbnail, descrizioni e riferimenti storage | File locali originali apribili, nessun media orfano o mancante | NOT VERIFIED |
| DAT-05 | P0 | Audio / sketch | Verificare audio e disegni originali, anteprima e replay/render | Byte/mime e record coerenti; test per entrambi i tipi | NOT VERIFIED |
| DAT-06 | P0 | Archivio / Trash | Confrontare archiviati e elementi nel cestino, incluso ripristino non distruttivo su test dedicato | Status invariato, ripristino non crea duplicati | NOT VERIFIED |
| DAT-07 | P0 | Calendario / eventi | Verificare eventi, ricorrenze, giorno selezionato e allarmi | No orari/date alterati, trigger/identita' coerenti | NOT VERIFIED |
| DAT-08 | P0 | Task / promemoria | Verificare task completati/aperti, scadenze e reminder associati | Nessun duplicato, orario e completamento persistono | NOT VERIFIED |
| DAT-09 | P0 | Persone / compleanni | Verificare persone collegate, compleanni e relazioni di memoria | Associazioni e ricorrenze coerenti | NOT VERIFIED |
| DAT-10 | P0 | Personalizzazione | Palette 5+HSV, tema, Classic, shortcut, preferenze e moduli abilitati | Le scelte originarie persistono dopo restart e switch account | NOT VERIFIED |
| DAT-11 | P0 | Privacy / Vault | Verificare PIN/biometria, lock/resume, schermate protette e Search non indicizzata | Nessuna fuga dati; non catturare screenshot o contenuti Vault | NOT VERIFIED |
| DAT-12 | P0 | Identity / isolamento | Testare guest/account-switch A→B→A con dati sintetici separati | Nessuna contaminazione o retro-lettura dati account B su A | NOT VERIFIED |
| DAT-13 | P0 | Offline/sync | Creare/modificare item sintetico offline, riavviare, ricollegare | Coda intatta, nessuna duplicazione, eventuale error state esplicito | NOT VERIFIED |
| SHR-01 | P0 | Spazio condiviso | Su DUE account/device testare join, owner/invite, expiry, revoca, riavvio | Membership server autorizzate e contenuti compartimentati | NOT VERIFIED |
| SHR-02 | P0 | QR/camera | Con permesso accordato/negato verificare QR e ingresso manuale | Niente bypass auth, revoca e scadenza restano server-authoritative | NOT VERIFIED |
| UX-01 | P1 | DS6 Oggi + Calendar | Oggi, calendario, settimana/mese, selezione data e +Crea | 10/10 journey approvati coerenti con dati veri e senza errori | NOT VERIFIED |
| UX-02 | P1 | DS6 Ricordi + Cerca | Timeline, Map, Collections, tipologie e filtri ricerca | Accessi ai record originali, risultati veritieri, privacy applicata | NOT VERIFIED |
| UX-03 | P1 | DS6 Altro + Impostazioni | Navigazione, Inbox, settings, backup, personalizzazione | Nessun crash/overflow, tutte le funzioni accessibili | NOT VERIFIED |
| UX-04 | P1 | Responsive/localizzazione | 320–390dp, testo grande 1×/1.6×, IT/EN/ES/FR/PT, TalkBack | 48dp target, nessun overflow e semantica utilizzabile | NOT VERIFIED |
| UX-05 | P1 | Performance/consumi | Misurare cold-start, scroll Today/Ricordi, input, memoria, ANR/jank | Numeri misurati sullo stesso artifact/telefono, non stime | NOT VERIFIED |
| REC-01 | P0 | Same version repair | Se autorizzato, reinstallare la stessa versione firmata con -r sul device di prova | Dato conservato; non e' downgrade ne' rollback di codice | NOT VERIFIED |
| REC-02 | P0 | Failure/recovery | Interrompere un update solo su device spare con dataset sintetico | Recovery documentato, nessuna prova distruttiva sul device personale | NOT VERIFIED |
| STORE-01 | Separato | Google Play Internal Testing | Solo con track/app/versionCode e owner approval espliciti | Receipt di upload/test su Play; sideload != Play acceptance | NOT VERIFIED |

## 4. Sintesi dei gate e scope

- **P0 A — Backup e identita':** PRE-01…PRE-06 devono essere PASS. Se l'APK installato ha firma diversa o versionCode >= candidato: STOP. Un recupero non distruttivo e' preferibile a un tentativo di downgrade.
- **P0 B — Conservazione dati:** UPD-01/02 e DAT-01…DAT-13 devono essere registrati singolarmente per gli oggetti **effettivamente esistenti**; l'assenza di un tipo nel dataset non e' PASS ma `NOT VERIFIED` per quella tipologia. Test di restore su device spare dopo copia del backup, mai sul telefono principale come prova iniziale.
- **P0 C — Privacy/condivisione:** SHR-01/02 richiedono due account/dispositivi distinti e accesso autorizzato; non simulare una seconda persona con sessioni dello stesso account.
- **P1 — UI / performance:** UX-01…05 misurati su artefatto reale esatto e dispositivo. Nessuna promozione di `NO_BASELINE` a visual regression PASS.
- **Recovery:** REC-01/02 solo se precondizioni di sicurezza soddisfatte. Un normale downgrade rifiutato dimostra il guardrail Android, non la possibilita' di tornare al vecchio schema.
- **Store:** STORE-01 separato e fuori perimetro dell'esecuzione attuale.

## 5. Tracciamento risultato

**Stato al momento della creazione del documento:** gate fisici `NOT VERIFIED`, backup personale `NOT VERIFIED`, APK candidate successivo `NOT VERIFIED`, Play `NOT AUTHORIZED`. Numero scenari: **31**, tutti `NOT VERIFIED`. Codice/app/SQL, firme, dati e `pubspec.yaml` non vengono modificati da questo piano.

Dopo l'esecuzione fisica, riportare solo receipt per singolo scenario e aggiornare questa matrice tramite nuova PR/review exact-head. Promuovere X10-032 nel registro 10x **solo** con prove complete richieste dalla sua acceptance, inclusi i gate Play; non convertire automaticamente un collaudo Android locale in `VERIFIED` globale.

## 6. Preflight locale in sola lettura (tool disponibile; telefono NON collaudato)

Script canonico: [`tool/read_only_android_phone_preflight.py`](../../tool/read_only_android_phone_preflight.py). Prima dell'utilizzo collegare **un solo dispositivo fisico Android ARM64** al PC via USB e autorizzare il debugging Android sul telefono. Lo script non fa `install`, `uninstall`, `pm clear`, `push`, `pull`, export, backup o restore; non registra il seriale/IMEI, dati del diario o password. Vieta gli emulatori per evitare di confondere preflight fisico con il Maxi-step 2.

Da PowerShell Windows, nella cartella locale clonata di `Agenda-per-Anna`, con Python e Android SDK già installati:

```powershell
$sdk = if ($env:ANDROID_HOME) { $env:ANDROID_HOME } else { $env:ANDROID_SDK_ROOT }
if (-not $sdk) { throw 'ANDROID_HOME / ANDROID_SDK_ROOT mancante' }
$adb = Join-Path $sdk 'platform-tools\adb.exe'
$aapt = Join-Path $sdk 'build-tools\36.0.0\aapt.exe'
$signer = Join-Path $sdk 'build-tools\36.0.0\apksigner.bat'
python tool/read_only_android_phone_preflight.py --adb "$adb" --aapt "$aapt" --apksigner "$signer" --output "$env:USERPROFILE\Documents\anna-physical-preflight.json"
```

Opzionali: `--candidate "C:\percorso\Anna-Diary-arm64-release.apk"` verifica sul file locale reale SHA-256, package, Android `versionCode` e firma con `apksigner` oltre alla versione installata. `--backup "C:\percorso\backup_diario.zip"` calcola **solo** hash/dimensione di un file backup pre-esistente: NON verifica contenuto, cifratura o ripristinabilità. Nessuna opzione crea un backup, scarica APK o autorizza installazioni.

Se il telefono non ha Anna già installata, non è arm64, un dispositivo non è autorizzato, l'APK candidato è più vecchio/uguale, la firma è diversa o un tool fallisce, lo script termina `BLOCKED`. La firma dell'APK **installato** non è autenticata dalla sola lettura del `dumpsys`; anche in esito positivo restano `installed_signer_match`, backup/restore, inventario dati e update fisico `NOT_VERIFIED`. Il JSON locale non viene caricato in GitHub, e `installation_authorized=false` e `physical_qa_pass=false` sono invarianti.

**Gate dopo il preflight:** prima di qualunque installazione sul telefono personale, servono un vero backup recuperabile verificato separatamente su ambiente isolato, un candidato firmato e più recente prodotto da CI autorizzata, la prova d'identità dei binari e la matrice P0. L'ultima run [43434093799](https://github.com/riccardopinato/Agenda-per-Anna/actions/runs/43434093799) ha `signed-apk SKIPPED`: non produce un candidato. Nessuna conclusione `DEVICE_VERIFIED` o X10-032 `VERIFIED` in questo passo.
