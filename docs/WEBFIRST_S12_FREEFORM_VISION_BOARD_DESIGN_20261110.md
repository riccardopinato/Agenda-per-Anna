# Anna's Diary — S12: Vision Board a tela espandibile + ingresso Crea +

**Data:** 10 novembre 2026. **Origine:** prova manuale riferita dall'utente
per la Vision Board precedente, che ha confermato creazione→foto→salvataggio→
Ricordi e scarto bozza, ma ha rilevato i limiti dei 3/4 slot foto predefiniti
e del pulsante + che aggiunge una pagina bianca.

**Source baseline Anna:** `8bfb4bcd58e820c995bd913e2c8f08c223c2b45d` (PR #298,
solo prototipo documentale). **Factory baseline già fissata nel ciclo S11-A:**
`App-Factory-Core@d4ed1185d36d419228fba6b57a979cde308bd321`
(Master v27, Golden Index v29). Questa PR non aggiorna la Factory centrale.

## Audit donor Notes-Ecosistema e scelta architetturale
- Analizzato `riccardopinato/Notes-Ecosistema@09fbd28728178078fa281f5a0010b50ca1eb5375`
  in `flutter_app/lib/src/screens/whiteboard_screen.dart`. Il donor usa
  `TransformationController`, `InteractiveViewer.builder`, camera centrata
  e crescita a segmenti del mondo visibile; include toolbar per mano,
  disegno, testo, frecce e storico.
- **Riuso del principio architetturale, non un'incorporazione di SDK o di codice
  terzo:** Vision Board usa l'editor Sketchbook canonico già esistente in
  Anna e solo un helper geometrico separato `VisionBoardWorld`. Nessun nuovo
  package, sistema di media o database.
- Legacy: i punti normalizzati `x/y ∈ [0,1]` di S11-B/C/D/E corrispondono
  allo stesso riquadro iniziale 640×853⅓ (proporzioni 3:4) nella scena espandibile. I nuovi punti
  possono essere negativi o maggiori di 1, senza migrazione dello schema.
  Una board con vecchie pagine multiple mantiene la navigazione tra pagine,
  ma il comando + non crea ulteriori pagine.

## Nuovo comportamento
- **Vision Board soltanto:** canvas con scena centrata, dimensioni che crescono
  se elementi o viewport avanzano, pinch zoom e modalità Mano per pan,
  zoom +/− e centra. Su penna/freccia l'utente trascina per disegnare.
  L'editor Sketchbook tradizionale mantiene pagina 3:4 e add-page.
- **Nessun vincolo di slot:** un preset conserva eventuali rettangoli originali
  come decorazioni/guide modificabili, ma aggiungere una foto non attiva più
  l'autodisposizione nelle cornici. Le foto e i testi vengono inseriti al
  centro dell'area visibile, anche dopo pan/zoom.
- **Pulsante + nella Vision Board:** menu Foto/Testo/Freccia/Disegna.
  Scomparsa dell'azione Nuova pagina per le board a pagina unica.
  Eventuali board legacy multipagina mantengono indici e frecce di accesso.
  Disposizioni collage restano disponibili solo come opzione esplicita.
- **Frecce vettoriali:** nuovo valore append-only `DiarySketchTool.arrow`,
  reso come linea e due segmenti orientati; serializzazione del tool tramite
  `.name` esistente e lettura fail-soft dei tool ignoti già presente.
- **Crea + globale:** aggiunge una voce Vision Board visibile nel menu
  (opzione privata pin nell'area principale quando non sia tra le top 4),
  rispettando l'account epoch, il filtro shared-only e
  `VisionBoardFoundation.saveDraft`; nessuna nuova route o writer.
- **Esportazione PNG:** per scene estese cattura il *viewport visibile* tramite
  `RepaintBoundary` di dimensioni schermo, non un'immagine 5000×5000 a
  multipli pixel ratio. L'export completo dell'intera board, PDF, minimappa,
  allineamento magnetico e drag-and-drop desktop restano successive estensioni
  non comprese in S12.

## Gates e non regressione
- Sintesi schema/backward compatibility per punti e foto originali.
- Test helper pan/zoom/world growth, coordinate negative e grandi, frecce,
  creazione contenuti vs creazione pagine e compatibilità Sketchbook.
- Dev-checks: analyze, Flutter test completi, C2, Vault crypto, build Web
  release; build Web PR e AppLab Source Gate, review senza blocker e strict
  main. Merge solo dopo gate protetti, poi Development e Pages *push main* su
  esatto merge SHA.
- Test fisici rimangono **NOT_VERIFIED** finché non vengono eseguiti:
  pinch zoom e disegno su due telefoni, 30 foto, testo/freccia, pan
  tra aree molto lontane, persistenza dopo refresh, import/scarto con
  immagini, backup ZIP, screen reader, Crea + da tutte le schede,
  accesso da Ricordi e passaggio account A→B→A.
- Nessun APK, nessuna modifica all'offline PWA, nessuna pretesa di
  certificazione fisica tramite le sole GitHub Actions.
