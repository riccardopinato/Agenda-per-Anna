
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
    'moreSearch', 'moreInbox', 'moreExplore',
    'moreVault', 'moreData', 'moreSettings',
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
  'moreInbox': Icons.inbox_outlined,
  'moreExplore': Icons.apps_outlined,
  'moreVault': Icons.lock_person_outlined,
  'moreData': Icons.backup_outlined,
  'moreSettings': Icons.settings_outlined,
};

const Map<String, Map<String, List<String>>> _annaContextHelpArticles = {
    'it': {
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
  // EXTRA_TOPICS
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
