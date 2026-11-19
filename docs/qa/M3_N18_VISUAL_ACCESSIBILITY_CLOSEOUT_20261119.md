# M3 — N18 10/10 Flutter visual and accessibility closeout
19 novembre 2026 · **evidence-first, Design-App first, no redesign of Vault**

## Decisione e source baseline
L'utente ha approvato 10 mockup N18 il 18 novembre (design) e ordinato il 19 novembre di **finalizzare e collaudare, non espandere**. App source al kickoff `adbab7db67a1262a5255a64e4aa34da376d6d051` (+139). Existing PR #357–#366 are already merged and must **not** be re-implemented. Factory `6dfde2d6b6a5be6cbc898cea137f87803701814d` v27/Index29, Design-App main at kickoff `068264f82d10bd645ea18b3ae13efa5bb9555734`.

**Reference prese PRIMA di nuove idee**: `UIX-STYLE-004` NEO-APPLE e `UIX-STYLE-007` PASTEL UI = **ADATTATA**; `STYLE-A` Editorial Personal, `MOCK-STYLE-008` Organic = **ADATTATA** con Manrope/Lora, palette 5+HSV e carta già presente. `MOCK-STYLE-005` Polaroid = SOLO DA VALUTARE per fotografie reali; nessun asset terzo importato. Vecchi `UIR-0003/0014/0021/0029` puntano ad immagini non pubblicate nel file storico; `UIR-0051/0052/0076` esistono ma NON sono sostituti verificati. Correggere solo l'indice della libreria con provenance/owner. Nessun Material 3 look generico obbligatorio; host tecnico mantenuto dove serve.

## Copertura dieci superfici e gate che mancano
| ID | Superficie e codice N18 già presente | Effettiva verifica prima della chiusura |
|---|---|---|
| N18-01 | Oggi / Week Review, PR #359 | Fixture vuota/piena, rispetta selected-day, schermi narrow + text 2× |
| N18-02 | Calendario Mese/Settimana, PR #335/#346 | Eventi lunghi, marker, mese→settimana→giorno; no duplicato |
| N18-03 | Impegni compatti + timeline, PR #360 | Eventi contemporanei, schermata 320dp, tastiera + CTA |
| N18-04 | Crea + gruppi, PR #361 | Tutte 13 azioni raggiungibili; editor data/scelta; cancel |
| N18-05 | Ricordi, PR #362 | Album foto reali a rapporto originale, testuale non alto come foto, zero dati inventati |
| N18-06 | Insieme label, hub e status, PR #357/#365/#366 | Due owner/member, cache/offline/errore, zero preview private dopo A→B→A |
| N18-07 | Altro/Esplora, PR #363 | Group navigation completa con moduli inattivi davvero nascosti |
| N18-08 | Impostazioni/HSV, PR #364 | Five presets + custom HEX, draft/apply, dark, 320dp+200%, 5 lingue |
| N18-09 | Cerca/Inbox, PR #358 | Un carattere, sort, tag archiviati, navigazione e ricerca senza Vault |
| N18-10 | Cross-screen dock/semantica/stati | Back, insets, keyboard, reduced-motion, loading/error truth, contrasto |

Questa tabella è una **lista di criteri**, non dieci PASS. `test/m3_appearance_hsv_accessibility_test.dart` aggiunge un vero Flutter widget check del picker HSV a 320dp/200% in tema scuro: azioni impilate, HEX invalidato, selezione draft non persiste. Non produce da solo screenshot e non sostituisce screen reader manuale.

## Matrice screenshot da acquisire (N18 ed issue #237)
1. Sorgente con SHA e Flutter SDK fissati; fixture **sintetiche e realmente renderizzate**. Prima/current e dopo con *identico* contenuto (vuoto e popolato), viewport 320×640, 390×844, 600/tablet, locale IT/EN/ES/FR/PT, Light/Dark e custom HSV, font 1.0/1.6/2.0, reduced-motion.
2. Ogni N18: screenshot attuale, riferimento mockup decisionale, diff di gerarchia e leggibilità, cosa già corrisponde, cosa manca; owner approva o chiede singolo fix. I 14 PNG Insieme della PR #366 coprono **solo** guest/help: non inventare screenshot per altre nove schermate.
3. CAP-0069: dieci checkpoints × sette varianti con **70 PNG baseline + 70 PNG candidate**; creare manifest dei due lotti, mai generare baseline=future per auto-approvazione. Il comparatore source PASS è distinto da evidenza reale e user acceptance.
4. File JPEG della libreria Design-App: registrare ID, path esatto, commit, titolarità e licenza per ogni reference scelta; vecchi link UIR rotti segnati `MISSING_BINARY` fino al recupero, nessuna corrispondenza presunta.

## QA operatore e criteri tecnici
- L10n: cinque lingue, stringhe complete sui flussi secondari e native, lunghezze reali, font 200%, RTL solo se supportato; no regressioni di numeri e date.
- A11y: TalkBack/VoiceOver su device, hit target e nomi controlli, focus tastiera/dock, rotazione, reduced motion, alto contrasto e stato errore offline; nessun glimmer/slop non funzionale.
- Media: provare proporzioni e viewer, ritorno editor, 20–30 foto synthetic, file JPEG autentici solo dati di test.
- Performance: raccogliere startup, frame p95/jank, RAM e scroll con ambiente identico, 3+ campioni, distinguere Flutter widget-wall-time da benchmark GPU/Android; ancora `NOT_MEASURED`.
- Nuove guide secondarie #355 solo dove problema d'uso provato, tutte localizzate; non introdurre un nuovo onboarding forzato.
- **Do not** modificare Vault, Account, shared ACL, persisted media, Classic o status sync da un task di design. Microfix soli quando riproducibili; nuove idee salvate nel repo idee e lasciate `DEFERRED`.

**DoD M3 software:** N18 crosswalk con same-fixture source, widget test CI PASS, PR separata e merge. **DoD M3 estetico:** approvazione esplicita resa Flutter finale; **DoD dispositivo:** screenshot, a11y e perf misurati sul device; non autocertificabili.
