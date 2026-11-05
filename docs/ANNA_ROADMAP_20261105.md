# Anna's Diary — Roadmap esecutiva aggiornata al 5 novembre 2026

Factory baseline: App-Factory-Core commit 42ad47a9ebacc55ae901ea55a01a6855e320377d, Master v27, Golden Index v28.
Sorgente audit iniziale: Agenda-per-Anna commit 508a207afe67f5cc61e05fc911ee8006a42431b2.
Regola di evidenza: SOURCE MERGED != APK aggiornato != physical QA != Play release.

## Stato delle modifiche

| Feature | PR | Esito |
| --- | --- | --- |
| Tag inline automatici offline con Salva esplicito | #245 | MERGED, Web E2E PASS |
| Dialog Nota rapida piu ampio | #246 | MERGED, Flutter/Web/AppLab PASS |
| Crea nuovo Spazio anche se altri esistono | #246 | MERGED |
| Rinomina tutti gli spazi di cui si e proprietari | #246 | MERGED, vincolo server owner |
| Ricordi raggruppati per nome del luogo anche singoli | #247 | MERGED |
| Riassunti estrattivi locali settimanali/mensili/luogo/persona | #248 | MERGED; ranking lessicale, non TextRank |
| Alias personale per spazi di cui si e membro | #249 | IN VALIDAZIONE, merge solo con gate |
| APK incrementale +125 | release lane | NON ANCORA CERTIFICATA |

## Cinque maxi-step, nell'ordine

### 1. Finire Shared Space + Inbox (BLOCKING_NOW)
- #249: unire solo dopo CI Flutter, Web, AppLab e review all'esatto head.
- Rinomina owner globale via RPC (migration SQL #099), membro solo alias per account e dispositivo.
- Nomi storici predefiniti con cuore resi neutri senza riscrivere i record del server; non eliminare cuori da nomi creati dall'utente.
- Verificare creare secondo e terzo spazio, accesso membro, QR, riavvio, cache e account switch; finestra Nota rapida su piccolo Android con tastiera, font grande, Annulla e Salva.

### 2. APK firmato +125 e collaudo fisico (RELEASE GATE)
- Dopo i merge sorgente, versione +124 -> +125 con PR monotona separata e test esatti.
- Lane di firma ARM64 solo da trusted main e CI verde; registrare SHA sorgente, hash APK, fingerprint della firma e manifest.
- Installazione come update in-place, preservando dati privati, Vault, ricordi, categorie e shared; test propietario + membro e sync su due telefoni.
- Il collaudo reale richiede una verifica su device; nessun Play/Store rollout automatico.

### 3. Ricordi per luogo + persona (SOURCE DONE, UX POLISH)
- Usare MemoryMapSnapshot, Life Threads e diary places canonici. Luoghi singoli visibili via #247, click apre i ricordi originali.
- Life Threads gia raggruppa per persona, luoghi e tag ricorrenti: migliorarne discoverability senza secondo database.
- Solo candidate future copertine foto, filtri per periodo, frequenza tag; clustering geodesico CAP-0159 completo richiede prova coordinate/null/antimeridiano, privacy, consensi.

### 4. Riassunti estrattivi locali (SOURCE DONE, QUALITY QA)
- #248 riusa note private non archiviate, frasi letterali e apertura sorgente; nessuna AI generativa o cloud.
- QA su testi con negazioni, revisione/Trash, account switch, multilingua, grandi archivi e disclosure del limite di corpus.
- CAP-0151 TextRank vero resta candidato separato: benchmark qualitativo prima di aggiungere costi CPU o dipendenze.

### 5. Valore e retention (FUTURE, proposta da valutare)
- Ricordo del giorno: riusare memoryReferencesOnThisDay senza notifiche invasive.
- Ricordi per persona: valorizzare Life Threads gia presente; metadati e foto soltanto da contenuti disponibili.
- Altre idee dal catalogo: trascrizione locale CAP-0031 (modello/licenza/footprint e opt-in), domande a doppia rivelazione AD-NL26-01 (privacy/sync), Dark Velvet AD-NL26-14 (contrasto/accessibilita), widget Oggi (Android QA).
- Navigazione: preservare il Product Bible e le dieci schermate gia approvate; nessun redesign silenzioso nella fix PR.

## Confronto con Idee-app-Archivi-riferimenti

CAP-0160: codice integrato, non duplicare; CAP-0159: only named-place grouping, non DBSCAN geospaziale; CAP-0151: MVP lessicale estrattivo, non full TextRank; CAP-0011: Life Threads gia presente; CAP-0031, AD-NL26-01 e Dark Velvet da valutare con gate.
Il registro idee ha uno stato storico: non considerare una classificazione PROPOSTA prova che una PR appena integrata manchi nel codice.

## Gate invarianti

- Non riaprire Privacy V2 #215, Google Calendar Direct #199, billing/cloud/AI non approvati.
- Non alterare UUID, encryption, membership, keystore, dati salvati o provider ACL per forzare un PASS.
- Verificare davvero che migration SQL #099 sia applicata su Supabase per rename globale owner.
- Web smoke ed emulator non equivalgono a dispositivo fisico; source check non equivale a Store.
