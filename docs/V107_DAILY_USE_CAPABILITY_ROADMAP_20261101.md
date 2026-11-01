# v1.07 Daily-use UX — piano di implementazione capability
_Aggiornamento post PR #186: A1 source MERGED; F0 USER_ATTESTED_GENERAL_PASS; altre wave ancora PLANNED._

**Stato aggiornato 2026-11-01:** l'utilizzatore riferisce **«collaudo fatto, tutto ok»** per l'APK firmato `+115`, senza fornire identificativi del dispositivo, impronte digitali o risultati individuali per scenario. Questa comunicazione attesta soddisfazione nell'uso reale; non autorizza a compilare come PASS la tabella dei test fisici che resta senza log. La PR A1 e stata integrata su `main@308faebb7ed06873c244103f107192d8d25a4b18` dopo CI/QA sorgente verde. **A1 non e contenuta nell'APK +115**: richiede successiva build >115 e collaudo sul nuovo artefatto. **Prossima wave: A2**.



**Aggiornamento dopo PR #188:** A2 CAP-0003 e' SOURCE MERGED su main al commit `31500ea9687680f3159f45ff1d4dbeb9bc53ae22`. L'APK +115 precede A1+A2 e NON le contiene. Il candidato `1.0.0-rc.6+116` (build number 116) e' predisposto in questa release PR, e sara' considerato ARTIFACT BUILT solo dopo il successo del workflow stabile su esatto source SHA; [gate fisico v116](V116_ANDROID_PHYSICAL_GATE.md). La wave B1 resta pianificata.

**Aggiornamento release +116 (2026-11-01):** A1 e A2 sono integrate nel commit `6380af49d2dd0e35db747e7862456b4ac6bf6a87`, la release Android `1.0.0-rc.6+116` e stata **costruita e firmata** dal workflow [#41262693723](https://github.com/riccardopinato/Agenda-per-Anna/actions/runs/41262693723) con esito SUCCESS; artefatto `annas-diary-light-arm64` (ID 13065409792) disponibile. **Test fisici +116 NON VERIFICATI.** Verificare in place update, Cassaforte, A1/A2 e checklist nella [matrice v116](V116_ANDROID_PHYSICAL_GATE.md). Tutte le note sopra sullo stato pre-build sono cronologia, non stato corrente.

**Aggiornamento B1 post-merge (2026-11-01):** CAP-0002 e' **SOURCE MERGED** tramite [PR #191](https://github.com/riccardopinato/Agenda-per-Anna/pull/191), commit `58a23f94644b29abf374832164b3a3ac1e5cce56`; Development checks / Deploy Web / AppLab Source Gate tutti SUCCESS all'exact head `58a423a5ae4c8acd3bef5390535a48815f4ef21c`, 6 review finding corretti. Il vecchio APK +116 non include B1. La verifica fisica resta **NOT VERIFIED**.

**Aggiornamento B2 post-merge (2026-11-01):** CAP-0001 e' **SOURCE MERGED** tramite [PR #193](https://github.com/riccardopinato/Agenda-per-Anna/pull/193), commit `18ce8b4bd0f8a997aeef381caa57a6430c4d9757`. Exact-head PR `d22b18eb8f89b3c6100946344867aa2bb13df707`: Development checks / Deploy Web / AppLab Source Gate SUCCESS; 2 finding review risolti. La funzione e' un calcolo read-only e richiede salvataggio esplicito nel compositore esistente. L'APK `+116` NON include B1/B2; verifica fisica B2 **NOT VERIFIED**. Per continuare lo sviluppo l'utente ha chiesto di non attendere il gate fisico: nessuna evidenza di test e' stata inventata o certificata. Prossimo: B3 export e' **decision gate separato**, oppure C1 secondo roadmap.

**Aggiornamento B3 post-merge (2026-11-01):** la modalita' Android e' autorizzata dall'utente come soluzione immediata, lasciando Google Calendar API diretta per un secondo momento. SOURCE MERGED tramite [PR #195](https://github.com/riccardopinato/Agenda-per-Anna/pull/195), main `ad48e1f5abd7ef8bff96ca25164d205bb62f60b7`. Dev/Web/AppLab exact-head `15028ebffc86de2ed72cc6fd964ac7011212fc01` SUCCESS e review risolta. La sincronizzazione richiede consent READ/WRITE_CALENDAR Android, selezione calendario scrivibile e attivazione esplicita: non e' certificata da prove su telefono. Questo branch prepara soltanto +117 e **non** dichiara un artifact finche' il workflow di firma non e' completato; nessun Play release automatico. Il promemoria ChatGPT per il collegamento Google di domani NON e' stato creato per limite 5 automazioni attive; nessuna attivita' esistente e' stata sostituita.


**Aggiornamento QA B3 +117, 1 novembre 2026:** `1.0.0-rc.6+117` firmato ARM64 **ARTIFACT BUILT** da `main@8824f0dcf427d67aa2e069da6fd2dd02bc6cb1e1`, [run #41269542695](https://github.com/riccardopinato/Agenda-per-Anna/actions/runs/41269542695) **SUCCESS**, artifact `annas-diary-light-arm64` ID 13068413157. Il gate di compilazione Android nativo in PR #197 e' **SUCCESS** (run #41269809343), poi MERGED su `2876b986df92df1e560b9c8022072c126cbc770a`. Ciò non prova esecuzione su device. **PHYSICAL NOT VERIFIED** per +117 (aggiornamento in-place, permessi, scelta calendario, sincronizzazione, fingerprint). La precedente dicitura BUILD PENDING apparteneva alla fase pre-release. Google OAuth diretto resta rimandato; il promemoria per il 2 novembre non e' stato creato per il limite di task.

## Fonti, baseline e competenze

- Product scope e privacy: [PRODUCT_BIBLE.md](PRODUCT_BIBLE.md); ordine di delivery e stato: [ROADMAP.md](ROADMAP.md); AGENTS.md nel root.
- Anna snapshot: `riccardopinato/Agenda-per-Anna@fbfc9dc445590fd8652cc7414bebbcd2865c6074`; Flutter `1.0.0-rc.6+115`. Factory `riccardopinato/App-Factory-Core@632a66dce4aa00e8e1700b0a3e4dfc7ea008197c`, Master v27 / Golden Index v23.
- Capability registry snapshot: `riccardopinato/Idee-app-Archivi-riferimenti@44d251be866e21467d6d8d8c6a42250ceb6fdd54`, 91 record; [vista per Anna](https://github.com/riccardopinato/Idee-app-Archivi-riferimenti/blob/44d251be866e21467d6d8d8c6a42250ceb6fdd54/12-CAPABILITY-E-IMPLEMENTAZIONI/PER_APP/Agenda-per-Anna.md).
- Questo e un piano di lavoro per Anna, non una promozione degli stati `PROPOSTA` a `IMPLEMENTED`, ne una certificazione di licenza runtime.
- Non riaprire le funzioni gia presenti: calendario esterno in sola lettura, notifiche, OCR immagini, voice diary, cattura universale, categorie Inbox, Trash, Ricordi/Then-Now/mappe, backup/sync, QR ed entitlement. Le nuove funzioni sono proiezioni/comandi sulle ownership esistenti.
- La v1.08 e un **milestone di design**, non un numero di distribuzione Android. La v1.06 Ecosystem Expansion resta DEFERRED finche non sia possibile una prova cross-app/device.

## Sequenza vincolante e work lanes

| Wave | CAP | Deliverable previsto | Stato | Dipendenza / gate |
| --- | --- | --- | --- | --- |
| F0 · Release reality | — | Collaudo fisico signed `+115` esatto | USER_ATTESTED_GENERAL_PASS (dettaglio mancante) | [V115_ANDROID_PHYSICAL_GATE.md](V115_ANDROID_PHYSICAL_GATE.md); blocchi reali separati da migliorie |
| v1.07-A1 | CAP-0014 | Appuntamento passato -> bozza ricordo | MERGED SOURCE / DEVICE QA FUTURA | riuso `AgendaItem`, `DayJournal/DiaryBlock`, `Unified Capture`, nessuna scrittura implicita |
| v1.07-A2 | CAP-0003 | Preparazione leggera: note/checklist contestuali evento | MERGED SOURCE / DEVICE QA FUTURA | no task manager; riuso contenuti e reminder, nessun secondo scheduler |
| v1.07-B1 | CAP-0002 | Testo -> bozza appuntamento offline deterministica | MERGED SOURCE / DEVICE QA FUTURA | A chiusa; parser EN/IT/ES/FR/PT, preview esplicita, timezone e ricorrenza |
| v1.07-B2 | CAP-0001 | Slot liberi calcolati da eventi visibili all'utente | MERGED SOURCE / DEVICE QA FUTURA | B1, calendario privato + overlay opt-in read-only; niente evento salvato |
| v1.07-B3 | CAP-0005 estesa | Sincronizzazione Android Calendar Provider unidirezionale su consenso, senza OAuth Google API | MERGED SOURCE / NATIVE BUILD PASS / APK +117 SIGNED / PHYSICAL QA FUTURA | solo appuntamenti privati futuri, selezione calendario, permessi READ/WRITE Android, gestione idempotenza; nessuna cancellazione esterna automatica |
| v1.07-C1 | CAP-0077 | Diagnostica permessi/capability, correzione assistita | PLANNED | servizi nativi reali; UI non mente su stato 'healthy' |
| v1.07-C2 | CAP-0069 | Regressione visiva automatica mirata alle 10 schermate | PLANNED | test/dev only, dispositivi/locale/theme/dimensioni di baseline fissati |
| Follow-up eventuali | CAP-0086, CAP-0039, CAP-0031, CAP-0008 | TTS, copie foto senza EXIF, STT offline, import workout media | EVALUATE LATER | adozione separata; nessuna dipendenza release |
| v1.06 | Ecosystem Bridge | accoppiamento verificato con app esterne | DEFERRED | due app + device reali, fonte/revision/permission e privacy |

**Execution:** PR piccola e autonoma per ogni sub-step, oppure accorpamento solo se gli stessi componenti e gate rendono la separazione inutilmente costosa. Release planning e software development sono due lane diverse. Mantenere il QA source-only disponibile prima del device, ma **non certificare** né distribuire una nuova v1.07 senza chiudere il gate release pertinente. In caso di blocco fisico reale, registrare `BLOCKED` e lavorare solo su contenuti o test indipendenti; non convertire il blocco in PASS.

## A — Agenda -> Ricordo e preparazione eventi

### A1: da appuntamento a memoria (CAP-0014)

**UX:** solo su evento reale passato, pulsante esplicito `Conserva un ricordo`. Si apre una bozza *modificabile* di diario con data e riferimento contestuale all'appuntamento; l'utente puo cambiare testo, persone, media e annullare senza modificare i dati. Il salvataggio usa il percorso canonico `AgendaStore.saveJournal` e le proiezioni Ricordi gia presenti. Niente notifica automatica o riscrittura dell'evento.

**Test/accettazione:**
1. Evento passato -> azione visibile in posizione ragionevole -> bozza con data corretta; evento futuro non produce invito non sensato.
2. Cancel/back non salva; save scrive un solo record nel diario canonico; ripetizione del tap non crea doppioni accidentali.
3. Privacy privata by default anche per eventi condivisi; dati di altri membri non passano in contenuto privato/esterno senza azione e permesso espliciti.
4. Ricordo appare in Timeline/search, riapertura, backup/restore e lifecycle (Trash) senza alterare evento/ricordo precedente.
5. Funziona offline; cinque lingue; focus, text-scale, Reduce Motion, Web/native differenziati.

### A2: preparazione contestuale (CAP-0003)

**UX:** da scheda evento *facoltativa* checklist e riferimenti a note esistenti, senza un nuovo piano di produttivita o reminder engine. Se serve memorizzare checkboxes, preferire il formato/entita gia compatibile con note/template e preservare la loro ownership. Nessun nuovo calendario, database o sync scheduler.

**Test/accettazione:** modifica/archiviazione/restore coerenti con sorgenti; contenuti privati non visibili in contesti condivisi senza permesso; nessuna checklist duplicata, no reminder involontario, funziona offline.

## B — Calendario intelligente ma deterministico

### B1: frase -> evento (CAP-0002)

**UX di esempio:** `Dentista domani alle 17:30, ricordami il giorno prima` -> anteprima data/ora/timezone/categoria/reminder -> `Conferma` -> nuovo `AgendaItem` tramite writer esistente. Supporto iniziale a costruzioni frequenti e riconoscibili in italiano, inglese, spagnolo, francese e portoghese; se una lingua o sintassi non e supportata, feedback `Non riconosciuto` e passaggio a editor manuale. Il parsing **non deve inventare** campi né dichiarare di essere un assistente NLP generale.

**Test/accettazione:**
1. Suite table-driven con esempi validi/invalidi per cinque lingue, date assolute/relative, `oggi/domani`, domeniche, cambio mese/anno, leap day, DST e ambiguita (ad esempio solo `giovedi`).
2. Timezone esplicito e coerente con device locale; in assenza di orario o data certa **non creare** evento.
3. Eventi ripetuti e reminder ammessi solo quando l'input e univoco; nessun update/delete automatico di eventi precedenti.
4. Preview modifica/cancel, undo dove disponibile, account ownership, idempotenza, privacy, backup/restore e Web/PWA degradation veritiera.
5. Nessuna AI cloud, permesso microfono o rete per il parser.

### B2: slot liberi (CAP-0001)

Calcolare intervalli derivati dalle date degli eventi *visibili e autorizzati*, con disponibilita definita soltanto dai calendari selezionati; chiarire che calendario non collegato/permesso revocato = copertura parziale. Default orari diurni configurabili, durata minima esplicita, eventi all-day/recorrenti, sovrapposizioni, DST, orario di lavoro facoltativo. Nessuno slot sposta eventi; crea appuntamento solo dopo conferma.

**Test/accettazione:** overlap merge, all-day, ordinamento, finestra oltre mezzanotte, assenza evento, calendario esterno in sola lettura, permesso denied/unavailable, bassa latenza offline, nessuna lettura Vault.

### B3: export evento (CAP-0005, decisione separata)

Esporre il comando `Aggiungi al calendario del dispositivo` per singoli eventi. Preferire un'azione con intent o file .ics e selezione dell'app/account quando fattibile; evitare `WRITE_CALENDAR` se non serve. Mai sostituire l'attuale overlay read-only o costruire sync bidirezionale. Test ripetizioni, duplicati esterni, timezone e rifiuto export.

## C — Affidabilita, regressione visuale e accessibilita

### C1: permission/capability health (CAP-0077)

Sviluppare una sezione semplice in Impostazioni e riutilizzare i bridge nativi esistenti. Stati indipendenti: `NON SUPPORTATO`, `SERVE PERMESSO`, `NON DISPONIBILE`, `PRONTO`, `DEGRADATO`, `DA VERIFICARE`. **Permesso concesso != consegna notifiche != servizio healthy.** Indicare `ultimo controllo`, controllare realmente servizio/configurazione quando possibile, e offrire `Apri Impostazioni` solo quando serve. No permission wall all'avvio; nessun segnale di sicurezza positiva inventato su Web.

**Test:** supporto piattaforma, permission denied/permanently denied, permission granted ma service off, notification channel disabled, stale state, repair success/failure, restart, no false PASS.

### C2: visual regression (CAP-0069)

Partire dalla suite di screenshot/baseline gia documentata in v1.05-A5 e dal contratto delle dieci schermate, **non** introdurre un secondo framework autonomo. Snapshot golden per lingua/fonte/testo ridotto/tema/dimensione deterministiche; media utente mai in screenshot CI o leak di Cassaforte. L'automazione non sostituisce Android fisico e va calibrata per pixel-diff instabili/animazioni.

**Test:** baseline revisionata, diff intentional vs regression, screenshot su stato deterministico, nessun mock inventato spacciato per screenshot dispositivo.

## Ricerca donor, riuso e alternative

| Funzione | Riutilizzo piu economico | Licenza/decisione |
| --- | --- | --- |
| Parser eventi | nuovo parser Dart minimo su modelli calendario esistenti; [chrono JS](https://github.com/wanasit/chrono) solo pattern | MIT dichiarato upstream, incompatibilita diretta JS -> Dart; test locale |
| Ricorrenze/ICS | writer esistente; [rrule](https://github.com/JonasWanke/rrule) / [enough_icalendar](https://github.com/Enough-Software/enough_icalendar) solo se necessario | Apache-2.0 / MPL-2.0; non introdurre secondo motore ricorrenza |
| TTS facoltativo | [flutter_tts](https://github.com/dlutton/flutter_tts) Android/iOS native engine | MIT; spike separato, voce di sistema, privacy no upload implicito |
| STT opzionale | [sherpa-onnx](https://github.com/k2-fsa/sherpa-onnx) o [whisper.cpp](https://github.com/ggml-org/whisper.cpp) | Apache-2.0 / MIT, bridge, pesi modello e footprint da audit; non in APK base |
| Safe photo share | codice interno Android Omni Cleaner `JpegExifEditor` + `JpegContentDigest` | riuso interno Kotlin, media in copia, verifica hash/orientamento; PR separata |
| Diagnostica | Golden `GOLDEN_CAPABILITY_PERMISSION_HEALTH_FLUTTER_v1_DRAFT` | DRAFT, da validare per-app; no copia cieca |
| UI/accessibilita | Design System attuale + v1.05-A5 screenshot baseline | gia donor interno compatibile; non duplicare tema e widget |

**No go per v1.07:** OpenWhispr desktop intero, VoiceStudio AGPL come codice embedded, Dextop, disktree, Gods Eye live layer, AI generative narrator, social scoring, engagement coercitivo, secondo database/sync/agenda e duplicazione app specializzate.

## Gate, distribuzione e criteri di Done

1. Ogni step: PR source con Scope/No-scope, test mirati, lint/Flutter, Web, AppLab Source Gate dove previsto da `AGENTS.md` e branch rules; Codex review advisory, findings pertinenti riparati; exact-head green. Docs-only: review/test minima necessaria, non inventare runtime evidence.
2. Versioning: `1.0.0-rc.6+115` e **gia un artifact firmato** di uno SHA precedente. Le fasi `v1.07-A/B/C` non sono un `versionCode`; nuovo APK solo con incremento monotono oltre 115 su `main`, stable signing e trigger di build autorizzato. Nessun nuovo APK su document-only PR.
3. Physical: checklist [V115_ANDROID_PHYSICAL_GATE.md](V115_ANDROID_PHYSICAL_GATE.md) prima della certificazione; i test di QR, Cassaforte Keystore, foto reali, policy notifiche, account isolation, storage e update-in-place non possono diventare PASS da solo Web/CI.
4. Permanenza dati: nessuna migrazione distruttiva, export/import/backup compatibili, nessun contenuto fittizio negli account reali e nessuna modifica implicita a Cassaforte, Password Vault, ciclo, privacy, RevenueCat, sharing consent.
5. Privacy: le funzioni sono local-first, opt-in quando necessario; dati di altre app non sono automaticamente autorizzati, mai rendere pubblico il calendario o il diario.
6. **Stop rule:** quando la F0 rileva data loss/secret/privacy/upgrade incompatible segnare `BLOCKING_NOW`; fix della wave attiva solo se introdotto dalla wave (`FIX_CURRENT_STEP`); altro debt `BACKGROUND_MAINTENANCE` o `FUTURE` (Golden Roadmap Fast).
7. Questa roadmap definisce il perimetro della futura implementazione; non implica che sviluppo, merge o certificazione funzionale siano gia avvenuti.

## Tracciamento iniziale

| Deliverable | Stato al 2026-11-01 | Prova |
| --- | --- | --- |
| v1.08/UI5 codice | MERGED | `docs/APPROVED10_FULL_AUDIT_20261031.md`, `docs/ROADMAP.md` |
| Signed APK +115 | ARTIFACT BUILT | Actions #41248307448 su `31b66ba9` |
| Physical device certification +115 | USER_ATTESTED_GENERAL_PASS, dettagli tecnici NON VERIFICATI | messaggio utente 2026-11-01; checklist per scenario priva di prove |
| v1.07-A1/A2 | SOURCE MERGED; DEVICE QA ON +116 PENDING | PR #186, PR #188, v116 gate |
| v1.07-B1/B2/B3 | PLANNED / B3 DECISION GATE | questa roadmap |
| v1.07-C1/C2 | PLANNED | questa roadmap |
| v1.06 cross-app | DEFERRED | `docs/ROADMAP.md` |

