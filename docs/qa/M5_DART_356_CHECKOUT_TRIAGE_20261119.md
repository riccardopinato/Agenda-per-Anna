# Flutter/Dart checkout source audit — exact-head triage (19/11/2026)
Stato: `SCAN_PASS / 279 HEURISTIC REVIEW / NO MASS REFACTOR`.

## Provenienza
Workflow [Anna full Dart checkout audit #44430371797](https://github.com/riccardopinato/Agenda-per-Anna/actions/runs/44430371797); artifact JSON `anna-dart-full-source-audit-2f6982c95d5970b1c3855641879dd955629c39e4` (ID `14486211822`). **Source ref esatto**: `2f6982c95d5970b1c3855641879dd955629c39e4` (PR [#369](https://github.com/riccardopinato/Agenda-per-Anna/pull/369)). Script canonico: `tool/audit_flutter_antipatterns.py`, provenance esterna `Idee-app-Archivi-riferimenti@8fdc4e1f: scripts/audit_flutter_antipatterns.py`. La PR M4 #370 successiva cambia soltanto metadata versione e documento candidato: non trasforma retroattivamente i risultati di questo scan in una certificazione runtime.

## Dati realmente letti da report JSON
- `scanned_dart_files=356`, `skipped_files=0`, `truncated=false`;
- `legacy_api_detected=false` (zero firme LEGACY_API ad alta confidenza);
- **279 REVIEW euristici, non 279 bug**:

| Regola | Count | Interpretazione / decisione conservativa |
|---|---:|---|
| `native_dart_io` | 153 | import/uso di I/O nativo, presenti anche in test, script o codice condizionale; build Flutter Web exact-head PASS. Valutare singolo path solo per bug Web riproducibile, niente rimozioni generalizzate |
| `eager_listview` | 68 | `ListView(` potenzialmente costosa su elenco lungo; senza frame metrics/device non è prova di jank. Per dati grandi, misurare PERF-02/03 prima di migrare a builder |
| `legacy_preferences` | 57 | chiamate a `SharedPreferences.getInstance()` in servizi (es. calendario esterno/push); non automaticamente duplicati di `AgendaStore`. Verificare origine/scope/lifecycle per ogni refactor proposto |
| `async_void_handler` | 1 | `lib/notification_service.dart:13`, callback top-level `@pragma('vm:entry-point') void notificationTapBackground(NotificationResponse response) async`. Collegata esplicitamente a `onDidReceiveBackgroundNotificationResponse`; la signature callback è un vincolo dell'API del plugin; non convertirla ciecamente a Future rompendo l'entry-point. QA notifica Android reale resta P1 |

## Triage operativo
- `LEGACY_API`: **0, nessuna modifica obbligatoria confermata**;
- `REVIEW`: **279, classificazione per famiglia completata**; la convalida semantica di ogni singola istanza e i benchmark restano `NOT_VERIFIED` finché non ci sono issue/riproduzioni. L'assenza di legacy non significa assenza di bug.
- `FIX_CURRENT_STEP`: **nessuna modifica di codice** sulla sola base di questo report; il lavoro è in finalizzazione/QA, quindi stop a refactoring indiscriminato.
- `BACKGROUND_MAINTENANCE`: solo casi con prova specifica di duplicazione, crash Web, perdita di stato o jank. Per un eventuale edit aprire branch isolato con test e guard di migrazione; mai introdurre seconda persistenza o cambiare Vault.
- **Source/review vs physical**: Dev/Web CI PASS, emulatore/telefono/notification background callback non certificati dal detector.

Questa analisi soddisfa la **riesecuzione A20-15 e il triage per famiglia**, non il controllo manuale di tutte le 279 righe; non trasformare l'euristica in 279 task o in `TECH_DEBT_FIXED`.
