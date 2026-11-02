# Privacy UX V2 — Personale / Condiviso / Riservato

**Status: IMPLEMENTAZIONE PARZIALE SU PR IN BOZZA. NON MERGERE FINCHÉ NON SI CHIUDONO I GATE DI PRIVACY.**

## Distinzione logica

- **Tutto / Personale / Spazio condiviso:** filtri di provenienza e destinazione. La precedente etichetta `Privato` non significa contenuto protetto dalla vista di terzi.
- **Anteprima riservata:** un attributo ortogonale `isSensitive` sia su `AgendaItem` sia su `SharedEntry`. I due partecipanti possono considerare riservato anche un elemento condiviso.
- **Home discreta:** preferenza esclusivamente locale `homeDiscreetMode`, inizializzata a `true` quando manca il campo anche nelle configurazioni precedenti. L'impostazione non e' sincronizzata via cloud e non sostituisce l'autenticazione dell'app.

## Implementazione sorgente (PR #200)

- Filtro `AgendaContentFilter.privateOnly` invariato per compatibilità con cache, UI etichettata **Personale**. Stesso schema lingue EN/IT/ES/FR/PT.
- Campi `isSensitive` nei payload locali/sincronizzati e nei `copyWith`, `fromJson` legacy `false`: nessuna cancellazione dei dati preesistenti, nessuna migrazione distruttiva.
- Toggle `homeDiscreetMode` in Oggi/Home; continua a rispettare `hideHomeDetails` preesistente. Le anteprime nascoste non mostrano titoli e orari negli elementi standard dei `UnifiedAgendaTile` e `EventTile`.
- Editor personale/condiviso: anteprima riservata marcabile con PIN app gia' configurato; se assente controllo disabilitato e spiegazione.
- `requestSensitiveItemAccess` riutilizza verifica PIN/biometria dell'app e nega l'apertura se non ci sono credenziali. E' un controllo di disclosure UI, NON cifratura.
- `AndroidCalendarSyncService`: esclude i nuovi elementi marcati sensibili dal successivo export B3; i precedenti export Android **non vengono rimossi** automaticamente.

## Audit incrementale PR #200 (source-level; non certificazione)

**Mitigazioni implementate in questa iterazione:**
- SharedSpaceScreen: le card sensibili di feed, giorno e diario sono mascherate senza costruire titoli, note o thumbnail; apertura e modifica passano per challenge PIN/biometrica.
- SharedMemoriesScreen: le voci sensibili sono escluse da ricerca, copertine, timeline e griglie finche' tali percorsi non hanno gate dedicati. I record restano conservati.
- Note e sketch condivisi: preservano isSensitive durante le modifiche. La sostituzione di una foto sensibile e' bloccata finche' il percorso di upload differito non propaga il flag.
- Widget Android: eventi sensibili mascherati; con Home discreta anche appuntamenti ordinari e nominativo del prossimo compleanno sono mascherati.
- Android e Web Push: i nuovi promemoria sensibili usano testo generico, anche nel payload snooze.
- Timeline oraria e blocchi temporali: le voci sensibili sono omesse per non rivelare l'orario attraverso il posizionamento.
- Archivio generale e Year Review fondati su lifeArchiveEntries: le voci agenda sensibili non appaiono nelle proiezioni non autenticate.
- Challenge: verifica account corrente prima di consentire la visualizzazione dopo PIN o biometria.

**Limitazioni e gate ancora aperti:**
- I tre export (backup ZIP, archivio aperto ZIP, export TXT) richiedono challenge PIN/biometrica e conferma esplicita se esistono appuntamenti personali sensibili. Il file resta leggibile/non cifrato: conservarlo e condividerlo con cautela.
- Calendari esterni gia' esportati, notifiche gia' consegnate, screenshot/app switcher, accessibilita' e cache esterne non sono bonificati retroattivamente.
- SharedMediaPendingUpload non preserva ancora il marker riservato durante sostituzione foto: percorso disabilitato per le foto gia' sensibili, non certificato come flusso completo.
- Test reali su due dispositivi, account switch, background/resume, permessi biometrici, APK firmato e verifica visuale: NON VERIFICATI.
- Non e' crittografia at-rest ne' E2EE; nessuna garanzia di riservatezza lato server.

**Decisione:** PR resta Draft; niente merge, APK firmato o PHYSICAL PASS prima di chiudere i gate.
## Gate privacy da completare prima del merge

1. **SharedSpaceScreen e feed indipendente:** tutte le righe per appuntamenti, note, foto, descrizioni, interazioni, contenuti ricordo devono rispettare `isSensitive` ove previsto. Al momento questa PR presidia principalmente i componenti agenda/Oggi; non affermare privacy a livello intera app.
2. **Altre vie di visualizzazione:** notifiche, widgets Android, ricerca, panoramiche, timeline oraria, duplicazione, deep link, recap, export/backup, accessibilità semantica, app switcher/screenshot e scorciatoie. Un elemento marcato non puo' essere considerato «protetto» se una via alternativa lo espone.
3. **PIN/biometria e ritorno dall'app:** valutare PIN obbligatorio per rivelare anteprime e auto-mascheramento dopo resume/background; nessuna persistenza di «sbloccato» in storage.
4. **Condiviso/multi-dispositivo:** `isSensitive` nel payload condiviso puo' sincronizzare il marker con gli altri membri, ma occorrono test reali per editor concorrenti, cache, revoche, utenti con diverse preferenze locali e migrazione legacy.
5. **Calendari esterni:** B3 esclude nuovi export sensibili ma eventi gia' pubblicati su calendario Android/Google restano e richiedono una scelta manuale. Anche il modulo Google diretto in staging PR #199 dovrà includere la stessa esclusione al momento dell'attivazione.
6. **Piattaforme:** test Android firmato + Web preview; il PIN/biometria non e' equivalente a crittografia di un database e non rende i dati protetti lato server. No dichiarazione `PHYSICAL PASS` senza collaudo.

## Accettazione UX

- In Home, **Personale** filtra solo l'origine; **Condiviso** solo la destinazione; **Tutto** li aggrega. La Home inizialmente maschera le anteprime, indipendentemente dal filtro.
- Creare due elementi con stesso giorno, uno personale e uno condiviso; marcarli `isSensitive`; confermare che appaiano mascherati nei componenti di agenda anche cambiando filtro.
- Con PIN non configurato, l'app deve spiegare perché non puo' rendere sensibile un nuovo elemento; con PIN attivo deve richiedere una verifica per l'apertura.
- Riavvio, aggiornamento versione e account switch non cancellano gli elementi o i flag.

Questa PR non deve essere confusa con un gate di sicurezza completato. L'APK 1.0.0-rc.6+117 resta la release valida sino ad apposita promozione.
