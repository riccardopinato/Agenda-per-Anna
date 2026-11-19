# M2 — Account, media, backup e Insieme: QA di consolidamento
Stato: **SOURCE REGRESSION ADDED / PHYSICAL AND TWO-PWA QA NOT VERIFIED** · 19/11/2026

## Prerequisiti e confini
La base approvata è il vecchio `main@adbab7db67a1262a5255a64e4aa34da376d6d051`, Flutter +139, Factory `6dfde2d6b6a5be6cbc898cea137f87803701814d`. Verificare nuovo HEAD dopo eventuali merge. L'app resta diario personale local-first, Classic reversibile, senza seconda cache, nuovo account store o modifica Vault. Le schermate condivise usano i permessi/RPC già esistenti; il solo widget test **non** certifica la revoca lato Supabase.

## Nuova prova riproducibile automatica (test isolato)
`flutter test --reporter expanded test/m2_cross_account_vision_board_backup_test.dart`:
- uso di **soli account, etichette e byte sintetici**;
- Vision Board con foto nel profilo A; backup ZIP include il riferimento originale e gli esatti byte;
- switch a B: la galleria e il diario sono vuoti per A; export ZIP B non contiene testo/media di A;
- salva board privata in B; ritorna ad A: board A integra, nessun dato B visibile/in ZIP;
- guard dell'editor catturato prima di A→B→A non può più salvare in A.
Queste sono asserzioni del **store locale e serializer**, non prove di PWA/Android reali.

## Matrice reale con due dispositivi/PWA A e B (issue #297 e #329)
| Gate | Azione con sole fixture sintetiche | Risultato iniziale | Evidence richiesta |
|---|---|---|---|
| M2-PWA-01 | Installare/riaprire due PWA e registrare build SHA esatto | NOT_VERIFIED | OS/browser/versione, screenshot senza dati privati |
| M2-PWA-02 | A crea/modifica foto, testo e frecce nella board; B resta separato | NOT_VERIFIED | record ID fittizi e differenze reali |
| M2-PWA-03 | A→B→A con editor, file-picker e conferma Cestino aperti | NOT_VERIFIED | nessuna write/stale action o perdita |
| M2-PWA-04 | Filtri Personale/Condiviso, ritorno e ripristino Trash | NOT_VERIFIED | board A mai resa in Shared-only |
| M2-PWA-05 | ZIP/JSON export A, ripristino su profilo **isolato** B | NOT_VERIFIED | hash file e asset, links/riferimenti integri |
| M2-PWA-06 | Interruzione del restore, file corrotto, media assente | NOT_VERIFIED | rollback, dati precedenti integri |
| M2-PWA-07 | 20–30 fotografie reali di **test**; zoom/pan/export PNG | NOT_MEASURED | trace, screenshot e tempi reali |
| M2-SHARED-01 | Owner invia codice/QR valido e scaduto; secondo/terzo spazio | NOT_VERIFIED | server response, ruoli e nomi canonici |
| M2-SHARED-02 | A crea/modifica, B riceve e modifica; offline/reconnect e conflitto | NOT_VERIFIED | ack backend + stato finale di entrambi |
| M2-SHARED-03 | Owner revoca B e B tenta update da cache offline | NOT_VERIFIED | rifiuto server e purge mirror dopo riconciliazione |
| M2-D7-01 | Android picker, ZIP, rollback interrupted, shared photo GC | NOT_VERIFIED | D7 DS-01…DS-06 |
| M2-D7-02 | Vault PIN/biometria/Keystore/Recents & shared passwords | NOT_VERIFIED | D7 VAULT-01…04 e NOI-01…03; **nessuno screenshot privato** |
| M2-D7-03 | Push/local notification, reboot, deny/grant, DST | NOT_VERIFIED | D7 NATIVE-03, timestamp/device/permission state |
| M2-PROVIDER-01 | Supabase migrations/advisory RLS/pg_net read-only | NOT_RECHECKED | revisione admin non distruttiva, #182 |

**Stop immediato:** perdita dati, prova cross-account di contenuto privato, write server da utente revocato, backup di cui non si verificano gli asset, o PIN/biometria aggirati. Non fare merge di OAuth Direct #199, Privacy V2 #215, non usare dati reali nel runner e non attivare Premium preview per falsificare le prove.

## Metodo
- Prima del device QA produrre backup di sicurezza **verificato** su supporto indipendente; nessun `adb shell pm clear`, reinstallazione o restore sopra l'account personale.
- Identificare data, build SHA, dispositivo/browser, account fittizio, caso, PASS/FAIL/BLOCKED/NOT_RUN, foto redatta o hash; memorizzare evidenze private fuori dal repo.
- Se uno scenario fallisce, aprire fix mirato e test regressivo; non estendere l'intervento a nuovi moduli o al backend reale.
- L'offline PWA era `DEFERRED_BY_USER`: testare la veridicità degli stati quando online/offline, ma **non** convertire quel rinvio in P0 senza nuova decisione.
- Questa matrice integra ma non sostituisce [D7](../V100_D_SECURITY_NATIVE_PHYSICAL.md), [S13](../WEBFIRST_S13_VISION_BOARD_PWA_ACCEPTANCE_20261110.md), [issue #297](https://github.com/riccardopinato/Agenda-per-Anna/issues/297), [#329](https://github.com/riccardopinato/Agenda-per-Anna/issues/329).

**Definition of Done M2 software:** test mirati + full CI/AppLab/Web exact-head, merge, assenza di regressioni. **Definition of Done M2 prodotto**: matrici reali con prove; fino ad allora stato `PHYSICAL_TWO_CLIENT_NOT_VERIFIED`.
