# Anna's Diary — S11-D: Vision Board privata nei Ricordi e integrità lifecycle

**Data:** 10 novembre 2026 · **Baseline centrale:** App-Factory-Core
`d4ed1185d36d419228fba6b57a979cde308bd321` (Master v27,
Golden v29 già risolti in S11-A; non riletti). **Base Anna:**
`f12e6a54fc982ca48593aa476daa05a50e76d226` (S11-C merged,
main CI + Pages SUCCESS).

## Perimetro autorizzato
Vision Board individuali già ammesse nel Product Bible e fondate su
`DiaryBlockType.sketch` + `DiaryCreativeSubtype.visionBoard`. Nessun database,
ACL, provider cloud, media editor, tab principale, import automatico, vault,
condivisione Noi ♡ o APK nuovi.

## Implementazione
- `lib/src/diary/diary_vision_board_gallery.dart`: raccolta dedicata
  accessibile da Ricordi > Per te (solo profilo personale, non pagina con
  filtro persona o shared-only), ordinamento dal journal canonico. Anteprima
  Sketchbook, apertura editor S11-C, azione Collega ricordi, Cestino, link
  correnti navigabili al Planner. Testi originali IT/EN/ES/FR/PT. Nessuna
  persistenza nuova, nessuna modifica al modello.
- `VisionBoardMemories.current` risolve un blocco ancora attivo nello
  stesso snapshot; i riferimenti archiviati, rimossi, account scope non pronto
  o shared-only non sono mostrati.
- `VisionBoardMemories.saveLinks`: riuso del picker personale già presente
  in `search_connections_domain.dart` ma commit attraverso
  `AgendaStore.saveJournal` con `Cap0160TagEditGuard` esatto. Max 12 ID
  distinti, solo target attivi del diario personale, esclude sé stessi.
  Non usa `setDiaryBlockConnections` perché il setter generico non accetta
  un guard di epoch. A→B→A e riferimento stale vengono rifiutati.
- Cestino: `moveDiaryBlockToTrash` e `restoreTrashEntry` esistenti;
  `DiaryBlock.toLocalJson` conserva subtype, pagine e relatedBlockIds. La
  funzione di spostamento controlla il guard immediatamente prima della
  chiamata al Cestino; l'implementazione legacy del mutatore non è ancora
  completamente transaction-aware rispetto a un account switch durante
  l'await di persistenza: **limite da auditare in S11-E trasversale**.
- Export portabile del diario/coda private cloud: `_portableSketchPages`
  ora accetta `requireCompleteImages` per i soli blocchi Vision Board.
  Se un'immagine referenziata è assente o è base64 invalido, solleva
  `StateError(vision_board_missing_media/vision_board_invalid_media)`:
  niente esportazioni che attestino fotografie perdute. Gli Sketchbook legacy
  mantengono il comportamento precedente. Questo può intenzionalmente
  bloccare il trasporto cloud di un board danneggiato: riparare l'asset,
  non inventare fotografie né fare upload incompleto.
- Backup ZIP: conserva i media binari e i blocchi serializzati. Nuovi test
  di roundtrip con immagini e collegamenti, più test Cestino. Sono prove
  sintetiche, non un restore fisico end-to-end su un secondo telefono.
- Media transient di foto importate e poi scartate: l'asset store attuale ha
  una manutenzione programmata di pruning, non un orphan-cleanup per singola
  bozza che sappia riconoscere un altro editor aperto. Non si cancellano
  media direttamente per evitare data loss; audit specifico S11-E.

## Acceptance evidence gate
- Nuovi test `test/webfirst_s11d_vision_board_memories_lifecycle_test.dart`
  per dati privati, limite collegamenti, stale A→B→A, archived/shared-only,
  Trash/restore, ZIP con media, widget 320dp.
- Flutter Analyze, suite completa, C2, Web Vault crypto, build Web release;
  Web PR build e AppLab Source Gate sullo stesso SHA del PR head.
- Review senza blocker, strict-main sync e required checks, merge protetto.
  Dopo merge, Development e Pages `push main` **stesso SHA**.
- Two-PWA, screen reader, UX su hardware, backup cross-device/cloud e
  performance: **NOT_VERIFIED** fino ad evidenza fisica.
- APK/Google Play e offline PWA **esclusi**.

## S11-E residuo
Matrice browser/PWA/gesti/accessibilità cinque lingue e account reali,
hardening gestione media transient, verifica export PDF/PNG e validazione
cross-device di backup/restore e isolamento account, audit completo
dell'asincronia delle mutazioni Cestino, profiling e release receipt.
