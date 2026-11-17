
part of '../main.dart';

/// On-demand education, separate from first-run onboarding, capture writers,
/// privacy permissions, local settings, cloud, and personal content.
enum AnnaContextHelpSection { create, sharedHub, sharedSpace, memories, more }

class AnnaContextHelpTopic {
  const AnnaContextHelpTopic({
    required this.id,
    required this.icon,
    required this.title,
  });

  final String id;
  final IconData icon;
  final String title;
}

// Topic IDs intentionally match the actual canonical Unified Capture actions.
// Additional sections are small, stable top-level guides; nested routes follow
// in a future bounded step and must not silently expose hidden modules.
const Map<AnnaContextHelpSection, List<String>> _annaContextHelpSections = {
  AnnaContextHelpSection.sharedHub: [
    'hubSpaces', 'hubInvite', 'hubJoin', 'hubAvatar', 'hubSync',
  ],
  AnnaContextHelpSection.sharedSpace: [
    'spaceCreate', 'spaceInteractions', 'spaceMembers', 'spaceMemories',
    'spaceUtilities', 'spacePrivacy',
  ],
  AnnaContextHelpSection.memories: [
    'memoriesForYou', 'memoriesTimeline', 'memoriesBrowse',
    'memoriesFind', 'memoriesOrganize',
  ],
  AnnaContextHelpSection.more: [
    'moreSearch', 'moreInbox', 'moreFavorites', 'moreExplore',
    'moreVault', 'moreLetters', 'moreData', 'moreSettings',
  ],
};

const Map<String, IconData> _annaContextHelpIcons = {
  'date': Icons.event_available_outlined,
  'text': Icons.edit_note_outlined,
  'photo': Icons.photo_camera_back_outlined,
  'task': Icons.check_circle_outline,
  'taskFromText': Icons.auto_awesome_motion_outlined,
  'checklistFromNote': Icons.playlist_add_check_outlined,
  'voice': Icons.mic_none_outlined,
  'sketch': Icons.draw_outlined,
  'visionBoard': Icons.dashboard_customize_outlined,
  'inbox': Icons.inbox_outlined,
  'event': Icons.event_outlined,
  'birthday': Icons.cake_outlined,
  'person': Icons.person_add_alt_1_outlined,
  'templates': Icons.library_books_outlined,
  'hubSpaces': Icons.groups_outlined,
  'hubInvite': Icons.person_add_alt_1_outlined,
  'hubJoin': Icons.qr_code_scanner_outlined,
  'hubAvatar': Icons.photo_camera_outlined,
  'hubSync': Icons.sync_outlined,
  'spaceCreate': Icons.add_circle_outline,
  'spaceInteractions': Icons.favorite_border,
  'spaceMembers': Icons.group_outlined,
  'spaceMemories': Icons.photo_library_outlined,
  'spaceUtilities': Icons.shopping_cart_outlined,
  'spacePrivacy': Icons.lock_outline,
  'memoriesForYou': Icons.auto_awesome_outlined,
  'memoriesTimeline': Icons.view_stream_outlined,
  'memoriesBrowse': Icons.calendar_month_outlined,
  'memoriesFind': Icons.search_outlined,
  'memoriesOrganize': Icons.collections_bookmark_outlined,
  'moreSearch': Icons.search,
  'moreFavorites': Icons.star_outline,
  'moreLetters': Icons.mark_email_unread_outlined,
  'moreInbox': Icons.inbox_outlined,
  'moreExplore': Icons.apps_outlined,
  'moreVault': Icons.lock_person_outlined,
  'moreData': Icons.backup_outlined,
  'moreSettings': Icons.settings_outlined,
};

const Map<String, Map<String, List<String>>> _annaContextHelpArticles = {
    'it': {
    'hubSpaces': ["Creare e aprire uno spazio", "Uno spazio raccoglie solo gli elementi che scegli di condividere con i suoi membri.", "Seleziona Crea spazio, assegna un nome e conferma; ogni spazio ha un proprio elenco e un codice d'invito.", "Tocca il riquadro dello spazio per entrare, pubblicare contenuti e consultare le attività condivise.", "Cambiare il nome non cambia il codice interno né cancella contenuti."],
    'hubInvite': ["Invitare qualcuno", "Gli inviti permettono ad altre persone di accedere allo stesso spazio, secondo le regole già presenti.", "Entra nello spazio e usa Invita per ottenere o condividere il codice d'accesso.", "Invia il codice alla persona desiderata, che lo userà dal proprio account per entrare.", "Condividi il codice solo con persone di fiducia: uno spazio può contenere dati personali."],
    'hubJoin': ["Entrare con codice o QR", "Puoi raggiungere uno spazio altrui senza crearne uno nuovo.", "Tocca Entra in uno spazio oppure Scansiona QR, se presente, e usa l'invito ricevuto.", "Conferma con il tuo account e apri lo spazio aggiunto all'elenco.", "Servono accesso e invito valido; non è possibile entrare in spazi sconosciuti senza autorizzazione."],
    'hubAvatar': ["Foto e nome dello spazio", "Ogni spazio può avere una foto propria, visibile a tutti i membri, oltre al suo nome.", "Se ne sei proprietario, usa l'icona della fotocamera vicino allo spazio per scegliere o scattare una foto.", "Puoi sostituire o rimuovere la foto e rinominare lo spazio con i comandi disponibili.", "I membri vedono la stessa foto dopo l'aggiornamento, ma non possono cambiarla per tutti."],
    'hubSync': ["Sincronizzazione e stato", "Le modifiche condivise vengono inviate al cloud con il tuo account, mentre alcune operazioni possono restare in attesa.", "Guarda gli indicatori del riquadro per capire se ci sono elementi ancora da sincronizzare.", "Tocca Aggiorna per recuperare le informazioni più recenti quando hai connessione.", "Un'operazione in attesa non è ancora confermata sugli altri dispositivi."],
    'spaceCreate': ["Aggiungere contenuti", "Dentro lo spazio puoi aggiungere contenuti condivisi, scegliendo di volta in volta cosa pubblicare.", "Tocca il pulsante Aggiungi o Condividi nella schermata dello spazio.", "Scegli il tipo di elemento, compila i dettagli e conferma la pubblicazione.", "Il diario personale non viene condiviso automaticamente: la scelta di pubblicare è esplicita."],
    'spaceInteractions': ["Mi piace, commenti e visualizzazioni", "Le interazioni aiutano a sapere come gli altri membri hanno reagito agli elementi condivisi.", "Usa il cuore per lasciare o togliere Mi piace e Commenta per rispondere a un contenuto.", "Tocca il numero accanto al cuore per vedere chi ha messo Mi piace e quando, se la reazione è confermata dal server.", "La data e l'ora non vengono inventate: per i dettagli serve una sincronizzazione riuscita."],
    'spaceMembers': ["Persone e inviti", "La sezione Membri mostra chi partecipa allo spazio; il proprietario gestisce alcuni permessi.", "Apri Persone nello spazio per vedere i partecipanti.", "Usa Invita per condividere il codice, oppure i comandi del proprietario per gestire gli accessi disponibili.", "Non condividere codici con sconosciuti e controlla chi può vedere i contenuti."],
    'spaceMemories': ["Ricordi condivisi", "Puoi ritrovare le foto e gli altri ricordi pubblicati nello spazio, separati dai tuoi ricordi personali.", "Apri Ricordi dello spazio, dal menu o dall'azione dedicata.", "Sfoglia i contenuti condivisi e apri quello che desideri rivedere.", "Solo ciò che è stato realmente condiviso compare qui."],
    'spaceUtilities': ["Strumenti dello spazio", "Oltre ai ricordi puoi utilizzare le utilità condivise presenti nella schermata, come la lista della spesa o le password condivise.", "Apri la funzione direttamente dal riquadro dello spazio o dal menu in alto.", "Aggiungi o modifica solo gli elementi per cui hai le autorizzazioni richieste.", "Per password e dati protetti possono essere necessari accesso o sblocco dedicati."],
    'spacePrivacy': ["Privacy e sincronizzazione", "Lo spazio è distinto dal diario privato e richiede un account per sincronizzare i contenuti con gli altri membri.", "Prima di pubblicare, controlla che il contenuto sia nello spazio corretto e che i destinatari siano quelli desiderati.", "Verifica gli stati In attesa, Aggiorna e le indicazioni sui permessi quando un elemento non compare subito.", "Eliminare o lasciare uno spazio ha conseguenze diverse: leggi sempre la conferma prima di procedere."],
    'memoriesForYou': ["Per te", "Questa vista mette in evidenza momenti già conservati, come ricordi da riscoprire o anniversari.", "Tocca Per te per tornare alla selezione di ricordi.", "Apri una card per rivedere il contenuto originale, quando disponibile.", "La sezione presenta soltanto contenuti realmente registrati: non inventa ricordi."],
    'memoriesTimeline': ["Cronologia", "La cronologia raccoglie i ricordi nel tempo, permettendoti di tornare alle giornate in cui li hai creati.", "Seleziona Cronologia per scorrere le registrazioni.", "Tocca un ricordo per aprirne dettagli o giornata di riferimento.", "L'ordine dipende dalle date associate ai contenuti salvati."],
    'memoriesBrowse': ["Giorni, mesi e anni", "Le viste di esplorazione permettono di passare da una giornata a periodi più ampi senza perdere la cronologia.", "Tocca Esplora nei Ricordi e scegli Giorni, Mesi o Anni.", "Seleziona un periodo per vedere i ricordi effettivamente presenti.", "Un periodo vuoto rimane vuoto: non vengono creati elementi di riempimento."],
    'memoriesFind': ["Ricerca e filtri", "Trova ricordi grazie al testo, alle date e alle tipologie disponibili.", "Tocca la lente per cercare un argomento, una persona o una data nel catalogo.", "Usa Filtri per limitare il risultato a note, foto, audio o disegni e cancella il filtro per vedere tutto.", "Le ricerche rispettano l'ambito e i contenuti visibili della schermata."],
    'memoriesOrganize': ["Organizzare e proteggere i ricordi", "Aprire un ricordo permette di gestirlo con gli strumenti disponibili, incluse eventuali raccolte e collegamenti.", "Apri il ricordo che vuoi modificare e usa i comandi previsti per quel tipo di contenuto.", "Per raggruppare o recuperare elementi, visita le sezioni Raccolte, Archivio o Cestino quando disponibili.", "Archiviare, cancellare e rimuovere definitivamente non sono equivalenti: verifica la conferma."],
    'moreSearch': ["Ricerca personale", "Cerca informazioni già presenti nelle aree personali senza navigare ogni schermata.", "Apri Cerca da Altro e inserisci un termine.", "Tocca il risultato che riconosci per raggiungere la sua schermata originale.", "I risultati dipendono dai dati salvati e dall'ambito accessibile."],
    'moreInbox': ["Inbox", "Inbox raccoglie appunti e idee che vuoi sistemare in un secondo momento.", "Apri Inbox dalla sezione Accessi rapidi.", "Rileggi le note, organizza quelle importanti e sposta o archivia con gli strumenti disponibili.", "Una nota non viene convertita automaticamente in appuntamento."],
    'moreExplore': ["Esplora funzioni", "Esplora contiene le funzioni aggiuntive che hai attivato nella tua personalizzazione.", "Apri Esplora da Altro.", "Scegli la destinazione desiderata, come Persone o altri strumenti visibili, per aprire la schermata dedicata.", "Le sezioni nascoste dalle preferenze non sono eliminate e possono essere riattivate."],
    'moreFavorites': ["Accessi preferiti", "Puoi ritrovare più velocemente le funzioni che usi spesso.", "Consulta la sezione dei preferiti nella pagina Altro.", "Usa i collegamenti disponibili per tornare alle destinazioni più frequenti.", "Gli accessi rapidi non creano copie dei contenuti."],
    'moreVault': ["Cassaforte privata", "La Cassaforte è una sezione protetta, separata dai normali contenuti del diario.", "Apri Cassaforte privata da Altro, quando il modulo è attivo.", "Sblocca con il metodo richiesto prima di leggere o modificare dati riservati.", "Non confondere la Cassaforte privata con le password condivise: hanno ambiti e permessi diversi."],
    'moreLetters': ["Lettere al futuro", "Le lettere al futuro permettono di conservare un messaggio destinato a essere riletto più avanti.", "Apri Lettere al futuro nella sezione Il tuo spazio, se disponibile.", "Crea o consulta le lettere usando i comandi della schermata dedicata.", "Controlla sempre le date e le condizioni mostrate prima di programmare una lettera."],
    'moreData': ["Archivio, backup e cloud", "Questi strumenti gestiscono destinazioni diverse: contenuti archiviati, copie di sicurezza e account con sincronizzazione.", "Apri Archivio per consultare gli elementi conservati fuori dalle viste correnti; usa Backup per le procedure di salvataggio o ripristino disponibili.", "Apri Cloud e account per controllare accesso e sincronizzazione, soprattutto se vuoi usare Spazio condiviso.", "Un backup non equivale alla sincronizzazione cloud: verifica sempre lo stato e gli avvisi."],
    'moreSettings': ["Profilo, impostazioni e aspetto", "Personalizza la tua esperienza senza modificare i contenuti del diario.", "Tocca il riquadro del profilo oppure Impostazioni in Altro.", "Configura preferenze, funzioni visibili, stile Journal/Classic e colori dalla sezione appropriata.", "Nascondere un modulo è reversibile e non cancella i dati salvati."],
    'date': ["Data del contenuto", "Crea+ usa il giorno visualizzato: puoi cambiarlo prima di iniziare, anche se stai aprendo Crea da Calendario o Inbox.", "Tocca la riga della data, sotto il titolo Crea, per aprire il calendario.", "Scegli il giorno desiderato, poi seleziona il tipo di contenuto: il nuovo elemento nascerà su quella data.", "Cambiare la data qui non sposta né modifica contenuti già salvati."],
    'text': ["Nota di diario", "Scrivi un pensiero, un episodio o ciò che hai fatto in giornata: la nota entra nel diario del giorno scelto.", "Seleziona Nota di diario e scrivi il testo nell'editor che si apre.", "Conferma il salvataggio: ritroverai la nota nei Ricordi e nella giornata del diario.", "Se chiudi senza salvare, non viene creato un nuovo ricordo."],
    'photo': ["Fotografia", "Conserva un momento con un'immagine e, se vuoi, una descrizione legata alla giornata.", "Scegli Foto, poi scatta un'immagine o selezionala dalla galleria.", "Controlla la foto, aggiungi una didascalia se richiesta e conferma: sarà un ricordo fotografico.", "La foto viene salvata solo dopo la conferma; l'accesso a fotocamera o galleria può richiedere il relativo permesso."],
    'task': ["Attività da completare", "Crea un impegno concreto da segnare come fatto quando lo completi.", "Seleziona Attività e compila il titolo nell'editor previsto.", "Controlla data e altri dettagli, quindi salva; potrai spuntare l'attività nelle viste dove compare.", "Una nuova attività non viene segnata come completata automaticamente."],
    'taskFromText': ["Attività da una frase", "Trasforma una frase in una bozza di attività; il riconoscimento della data dipende da quanto è chiara la frase.", "Inserisci una frase come «Telefonare domani alle 18» per proporre titolo, giorno e, quando possibile, ora.", "Esamina il risultato nell'editor e salva soltanto dopo aver corretto eventuali interpretazioni.", "È una proposta locale: nulla viene aggiunto automaticamente e i fusi orari ambigui non vengono indovinati."],
    'checklistFromNote': ["Checklist da una nota", "Trasforma righe già strutturate come elenco in una bozza di attività con passi da controllare.", "Scrivi o incolla una nota con righe come «- Comprare biglietti» e «- Preparare valigia».", "Controlla la checklist proposta nell'editor e salva la nuova attività se è corretta.", "Servono righe riconoscibili come elenco; la proposta non modifica la nota originale."],
    'voice': ["Nota vocale", "Registra la tua voce per conservare un racconto o un pensiero nel diario.", "Seleziona Nota vocale, autorizza il microfono se richiesto e avvia la registrazione.", "Ferma la registrazione, conferma e aggiungi la didascalia richiesta per salvare il ricordo audio.", "Annullare la registrazione o la didascalia non crea una nota vocale."],
    'sketch': ["Disegno", "Aggiungi al diario una pagina illustrata da disegnare liberamente.", "Tocca Disegno per aprire la lavagna con i suoi strumenti.", "Disegna, controlla il risultato e salva per aggiungere la pagina alla giornata.", "Il disegno viene aggiunto al diario solo dopo il salvataggio esplicito."],
    'visionBoard': ["Vision board", "Crea un collage personale di immagini, parole e obiettivi sul giorno scelto.", "Seleziona Vision board e scegli un modello iniziale tra quelli disponibili.", "Personalizza la tela con i suoi strumenti, quindi salva la composizione nel tuo diario.", "È una funzione personale: può non comparire in modalità solo Spazio condiviso."],
    'inbox': ["Nota rapida in Inbox", "Cattura un'idea non ancora organizzata, senza dover decidere subito dove inserirla.", "Tocca Inbox rapida e scrivi il pensiero da non perdere.", "Salva e torna in Inbox quando vuoi trasformarlo o archiviarlo.", "Una nota Inbox non diventa automaticamente un appuntamento o un'attività."],
    'event': ["Appuntamento", "Registra un evento o un impegno che vuoi vedere nel Calendario.", "Scegli Appuntamento e inserisci titolo, data e gli orari pertinenti nell'editor.", "Verifica le informazioni e salva; potrai rivedere l'evento nelle viste calendario.", "Le notifiche dipendono dalle impostazioni e dai permessi: il salvataggio non garantisce un avviso."],
    'birthday': ["Compleanno", "Annota una data importante legata a una persona.", "Tocca Compleanno e inserisci le informazioni richieste, come nome e data.", "Salva e verifica la ricorrenza nella sezione dedicata ai compleanni.", "Inserire la data non abilita da solo promemoria o notifiche."],
    'person': ["Persona importante", "Crea un riferimento a una persona per tenerne traccia nel tuo diario.", "Seleziona Persona importante e compila i dati che desideri ricordare.", "Salva il profilo: potrai collegare questa persona ai ricordi e ritrovarla nella relativa sezione.", "Inserisci solo informazioni che vuoi effettivamente conservare."],
    'templates': ["Modelli di diario", "Parti da una traccia di scrittura invece che da una pagina vuota.", "Scegli Modelli, poi apri il modello che ti aiuta a iniziare.", "Modifica liberamente il testo proposto e salva il risultato come nota della giornata.", "Il modello è un punto di partenza: non scrive o salva al posto tuo."],
  },
  'en': {
    'hubSpaces': ["Create and open a space", "A space contains items you choose to share with its members.", "Create a space, name it and confirm; spaces have separate content and invitations.", "Open the space card to view or add shared items.", "Renaming does not delete content or change its identifier."],
    'hubInvite': ["Invite someone", "Invitations let another person join the same shared space.", "Open the space and use Invite to access a code.", "Send it to the person you want to invite; they join from their own account.", "Share codes only with people you trust."],
    'hubJoin': ["Join using code or QR", "Join another person's space without creating a new one.", "Choose Join or Scan QR and enter the invitation you received.", "Confirm with your account and open the new space in the list.", "You need a valid invitation and account."],
    'hubAvatar': ["Space name and photo", "A space can have its own photo, visible to members alongside its name.", "If you own it, use the camera icon to choose or take a photo.", "Replace, remove or rename using the available controls.", "Members can view the same photo after refreshing, but cannot replace it for everyone."],
    'hubSync': ["Sync and status", "Shared changes use your cloud account; some may remain pending.", "Check the space's indicators for unsent changes.", "Tap Refresh when online to retrieve the latest information.", "Pending actions are not yet confirmed on other devices."],
    'spaceCreate': ["Add shared items", "You can add content inside this space when you decide to share it.", "Tap Add or Share inside the space.", "Choose an item type, enter details and confirm.", "Your personal diary is not shared automatically."],
    'spaceInteractions': ["Likes, comments and reads", "Interactions show how members reacted to shared items.", "Use the heart to like/unlike and Comment to reply.", "Tap the count beside the heart to see confirmed names and server dates.", "Exact times require successful sync and are never guessed."],
    'spaceMembers': ["People and invites", "Members shows who belongs to the space. The owner manages access controls.", "Open People in space to see participants.", "Use Invite or owner controls to manage access when available.", "Protect invitation codes and check who can view your items."],
    'spaceMemories': ["Shared memories", "Find photos and memories posted in this space, separate from private memories.", "Open the space's Memories action or menu.", "Browse and reopen the items you want to revisit.", "Only content explicitly shared appears here."],
    'spaceUtilities': ["Space utilities", "Beyond memories, use available shared tools such as Shopping List or shared passwords.", "Open a tool from its space card or top menu.", "Add or edit items only when you have permission.", "Protected passwords can require a separate unlock."],
    'spacePrivacy': ["Privacy and syncing", "Shared content is separate from the private diary and needs an account for cloud sync.", "Before posting, check the selected space and its participants.", "Check pending/retry indicators if an item does not appear yet.", "Leaving and deleting a space are different actions; read confirmations."],
    'memoriesForYou': ["For you", "This view highlights memories you already saved, including moments worth revisiting.", "Choose For you to return to curated memories.", "Tap a card to open its original content where available.", "Suggestions come from saved content, not invented memories."],
    'memoriesTimeline': ["Timeline", "Timeline arranges saved memories over time.", "Choose Timeline to browse entries.", "Open a memory to revisit its details or day.", "Ordering uses saved entry dates."],
    'memoriesBrowse': ["Days, months and years", "Browse individual days or wider periods.", "Open Browse in Memories and select Days, Months or Years.", "Choose a period to see its actual saved memories.", "Empty periods stay empty."],
    'memoriesFind': ["Search and filters", "Find memories using text, dates and content types.", "Tap Search to enter a term, person or date.", "Open Filters to narrow by notes, photos, voice or drawings; clear to show all.", "Results respect the current content scope."],
    'memoriesOrganize': ["Organize and protect memories", "Open a saved memory to access its available tools and collections.", "Open a memory and choose actions supported for that content type.", "Use Collections, Archive or Trash when available to organize or recover items.", "Archive, delete and permanent removal are different actions."],
    'moreSearch': ["Personal search", "Find stored information without visiting every page.", "Open Search in More and type a term.", "Tap a result to open the original location.", "Results depend on accessible, saved data."],
    'moreInbox': ["Inbox", "Keep ideas you want to sort later.", "Open Inbox from Quick access.", "Review and organize saved notes using available actions.", "An Inbox item is not automatically a calendar event."],
    'moreExplore': ["Explore tools", "Explore shows optional features enabled in Personalization.", "Open Explore from More.", "Choose a visible tool to open its dedicated page.", "Hiding a feature does not delete its saved data."],
    'moreFavorites': ["Favorites", "Find the tools you use most often more quickly.", "Check Favorites on the More page.", "Use a shortcut to return to a frequent destination.", "Shortcuts do not duplicate content."],
    'moreVault': ["Private Vault", "Vault protects sensitive information separately from your usual diary.", "Open Private Vault in More when enabled.", "Complete the required unlock before viewing protected data.", "Private Vault and shared passwords have different access rules."],
    'moreLetters': ["Future letters", "Save a message intended for a later moment.", "Open Future letters in Your space if enabled.", "Create or review letters on their dedicated page.", "Check the displayed dates and conditions before planning a letter."],
    'moreData': ["Archive, backup and cloud", "Archive, backup and account sync are different tasks.", "Open Archive for stored items; use Backup for available export/restore workflows.", "Open Cloud and account for sign-in and synchronization.", "Backup is not the same as cloud sync; check the real status."],
    'moreSettings': ["Profile, settings and appearance", "Adjust your experience without changing diary content.", "Open your profile card or Settings in More.", "Set preferences, module visibility, Journal/Classic style and colors.", "Hiding a module is reversible; it does not delete data."],
    'date': ["Content date", "Create+ uses the selected day. You can change it before starting, including when opening from Calendar or Inbox.", "Tap the date row below Create to open the calendar.", "Pick the day, then choose what to add; the new item uses that date.", "This does not move existing saved items."],
    'text': ["Diary note", "Write a thought, an experience or something from your day, saved to that day's journal.", "Select the diary-note option and write in the editor.", "Save to see it in Memories and on the journal day.", "Closing without saving does not create a memory."],
    'photo': ["Photo", "Keep a moment as a picture, optionally with a caption on the selected day.", "Choose Photo, then use your camera or pick from the gallery.", "Review, add a caption if prompted and save your photo memory.", "Photos are saved only after confirmation; camera/gallery access may require permission."],
    'task': ["Task", "Create something actionable you can later mark as done.", "Choose Task and enter the task title in the editor.", "Review the date and details, then save; mark it done when completed.", "Creating a task does not mark it completed."],
    'taskFromText': ["Task from a sentence", "Turn plain language into a task draft. Date recognition depends on clear wording.", "Type a sentence such as “Call tomorrow at 6 pm” to propose a title and date/time.", "Review and edit the draft before saving it.", "Nothing is created automatically; ambiguous time-zone abbreviations are not guessed."],
    'checklistFromNote': ["Checklist from a note", "Convert bullet lines in text into a draft task with preparation steps.", "Paste lines such as “- Buy tickets” and “- Pack bag”.", "Check the proposed list in the editor and save the task if correct.", "List syntax matters; the source note is not modified."],
    'voice': ["Voice note", "Record a spoken thought or story into your diary.", "Choose Voice note, allow microphone access if requested and start recording.", "Stop, confirm and add a caption if prompted to save the audio.", "Cancelling the recording or its caption does not create an audio note."],
    'sketch': ["Drawing", "Add a freehand illustrated page to the selected journal day.", "Tap Drawing to open the sketchbook tools.", "Draw and save the result to attach it to the day.", "Your drawing enters the diary only after you save it."],
    'visionBoard': ["Vision board", "Create a personal collage of images, words and goals for the selected day.", "Choose Vision board and select a starting template.", "Customize the canvas and save the finished composition to your diary.", "It is personal; it may be hidden in shared-only mode."],
    'inbox': ["Quick Inbox note", "Capture an idea without deciding where it belongs yet.", "Tap Quick Inbox note and write what you want to remember.", "Save it and organize or archive it from Inbox later.", "Inbox notes are not automatically calendar events or tasks."],
    'event': ["Appointment", "Add an event you want to see on your calendar.", "Choose Appointment and enter a title, date and relevant time in the editor.", "Review and save it to display the event in calendar views.", "Notifications depend on settings and permissions; saving does not guarantee an alert."],
    'birthday': ["Birthday", "Remember a meaningful date connected to someone.", "Tap Birthday and fill in the requested name and date.", "Save and find it among birthdays.", "Saving a birthday does not automatically enable notifications."],
    'person': ["Important person", "Create a personal contact record to connect with memories.", "Choose Important person and enter details you want to remember.", "Save the person and link them to diary memories where supported.", "Only enter information you intend to keep."],
    'templates': ["Diary templates", "Start from a writing prompt rather than an empty page.", "Choose Templates and pick a prompt that suits your entry.", "Edit the suggested text and save it as a note for that day.", "A template is a starting point; it does not write or save for you."],
  },
  'es': {
    'hubSpaces': ["Crear y abrir un espacio", "Un espacio agrupa el contenido que decides compartir con sus miembros.", "Crea un espacio, ponle nombre y confirma.", "Abre su tarjeta para ver o añadir elementos compartidos.", "Cambiar el nombre no elimina contenidos."],
    'hubInvite': ["Invitar a alguien", "Las invitaciones permiten que otras personas entren en el mismo espacio.", "Entra al espacio y abre Invitar para obtener el código.", "Envía el código a la persona que quieras añadir.", "Compártelo solo con personas de confianza."],
    'hubJoin': ["Entrar con código o QR", "Únete a otro espacio sin crear uno nuevo.", "Usa Entrar o Escanear QR e introduce la invitación recibida.", "Confirma con tu cuenta y abre el espacio añadido.", "Se requiere una invitación válida."],
    'hubAvatar': ["Foto y nombre del espacio", "Cada espacio puede tener una foto visible para sus miembros.", "Si eres propietario, usa la cámara para elegir o tomar una foto.", "Puedes cambiarla, quitarla o renombrar el espacio.", "Los miembros la ven pero no pueden cambiarla para todos."],
    'hubSync': ["Sincronización y estado", "Los cambios compartidos utilizan tu cuenta en la nube.", "Consulta los indicadores para ver cambios pendientes.", "Pulsa Actualizar con conexión para recibir novedades.", "Lo pendiente puede no estar en otros dispositivos."],
    'spaceCreate': ["Añadir contenido", "Decide qué contenido añadir al espacio compartido.", "Pulsa Añadir o Compartir.", "Elige el tipo, completa los datos y confirma.", "El diario personal no se comparte automáticamente."],
    'spaceInteractions': ["Me gusta, comentarios y lecturas", "Consulta cómo reaccionaron los miembros al contenido.", "Usa el corazón y Comentar para interactuar.", "Pulsa la cifra del corazón para ver nombres y fechas confirmados.", "Las horas requieren datos sincronizados."],
    'spaceMembers': ["Personas e invitaciones", "Miembros muestra quién forma parte del espacio.", "Abre Personas del espacio.", "Usa Invitar o los controles del propietario para gestionar accesos.", "Protege los códigos de invitación."],
    'spaceMemories': ["Recuerdos compartidos", "Encuentra fotos y recuerdos publicados en este espacio.", "Abre Recuerdos del espacio.", "Explora y abre los elementos guardados.", "Solo aparece lo compartido explícitamente."],
    'spaceUtilities': ["Herramientas del espacio", "Utiliza opciones compartidas como la lista de compras o contraseñas.", "Abre la herramienta desde el espacio o menú.", "Edita solamente elementos permitidos.", "Las contraseñas pueden requerir desbloqueo adicional."],
    'spacePrivacy': ["Privacidad y sincronización", "Lo compartido está separado del diario privado y requiere cuenta para sincronizar.", "Comprueba el espacio y sus miembros antes de publicar.", "Revisa los estados pendientes si algo no aparece.", "Salir y eliminar un espacio son acciones diferentes."],
    'memoriesForYou': ["Para ti", "Destaca recuerdos guardados que vale la pena revivir.", "Abre Para ti.", "Pulsa una tarjeta para volver al recuerdo.", "No se crean recuerdos inventados."],
    'memoriesTimeline': ["Cronología", "Ordena tus recuerdos guardados a lo largo del tiempo.", "Elige Cronología para explorarlos.", "Abre un recuerdo para ver sus detalles.", "Se ordenan según sus fechas."],
    'memoriesBrowse': ["Días, meses y años", "Explora por día o por periodos más amplios.", "Abre Explorar y elige Días, Meses o Años.", "Selecciona el periodo que quieras consultar.", "Un periodo vacío sigue vacío."],
    'memoriesFind': ["Búsqueda y filtros", "Encuentra recuerdos por texto, fecha o tipo.", "Pulsa Buscar e introduce una palabra o fecha.", "Usa Filtros para limitar resultados; bórralos para ver todo.", "Se respeta el contenido visible."],
    'memoriesOrganize': ["Organizar y proteger recuerdos", "Abre un recuerdo para ver las opciones disponibles.", "Selecciona el recuerdo y sus herramientas.", "Utiliza Colecciones, Archivo o Papelera cuando existan.", "Archivar y eliminar definitivamente son distintos."],
    'moreSearch': ["Búsqueda personal", "Encuentra información guardada sin abrir cada sección.", "Abre Buscar e introduce un término.", "Pulsa un resultado para abrirlo.", "Depende de datos guardados y accesibles."],
    'moreInbox': ["Inbox", "Guarda ideas que quieras ordenar después.", "Abre Inbox desde accesos rápidos.", "Revisa y organiza los apuntes.", "No se convierten solos en citas."],
    'moreExplore': ["Explorar funciones", "Explorar muestra opciones activadas en Personalización.", "Abre Explorar desde Más.", "Elige una herramienta visible.", "Ocultar no elimina los datos guardados."],
    'moreFavorites': ["Favoritos", "Accede antes a las funciones que usas más.", "Busca Favoritos en Más.", "Usa los accesos directos disponibles.", "No duplican contenido."],
    'moreVault': ["Caja fuerte privada", "Protege datos sensibles fuera del diario habitual.", "Abre Caja fuerte desde Más si está activada.", "Desbloquea para ver o editar contenido.", "No es igual a las contraseñas compartidas."],
    'moreLetters': ["Cartas futuras", "Guarda mensajes para leerlos en otro momento.", "Abre Cartas futuras si está disponible.", "Crea o consulta las cartas allí.", "Revisa fechas y condiciones."],
    'moreData': ["Archivo, copia y nube", "Archivo, copias y sincronización tienen funciones distintas.", "Abre Archivo para elementos guardados y Copia para exportar/restaurar.", "Usa Nube y cuenta para acceso y sincronización.", "La copia no es lo mismo que sincronizar."],
    'moreSettings': ["Perfil, ajustes y apariencia", "Personaliza la app sin cambiar el diario.", "Abre el perfil o Ajustes.", "Configura preferencias, módulos y estilo Journal/Classic.", "Ocultar módulos es reversible y no borra datos."],
    'date': ["Fecha del contenido", "Crea+ usa el día seleccionado, pero puedes cambiarlo antes de empezar.", "Pulsa la fila de fecha para abrir el calendario.", "Selecciona el día y después el tipo de contenido que quieres añadir.", "No cambia la fecha de elementos ya guardados."],
    'text': ["Nota de diario", "Escribe un pensamiento o una experiencia vinculada al día elegido.", "Abre Nota de diario y redacta el texto.", "Guarda para encontrarlo en Recuerdos y en ese día del diario.", "Si cierras sin guardar no se crea el recuerdo."],
    'photo': ["Foto", "Conserva un momento con una imagen y, si quieres, una descripción.", "Elige Foto y haz una foto o selecciónala de la galería.", "Revísala, añade un pie si se solicita y guarda el recuerdo.", "La cámara y galería pueden necesitar permiso; cancelar no guarda nada."],
    'task': ["Tarea", "Crea algo pendiente que después puedas marcar como completado.", "Elige Tarea y escribe su título.", "Revisa la fecha, guarda y márcala al terminar.", "Las tareas nuevas no se marcan como hechas automáticamente."],
    'taskFromText': ["Tarea desde una frase", "Convierte una frase en un borrador de tarea con fecha cuando sea clara.", "Escribe algo como «Llamar mañana a las 18» y revisa la propuesta.", "Corrige los detalles en el editor y guarda solo cuando estén bien.", "No se crea nada automáticamente ni se adivinan zonas horarias."],
    'checklistFromNote': ["Checklist desde una nota", "Convierte líneas de una lista en pasos dentro de una tarea.", "Pega líneas como «- Comprar entradas» y «- Preparar maleta».", "Revisa el borrador y guarda la tarea cuando esté correcta.", "Deben parecer líneas de lista; la nota original no cambia."],
    'voice': ["Nota de voz", "Graba un pensamiento con tu voz para conservarlo en el diario.", "Abre Nota de voz, concede acceso al micrófono y comienza a grabar.", "Detén la grabación, confirma y añade el texto solicitado para guardar.", "Cancelar la grabación o el pie de texto no crea la nota."],
    'sketch': ["Dibujo", "Añade una página ilustrada dibujada a mano a tu diario.", "Pulsa Dibujo para abrir el lienzo.", "Dibuja y guarda la página en el día elegido.", "Solo se añade al diario después de guardar."],
    'visionBoard': ["Tablero de visión", "Crea un collage personal con imágenes, palabras y objetivos.", "Elige Tablero de visión y selecciona una plantilla.", "Personaliza el lienzo y guarda la composición en el diario.", "Es personal y puede ocultarse en modo solo compartido."],
    'inbox': ["Nota rápida en Inbox", "Guarda una idea sin organizarla inmediatamente.", "Abre Nota rápida y escribe el pensamiento.", "Guárdalo y organízalo más tarde desde Inbox.", "No se transforma automáticamente en tarea o cita."],
    'event': ["Cita", "Registra un evento que quieras ver en el calendario.", "Elige Cita e introduce título, fecha y horario.", "Revisa y guarda para verlo en el calendario.", "Los avisos dependen de ajustes y permisos."],
    'birthday': ["Cumpleaños", "Guarda una fecha importante de una persona.", "Pulsa Cumpleaños e introduce nombre y fecha.", "Guarda y consulta la sección de cumpleaños.", "Guardarlo no activa avisos automáticamente."],
    'person': ["Persona importante", "Crea una ficha personal para enlazar recuerdos.", "Elige Persona importante y escribe los datos que quieras.", "Guarda y asocia esa persona a tus recuerdos.", "Introduce solo datos que desees conservar."],
    'templates': ["Plantillas de diario", "Empieza a escribir con una guía en lugar de una hoja vacía.", "Abre Plantillas y elige una.", "Edita el texto sugerido y guárdalo como nota del día.", "La plantilla no escribe ni guarda por ti."],
  },
  'fr': {
    'hubSpaces': ["Créer et ouvrir un espace", "Chaque espace réunit les éléments que tu choisis de partager avec ses membres.", "Crée un espace, donne-lui un nom et confirme.", "Ouvre sa carte pour consulter et ajouter des éléments.", "Renommer ne supprime pas son contenu."],
    'hubInvite': ["Inviter quelqu'un", "Une invitation permet à une autre personne de rejoindre le même espace.", "Ouvre l'espace puis Inviter pour obtenir le code.", "Transmets-le à la personne souhaitée.", "Ne partage le code qu'avec des personnes de confiance."],
    'hubJoin': ["Rejoindre avec code ou QR", "Rejoins un espace existant sans en créer un autre.", "Utilise Rejoindre ou Scanner un QR avec ton invitation.", "Confirme avec ton compte puis ouvre l'espace.", "Une invitation valide est nécessaire."],
    'hubAvatar': ["Photo et nom de l'espace", "Un espace peut avoir une photo visible par ses membres.", "Si tu en es propriétaire, utilise l'icône caméra pour choisir une photo.", "Modifie, retire la photo ou renomme l'espace via les commandes.", "Les membres peuvent la voir, mais pas la changer pour tous."],
    'hubSync': ["Synchronisation et état", "Les modifications partagées passent par ton compte cloud.", "Consulte les indicateurs d'envoi en attente.", "Appuie sur Actualiser en ligne pour récupérer les dernières données.", "Un élément en attente n'est pas encore confirmé ailleurs."],
    'spaceCreate': ["Ajouter du contenu", "Décide quels éléments tu souhaites partager.", "Appuie sur Ajouter ou Partager dans l'espace.", "Choisis le type, remplis les informations et confirme.", "Ton journal personnel n'est pas partagé automatiquement."],
    'spaceInteractions': ["J'aime, commentaires et lectures", "Consulte les réactions des membres.", "Utilise le cœur ou Commenter pour participer.", "Appuie sur le nombre près du cœur pour voir qui a aimé et quand.", "Les heures ne s'affichent que si le serveur les confirme."],
    'spaceMembers': ["Personnes et invitations", "Membres affiche les personnes qui participent.", "Ouvre Personnes dans l'espace.", "Utilise Inviter ou les commandes du propriétaire.", "Garde les codes d'invitation confidentiels."],
    'spaceMemories': ["Souvenirs partagés", "Retrouve les photos et souvenirs publiés dans cet espace.", "Ouvre Souvenirs de l'espace.", "Parcours puis ouvre les éléments souhaités.", "Seul le contenu partagé y figure."],
    'spaceUtilities': ["Outils de l'espace", "Utilise des outils partagés comme la liste de courses et les mots de passe.", "Ouvre un outil depuis l'espace ou le menu.", "Ne modifie que les éléments autorisés.", "Les mots de passe peuvent exiger un déverrouillage."],
    'spacePrivacy': ["Confidentialité et synchro", "Le contenu partagé est distinct du journal privé et nécessite un compte pour la synchro.", "Vérifie l'espace et ses membres avant d'envoyer.", "Consulte les états en attente si l'élément n'apparaît pas.", "Quitter et supprimer un espace n'ont pas les mêmes effets."],
    'memoriesForYou': ["Pour toi", "Mets en avant des souvenirs déjà enregistrés.", "Ouvre Pour toi.", "Appuie sur une carte pour revoir le contenu.", "Aucun souvenir n'est inventé."],
    'memoriesTimeline': ["Chronologie", "Classe tes souvenirs enregistrés dans le temps.", "Ouvre Chronologie pour les parcourir.", "Appuie sur un souvenir pour le revoir.", "L'ordre dépend des dates enregistrées."],
    'memoriesBrowse': ["Jours, mois et années", "Explore tes souvenirs par jour ou par période.", "Ouvre Explorer puis Jours, Mois ou Années.", "Sélectionne une période pour afficher ses souvenirs.", "Les périodes vides le restent."],
    'memoriesFind': ["Recherche et filtres", "Retrouve des souvenirs par texte, date ou type.", "Appuie sur Rechercher et saisis un mot ou une date.", "Utilise Filtres puis efface-les pour tout revoir.", "La recherche respecte les contenus accessibles."],
    'memoriesOrganize': ["Organiser et protéger les souvenirs", "Ouvre un souvenir pour afficher ses outils.", "Sélectionne un souvenir et ses actions disponibles.", "Utilise Collections, Archives ou Corbeille si disponibles.", "Archiver et supprimer définitivement sont différents."],
    'moreSearch': ["Recherche personnelle", "Retrouve tes informations sans visiter chaque page.", "Ouvre Rechercher et saisis un terme.", "Appuie sur un résultat pour l'ouvrir.", "Seuls les éléments accessibles sont inclus."],
    'moreInbox': ["Inbox", "Note des idées à organiser plus tard.", "Ouvre Inbox depuis les accès rapides.", "Relis et organise les notes enregistrées.", "Rien ne devient automatiquement un rendez-vous."],
    'moreExplore': ["Explorer les fonctions", "Explorer affiche les outils activés dans Personnalisation.", "Ouvre Explorer depuis Autre.", "Choisis un outil pour accéder à son écran.", "Masquer une fonction ne supprime pas ses données."],
    'moreFavorites': ["Favoris", "Retrouve plus vite les outils utilisés souvent.", "Consulte Favoris sur la page Autre.", "Utilise un raccourci vers la fonction souhaitée.", "Les raccourcis ne dupliquent rien."],
    'moreVault': ["Coffre privé", "Protège les données sensibles à part du journal.", "Ouvre Coffre privé dans Autre si disponible.", "Déverrouille avant de consulter les données.", "Il est distinct des mots de passe partagés."],
    'moreLetters': ["Lettres futures", "Conserve un message à relire plus tard.", "Ouvre Lettres futures si disponible.", "Crée ou consulte les lettres dans cet écran.", "Vérifie les dates et conditions."],
    'moreData': ["Archives, sauvegarde et cloud", "Ce sont des outils distincts de conservation et de synchronisation.", "Ouvre Archives pour les éléments stockés et Sauvegarde pour exporter ou restaurer.", "Utilise Cloud et compte pour la connexion et la synchro.", "Une sauvegarde n'est pas une synchronisation."],
    'moreSettings': ["Profil, réglages et apparence", "Personnalise l'application sans modifier le journal.", "Ouvre le profil ou Réglages.", "Configure les préférences, modules, couleurs et style Journal/Classic.", "Masquer un module n'efface pas les données."],
    'date': ["Date du contenu", "Créer+ utilise le jour sélectionné ; tu peux le changer avant de commencer.", "Appuie sur la ligne de la date pour ouvrir le calendrier.", "Choisis le jour puis le contenu à créer.", "Les éléments existants ne changent pas de date."],
    'text': ["Note de journal", "Écris une pensée ou un événement associé au jour choisi.", "Ouvre la note de journal et écris ton texte.", "Enregistre pour la retrouver dans Souvenirs et dans ton journal.", "Fermer sans enregistrer ne crée rien."],
    'photo': ["Photo", "Conserve un moment avec une image et, si tu veux, une légende.", "Choisis Photo puis l'appareil photo ou la galerie.", "Vérifie l'image, ajoute une légende si demandé puis enregistre.", "L'accès aux photos peut nécessiter une autorisation ; annuler ne sauvegarde rien."],
    'task': ["Tâche", "Crée une action à réaliser et à cocher ensuite.", "Choisis Tâche et saisis son titre.", "Vérifie la date, enregistre et coche-la une fois terminée.", "La création ne marque pas la tâche comme accomplie."],
    'taskFromText': ["Tâche depuis une phrase", "Transforme une phrase en brouillon de tâche, avec une date si elle est claire.", "Écris « Appeler demain à 18 h » et regarde la proposition.", "Corrige les détails dans l'éditeur avant d'enregistrer.", "Aucune tâche n'est créée automatiquement ; les fuseaux ambigus sont refusés."],
    'checklistFromNote': ["Checklist depuis une note", "Transforme les lignes d'une liste en étapes d'une tâche.", "Colle par exemple «- Acheter les billets» et «- Faire la valise».", "Vérifie la proposition avant d'enregistrer la tâche.", "Les lignes doivent former une liste ; la note source reste intacte."],
    'voice': ["Note vocale", "Enregistre un souvenir raconté à voix haute.", "Choisis Note vocale, autorise le micro si demandé et enregistre.", "Arrête, confirme et ajoute la légende demandée pour sauvegarder.", "Annuler l'enregistrement ou la légende ne crée pas de note."],
    'sketch': ["Dessin", "Ajoute une page illustrée à la main au jour sélectionné.", "Ouvre Dessin pour afficher la toile.", "Dessine puis enregistre la page dans ton journal.", "Seul un enregistrement explicite ajoute la page."],
    'visionBoard': ["Tableau de vision", "Compose un collage personnel d'images, mots et objectifs.", "Choisis un modèle de tableau de vision.", "Personnalise la toile puis enregistre-la dans le journal.", "Cette fonction personnelle peut être masquée en mode partagé uniquement."],
    'inbox': ["Note rapide dans Inbox", "Note une idée sans la classer immédiatement.", "Ouvre la note rapide et écris ton idée.", "Enregistre puis organise-la plus tard depuis Inbox.", "Elle ne devient pas automatiquement une tâche ou un rendez-vous."],
    'event': ["Rendez-vous", "Ajoute un événement que tu veux voir au calendrier.", "Choisis Rendez-vous puis saisis le titre, la date et l'heure.", "Vérifie et enregistre pour l'afficher dans le calendrier.", "Les alertes dépendent des réglages et autorisations."],
    'birthday': ["Anniversaire", "Garde une date importante pour une personne.", "Choisis Anniversaire et saisis le nom et la date.", "Enregistre puis retrouve-la avec les anniversaires.", "Cela n'active pas automatiquement les rappels."],
    'person': ["Personne importante", "Crée une fiche personnelle pour relier des souvenirs.", "Choisis Personne importante et saisis les informations souhaitées.", "Enregistre et associe cette personne aux souvenirs.", "Ne saisis que les informations que tu veux conserver."],
    'templates': ["Modèles de journal", "Commence par une proposition plutôt qu'une page blanche.", "Ouvre Modèles et choisis une trame.", "Modifie le texte proposé puis enregistre-le dans le journal.", "Le modèle n'écrit ni n'enregistre à ta place."],
  },
  'pt': {
    'hubSpaces': ["Criar e abrir um espaço", "Cada espaço contém o que decides partilhar com os seus membros.", "Cria o espaço, escolhe um nome e confirma.", "Abre o cartão para consultar ou adicionar conteúdos.", "Mudar o nome não elimina conteúdos."],
    'hubInvite': ["Convidar alguém", "Um convite permite a outra pessoa entrar no mesmo espaço.", "Abre o espaço e toca em Convidar para obter o código.", "Envia-o à pessoa que queres adicionar.", "Partilha o código apenas com pessoas de confiança."],
    'hubJoin': ["Entrar com código ou QR", "Entra num espaço existente sem criares outro.", "Usa Entrar ou Ler QR com o convite recebido.", "Confirma com a tua conta e abre o espaço.", "É necessário um convite válido."],
    'hubAvatar': ["Foto e nome do espaço", "Cada espaço pode ter uma fotografia visível a todos os membros.", "Se fores proprietário, usa a câmara para escolher uma foto.", "Altera, remove ou muda o nome pelos comandos disponíveis.", "Os membros podem ver a foto, mas não alterá-la para todos."],
    'hubSync': ["Sincronização e estado", "As alterações partilhadas usam a tua conta na cloud.", "Verifica os indicadores de alterações pendentes.", "Atualiza quando estiveres online para obter os dados recentes.", "O que está pendente pode ainda não aparecer noutros dispositivos."],
    'spaceCreate': ["Adicionar conteúdo", "Decide o que queres partilhar neste espaço.", "Toca em Adicionar ou Partilhar.", "Escolhe o tipo, preenche os detalhes e confirma.", "O diário pessoal não é partilhado automaticamente."],
    'spaceInteractions': ["Gostos, comentários e leituras", "Vê como os membros reagem aos conteúdos.", "Usa o coração e Comentário para interagir.", "Toca no número junto ao coração para ver nomes e datas confirmados.", "As horas exigem dados sincronizados."],
    'spaceMembers': ["Pessoas e convites", "Membros mostra quem participa no espaço.", "Abre Pessoas no espaço.", "Usa Convidar ou os controlos do proprietário.", "Protege os códigos de convite."],
    'spaceMemories': ["Memórias partilhadas", "Encontra fotos e memórias publicadas neste espaço.", "Abre Memórias do espaço.", "Percorre os conteúdos e volta a abri-los.", "Só aparece o conteúdo partilhado."],
    'spaceUtilities': ["Ferramentas do espaço", "Usa opções partilhadas como lista de compras e palavras-passe.", "Abre a ferramenta na página ou no menu.", "Edita apenas conteúdos autorizados.", "Palavras-passe protegidas podem exigir desbloqueio."],
    'spacePrivacy': ["Privacidade e sincronização", "O conteúdo partilhado é separado do diário pessoal e exige conta para sincronizar.", "Confirma o espaço e membros antes de publicar.", "Verifica os estados pendentes se algo faltar.", "Sair e eliminar um espaço são ações diferentes."],
    'memoriesForYou': ["Para ti", "Destaca memórias já guardadas para reviver.", "Abre Para ti.", "Toca num cartão para rever o conteúdo.", "Não são criadas memórias fictícias."],
    'memoriesTimeline': ["Cronologia", "Organiza as memórias guardadas ao longo do tempo.", "Escolhe Cronologia para percorrer os registos.", "Abre uma memória para a reveres.", "A ordem segue as datas guardadas."],
    'memoriesBrowse': ["Dias, meses e anos", "Percorre memórias por dia ou períodos maiores.", "Abre Explorar e escolhe Dias, Meses ou Anos.", "Seleciona o período pretendido.", "Períodos vazios continuam vazios."],
    'memoriesFind': ["Pesquisa e filtros", "Encontra memórias por texto, data ou tipo.", "Toca em Pesquisar e introduz um termo.", "Usa Filtros e limpa-os para voltar a ver tudo.", "A pesquisa respeita os conteúdos visíveis."],
    'memoriesOrganize': ["Organizar e proteger memórias", "Abre uma memória para consultar as ferramentas disponíveis.", "Seleciona uma memória e as suas ações.", "Usa Coleções, Arquivo ou Lixo quando disponíveis.", "Arquivar e eliminar definitivamente não são iguais."],
    'moreSearch': ["Pesquisa pessoal", "Encontra informações guardadas sem abrir cada página.", "Abre Pesquisar e escreve um termo.", "Toca num resultado para o abrir.", "Depende dos dados acessíveis."],
    'moreInbox': ["Inbox", "Guarda ideias para organizar depois.", "Abre Inbox nos acessos rápidos.", "Revê e organiza as notas guardadas.", "Não se tornam compromissos automaticamente."],
    'moreExplore': ["Explorar funções", "Explorar mostra ferramentas ativadas na Personalização.", "Abre Explorar a partir de Mais.", "Escolhe uma ferramenta visível.", "Ocultar não elimina dados guardados."],
    'moreFavorites': ["Favoritos", "Reencontra mais depressa as funções frequentes.", "Consulta Favoritos na página Mais.", "Usa os atalhos disponíveis.", "Atalhos não duplicam conteúdos."],
    'moreVault': ["Cofre privado", "Protege informações sensíveis fora do diário.", "Abre Cofre privado em Mais se estiver ativo.", "Desbloqueia para veres os dados.", "É diferente das palavras-passe partilhadas."],
    'moreLetters': ["Cartas futuras", "Guarda uma mensagem para ler mais tarde.", "Abre Cartas futuras se disponível.", "Cria ou consulta cartas nessa página.", "Confirma datas e condições."],
    'moreData': ["Arquivo, cópia e cloud", "Arquivo, cópias e sincronização são diferentes.", "Abre Arquivo para conteúdos guardados e Backup para exportar/restaurar.", "Usa Cloud e conta para acesso e sincronização.", "Uma cópia não equivale a sincronizar."],
    'moreSettings': ["Perfil, definições e aspeto", "Personaliza a aplicação sem alterar o diário.", "Abre o perfil ou Definições.", "Ajusta preferências, módulos, cores e estilo Journal/Classic.", "Ocultar módulos é reversível e não apaga dados."],
    'date': ["Data do conteúdo", "Criar+ usa o dia selecionado, que podes alterar antes de começar.", "Toca na linha da data para abrir o calendário.", "Escolhe o dia e depois o tipo de conteúdo a criar.", "Os conteúdos já guardados não mudam de data."],
    'text': ["Nota de diário", "Escreve uma ideia ou acontecimento associado ao dia escolhido.", "Abre Nota de diário e escreve o texto.", "Guarda para o encontrares em Memórias e nesse dia do diário.", "Fechar sem guardar não cria uma memória."],
    'photo': ["Fotografia", "Guarda um momento com uma imagem e, se quiseres, uma legenda.", "Escolhe Foto e tira ou seleciona uma fotografia.", "Confirma a imagem, adiciona uma legenda se necessário e guarda.", "A câmara/galeria pode pedir permissão; cancelar não guarda nada."],
    'task': ["Tarefa", "Cria uma atividade para marcar como concluída mais tarde.", "Escolhe Tarefa e escreve o título.", "Verifica a data, guarda e assinala quando terminares.", "Criar a tarefa não a conclui automaticamente."],
    'taskFromText': ["Tarefa a partir de uma frase", "Converte texto em rascunho de tarefa com data, quando a frase é clara.", "Escreve «Telefonar amanhã às 18h» e observa a proposta.", "Corrige os detalhes no editor e só depois guarda.", "Nada é criado automaticamente e fusos horários ambíguos não são adivinhados."],
    'checklistFromNote': ["Checklist a partir de uma nota", "Transforma linhas de lista em passos de uma tarefa.", "Cola linhas como «- Comprar bilhetes» e «- Preparar mala».", "Revê a proposta no editor e guarda quando estiver correta.", "O texto deve ter formato de lista; a nota original não muda."],
    'voice': ["Nota de voz", "Grava um pensamento ou uma história para o diário.", "Escolhe Nota de voz, permite o microfone se necessário e grava.", "Termina, confirma e adiciona a legenda pedida para guardar.", "Cancelar a gravação ou legenda não cria a nota."],
    'sketch': ["Desenho", "Adiciona uma página desenhada ao dia escolhido.", "Abre Desenho e usa as ferramentas da tela.", "Desenha e guarda o resultado no diário.", "A página só é adicionada após guardares."],
    'visionBoard': ["Quadro de visão", "Cria uma colagem pessoal com imagens, palavras e objetivos.", "Escolhe um modelo de quadro de visão.", "Personaliza a tela e guarda a composição no diário.", "É pessoal e pode estar oculta no modo só partilhado."],
    'inbox': ["Nota rápida na Inbox", "Guarda uma ideia antes de a organizares.", "Abre a nota rápida e escreve o que queres lembrar.", "Guarda e organiza mais tarde na Inbox.", "Não se torna automaticamente tarefa ou compromisso."],
    'event': ["Compromisso", "Adiciona um evento que queres ver no calendário.", "Escolhe Compromisso e indica título, data e hora.", "Confirma e guarda para o veres no calendário.", "Os avisos dependem de definições e permissões."],
    'birthday': ["Aniversário", "Regista uma data importante de alguém.", "Escolhe Aniversário e preenche nome e data.", "Guarda e consulta a lista de aniversários.", "Guardar não ativa avisos automaticamente."],
    'person': ["Pessoa importante", "Cria um registo pessoal ligado às memórias.", "Escolhe Pessoa importante e preenche o que quiseres lembrar.", "Guarda e associa esta pessoa às memórias.", "Introduz apenas dados que queres conservar."],
    'templates': ["Modelos de diário", "Começa por uma sugestão em vez de uma página vazia.", "Abre Modelos e escolhe um.", "Edita o texto sugerido e guarda-o como nota do dia.", "O modelo não escreve nem guarda por ti."],
  },
  // All top-level guides have five-language content.
};

const Map<String, Map<AnnaContextHelpSection, List<String>>>
    _annaContextHelpHeaders = {
    'it': {
    AnnaContextHelpSection.create: ["Guida a Crea+", "SCEGLI COSA CONSERVARE", "Dalla nota veloce alla vision board: apri ogni voce per conoscere passaggi, risultati e limiti."],
    AnnaContextHelpSection.sharedHub: ["Guida allo Spazio condiviso", "NOI, INSIEME", "Crea e gestisci spazi, invita persone e controlla cosa viene sincronizzato."],
    AnnaContextHelpSection.sharedSpace: ["Guida a questo spazio", "CONTENUTI CONDIVISI", "Scopri come aggiungere contenuti, gestire le interazioni e proteggere i dati."],
    AnnaContextHelpSection.memories: ["Guida ai Ricordi", "IL TUO DIARIO NEL TEMPO", "Ritrova momenti importanti, esplora la cronologia e organizza ciò che hai conservato."],
    AnnaContextHelpSection.more: ["Guida ad Altro", "TUTTO AL SUO POSTO", "Questa schermata raccoglie strumenti, impostazioni e funzioni accessorie."],
  },
  'en': {
    AnnaContextHelpSection.create: ["Create+ guide", "CHOOSE WHAT TO KEEP", "From a quick note to a vision board: open each topic for steps, outcomes and limits."],
    AnnaContextHelpSection.sharedHub: ["Shared spaces guide", "TOGETHER", "Create spaces, invite people and understand what is synced."],
    AnnaContextHelpSection.sharedSpace: ["This space guide", "SHARED CONTENT", "Learn to add items, manage interactions and protect your data."],
    AnnaContextHelpSection.memories: ["Memories guide", "YOUR DIARY OVER TIME", "Find important moments, explore the timeline and organize what you kept."],
    AnnaContextHelpSection.more: ["More guide", "EVERYTHING IN ITS PLACE", "Find tools, settings and supporting features on this page."],
  },
  'es': {
    AnnaContextHelpSection.create: ["Guía de Crea+", "ELIGE QUÉ GUARDAR", "De notas rápidas a tableros de visión: consulta los pasos y sus límites."],
    AnnaContextHelpSection.sharedHub: ["Guía de espacio compartido", "JUNTOS", "Crea espacios, invita a otros y controla la sincronización."],
    AnnaContextHelpSection.sharedSpace: ["Guía de este espacio", "CONTENIDO COMPARTIDO", "Aprende a añadir contenido, gestionar interacciones y proteger datos."],
    AnnaContextHelpSection.memories: ["Guía de recuerdos", "TU DIARIO CON EL TIEMPO", "Encuentra momentos, explora la cronología y organiza recuerdos."],
    AnnaContextHelpSection.more: ["Guía de Más", "TODO EN SU SITIO", "Encuentra herramientas, ajustes y funciones adicionales."],
  },
  'fr': {
    AnnaContextHelpSection.create: ["Guide Créer+", "CHOISIS QUOI GARDER", "De la note rapide au tableau de vision : étapes, résultats et limites."],
    AnnaContextHelpSection.sharedHub: ["Guide des espaces partagés", "ENSEMBLE", "Crée des espaces, invite des membres et comprends la synchronisation."],
    AnnaContextHelpSection.sharedSpace: ["Guide de cet espace", "CONTENU PARTAGÉ", "Ajoute du contenu, gère les interactions et protège tes données."],
    AnnaContextHelpSection.memories: ["Guide des souvenirs", "TON JOURNAL AU FIL DU TEMPS", "Retrouve tes moments, explore la chronologie et organise tes souvenirs."],
    AnnaContextHelpSection.more: ["Guide Autre", "TOUT À SA PLACE", "Retrouve outils, réglages et fonctionnalités complémentaires."],
  },
  'pt': {
    AnnaContextHelpSection.create: ["Guia Criar+", "ESCOLHE O QUE GUARDAR", "De notas rápidas a quadros de visão: passos, resultados e limites."],
    AnnaContextHelpSection.sharedHub: ["Guia dos espaços partilhados", "JUNTOS", "Cria espaços, convida pessoas e compreende a sincronização."],
    AnnaContextHelpSection.sharedSpace: ["Guia deste espaço", "CONTEÚDO PARTILHADO", "Adiciona conteúdos, gere interações e protege os teus dados."],
    AnnaContextHelpSection.memories: ["Guia das memórias", "O TEU DIÁRIO NO TEMPO", "Encontra momentos, percorre a cronologia e organiza memórias."],
    AnnaContextHelpSection.more: ["Guia Mais", "TUDO NO SEU LUGAR", "Encontra ferramentas, definições e funcionalidades adicionais."],
  },
};

const Map<String, Map<String, String>> _annaContextHelpUi = {
    'it': {"button": "Apri la guida a questa schermata", "step": "Passaggi", "tip": "Da sapere", "footer": "Le guide spiegano le funzioni: non salvano né modificano contenuti.", "close": "Chiudi"},
  'en': {"button": "Open this screen's guide", "step": "Steps", "tip": "Good to know", "footer": "Guides explain features; they do not save or change your content.", "close": "Close"},
  'es': {"button": "Abrir la guía de esta pantalla", "step": "Pasos", "tip": "Importante", "footer": "Las guías explican funciones; no guardan ni modifican contenido.", "close": "Cerrar"},
  'fr': {"button": "Ouvrir le guide de cet écran", "step": "Étapes", "tip": "À savoir", "footer": "Les guides expliquent les fonctions sans modifier tes contenus.", "close": "Fermer"},
  'pt': {"button": "Abrir o guia deste ecrã", "step": "Passos", "tip": "A saber", "footer": "Os guias explicam as funções; não alteram nem guardam conteúdo.", "close": "Fechar"},
};

String _annaHelpLanguage(String value) =>
    _annaContextHelpArticles.containsKey(value) ? value : 'en';

List<String> _annaHelpArticle(String language, String id) =>
    _annaContextHelpArticles[_annaHelpLanguage(language)]?[id] ??
    _annaContextHelpArticles['en']![id]!;

String _annaHelpUi(String language, String id) =>
    _annaContextHelpUi[_annaHelpLanguage(language)]?[id] ??
    _annaContextHelpUi['en']![id]!;

class AnnaContextHelpButton extends StatelessWidget {
  const AnnaContextHelpButton({
    super.key,
    required this.section,
    this.captureActions = const <AnnaContextHelpTopic>[],
  });

  final AnnaContextHelpSection section;
  final List<AnnaContextHelpTopic> captureActions;

  @override
  Widget build(BuildContext context) => IconButton(
    key: ValueKey<String>('context-help-${section.name}'),
    tooltip: _annaHelpUi(AnnaStrings.of(context).languageCode, 'button'),
    icon: const Icon(Icons.info_outline_rounded),
    onPressed: () => Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AnnaContextHelpScreen(
          section: section,
          captureActions: captureActions,
        ),
      ),
    ),
  );
}

class AnnaContextHelpScreen extends StatefulWidget {
  const AnnaContextHelpScreen({
    super.key,
    required this.section,
    this.captureActions = const <AnnaContextHelpTopic>[],
  });

  final AnnaContextHelpSection section;
  final List<AnnaContextHelpTopic> captureActions;

  @override
  State<AnnaContextHelpScreen> createState() => _AnnaContextHelpScreenState();
}

class _AnnaContextHelpScreenState extends State<AnnaContextHelpScreen> {
  String? _expanded;

  List<AnnaContextHelpTopic> _visibleTopics(String language) {
    if (widget.section == AnnaContextHelpSection.create) {
      // A hidden Vision Board (or any future disabled action) is not
      // advertised as available. The selected date is always explained.
      return <AnnaContextHelpTopic>[
        AnnaContextHelpTopic(
          id: 'date',
          icon: Icons.event_available_outlined,
          title: _annaHelpArticle(language, 'date')[0],
        ),
        ...widget.captureActions,
      ];
    }
    return <AnnaContextHelpTopic>[
      for (final id in _annaContextHelpSections[widget.section]!)
        AnnaContextHelpTopic(
          id: id,
          icon: _annaContextHelpIcons[id]!,
          title: _annaHelpArticle(language, id)[0],
        ),
    ];
  }

  Widget _article(
    BuildContext context,
    AnnaContextHelpTopic topic,
    List<String> copy,
    bool organic,
  ) {
    final ink = AnnaEditorialColors.of(context).ink;
    final muted = AnnaEditorialColors.of(context).mutedInk;
    final expanded = _expanded == topic.id;
    final lang = AnnaStrings.of(context).languageCode;
    final contents = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          identifier: 'context-help-topic-${topic.id}',
          button: true,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => setState(
              () => _expanded = expanded ? null : topic.id,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 13,
              ),
              child: Row(
                children: [
                  Icon(topic.icon, color: AnnaEditorialColors.of(context).accent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      topic.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: organic
                          ? AnnaJournalTypography.editorial(context, size: 18)
                          : Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: muted,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (expanded) ...[
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 15, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(copy[1], style: TextStyle(color: ink, height: 1.5)),
                const SizedBox(height: 15),
                Text(
                  _annaHelpUi(lang, 'step'),
                  style: TextStyle(
                    color: muted, fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 9),
                for (var index = 2; index <= 3; index++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: AnnaEditorialColors.of(context).quiet,
                          child: Text(
                            '${index - 1}',
                            style: TextStyle(fontSize: 12, color: ink),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            copy[index],
                            style: TextStyle(color: ink, height: 1.45),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (copy[4].isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.lightbulb_outline, color: muted, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${_annaHelpUi(lang, 'tip')}: ${copy[4]}',
                            style: TextStyle(color: muted, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: organic
          ? AnnaOrganicPaperSurface(padding: EdgeInsets.zero, child: contents)
          : Card(
              margin: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              child: contents,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final language = _annaHelpLanguage(AnnaStrings.of(context).languageCode);
    final header = _annaContextHelpHeaders[language]![widget.section]!;
    final topics = _visibleTopics(language);
    final organic = AnnaOrganicPastel.enabled(context);
    final palette = AnnaEditorialColors.of(context);
    final expanded = _expanded ?? (topics.isEmpty ? null : topics.first.id);
    if (_expanded == null && expanded != null) {
      // Only the initial state is expanded. No persistence or mutations.
      _expanded = expanded;
    }
    return Scaffold(
      backgroundColor: organic ? palette.canvas : null,
      appBar: AppBar(
        title: Text(
          header[0],
          style: organic
              ? AnnaJournalTypography.editorial(context, size: 22)
              : null,
        ),
        backgroundColor: organic ? palette.canvas : null,
        surfaceTintColor: organic ? Colors.transparent : null,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              key: ValueKey<String>('context-help-page-${widget.section.name}'),
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
              children: [
                AnnaEditorialHeader(
                  eyebrow: header[1],
                  title: header[0],
                  subtitle: header[2],
                ),
                const SizedBox(height: 20),
                for (final topic in topics)
                  _article(
                    context,
                    topic,
                    _annaHelpArticle(language, topic.id),
                    organic,
                  ),
                const SizedBox(height: 10),
                Text(
                  _annaHelpUi(language, 'footer'),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: palette.mutedInk),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
