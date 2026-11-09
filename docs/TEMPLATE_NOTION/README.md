# Template Notion — Anna's Diary

Catalogo **di ricerca** per i template Notion la cui utilità principale riguarda la **vita personale** di Anna's Diary: diario, ricordi, routine leggere, obiettivi personali, pianificazione quotidiana, viaggi, raccolte di foto, Vision Board personali e `Noi ♡` quando gli accessi sono espliciti.

**Questa è una cartella di documentazione GitHub, non una nuova sezione visibile nell'app.** Nessun template Notion esterno è stato importato o installato.

## Indice template assegnati ad Anna

| ID Anna | Template | Categoria | Evidenza | Stato prodotto | Scheda |
|---|---|---|---|---|---|
| TN-ANNA-0001 | Routines Activities | Rituali / routine giornaliere e settimanali | **E2 Markdown + 4 immagini** | PROPOSTA — riuso di rituali esistenti | [Analisi](SCHEDE/TN-ANNA-0001-ROUTINES_ACTIVITIES.md) |
| TN-ANNA-0002 | Weekly Planner | Pianificazione leggera | **E0 funzionale** — export contiene solo intro/upsell | RINVIA — export incompleto | [Analisi](SCHEDE/TN-ANNA-0002-WEEKLY_PLANNER_INCOMPLETE.md) |
| TN-ANNA-0003 | Weight Loss Tracker | Wellness sensibile | **E2 Markdown + CSV + GIF** | BLOCCATO — product/privacy gate | [Analisi](SCHEDE/TN-ANNA-0003-WEIGHT_LOSS_TRACKER_RESTRICTED.md) |

Il [registro strutturato](CATALOGO.json) distingue **ricerca, sorgente incompleta e blocco privacy**: una scheda presente non autorizza l'integrazione Flutter.

## Template citati ma assegnati ad altre app

- **Second Brain (PARA Dashboard)**, Abdo Karamallah — assegnato **primariamente a Notes**. La scheda è nell'[indice Notes](https://github.com/riccardopinato/Notes-Ecosistema/tree/main/docs/TEMPLATE_NOTION) e nell'[archivio di riferimento App Factory](https://github.com/riccardopinato/Idee-app-Archivi-riferimenti/tree/main/17-RICERCA-TEMPLATE-UX). Per Anna possono essere valutati *soltanto come spunti astratti* Quick Actions, card personali e recupero dei ricordi. Non entra nell'indice Anna perché un workspace PARA/CRM professionale è fuori dal Product Bible.

## Regole per i prossimi template

- **Scegli la destinazione dal caso d'uso**: Notes per Second Brain, Study, progetti, knowledge e produttività; Anna per diario, rapporti personali, abitudini quotidiane, ricordi e Vision Board di vita. Se un template è effettivamente rilevante per entrambi, aggiungere due schede di adattamento app-specifiche, collegate a **un unico ID del riferimento centrale**, evitando copie dei file originali.
- **Product Bible vincolante**: Anna resta diario personale + agenda leggera + ricordi; nessun clone Notion, nuovo project manager, CRM o secondo database. `Noi ♡` condivide solo i record autorizzati; Vault invariato e non coinvolto da riferimenti esterni.
- **Evidenza**: E0 titolo, E1 descrizione/screenshot pubblici, E2 export Notion realmente esaminato, E3 solo eventuale donor codice con licenza e test. E1 non significa che database e formule siano stati letti.
- **Stati indipendenti**: RICERCA / PROPOSTA / APPROVATO / IN_CODICE / TESTATO / RELEASE / SCARTATO. Un'idea adottata in Notes **non** diventa automaticamente funzione implementata in Anna.
- **Privacy, diritti, UX**: non pubblicare acquisti, ricevute, ZIP di template, account, immagini o formula proprietaria; riuso concettuale clean-room. Conservare stile DS6 editoriale, personalizzazione esistente, privacy, sincronizzazione e backup.
- **Riuso-first**: usare i percorsi canonici `Unified Capture`, modelli di diario, `AgendaPreferences`, giorno realistico, Week Review, Memories e `Noi ♡` prima di proporre una nuova source of truth.

## Procedura per nuovi invii

1. Cercare il template nel [catalogo centrale](https://github.com/riccardopinato/Idee-app-Archivi-riferimenti/tree/main/17-RICERCA-TEMPLATE-UX) e verificare se è già assegnato a Notes/Anna.
2. Aprire una scheda secondo [MODELLO_SCHEDA.md](MODELLO_SCHEDA.md), assegnando ID monotono `TN-ANNA-NNNN` **solo** quando il template è coerente con Anna.
3. Inserire nell'indice di questa pagina e in `CATALOGO.json` il medesimo ID/scheda/stato in una PR.
4. Contrassegnare ogni idea come verificata **solo** per il proprio livello E0–E3. Per E2 occorre export autorizzato Markdown & CSV con sottopagine, o accesso consentito ai blocchi Notion, più screenshot per layout non recuperabili dall'export.
5. Proporre l'integrazione Flutter in una roadmap separata, solo dopo ammissione di prodotto e controlli: privacy/ACL, reversibilità, test e visual approval.

**Baseline**: Anna's Diary `main@7d22e5f2e5710599fdcd56c785b6ebe7bf6c33f0` e App Factory Core `2b3ae9e01764b7504980efca34f2543949dc7b89` (Master v27 / Golden Index v29), classificazione documentale 2026-11-09. Questo elenco non cambia le release o la roadmap esistente.

## Idea futura — Store interno di template Anna

[**TPL-STORE-2026-01: idea valida da conservare**](https://github.com/riccardopinato/Idee-app-Archivi-riferimenti/blob/main/17-RICERCA-TEMPLATE-UX/IDEA_STORE_TEMPLATE_INTERNO_2026-11-09.md). Prezzo candidato **€3,99** una tantum per template **originale**, alcuni preset gratuiti, preview e ripristino acquisti. **Non implementato**, non cambia Product Bible, RevenueCat, permessi, dati, `Noi ♡` o Vault. Nessuno dei template caricati è autorizzato automaticamente per vendita o copia.

## Lotto Notion di novembre 2026 — ricerca, non app integrata

| ID | Fonte | Ruolo | Stato | Scheda |
|---|---|---|---|---|
| TN-ANNA-0004 | Shopping List | PRIMARY | E2 export, proposta da valutare | [Analisi](SCHEDE/TN-ANNA-0004.md) |
| TN-ANNA-0005 | Trip Planner | SECONDARY_LIMITED | E2 export, proposta da valutare | [Analisi](SCHEDE/TN-ANNA-0005.md) |

Il template completo `Trip Planner` ha come proprietario principale **Wonderlog**, mentre Anna può eventualmente usarne solo aspetti di diario personale. Non viene modificata la roadmap di prodotto.
