# UX STEP 2 — Anna's Diary | Rituali gentili

**STATO:** DRAFT UX / DA APPROVARE. Fonte E2: TPLUX-REF-0002 (1 MD e 4 JPEG) **solo come ispirazione di routine mattina/sera/settimana**. Nessuna media, formula o testo Notion copiato. Baseline Anna `bee3b22b9c2e8a614efa9deeec32815102c78522`, Factory `d4ed1185d36d419228fba6b57a979cde308bd321`.

[**Prototipo HTML originale con interazioni simulate**](PROTOTIPO_RITUALI_GENTILI.html). NON è l'app, non modifica preferenze, reminder, diarî o sincronizzazione.

## Perché è diverso dal template Notion e da una nuova funzionalità

Anna dispone **già** di `DailyRitualKind.morning/evening`, `startDailyRitual` e `DiaryTemplatePreset`. La proposta UX è **una confezione leggera e originale di contenuti guidati**, NON una seconda architettura habit tracker, non uno streak engine e non una funzione da vendere come se fosse nuova.

**Prima versione gratuita**, senza nuovo premium gate: `Il mio risveglio` e `Il mio momento della sera` come diario privato. Un eventuale futuro pack premium a €3,99 dovrà aggiungere valore vero (es. varianti di prompt originali, layout differenziati, ricordi collegati) e superare approvazione specifica, mantenendo gratuiti i rituali esistenti.

## Source of truth riutilizzata

- `lib/src/daily_rituals.dart`: `DailyRitualKind`, `hasStartedDailyRitual`, `dailyRitualBlock`, `startDailyRitual`; idempotenza dello stesso giorno tramite `ritual:morning/evening`.
- `lib/src/diary/diary_templates.dart`: `DiaryTemplatePreset` e `applyDiaryTemplate` → salva **un normale `DiaryBlock` editabile** in `saveJournal`; `showDiaryTemplatePicker` esiste.
- `docs/V104_DAILY_RITUALS.md`: preferenze on/off individuali, eventuali reminder con consenso, orari predefiniti 08:00 e 20:30 (modificabili), 1 blocco al giorno, no streak.
- `docs/DS6_PREMIUM_EDITORIAL_10_10_20261107.md`: gerarchia Lora/Manrope e palette rose/HSV, Classic reversibile, cinque lingue IT/EN/ES/FR/PT; Privacy First, **non toccare Vault**.

## Flusso UX

1. **Oggi / rituali** o **Crea → Modelli**: card editoriale `Rituali gentili`, GRATIS, con azioni `Anteprima` / `Personalizza`. Il luogo finale nel menu è **una proposta da approvare**.
2. **Anteprima**: due card leggibili con domande originali. Mai mostrare come completata un'attività non registrata; il testo corretto è `Inizia` / `Già iniziato`.
3. **Personalizza**: preferenze mattina/sera (entrambe inizialmente disattivate nelle impostazioni reali), orari esistenti e reminder **opzionale**; il mock-up non cambia impostazioni.
4. **Conferma**: `Salva come preferenza privata` e `Apri rituale di oggi` solo quando i rispettivi writer e consenso sono verificati. Nessun accesso a `Noi ♡`; mai al Vault.
5. **Step 3:** evitare due blocchi per lo stesso giorno/rituale; all'apertura ripetuta mostrare il blocco già esistente. Su errore di notifica non perdere il diario, consentire retry con stato reale.
6. **Rimozione pack:** disattivare l'esperienza/preset (se l'utente vuole), ma **non cancellare** i `DiaryBlock` precedenti, che restano nel normale lifecycle.

## Contenuti originali in anteprima

- Mattina: `Una cosa che mi farebbe stare bene oggi…`; `Un piccolo obiettivo realistico…`.
- Sera: `Un dettaglio bello della giornata…`; `Cosa vorrei ricordare…`.

Sono testi creati per questo mock-up, non estratti da Notion né storie personali reali.

## Stati / qualità / sicurezza

Disabled by default; niente notifiche senza scelta esplicita. Empty, offline, permesso reminder negato, giornata diversa, account switch, blocco già iniziato, restore backup, contrasto, font scale, Reduce Motion, 48dp e L10n. Il prototipo HTML è solo IT e non prova le traduzioni.

**Gate:** approvazione UX utente e verifica Product Bible, poi adapter con backup, ACL/private owner, test UI/app. Nessuno schema/database, Vault, E2EE, RevenueCat o Google Play cambiato in questo step. Resta `UX_DRAFT_PENDING_APPROVAL`.
