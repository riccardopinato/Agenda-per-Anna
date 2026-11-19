# Anna's Diary — Backlog scremato A20: 13 residui effettivi
**19 novembre 2026 — decisione di sfoltimento dopo integrazione M1–M5.** Questo è l'**indice operativo di ciò che rimane**; il [registro 20 punti](ANNA_CONSOLIDATION_20_POINT_EXECUTION_20261119.md) mantiene lo storico verificabile e gli ID originali. Non sono nuove issue né nuove capability.

## Identità ed evidenza attuale
- `main@e9b3541dbbade080952ff88bf5138f5d2eb97980`, versione sorgente `1.0.0-rc.6+140`, [postmerge Development checks PASS](https://github.com/riccardopinato/Agenda-per-Anna/actions/runs/44435654931).
- APK ARM64 firmato [run #44433294681](https://github.com/riccardopinato/Agenda-per-Anna/actions/runs/44433294681), artifact `14487751762`, source esatta `2395ca6f78ff35a9d65f59f6809b4be7d11fcee6`, Android versionCode `2140`, APK SHA-256 `196a3310fd3043745e5a7b5fc7eec68d2b3a386e2e37683b77e492cb5f86a237`; il successivo commit M5 è **solo documentale**. [Receipt dettagliata](release_evidence/ANDROID_RC6_140_SIGNED_ARTIFACT_RECEIPT_20261119.md).
- Nessuna prova di installazione su device, due PWA installate, backup Android fisico, accettazione visuale 10/10 o Google Play Internal Testing. Rispettare `SOURCE != CI != ARTIFACT != DEVICE != STORE`.

## A. CHIUSI COME ATTIVITÀ AUTONOME — 5/20
| ID | Esito conclusivo circoscritto | Cosa NON si afferma |
|---|---|---|
| **A20-01** | **CLOSED / BASELINE TRACEABILITY**: mapping source→CI Web→APK→signer/hash disponibile su +140, receipt e storico. La componente *device* è ora **unicamente** nel gate A20-19 per non duplicare | NON prova di update fisico o dei dati del dispositivo |
| **A20-12** | **CLOSED / PR TRIAGE**: #309 e #252 chiuse per supersedimento; #152 QA donor, #254 esperimento; #215 Privacy V2 e #199 OAuth Direct deliberatamente DO NOT MERGE. Le 4 restanti non sono PR da unire automaticamente | NON significa implementare #152/#254/#215/#199 o approvare nuovi scope |
| **A20-13** | **CLOSED / DOC RECONCILIATION**: README, ROADMAP, AGENTS e registro su +140 dopo #367/#371; CI postmerge PASS | Gli aggiornamenti futuri devono restare ancorati a SHA/artefatto, senza riaprire questo audit |
| **A20-14** | **CLOSED / BROKEN LINKS REPAIRED**: Design-App [PR #47](https://github.com/riccardopinato/Design-App/pull/47) corregge i riferimenti e preserva i 4 UIR. Gli originali JPG 12/11 sono marcati `MISSING_BINARY`, **non inventati** | NON significa aver recuperato i 4 JPG o averli introdotti nell'app; recupero opzionale separato se richiesto |
| **A20-15** | **CLOSED / SOURCE AUDIT RUN AND RULE-FAMILY TRIAGE**: scanner esatto su PR head, 356 Dart, 0 skipped, 0 LEGACY; 279 REVIEW classificati per famiglia in [M5 Dart triage](qa/M5_DART_356_CHECKOUT_TRIAGE_20261119.md) | NON equivale a 279 bug risolti né a validazione semantica manuale di tutte le occorrenze; singoli casi diventano attività soltanto se emerge un difetto concreto |

**Criterio per riapertura:** nuova evidenza di rottura, drift o richiesta esplicita; **non** riaprire per la sola presenza di uno storico, advisory euristico o asset personale non allegato.

## B. NON ATTIVI — 2/20 (conservati, non spacciati per risolti)
| ID | Trattamento | Riattivazione |
|---|---|---|
| **A20-09** | **ABSORBED into A20-08**. Nessuna generica nuova wave estetica: se il confronto 10/10 evidenzia un delta reale, aprire un fix mirato nel *medesimo* processo A20-08 | Solo difetto riproducibile e revisionato contro mockup già approvato |
| **A20-17** | **DEFERRED BY USER** in [#355](https://github.com/riccardopinato/Agenda-per-Anna/issues/355); guide principali già implementate, Wave 2 secondaria non autorizzata ora | Solo frizione d'uso dimostrata o nuova decisione del titolare |

## C. BACKLOG OPERATIVO — 13/20 (nessuno è dispositivo/Store PASS)
| ID | Residuo **non ancora certificato** | Priorità operativa / owner originale |
|---|---|---|
| **A20-19** | Installare **in-place** su ARM64 dedicato con firma versione già installata verificata, backup indipendente testato, 31 casi fisici e assenza perdita dati. **APK +140 firmato/esatto già prodotto; NON ricompilarlo per ripetizione** | **P1 · primo gate Android** · [#329](https://github.com/riccardopinato/Agenda-per-Anna/issues/329) |
| **A20-02** | A→B→A su **due client installati** durante editor/picker/Trash; isolamento privacy end-to-end | P1 · [#329](https://github.com/riccardopinato/Agenda-per-Anna/issues/329) / [#297](https://github.com/riccardopinato/Agenda-per-Anna/issues/297) |
| **A20-03** | ZIP/JSON + foto/audio/Trash/restore su provider Android/PWA reali, file corrotto/interruzione, rollback e hash media | P1 · #329 |
| **A20-04** | 2 PWA installate, editing Vision Board, immagini, filtro privato, refresh, export/ripristino cross-device | P1 · [#297](https://github.com/riccardopinato/Agenda-per-Anna/issues/297) |
| **A20-05** | Condivisione Insieme: inviti/QR, revoche, owner/member, offline ACK e conflitti con due account reali sintetici | P1 · #329 |
| **A20-06** | Cassaforte su device: PIN, biometria, Keystore, privacy di background/Recents, recovery; **non toccare l'implementazione sensibile senza bug comprovato** | P1 · #329 / D7 |
| **A20-07** | Reminder/push/bridge Android: permessi, reale delivery, riavvio, cambio fuso/DST, interazione tap/snooze | P1 · #329 |
| **A20-08** | Confronto finale N18-01…10 con schermate Flutter reali e decisione di accettazione. **A20-09 confluisce qui solo se emergono difetti** | P1 · [#327](https://github.com/riccardopinato/Agenda-per-Anna/issues/327) |
| **A20-10** | CAP-0069: 70 baseline + 70 candidate PNG e manifest trusted, confronto senza prova sintetica artificiosamente promossa ad approvazione | P2 · [#237](https://github.com/riccardopinato/Agenda-per-Anna/issues/237) |
| **A20-11** | Matrice reale 5 lingue, 320/390/600dp, font 200%, focus, TalkBack/VoiceOver e reduced motion | P2 · #329 / #327 |
| **A20-16** | Benchmark in Flutter profile mode su hardware: startup, p95/jank, RAM, media e grandi raccolte, campioni comparabili | P2 · #329 |
| **A20-18** | Due WARN Supabase ancora aperti: protezione password compromesse e `pg_net` in `public`. Metadata RLS già letti, **non** correggere via SQL mutante senza approvazione/change e staging | P2 admin/security · [#182](https://github.com/riccardopinato/Agenda-per-Anna/issues/182) |
| **A20-20** | Google Play AAB/Internal Testing, RevenueCat acquisto/restore reali, dichiarazioni Data Safety/Health, URL privacy/deletion. **Non è un gate immediato per l'APK sideload personale** | **P3, separato dalla stabilizzazione**, [M5 checklist](qa/M5_PROVIDER_PERFORMANCE_STORE_GATES_20261119.md) |

### Esecuzione senza doppioni: sei gruppi, solo test restanti
1. **Android e dati** — A20-19 + 03 + 06 + 07: release firmata già pronta, usare fixture sintetiche e 31-test senza reset su telefono personale.
2. **Condivisione e due account** — A20-02 + 05: due client con ACL/revoche reali, senza promuovere widget tests a QA.
3. **Vision Board/PWA** — A20-04, accorpare prove backup/restore già previste in 03.
4. **Accettazione UI** — A20-08 + 10 + 11: stessa fixture, schermate reali, a11y e approvazione dell'utente; niente nuovo redesign.
5. **Performance + provider** — A20-16 + 18: benchmark dedicati e admin read-only/controllo change; 2 WARN rimangono reali.
6. **Store futuro** — A20-20: predisposizione già documentata; attivazione solo quando si decide di distribuire tramite Play, senza fingere acquisti sandbox effettuati.

### Numero ufficiale dopo scrematura
**5 attività risolte/chiuse come scopo; 1 assorbita da altra attività; 1 differita; 13 residui autentici.** Le cinque chiuse escono dalla lista prioritaria; lo storico resta. **Non** si chiudono automaticamente gli issue #297/#327/#329/#237/#182 perché i rispettivi gate di accettazione sono ancora aperti. La #355 rimane con stato di decisione differita, senza caricarla nei lavori attuali.
