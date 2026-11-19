# Anna's Diary — Consolidamento audit 360°: 20 interventi e cinque maxi-step
Data: 19 novembre 2026 · Decisione titolare: **eseguire roadmap, M2 e M3 in lane indipendenti, senza espansione funzionale**.
Stato: **PIANO OPERATIVO + REGISTRO PROVE**, non certificazione di runtime/dispositivi.

## Autorità, baseline, scopo
- App `riccardopinato/Agenda-per-Anna@adbab7db67a1262a5255a64e4aa34da376d6d051`, Flutter `1.0.0-rc.6+139`, 19 novembre. `main` continua ad evolvere, fissare sempre l'HEAD del proprio merge.
- App Factory CURRENT risolto sul nuovo main centrale `6dfde2d6b6a5be6cbc898cea137f87803701814d`, Master v27 / Golden Index v29 / Registry v2; per sessione non risolvere più volte se non cambia centrale.
- App source: [Product Bible](PRODUCT_BIBLE.md), [Roadmap storica](ROADMAP.md), [residui audit](AUDIT_RESIDUAL_POST_134_20261116.md), [N18 design 10/10](DESIGN_REVIEW_10_OF_10_20261118_INTEGRATION.md), [D7 physical](V100_D_SECURITY_NATIVE_PHYSICAL.md), [Vision Board QA](WEBFIRST_S13_VISION_BOARD_PWA_ACCEPTANCE_20261110.md).
- `CODE != CI != RUNTIME != PHYSICAL != RELEASE != STORE`. Nessun collaudo umano viene promosso automaticamente. Vietato introdurre nuovi store, sync, DB, billing, AI o ridisegnare Vault; preservare account/data, Classic, HSV, Manrope/Lora, cinque lingue e gli owner canonici.
- Web main [#44413421279](https://github.com/riccardopinato/Agenda-per-Anna/actions/runs/44413421279) e Development [#44413420982](https://github.com/riccardopinato/Agenda-per-Anna/actions/runs/44413420982): **SUCCESS sull'HEAD iniziale**. Auto-sign [#44414372272](https://github.com/riccardopinato/Agenda-per-Anna/actions/runs/44414372272): preflight success, job `signed-apk` **SKIPPED**, zero artifact. Un precedente +139 firmato esiste [#44097602073](https://github.com/riccardopinato/Agenda-per-Anna/actions/runs/44097602073) ma è di un SHA anteriore alla #366. Ultima Release pubblica +138. Update-in-place dell'HEAD corrente: **NOT_VERIFIED**.
- M2 e M3: branch differenti, proprietà disgiunta di file/fixture e PR CI exact-head. Non usare il piano come autorizzazione a reset, login provider, file personali o release pubblica.

## Indice univoco delle 20 azioni — stato aggiornabile
Legenda: `SOURCE_PRESENT` esiste già codice; `SOURCE_QA_PLANNED` test/evidenza da integrare; `MANUAL_GATE` servono dispositivi/operatori; `PROVIDER_GATE` controllo provider senza mutazioni; `DEFERRED` futura, senza nuovo scope; `DOC_IN_PROGRESS` riconciliazione doc. Ogni riga deve ricevere una vera evidenza e un link di chiusura prima di PASS.

| ID | Audit | Lane | Stato iniziale verificato | Owner/prerequisiti per la chiusura |
|---|---|---|---|---|
| A20-01 | Baseline +139 code/Web/APK/device | M1 | DOC_IN_PROGRESS; source/Web PASS, APK stale | presente registro source SHA, Web SHA, artifact source/SHA256, signer, device solo se testato |
| A20-02 | A→B→A su due client reali | M2 | SOURCE_PRESENT #366; MANUAL_GATE | due account test e PWA/Android, no leakage su route editor/Trash |
| A20-03 | ZIP/JSON/media/Trash/restore | M2 | SOURCE_PRESENT; MANUAL_GATE | provider fisico, corrupt/interrupt, hash media e rollback |
| A20-04 | Vision Board su due PWA | M2 | SOURCE_PRESENT; MANUAL_GATE [#297](https://github.com/riccardopinato/Agenda-per-Anna/issues/297) | S13 16 scenari, due client installati, foto di test |
| A20-05 | Ruoli, inviti, revoche, conflitti Insieme | M2 | SOURCE_PRESENT; MANUAL_GATE [#329](https://github.com/riccardopinato/Agenda-per-Anna/issues/329) | ACL backend e receipt client A/B, QR scaduti, offline |
| A20-06 | Cassaforte real device e privacy | M2 | SOURCE_PRESENT; MANUAL_GATE [D7](V100_D_SECURITY_NATIVE_PHYSICAL.md) | PIN/biometria/Keystore/FLAG_SECURE, **zero restyling Vault** |
| A20-07 | Notification reboot/DST/tap | M2 | SOURCE_PRESENT; MANUAL_GATE | Android/Push real delivery, locale, denied/granted |
| A20-08 | N18-01…10 same-fixture comparison | M3 | DESIGN_APPROVED; VISUAL_QA_PENDING [#327](https://github.com/riccardopinato/Agenda-per-Anna/issues/327) | Flutter screenshot reali, stessa fixture, owner review |
| A20-09 | Fix soli delta visuali dimostrati | M3 | PARTIAL; not a blank-slate redesign | before/after, no UX regressions, Classic reversibile |
| A20-10 | CAP-0069 baseline/candidate 70×2 | M3 | TOOL_SOURCE_PRESENT; SCREENSHOTS_NOT_VERIFIED [#237](https://github.com/riccardopinato/Agenda-per-Anna/issues/237) | provenienza runner, 70+70 PNG, reviewer; non riusare 14 PNG Insieme |
| A20-11 | Accessibilità / 5 lingue / scale | M3 | PARTIAL_TESTS; MANUAL_GATE per screen-reader | IT/EN/ES/FR/PT, 320/390/600, 2×, keyboard, reduced motion |
| A20-12 | Sei PR aperte | M1 | TRIAGE_NEEDED | #252 e #309 da riconciliare; #152 da valutare; #254 research; #215 e #199 **DO NOT MERGE** |
| A20-13 | README/roadmap/registri +139 | M1 | DOC_IN_PROGRESS | header canonico corrente, storico immutato |
| A20-14 | Design-App UIR link non risolti | M3 | REFERENCE_GAP [Design-App](https://github.com/riccardopinato/Design-App) | non mappare UIR-0003/14/21/29 a nuove JPEG senza provenance |
| A20-15 | Full Dart checkout scan exact SHA | M1 | NOT_RE-RUN; storico 332 file, 257 REVIEW, 0 LEGACY | scanner canonico su **ultimo HEAD**, archivio segnali e false positive, nessun autofix |
| A20-16 | Profilazione p95/jank e foto | M3/M4 | NOT_MEASURED; MANUAL_GATE | profile mode, device, campioni, dati sintetici, before/after |
| A20-17 | Guide delle sottosezioni | M3 | PROPOSED wave 2 [#355](https://github.com/riccardopinato/Agenda-per-Anna/issues/355) | implementare solo sottosezioni con frizione comprovata |
| A20-18 | Provider/migration/security advisories | M2/M5 | ADVISORY_HISTORIC; PROVIDER_GATE [#182](https://github.com/riccardopinato/Agenda-per-Anna/issues/182) | verifica **read-only** migrations/RLS/Auth/cron; no SQL mutante |
| A20-19 | APK candidate firma/update + data retention | M4 | BLOCKED on source freeze + human physical gate | incrementare >139 solo al rilascio autorizzato, stable signer, source SHA, 31 casi |
| A20-20 | Play/RevenueCat/Data Safety | M5 | STORE_NOT_VERIFIED | AAB API 36, purchase reali, restore, documenti e policy; nessuna pubblicazione implicita |

## Percorso critico e parallelismo reale
1. **M1 — reconcile**: canonizzare versione e backlog, evitare PR obsolete e doppioni. Non chiudere issue/PR senza controllare diff o autorizzazioni.
2. **M2 — integrity/privacy** (in parallelo a M3): aggiungere/regredire prove sintetiche locali per guest/A→B→A, media/ZIP, e preparare matrice di due PWA/Android. Proprietà: `test/m2_*.dart`, dossier `docs/qa/M2_*.md`; non toccare `lib/src/` se non emerge bug concreto replicato. Chiudere gate fisici **solo con prove reali**.
3. **M3 — visual/accessibility** (in parallelo a M2): confrontare current real Flutter against N18, usare **prima Design-App** Neo-Apple/Pastel/Editorial approvati; produrre regression a11y e visual con stesse fixture. Proprietà: `test/m3_*.dart`, `docs/qa/M3_*.md`, componenti UI solo dopo bug riprodotto; **no Vault, DB, account, syncing**.
4. **M4 — release-device**: solo dopo integrazione e freeze M2/M3, release con buildNumber monotono; verify sha256, fingerprint, aggiornamento senza uninstall; 31 test con dati sintetici su device dedicato. Nessun reset telefono personale.
5. **M5 — performance/provider/store**: benchmark profile e provider read-only parallelizzabili; Store/release pubblica solo dopo gate esterni ed autorizzazione. Privacy V2 #215 e Google Calendar Direct #199 rimangono draft indipendenti.

## Definizione di concluso
Una riga `A20` è **CHIUSA** soltanto se il suo gate esplicito è eseguito sull'identità corretta. `TEST_PASS` è diverso da `DEVICE_VERIFIED`. Gli issue #297/#327/#329/#237/#355/#182 mantengono l'owner, non duplicare tracker GitHub. Le sette opportunità NON APPROVATE restano nell'[Inbox idee](https://github.com/riccardopinato/Idee-app-Archivi-riferimenti/blob/main/11-NUOVE-IDEE/INBOX_IDEE.md) (candidata PR dedicata), senza modificare Product Bible o ricavi.

## Non fare
- Non riscrivere l'app né introdurre un altro stack/framework per ottenere un aspetto generico.
- Non trasformare nuove idee AD-OPP in backlog immediato; valutazione successiva esplicita.
- Non usare materiale di terzi o reference UIR senza effettiva licenza e file.
- Non affermare che Web PASS = aggiornamento PWA installata, scanner storico = zero problemi o APK +139 storico = sorgente corrente.
- Non leggere dati personali, sbloccare Vault, impostare OAuth Direct, modificare Supabase o vendere Premium durante QA di codice.


## Checkpoint di esecuzione — 19 novembre 2026, dopo M1–M4 source merge
**Questa sezione aggiorna lo stato**, mentre la tabella iniziale resta lo snapshot storico di apertura. Date e SHA sono identità reali, non stime. M5 prepara solo controlli provider/performance/Store e non li certifica.

**Merge app source verificati:** [M1 #367](https://github.com/riccardopinato/Agenda-per-Anna/pull/367) `73d63a6`, [M2 #368](https://github.com/riccardopinato/Agenda-per-Anna/pull/368) `728e466`, [M3 #369](https://github.com/riccardopinato/Agenda-per-Anna/pull/369) `130fabd`, [M4 #370](https://github.com/riccardopinato/Agenda-per-Anna/pull/370) `2395ca6` (+140 solo source), CI PR exact-head PASS. [Idee #170](https://github.com/riccardopinato/Idee-app-Archivi-riferimenti/pull/170) 7 rinviate, [Design-App #47](https://github.com/riccardopinato/Design-App/pull/47) link UIR corretti con originali marcati missing. Due PR stale #309, #252 chiuse senza merge; #152 QA donor, #254 Design Lab reference, #215 Privacy V2 e #199 OAuth Direct non unire. [M5 dossier](qa/M5_PROVIDER_PERFORMANCE_STORE_GATES_20261119.md) tratta verifica provider e gate esterni.

| ID | Avanzamento **effettivo** | Chiusura (distinta da preparazione) |
|---|---|---|
| A20-01 | `SOURCE+PR_CI` M4 +140, precedente +139 manifest registrato | installato +140 e stessa firma su device **NOT VERIFIED** |
| A20-02 | `SOURCE+CI PASS` guard A→B→A #366, test M2 #368 | due client reali **NOT VERIFIED** |
| A20-03 | `SOURCE+CI PASS` ZIP, serializzazione e anti-mixing #368 | file picker/restore reale **NOT VERIFIED** |
| A20-04 | `SOURCE+CI PASS` Vision Board sintetica #368 | due PWA installate S13 #297 **NOT VERIFIED** |
| A20-05 | `SOURCE+CI PASS` stati Insieme #365–366 | ACL, revoca offline e due device reali **NOT VERIFIED** |
| A20-06 | `NO CHANGE TO VAULT` come richiesto; D7 checklist pronta | biometria/Keystore/screen secure device **NOT VERIFIED** |
| A20-07 | `SOURCE PRESENT` reminder, bridge, push | consegna/reboot/DST reali **NOT VERIFIED** |
| A20-08 | `SOURCE+CAPTURE PASS` M3 16+ schermate Flutter sintetiche | confronto owner 10 mockup **NOT APPROVED** |
| A20-09 | `EVIDENCE FIRST` no redraw arbitrario | nessun difetto attestato da owner per ulteriore fix; **PENDING REVIEW** |
| A20-10 | `CAPTURE PARTIAL` N18; non CAP-0069 | 70 baseline + 70 candidate e manifest **NOT VERIFIED** |
| A20-11 | `WIDGET CI PASS` HSV 320dp / font 200%, 5 lingue già in app | TalkBack/VoiceOver, 5 lingue full matrix su hardware **NOT VERIFIED** |
| A20-12 | `TRIAGE DOCUMENTED` #309/#252 closed, #152/#254 deferred, #215/#199 blocked | **CLOSED AS TRIAGE**, non tutte PR fuse |
| A20-13 | `DOC SOURCE MERGED` README, AGENTS, ROADMAP #367 | eventuali nuovi artifact/device richiedono receipts |
| A20-14 | `DOC SOURCE MERGED` Design-App #47, quattro link non più dead | originali UIR mancanti **NOT RECOVERED**; preferenze preservate |
| A20-15 | `EXACT-HEAD SCANNER PASS` #44430371797, 356 Dart, zero skipped/legacy | 279 euristiche review, non auto-trattare come 279 bug |
| A20-16 | `M5 BENCHMARK PROTOCOL READY` sei scenari | p95/jank/RAM su device **NOT MEASURED** |
| A20-17 | `DEFERRED BY USER` #355, guide principali già presenti | wave secondaria solo dopo frizioni reali documentate |
| A20-18 | `LIVE PROVIDER READ-ONLY VERIFIED` 16 tabelle RLS on, 2 WARN security, 14 INFO perf | due WARN **OPEN**, senza mutazioni |
| A20-19 | `ARTIFACT_BUILT / HASH+CERT PASS` rc.6+140 [run #44433294681](https://github.com/riccardopinato/Agenda-per-Anna/actions/runs/44433294681), [receipt](release_evidence/ANDROID_RC6_140_SIGNED_ARTIFACT_RECEIPT_20261119.md); APK versionCode 2140, SHA-256 validato, cert v2 uguale a +139 | **device install/update/backup/31 scenari NOT_VERIFIED** |
| A20-20 | `M5 OFFICIAL POLICY CHECK/PLAY MATRIX READY` API36, RevenueCat, salute | AAB/console, acquisto/restore e Data Safety **NOT VERIFIED** |

### Stop rule: niente completamento inventato
La richiesta del titolare di «chiudere tutti i 20 punti» significa **eseguire tutto ciò che è tecnicamente verificabile**, e lasciare solo veri gate esterni con motivo/owner e azione riproducibile. Non dichiarare chiuso come `DEVICE_VERIFIED` o `STORE_READY` un test non svolto. Non cancellare le sette idee rinviate, non introdurre una seconda sync, non toccare data/ACL/Vault per un restyling e non lanciare Play Store senza test reali.
