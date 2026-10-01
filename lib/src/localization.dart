part of '../main.dart';

class AnnaStrings {
  final String languageCode;

  const AnnaStrings(this.languageCode);

  static const supportedLocales = <Locale>[
    Locale('en'),
    Locale('it'),
    Locale('es'),
    Locale('fr'),
    Locale('pt'),
  ];

  static AnnaStrings of(BuildContext context) =>
      AnnaStrings(Localizations.localeOf(context).languageCode);

  static Locale resolveLocale(Locale? locale) {
    final code = locale?.languageCode.toLowerCase();
    for (final supported in supportedLocales) {
      if (supported.languageCode == code) return supported;
    }
    return const Locale('en');
  }

  static String intlLocale(BuildContext context) =>
      resolveLocale(Localizations.maybeLocaleOf(context)).languageCode;

  String _pick({
    required String en,
    required String it,
    required String es,
    required String fr,
    required String pt,
  }) =>
      switch (languageCode) {
        'it' => it,
        'es' => es,
        'fr' => fr,
        'pt' => pt,
        _ => en,
      };

  String get navHome => 'Home';

  String get navMonth => _pick(
        en: 'Month',
        it: 'Mese',
        es: 'Mes',
        fr: 'Mois',
        pt: 'Mês',
      );

  String get navWeek => _pick(
        en: 'Week',
        it: 'Settimana',
        es: 'Semana',
        fr: 'Semaine',
        pt: 'Semana',
      );

  String get navToday => _pick(
        en: 'Today',
        it: 'Oggi',
        es: 'Hoy',
        fr: "Aujourd’hui",
        pt: 'Hoje',
      );

  String get add => _pick(
        en: 'Add',
        it: 'Aggiungi',
        es: 'Añadir',
        fr: 'Ajouter',
        pt: 'Adicionar',
      );

  String get search => _pick(
        en: 'Search',
        it: 'Cerca',
        es: 'Buscar',
        fr: 'Rechercher',
        pt: 'Pesquisar',
      );

  String get archive => _pick(
        en: 'Archive',
        it: 'Archivio',
        es: 'Archivo',
        fr: 'Archives',
        pt: 'Arquivo',
      );

  String get backup => 'Backup';

  String get cloud => 'Cloud';

  String get settings => _pick(
        en: 'Settings',
        it: 'Impostazioni',
        es: 'Ajustes',
        fr: 'Réglages',
        pt: 'Definições',
      );

  String get myAgenda => _pick(
        en: 'My agenda',
        it: 'La mia agenda',
        es: 'Mi agenda',
        fr: 'Mon agenda',
        pt: 'A minha agenda',
      );

  String agendaFor(String name) => _pick(
        en: 'Agenda for $name',
        it: 'Agenda per $name',
        es: 'Agenda de $name',
        fr: 'Agenda de $name',
        pt: 'Agenda de $name',
      );

  String hello(String name) {
    if (name.trim().isEmpty) {
      return _pick(
        en: 'Hi ♡',
        it: 'Ciao ♡',
        es: 'Hola ♡',
        fr: 'Bonjour ♡',
        pt: 'Olá ♡',
      );
    }
    return _pick(
      en: 'Hi $name ♡',
      it: 'Ciao $name ♡',
      es: 'Hola $name ♡',
      fr: 'Bonjour $name ♡',
      pt: 'Olá $name ♡',
    );
  }

  String get todayPage => _pick(
        en: 'This is your page for today.',
        it: 'Questa è la tua pagina di oggi.',
        es: 'Esta es tu página de hoy.',
        fr: 'Voici ta page du jour.',
        pt: 'Esta é a tua página de hoje.',
      );

  String get myAgendaSection => myAgenda;

  String get name => _pick(
        en: 'Name',
        it: 'Nome',
        es: 'Nombre',
        fr: 'Nom',
        pt: 'Nome',
      );

  String get enterName => _pick(
        en: 'Enter your name',
        it: 'Inserisci il tuo nome',
        es: 'Introduce tu nombre',
        fr: 'Saisis ton nom',
        pt: 'Introduz o teu nome',
      );

  String get saveName => _pick(
        en: 'Save name',
        it: 'Salva nome',
        es: 'Guardar nombre',
        fr: 'Enregistrer le nom',
        pt: 'Guardar nome',
      );

  String get appearance => _pick(
        en: 'Appearance',
        it: 'Aspetto',
        es: 'Apariencia',
        fr: 'Apparence',
        pt: 'Aspeto',
      );

  String get language => _pick(
        en: 'Language',
        it: 'Lingua',
        es: 'Idioma',
        fr: 'Langue',
        pt: 'Idioma',
      );

  String get languageDescription => _pick(
        en: 'Use the device language or choose one manually.',
        it: 'Usa la lingua del dispositivo oppure scegline una manualmente.',
        es: 'Usa el idioma del dispositivo o elige uno manualmente.',
        fr: 'Utilise la langue de l’appareil ou choisis-en une manuellement.',
        pt: 'Usa o idioma do dispositivo ou escolhe um manualmente.',
      );

  String get systemTheme => _pick(
        en: 'System',
        it: 'Sistema',
        es: 'Sistema',
        fr: 'Système',
        pt: 'Sistema',
      );

  String get lightTheme => _pick(
        en: 'Light',
        it: 'Chiaro',
        es: 'Claro',
        fr: 'Clair',
        pt: 'Claro',
      );

  String get darkTheme => _pick(
        en: 'Dark',
        it: 'Scuro',
        es: 'Oscuro',
        fr: 'Sombre',
        pt: 'Escuro',
      );

  String get agendaColor => _pick(
        en: 'Agenda color',
        it: 'Colore dell’agenda',
        es: 'Color de la agenda',
        fr: 'Couleur de l’agenda',
        pt: 'Cor da agenda',
      );

  String get startupAndDay => _pick(
        en: 'Startup and day',
        it: 'Avvio e giornata',
        es: 'Inicio y día',
        fr: 'Démarrage et journée',
        pt: 'Início e dia',
      );

  String get openAppOn => _pick(
        en: 'Open the app on',
        it: 'Apri l’app su',
        es: 'Abrir la app en',
        fr: 'Ouvrir l’app sur',
        pt: 'Abrir a app em',
      );

  String get positiveQuote => _pick(
        en: 'Positive quote of the day',
        it: 'Frase positiva del giorno',
        es: 'Frase positiva del día',
        fr: 'Phrase positive du jour',
        pt: 'Frase positiva do dia',
      );

  String get positiveQuoteDescription => _pick(
        en: 'Show the quote in the day header.',
        it: 'Mostra la frase nella testata della giornata.',
        es: 'Muestra la frase en la cabecera del día.',
        fr: 'Affiche la phrase dans l’en-tête de la journée.',
        pt: 'Mostra a frase no cabeçalho do dia.',
      );


  String get calendar => _pick(en: 'Calendar', it: 'Calendario', es: 'Calendario', fr: 'Calendrier', pt: 'Calendário');
  String get noCommitments => _pick(en: 'No commitments.', it: 'Nessun impegno.', es: 'Sin compromisos.', fr: 'Aucun engagement.', pt: 'Sem compromissos.');
  String get capture => _pick(en: 'Capture', it: 'Cattura', es: 'Capturar', fr: 'Capturer', pt: 'Capturar');
  String get myDay => _pick(en: 'My day', it: 'La mia giornata', es: 'Mi día', fr: 'Ma journée', pt: 'O meu dia');
  String get hourlyTimeline => _pick(en: 'Hourly timeline', it: 'Timeline oraria', es: 'Cronología horaria', fr: 'Chronologie horaire', pt: 'Linha temporal horária');
  String noPrivateTimedAppointments(int count) => count == 0
      ? _pick(en: 'No private appointments with a time', it: 'Nessun appuntamento privato con orario', es: 'Ninguna cita privada con hora', fr: 'Aucun rendez-vous privé avec horaire', pt: 'Nenhum compromisso privado com hora')
      : _pick(en: '$count private timed appointments', it: '$count appuntamenti privati con orario', es: '$count citas privadas con hora', fr: '$count rendez-vous privés avec horaire', pt: '$count compromissos privados com hora');
  String get diary => _pick(en: 'Diary', it: 'Diario', es: 'Diario', fr: 'Journal', pt: 'Diário');
  String get dayContext => _pick(en: 'Day context', it: 'Contesto della giornata', es: 'Contexto del día', fr: 'Contexte de la journée', pt: 'Contexto do dia');
  String get openDay => _pick(en: 'Open day', it: 'Apri giornata', es: 'Abrir día', fr: 'Ouvrir la journée', pt: 'Abrir dia');
  String get journalStarted => _pick(en: 'Diary already started', it: 'Diario già iniziato', es: 'Diario ya iniciado', fr: 'Journal déjà commencé', pt: 'Diário já iniciado');
  String get journalEmpty => _pick(en: 'Diary still empty', it: 'Diario ancora vuoto', es: 'Diario todavía vacío', fr: 'Journal encore vide', pt: 'Diário ainda vazio');
  String get freeDayDiaryHint => _pick(en: 'Free day: you can still use it as a diary page.', it: 'Giornata libera: puoi comunque usarla come pagina di diario.', es: 'Día libre: puedes usarlo igualmente como página de diario.', fr: 'Journée libre : tu peux quand même l’utiliser comme page de journal.', pt: 'Dia livre: podes usá-lo na mesma como página de diário.');
  String get onThisDay => _pick(en: 'On this day', it: 'In questo giorno', es: 'Tal día como hoy', fr: 'Ce jour-là', pt: 'Neste dia');
  String get memories => _pick(en: 'Memories', it: 'Ricordi', es: 'Recuerdos', fr: 'Souvenirs', pt: 'Memórias');

  String get addPhoto => _pick(en: 'Add a photo', it: 'Aggiungi una foto', es: 'Añadir una foto', fr: 'Ajouter une photo', pt: 'Adicionar uma foto');
  String get photoStoredAsDiaryMoment => _pick(en: 'The photo is saved as a normal diary moment.', it: 'La foto viene salvata come normale momento del diario.', es: 'La foto se guarda como un momento normal del diario.', fr: 'La photo est enregistrée comme un moment normal du journal.', pt: 'A foto é guardada como um momento normal do diário.');
  String get takePhoto => _pick(en: 'Take a photo', it: 'Scatta una foto', es: 'Hacer una foto', fr: 'Prendre une photo', pt: 'Tirar uma foto');
  String get choosePhoto => _pick(en: 'Choose a photo', it: 'Scegli una foto', es: 'Elegir una foto', fr: 'Choisir une photo', pt: 'Escolher uma foto');
  String get chooseGallery => _pick(en: 'Choose from gallery', it: 'Scegli dalla galleria', es: 'Elegir de la galería', fr: 'Choisir dans la galerie', pt: 'Escolher da galeria');
  String get quickNote => _pick(en: 'Quick note', it: 'Nota rapida', es: 'Nota rápida', fr: 'Note rapide', pt: 'Nota rápida');
  String get writeQuickly => _pick(en: 'Write something quickly...', it: 'Scrivi al volo...', es: 'Escribe algo rápido...', fr: 'Écris rapidement...', pt: 'Escreve rapidamente...');
  String get cancel => _pick(en: 'Cancel', it: 'Annulla', es: 'Cancelar', fr: 'Annuler', pt: 'Cancelar');
  String get save => _pick(en: 'Save', it: 'Salva', es: 'Guardar', fr: 'Enregistrer', pt: 'Guardar');
  String dayWord(DateTime day) => AgendaStore.sameDay(day, DateTime.now())
      ? _pick(en: 'today', it: 'oggi', es: 'hoy', fr: "aujourd’hui", pt: 'hoje')
      : DateFormat('d MMMM', languageCode).format(day);
  String get captureInboxDescription => _pick(en: 'Write quickly or save a moment in the day.', it: 'Scrivi al volo oppure salva un momento nella giornata.', es: 'Escribe rápido o guarda un momento en el día.', fr: 'Écris rapidement ou enregistre un moment dans la journée.', pt: 'Escreve rapidamente ou guarda um momento no dia.');
  String get captureDayDescription => _pick(en: 'Text, voice and photos enter the same day flow.', it: 'Testo, voce e foto entrano nello stesso flusso della giornata.', es: 'Texto, voz y fotos entran en el mismo flujo del día.', fr: 'Texte, voix et photos rejoignent le même flux de la journée.', pt: 'Texto, voz e fotos entram no mesmo fluxo do dia.');
  String get writeMoment => _pick(en: 'Write a moment', it: 'Scrivi un momento', es: 'Escribir un momento', fr: 'Écrire un moment', pt: 'Escrever um momento');
  String addDiaryNote(String day) => _pick(en: 'Add a note to the diary for $day.', it: 'Aggiungi una nota al diario di $day.', es: 'Añade una nota al diario de $day.', fr: 'Ajoute une note au journal de $day.', pt: 'Adiciona uma nota ao diário de $day.');
  String get voiceNote => _pick(en: 'Voice note', it: 'Nota vocale', es: 'Nota de voz', fr: 'Note vocale', pt: 'Nota de voz');
  String recordDiaryAudio(String day) => _pick(en: 'Record audio in the diary for $day.', it: 'Registra un audio nel diario di $day.', es: 'Graba un audio en el diario de $day.', fr: 'Enregistre un audio dans le journal de $day.', pt: 'Grava um áudio no diário de $day.');
  String get photo => _pick(en: 'Photo', it: 'Foto', es: 'Foto', fr: 'Photo', pt: 'Foto');
  String savePhotoMoment(String day) => _pick(en: 'Save a photo as a moment for $day.', it: 'Salva una foto come momento di $day.', es: 'Guarda una foto como momento de $day.', fr: 'Enregistre une photo comme moment de $day.', pt: 'Guarda uma foto como momento de $day.');
  String get quickInboxNote => _pick(en: 'Quick note in Inbox', it: 'Nota rapida in Inbox', es: 'Nota rápida en Inbox', fr: 'Note rapide dans Inbox', pt: 'Nota rápida na Inbox');
  String get organizeLater => _pick(en: 'Organize it later.', it: 'Da organizzare in un secondo momento.', es: 'Para organizar más tarde.', fr: 'À organiser plus tard.', pt: 'Para organizar mais tarde.');
  String get task => _pick(en: 'Task', it: 'Attività', es: 'Tarea', fr: 'Tâche', pt: 'Tarefa');
  String get appointment => _pick(en: 'Appointment', it: 'Appuntamento', es: 'Cita', fr: 'Rendez-vous', pt: 'Compromisso');
  String get birthday => _pick(en: 'Birthday', it: 'Compleanno', es: 'Cumpleaños', fr: 'Anniversaire', pt: 'Aniversário');
  String get importantPerson => _pick(en: 'Important person', it: 'Persona importante', es: 'Persona importante', fr: 'Personne importante', pt: 'Pessoa importante');
  String get close => _pick(en: 'Close', it: 'Chiudi', es: 'Cerrar', fr: 'Fermer', pt: 'Fechar');
  String momentSaved(String day) => _pick(en: 'Moment saved in the diary for $day.', it: 'Momento salvato nel diario di $day.', es: 'Momento guardado en el diario de $day.', fr: 'Moment enregistré dans le journal de $day.', pt: 'Momento guardado no diário de $day.');
  String voiceSaved(String day) => _pick(en: 'Voice note saved in the diary for $day.', it: 'Nota vocale salvata nel diario di $day.', es: 'Nota de voz guardada en el diario de $day.', fr: 'Note vocale enregistrée dans le journal de $day.', pt: 'Nota de voz guardada no diário de $day.');
  String photoSaved(String day) => _pick(en: 'Photo saved in the diary for $day.', it: 'Foto salvata nel diario di $day.', es: 'Foto guardada en el diario de $day.', fr: 'Photo enregistrée dans le journal de $day.', pt: 'Foto guardada no diário de $day.');
  String get inboxSaved => _pick(en: 'Note saved in Inbox.', it: 'Nota salvata in Inbox.', es: 'Nota guardada en Inbox.', fr: 'Note enregistrée dans Inbox.', pt: 'Nota guardada na Inbox.');

  String get inbox => 'Inbox';
  String get inboxEmpty => _pick(en: 'Ideas and notes captured on the fly will end up here.', it: 'Qui finiranno le idee e le note catturate al volo.', es: 'Aquí aparecerán las ideas y notas capturadas al vuelo.', fr: 'Les idées et notes capturées rapidement apparaîtront ici.', pt: 'As ideias e notas capturadas rapidamente aparecerão aqui.');
  String get noteConvertedTask => _pick(en: 'Note converted to a task.', it: 'Nota trasformata in attività.', es: 'Nota convertida en tarea.', fr: 'Note convertie en tâche.', pt: 'Nota convertida em tarefa.');
  String get pin => _pick(en: 'Pin', it: 'Fissa', es: 'Fijar', fr: 'Épingler', pt: 'Fixar');
  String get unpin => _pick(en: 'Unpin', it: 'Togli dai fissati', es: 'Desfijar', fr: 'Désépingler', pt: 'Desafixar');
  String get tags => 'Tag';
  String get archiveAction => _pick(en: 'Archive', it: 'Archivia', es: 'Archivar', fr: 'Archiver', pt: 'Arquivar');
  String get copyForNotes => _pick(en: 'Copy for Notes', it: 'Copia per Notes', es: 'Copiar para Notes', fr: 'Copier pour Notes', pt: 'Copiar para Notes');
  String get convertToTask => _pick(en: 'Convert to task', it: 'Trasforma in attività', es: 'Convertir en tarea', fr: 'Convertir en tâche', pt: 'Converter em tarefa');
  String get delete => _pick(en: 'Delete', it: 'Elimina', es: 'Eliminar', fr: 'Supprimer', pt: 'Eliminar');

  String get lifeArchive => _pick(en: 'Life archive', it: 'Archivio della vita', es: 'Archivo de vida', fr: 'Archives de vie', pt: 'Arquivo da vida');
  String get trash => _pick(en: 'Trash', it: 'Cestino', es: 'Papelera', fr: 'Corbeille', pt: 'Lixo');
  String get storyOnePlace => _pick(en: 'Your story, all in one place', it: 'La tua storia, in un unico posto', es: 'Tu historia, en un solo lugar', fr: 'Ton histoire, au même endroit', pt: 'A tua história, num só lugar');
  String get storyArchiveEmptyDescription => _pick(en: 'Find diary, agenda, workouts and preserved content here without duplicating your data.', it: 'Qui ritrovi diario, agenda, allenamenti e contenuti conservati senza creare copie dei tuoi dati.', es: 'Aquí encuentras diario, agenda, entrenamientos y contenido conservado sin duplicar tus datos.', fr: 'Retrouve ici journal, agenda, entraînements et contenu conservé sans dupliquer tes données.', pt: 'Aqui encontras diário, agenda, treinos e conteúdo guardado sem duplicar os teus dados.');
  String momentsYears(int moments, int years) => _pick(
        en: '$moments moments · $years ${years == 1 ? 'year' : 'years'}',
        it: '$moments momenti · $years ${years == 1 ? 'anno' : 'anni'}',
        es: '$moments momentos · $years ${years == 1 ? 'año' : 'años'}',
        fr: '$moments moments · $years ${years == 1 ? 'an' : 'ans'}',
        pt: '$moments momentos · $years ${years == 1 ? 'ano' : 'anos'}',
      );
  String get all => _pick(en: 'All', it: 'Tutto', es: 'Todo', fr: 'Tout', pt: 'Tudo');
  String get searchWholeStory => _pick(en: 'Search your whole story...', it: 'Cerca in tutta la tua storia...', es: 'Busca en toda tu historia...', fr: 'Recherche dans toute ton histoire...', pt: 'Pesquisa em toda a tua história...');
  String get clearSearch => _pick(en: 'Clear search', it: 'Cancella ricerca', es: 'Borrar búsqueda', fr: 'Effacer la recherche', pt: 'Limpar pesquisa');
  String get archiveStillEmpty => _pick(en: 'The archive is still empty.', it: 'L’archivio è ancora vuoto.', es: 'El archivo todavía está vacío.', fr: 'Les archives sont encore vides.', pt: 'O arquivo ainda está vazio.');
  String get noMomentMatches => _pick(en: 'No moment matches this search.', it: 'Nessun momento corrisponde a questa ricerca.', es: 'Ningún momento coincide con esta búsqueda.', fr: 'Aucun moment ne correspond à cette recherche.', pt: 'Nenhum momento corresponde a esta pesquisa.');
  String get exploreByMonth => _pick(en: 'Explore by month', it: 'Esplora per mese', es: 'Explorar por mes', fr: 'Explorer par mois', pt: 'Explorar por mês');
  String monthsWithContent(int count) => _pick(en: '$count months with content', it: '$count mesi con contenuti', es: '$count meses con contenido', fr: '$count mois avec du contenu', pt: '$count meses com conteúdo');
  String commitmentsCount(int count) => _pick(en: '$count commitments', it: '$count impegni', es: '$count compromisos', fr: '$count engagements', pt: '$count compromissos');
  String journalDaysCount(int count) => _pick(en: '$count diary days', it: '$count giorni raccontati', es: '$count días de diario', fr: '$count jours racontés', pt: '$count dias de diário');
  String workoutsCount(int count) => _pick(en: '$count workouts', it: '$count allenamenti', es: '$count entrenamientos', fr: '$count entraînements', pt: '$count treinos');
  String goalsCount(int count) => _pick(en: '$count goals', it: '$count obiettivi', es: '$count objetivos', fr: '$count objectifs', pt: '$count objetivos');
  String get restoreToDiary => _pick(en: 'Restore to diary', it: 'Ripristina nel diario', es: 'Restaurar en el diario', fr: 'Restaurer dans le journal', pt: 'Restaurar no diário');
  String get restoreToInbox => _pick(en: 'Restore to Inbox', it: 'Ripristina in Inbox', es: 'Restaurar en Inbox', fr: 'Restaurer dans Inbox', pt: 'Restaurar na Inbox');
  String archiveKind(LifeArchiveKind kind) => switch (kind) {
        LifeArchiveKind.diary => diary,
        LifeArchiveKind.agenda => myAgenda,
        LifeArchiveKind.workout => _pick(en: 'Workouts', it: 'Allenamenti', es: 'Entrenamientos', fr: 'Entraînements', pt: 'Treinos'),
        LifeArchiveKind.inbox => inbox,
      };



  String get noPeopleSaved => _pick(en: 'No people saved', it: 'Nessuna persona salvata', es: 'No hay personas guardadas', fr: 'Aucune personne enregistrée', pt: 'Nenhuma pessoa guardada');
  String get addPersonBeforeLink => _pick(en: 'Add a person in “Important people” first, then you can link them to memories.', it: 'Aggiungi prima una persona da “Persone importanti”, poi potrai collegarla ai ricordi.', es: 'Añade primero una persona en “Personas importantes” y luego podrás vincularla a los recuerdos.', fr: 'Ajoute d’abord une personne dans « Personnes importantes », puis tu pourras la lier aux souvenirs.', pt: 'Adiciona primeiro uma pessoa em “Pessoas importantes” e depois poderás ligá-la às memórias.');
  String get peopleInMemory => _pick(en: 'People in this memory', it: 'Persone nel ricordo', es: 'Personas en este recuerdo', fr: 'Personnes dans ce souvenir', pt: 'Pessoas nesta memória');
  String get searchPersonHint => _pick(en: 'Search for a person...', it: 'Cerca una persona...', es: 'Buscar una persona...', fr: 'Rechercher une personne...', pt: 'Pesquisar uma pessoa...');
  String get noPersonFound => _pick(en: 'No people found.', it: 'Nessuna persona trovata.', es: 'No se encontraron personas.', fr: 'Aucune personne trouvée.', pt: 'Nenhuma pessoa encontrada.');
  String get recoverableTrashLink => _pick(en: 'In Trash · recoverable link', it: 'Nel Cestino · collegamento recuperabile', es: 'En la papelera · vínculo recuperable', fr: 'Dans la corbeille · lien récupérable', pt: 'No lixo · ligação recuperável');
  String get newPerson => _pick(en: 'New person', it: 'Nuova persona', es: 'Nueva persona', fr: 'Nouvelle personne', pt: 'Nova pessoa');
  String get editPerson => _pick(en: 'Edit person', it: 'Modifica persona', es: 'Editar persona', fr: 'Modifier la personne', pt: 'Editar pessoa');
  String get relationship => _pick(en: 'Relationship', it: 'Relazione', es: 'Relación', fr: 'Relation', pt: 'Relação');
  String get relationshipHint => _pick(en: 'e.g. friend, sister, colleague...', it: 'Es. amica, sorella, collega...', es: 'p. ej. amiga, hermana, compañera...', fr: 'ex. amie, sœur, collègue...', pt: 'ex. amiga, irmã, colega...');
  String get linkedBirthday => _pick(en: 'Linked birthday', it: 'Compleanno collegato', es: 'Cumpleaños vinculado', fr: 'Anniversaire lié', pt: 'Aniversário associado');
  String get noBirthday => _pick(en: 'No birthday', it: 'Nessun compleanno', es: 'Sin cumpleaños', fr: 'Aucun anniversaire', pt: 'Sem aniversário');
  String get birthdayUnavailable => _pick(en: 'Birthday unavailable', it: 'Compleanno non disponibile', es: 'Cumpleaños no disponible', fr: 'Anniversaire indisponible', pt: 'Aniversário indisponível');
  String get addBirthdaysFromDedicatedScreen => _pick(en: 'You can add birthdays from the dedicated screen.', it: 'Puoi aggiungere i compleanni dalla schermata dedicata.', es: 'Puedes añadir cumpleaños desde la pantalla dedicada.', fr: 'Tu peux ajouter les anniversaires depuis l’écran dédié.', pt: 'Podes adicionar aniversários no ecrã dedicado.');
  String get anniversaryImportantDate => _pick(en: 'Anniversary / important date', it: 'Anniversario / data importante', es: 'Aniversario / fecha importante', fr: 'Anniversaire / date importante', pt: 'Aniversário / data importante');
  String get noDate => _pick(en: 'No date', it: 'Nessuna data', es: 'Sin fecha', fr: 'Aucune date', pt: 'Sem data');
  String get removeDate => _pick(en: 'Remove date', it: 'Rimuovi data', es: 'Quitar fecha', fr: 'Supprimer la date', pt: 'Remover data');
  String get personalNote => _pick(en: 'Personal note', it: 'Nota personale', es: 'Nota personal', fr: 'Note personnelle', pt: 'Nota pessoal');
  String get personalNoteHint => _pick(en: 'Details you want to remember...', it: 'Dettagli che vuoi ricordare...', es: 'Detalles que quieres recordar...', fr: 'Détails que tu veux retenir...', pt: 'Detalhes que queres recordar...');
  String get showFirstInList => _pick(en: 'Show this person first in the list.', it: 'Mostrala per prima nell’elenco.', es: 'Muéstrala primero en la lista.', fr: 'Afficher cette personne en premier dans la liste.', pt: 'Mostrar esta pessoa primeiro na lista.');
  String personTrashDescription(String name) => _pick(en: '$name will be removed from the list, but memory links will remain ready for a possible restore.', it: '$name verrà rimossa dall’elenco, ma i collegamenti ai ricordi resteranno pronti per un eventuale ripristino.', es: '$name se eliminará de la lista, pero los vínculos a los recuerdos quedarán listos para una posible restauración.', fr: '$name sera retirée de la liste, mais les liens vers les souvenirs resteront disponibles pour une éventuelle restauration.', pt: '$name será removida da lista, mas as ligações às memórias ficarão prontas para um possível restauro.');
  String memoriesCount(int count) => _pick(en: '$count ${count == 1 ? 'memory' : 'memories'}', it: '$count ${count == 1 ? 'ricordo' : 'ricordi'}', es: '$count ${count == 1 ? 'recuerdo' : 'recuerdos'}', fr: '$count ${count == 1 ? 'souvenir' : 'souvenirs'}', pt: '$count ${count == 1 ? 'memória' : 'memórias'}');
  String get nextAnniversary => _pick(en: 'Next anniversary', it: 'Prossimo anniversario', es: 'Próximo aniversario', fr: 'Prochain anniversaire', pt: 'Próximo aniversário');
  String get yourTimeline => _pick(en: 'Your timeline', it: 'La vostra timeline', es: 'Vuestra línea temporal', fr: 'Votre chronologie', pt: 'A vossa linha temporal');
  String get firstLinkedMemory => _pick(en: 'First linked memory', it: 'Primo ricordo collegato', es: 'Primer recuerdo vinculado', fr: 'Premier souvenir lié', pt: 'Primeira memória associada');
  String get latestMemory => _pick(en: 'Latest memory', it: 'Ricordo più recente', es: 'Recuerdo más reciente', fr: 'Souvenir le plus récent', pt: 'Memória mais recente');
  String get diaryMemory => _pick(en: 'Diary memory', it: 'Ricordo del diario', es: 'Recuerdo del diario', fr: 'Souvenir du journal', pt: 'Memória do diário');
  String get seeLinkedMemories => _pick(en: 'See linked memories', it: 'Vedi ricordi collegati', es: 'Ver recuerdos vinculados', fr: 'Voir les souvenirs liés', pt: 'Ver memórias associadas');
  String get importantPeople => _pick(en: 'Important people', it: 'Persone importanti', es: 'Personas importantes', fr: 'Personnes importantes', pt: 'Pessoas importantes');
  String get person => _pick(en: 'Person', it: 'Persona', es: 'Persona', fr: 'Personne', pt: 'Pessoa');
  String get peopleThatMatter => _pick(en: 'The people who matter', it: 'Le persone che contano', es: 'Las personas que importan', fr: 'Les personnes qui comptent', pt: 'As pessoas que importam');
  String get importantPeopleDescription => _pick(en: 'Save only the name, relationship, a note and an optional birthday. Then link these people to diary memories.', it: 'Salva solo nome, relazione, una nota e l’eventuale compleanno. Poi collega queste persone ai ricordi del diario.', es: 'Guarda solo el nombre, la relación, una nota y, si quieres, el cumpleaños. Después vincula estas personas a los recuerdos del diario.', fr: 'Enregistre seulement le nom, la relation, une note et éventuellement l’anniversaire. Puis lie ces personnes aux souvenirs du journal.', pt: 'Guarda apenas o nome, a relação, uma nota e, se quiseres, o aniversário. Depois liga estas pessoas às memórias do diário.');
  String get addPerson => _pick(en: 'Add person', it: 'Aggiungi persona', es: 'Añadir persona', fr: 'Ajouter une personne', pt: 'Adicionar pessoa');
  String birthdayDetail(String value) => _pick(en: 'Birthday: $value', it: 'Compleanno: $value', es: 'Cumpleaños: $value', fr: 'Anniversaire : $value', pt: 'Aniversário: $value');
  String anniversaryDetail(String value) => _pick(en: 'Anniversary: $value', it: 'Anniversario: $value', es: 'Aniversario: $value', fr: 'Anniversaire : $value', pt: 'Aniversário: $value');
  String linkedMemoriesCount(int count) => _pick(en: '$count linked ${count == 1 ? 'memory' : 'memories'}', it: '$count ${count == 1 ? 'ricordo collegato' : 'ricordi collegati'}', es: '$count ${count == 1 ? 'recuerdo vinculado' : 'recuerdos vinculados'}', fr: '$count ${count == 1 ? 'souvenir lié' : 'souvenirs liés'}', pt: '$count ${count == 1 ? 'memória associada' : 'memórias associadas'}');
  String lastMemoryDetail(String value) => _pick(en: 'Last: $value', it: 'Ultimo: $value', es: 'Último: $value', fr: 'Dernier : $value', pt: 'Última: $value');
  String sinceDate(String value) => _pick(en: 'Since $value', it: 'Dal $value', es: 'Desde $value', fr: 'Depuis $value', pt: 'Desde $value');

  String recoverableBirthdayLabel(String name) => _pick(en: '$name · in Trash', it: '$name · nel Cestino', es: '$name · en la papelera', fr: '$name · dans la corbeille', pt: '$name · no lixo');
  String trashEntrySubtitle(String kind, String deletedAt) => _pick(en: '$kind · deleted $deletedAt', it: '$kind · eliminato $deletedAt', es: '$kind · eliminado $deletedAt', fr: '$kind · supprimé $deletedAt', pt: '$kind · eliminado $deletedAt');

  String get workout => _pick(en: 'Workout', it: 'Allenamento', es: 'Entrenamiento', fr: 'Entraînement', pt: 'Treino');
  String get record => _pick(en: 'Record', it: 'Registra', es: 'Registrar', fr: 'Enregistrer', pt: 'Registar');
  String get newWorkoutPlan => _pick(en: 'New plan', it: 'Nuova scheda', es: 'Nuevo plan', fr: 'Nouveau programme', pt: 'Novo plano');
  String get workoutSessions => _pick(en: 'Sessions', it: 'Sessioni', es: 'Sesiones', fr: 'Séances', pt: 'Sessões');
  String get workoutPlans => _pick(en: 'Plans', it: 'Schede', es: 'Planes', fr: 'Programmes', pt: 'Planos');
  String get noWorkouts => _pick(en: 'No workouts recorded', it: 'Nessun allenamento registrato', es: 'No hay entrenamientos registrados', fr: 'Aucun entraînement enregistré', pt: 'Nenhum treino registado');
  String get noWorkoutsDescription => _pick(en: 'Running, cycling, gym, swimming, hiking or any other activity: everything stays in the same history.', it: 'Corsa, bici, palestra, nuoto, trekking o qualsiasi altra attività: tutto resta nello stesso storico.', es: 'Carrera, bici, gimnasio, natación, senderismo o cualquier otra actividad: todo queda en el mismo historial.', fr: 'Course, vélo, salle, natation, randonnée ou toute autre activité : tout reste dans le même historique.', pt: 'Corrida, bicicleta, ginásio, natação, caminhada ou qualquer outra atividade: tudo fica no mesmo histórico.');
  String get workoutMovedToTrash => _pick(en: 'Workout moved to Trash.', it: 'Allenamento spostato nel Cestino.', es: 'Entrenamiento movido a la papelera.', fr: 'Entraînement déplacé vers la corbeille.', pt: 'Treino movido para o lixo.');
  String get noWorkoutPlans => _pick(en: 'No plans saved', it: 'Nessuna scheda salvata', es: 'No hay planes guardados', fr: 'Aucun programme enregistré', pt: 'Nenhum plano guardado');
  String get noWorkoutPlansDescription => _pick(en: 'Create a plan manually or import a TXT/CSV file. You can then record a session starting from that plan.', it: 'Crea una scheda manualmente oppure importa un file TXT/CSV. Potrai poi registrare una sessione partendo da quella scheda.', es: 'Crea un plan manualmente o importa un archivo TXT/CSV. Después podrás registrar una sesión a partir de ese plan.', fr: 'Crée un programme manuellement ou importe un fichier TXT/CSV. Tu pourras ensuite enregistrer une séance à partir de ce programme.', pt: 'Cria um plano manualmente ou importa um ficheiro TXT/CSV. Depois poderás registar uma sessão a partir desse plano.');
  String workoutPlanEntries(int count) => _pick(en: '$count entries', it: '$count voci', es: '$count elementos', fr: '$count éléments', pt: '$count itens');
  String get workoutPlanMovedToTrash => _pick(en: 'Plan moved to Trash.', it: 'Scheda spostata nel Cestino.', es: 'Plan movido a la papelera.', fr: 'Programme déplacé vers la corbeille.', pt: 'Plano movido para o lixo.');
  String moreEntries(int count) => _pick(en: '+ $count more entries', it: '+ $count altre voci', es: '+ $count elementos más', fr: '+ $count éléments supplémentaires', pt: '+ $count itens adicionais');
  String get recordFromPlan => _pick(en: 'Record from this plan', it: 'Registra da questa scheda', es: 'Registrar desde este plan', fr: 'Enregistrer depuis ce programme', pt: 'Registar a partir deste plano');
  String get sessionsMetric => _pick(en: 'sessions', it: 'sessioni', es: 'sesiones', fr: 'séances', pt: 'sessões');
  String get timeMetric => _pick(en: 'time', it: 'tempo', es: 'tiempo', fr: 'temps', pt: 'tempo');
  String workoutPlanPrefix(String name) => _pick(en: 'Plan: $name', it: 'Scheda: $name', es: 'Plan: $name', fr: 'Programme : $name', pt: 'Plano: $name');
  String get invalidWorkoutDuration => _pick(en: 'Invalid duration. Use MM:SS, HH:MM:SS or minutes.', it: 'Durata non valida. Usa MM:SS, HH:MM:SS oppure i minuti.', es: 'Duración no válida. Usa MM:SS, HH:MM:SS o minutos.', fr: 'Durée invalide. Utilise MM:SS, HH:MM:SS ou des minutes.', pt: 'Duração inválida. Usa MM:SS, HH:MM:SS ou minutos.');
  String get invalidWorkoutDistance => _pick(en: 'Invalid distance.', it: 'Distanza non valida.', es: 'Distancia no válida.', fr: 'Distance invalide.', pt: 'Distância inválida.');
  String get invalidWorkoutElevation => _pick(en: 'Invalid elevation gain.', it: 'Dislivello non valido.', es: 'Desnivel no válido.', fr: 'Dénivelé invalide.', pt: 'Desnível inválido.');
  String get recordWorkout => _pick(en: 'Record workout', it: 'Registra allenamento', es: 'Registrar entrenamiento', fr: 'Enregistrer un entraînement', pt: 'Registar treino');
  String get editWorkout => _pick(en: 'Edit workout', it: 'Modifica allenamento', es: 'Editar entrenamiento', fr: 'Modifier l’entraînement', pt: 'Editar treino');
  String fromWorkoutPlan(String name) => _pick(en: 'From plan: $name', it: 'Da scheda: $name', es: 'Desde el plan: $name', fr: 'Depuis le programme : $name', pt: 'Do plano: $name');
  String get sport => 'Sport';
  String get optionalTitle => _pick(en: 'Title (optional)', it: 'Titolo (opzionale)', es: 'Título (opcional)', fr: 'Titre (facultatif)', pt: 'Título (opcional)');
  String get workoutRunningHint => _pick(en: 'e.g. Hilly long run', it: 'es. Lungo collinare', es: 'p. ej. Tirada larga con cuestas', fr: 'ex. Sortie longue vallonnée', pt: 'ex. Corrida longa com subidas');
  String get workoutCyclingHint => _pick(en: 'e.g. Bike ride', it: 'es. Giro in bici', es: 'p. ej. Vuelta en bici', fr: 'ex. Sortie à vélo', pt: 'ex. Volta de bicicleta');
  String get workoutGenericHint => _pick(en: 'e.g. Evening session', it: 'es. Sessione serale', es: 'p. ej. Sesión de tarde', fr: 'ex. Séance du soir', pt: 'ex. Sessão ao fim do dia');
  String get duration => _pick(en: 'Duration', it: 'Tempo', es: 'Duración', fr: 'Durée', pt: 'Duração');
  String get distanceKm => _pick(en: 'Distance km', it: 'Distanza km', es: 'Distancia km', fr: 'Distance km', pt: 'Distância km');
  String get elevationGain => _pick(en: 'Elevation +m', it: 'Dislivello +m', es: 'Desnivel +m', fr: 'Dénivelé +m', pt: 'Desnível +m');
  String get optional => _pick(en: 'optional', it: 'opzionale', es: 'opcional', fr: 'facultatif', pt: 'opcional');
  String get intensity => _pick(en: 'Intensity', it: 'Intensità', es: 'Intensidad', fr: 'Intensité', pt: 'Intensidade');
  String get notes => _pick(en: 'Notes', it: 'Note', es: 'Notas', fr: 'Notes', pt: 'Notas');
  String get workoutNotesHint => _pick(en: 'Feelings, route, extra exercises, details...', it: 'Sensazioni, percorso, esercizi extra, dettagli...', es: 'Sensaciones, recorrido, ejercicios extra, detalles...', fr: 'Sensations, parcours, exercices supplémentaires, détails...', pt: 'Sensações, percurso, exercícios extra, detalhes...');
  String get planUsed => _pick(en: 'Plan used', it: 'Scheda usata', es: 'Plan utilizado', fr: 'Programme utilisé', pt: 'Plano utilizado');
  String get saveWorkout => _pick(en: 'Save workout', it: 'Salva allenamento', es: 'Guardar entrenamiento', fr: 'Enregistrer l’entraînement', pt: 'Guardar treino');
  String get cannotReadFile => _pick(en: 'I can’t read this file.', it: 'Non riesco a leggere questo file.', es: 'No puedo leer este archivo.', fr: 'Impossible de lire ce fichier.', pt: 'Não consigo ler este ficheiro.');
  String get workoutPlanFileTooLarge => _pick(en: 'The plan exceeds the 1 MB limit.', it: 'La scheda supera il limite di 1 MB.', es: 'El plan supera el límite de 1 MB.', fr: 'Le programme dépasse la limite de 1 Mo.', pt: 'O plano ultrapassa o limite de 1 MB.');
  String get fileContainsNoText => _pick(en: 'The file contains no text.', it: 'Il file non contiene testo.', es: 'El archivo no contiene texto.', fr: 'Le fichier ne contient aucun texte.', pt: 'O ficheiro não contém texto.');
  String get givePlanName => _pick(en: 'Give the plan a name.', it: 'Dai un nome alla scheda.', es: 'Ponle un nombre al plan.', fr: 'Donne un nom au programme.', pt: 'Dá um nome ao plano.');
  String get editWorkoutPlan => _pick(en: 'Edit plan', it: 'Modifica scheda', es: 'Editar plan', fr: 'Modifier le programme', pt: 'Editar plano');
  String get workoutPlanName => _pick(en: 'Plan name', it: 'Nome scheda', es: 'Nombre del plan', fr: 'Nom du programme', pt: 'Nome do plano');
  String get workoutPlanNameHint => _pick(en: 'e.g. Strength A, 10 km preparation...', it: 'es. Forza A, Preparazione 10 km...', es: 'p. ej. Fuerza A, Preparación 10 km...', fr: 'ex. Force A, Préparation 10 km...', pt: 'ex. Força A, Preparação 10 km...');
  String get generalNotes => _pick(en: 'General notes', it: 'Note generali', es: 'Notas generales', fr: 'Notes générales', pt: 'Notas gerais');
  String get planExercises => _pick(en: 'Plan / exercises', it: 'Scheda / esercizi', es: 'Plan / ejercicios', fr: 'Programme / exercices', pt: 'Plano / exercícios');
  String get planExercisesHint => _pick(en: 'One exercise or block per line\nBench press 4x8 @ 60kg\nSquat 4x6 @ 80kg\nEasy run 30 min', it: 'Un esercizio o blocco per riga\nPanca 4x8 @ 60kg\nSquat 4x6 @ 80kg\nCorsa facile 30 min', es: 'Un ejercicio o bloque por línea\nPress banca 4x8 @ 60kg\nSentadilla 4x6 @ 80kg\nCarrera suave 30 min', fr: 'Un exercice ou bloc par ligne\nDéveloppé couché 4x8 @ 60kg\nSquat 4x6 @ 80kg\nCourse facile 30 min', pt: 'Um exercício ou bloco por linha\nSupino 4x8 @ 60kg\nAgachamento 4x6 @ 80kg\nCorrida fácil 30 min');
  String get importWorkoutPlan => _pick(en: 'Import TXT / CSV plan', it: 'Importa scheda TXT / CSV', es: 'Importar plan TXT / CSV', fr: 'Importer un programme TXT / CSV', pt: 'Importar plano TXT / CSV');
  String get freeTextWorkoutPlanHelp => _pick(en: 'You can also use free text: anything that does not match the sets × reps format is still saved as a plan entry.', it: 'Puoi usare anche testo libero: ciò che non segue il formato serie × ripetizioni resta comunque salvato come voce della scheda.', es: 'También puedes usar texto libre: lo que no siga el formato series × repeticiones se guardará igualmente como elemento del plan.', fr: 'Tu peux aussi utiliser du texte libre : ce qui ne suit pas le format séries × répétitions est tout de même enregistré comme élément du programme.', pt: 'Também podes usar texto livre: o que não seguir o formato séries × repetições será guardado como item do plano.');
  String get saveWorkoutPlan => _pick(en: 'Save plan', it: 'Salva scheda', es: 'Guardar plan', fr: 'Enregistrer le programme', pt: 'Guardar plano');
  String workoutSets(int count) => _pick(en: '$count sets', it: '$count serie', es: '$count series', fr: '$count séries', pt: '$count séries');
  String workoutSportLabel(WorkoutSport sport) => switch (sport) {
        WorkoutSport.gym => _pick(en: 'Gym', it: 'Palestra', es: 'Gimnasio', fr: 'Salle', pt: 'Ginásio'),
        WorkoutSport.running => _pick(en: 'Running', it: 'Corsa', es: 'Carrera', fr: 'Course', pt: 'Corrida'),
        WorkoutSport.cycling => _pick(en: 'Cycling', it: 'Bici', es: 'Bici', fr: 'Vélo', pt: 'Bicicleta'),
        WorkoutSport.swimming => _pick(en: 'Swimming', it: 'Nuoto', es: 'Natación', fr: 'Natation', pt: 'Natação'),
        WorkoutSport.walking => _pick(en: 'Walking', it: 'Camminata', es: 'Caminata', fr: 'Marche', pt: 'Caminhada'),
        WorkoutSport.hiking => _pick(en: 'Hiking', it: 'Trekking', es: 'Senderismo', fr: 'Randonnée', pt: 'Caminhada'),
        WorkoutSport.yogaMobility => _pick(en: 'Yoga / Mobility', it: 'Yoga / Mobilità', es: 'Yoga / Movilidad', fr: 'Yoga / Mobilité', pt: 'Yoga / Mobilidade'),
        WorkoutSport.teamSport => _pick(en: 'Team sport', it: 'Sport di squadra', es: 'Deporte de equipo', fr: 'Sport collectif', pt: 'Desporto de equipa'),
        WorkoutSport.other => _pick(en: 'Other', it: 'Altro', es: 'Otro', fr: 'Autre', pt: 'Outro'),
      };

  String get shoppingList => _pick(en: 'Shopping list', it: 'Lista della spesa', es: 'Lista de la compra', fr: 'Liste de courses', pt: 'Lista de compras');
  String sharedShoppingFor(String name) => _pick(en: 'Shopping · $name', it: 'Spesa · $name', es: 'Compra · $name', fr: 'Courses · $name', pt: 'Compras · $name');
  String get sharedShopping => _pick(en: 'Shared shopping · Noi ♡', it: 'Spesa condivisa · Noi ♡', es: 'Compra compartida · Noi ♡', fr: 'Courses partagées · Noi ♡', pt: 'Compras partilhadas · Noi ♡');
  String get refresh => _pick(en: 'Refresh', it: 'Aggiorna', es: 'Actualizar', fr: 'Actualiser', pt: 'Atualizar');
  String get toBuy => _pick(en: 'To buy', it: 'Da comprare', es: 'Por comprar', fr: 'À acheter', pt: 'Por comprar');
  String get purchased => _pick(en: 'Purchased', it: 'Acquistati', es: 'Comprados', fr: 'Achetés', pt: 'Comprados');
  String get editShoppingItem => _pick(en: 'Edit item', it: 'Modifica articolo', es: 'Editar artículo', fr: 'Modifier l’article', pt: 'Editar item');
  String get item => _pick(en: 'Item', it: 'Articolo', es: 'Artículo', fr: 'Article', pt: 'Item');
  String get optionalQuantity => _pick(en: 'Quantity (optional)', it: 'Quantità (opzionale)', es: 'Cantidad (opcional)', fr: 'Quantité (facultative)', pt: 'Quantidade (opcional)');
  String get optionalQuantityHint => _pick(en: 'e.g. 2, 500 g, 1 pack', it: 'es. 2, 500 g, 1 confezione', es: 'p. ej. 2, 500 g, 1 paquete', fr: 'ex. 2, 500 g, 1 paquet', pt: 'ex. 2, 500 g, 1 embalagem');
  String get category => _pick(en: 'Category', it: 'Categoria', es: 'Categoría', fr: 'Catégorie', pt: 'Categoria');
  String get shoppingItemMovedToTrash => _pick(en: 'Item moved to Trash.', it: 'Articolo spostato nel Cestino.', es: 'Artículo movido a la papelera.', fr: 'Article déplacé vers la corbeille.', pt: 'Item movido para o lixo.');
  String get deleteSharedShoppingQuestion => _pick(en: 'Delete from shared shopping?', it: 'Eliminare dalla spesa condivisa?', es: '¿Eliminar de la compra compartida?', fr: 'Supprimer des courses partagées ?', pt: 'Eliminar das compras partilhadas?');
  String sharedShoppingDeleteDescription(String title) => _pick(en: '“$title” will be deleted for everyone in the Noi ♡ space.', it: '“$title” verrà eliminato per tutte le persone nello spazio Noi ♡.', es: '“$title” se eliminará para todos en el espacio Noi ♡.', fr: '« $title » sera supprimé pour tout le monde dans l’espace Noi ♡.', pt: '“$title” será eliminado para todos no espaço Noi ♡.');
  String get deleteForEveryone => _pick(en: 'Delete for everyone', it: 'Elimina per tutti', es: 'Eliminar para todos', fr: 'Supprimer pour tout le monde', pt: 'Eliminar para todos');
  String get sharedSpaceRequired => _pick(en: 'Create or join a Noi ♡ space first.', it: 'Crea o unisciti prima a uno spazio Noi ♡.', es: 'Crea o únete primero a un espacio Noi ♡.', fr: 'Crée ou rejoins d’abord un espace Noi ♡.', pt: 'Cria ou entra primeiro num espaço Noi ♡.');
  String get sharedShoppingSelectDescription => _pick(en: 'Choose the space: items will be visible and editable by both of you.', it: 'Scegli lo spazio: gli articoli saranno visibili e modificabili da entrambi.', es: 'Elige el espacio: los artículos serán visibles y editables por ambos.', fr: 'Choisis l’espace : les articles seront visibles et modifiables par vous deux.', pt: 'Escolhe o espaço: os itens ficarão visíveis e editáveis por ambos.');
  String get sharedListQuickAdd => _pick(en: 'Shared list in Noi ♡', it: 'Lista condivisa in Noi ♡', es: 'Lista compartida en Noi ♡', fr: 'Liste partagée dans Noi ♡', pt: 'Lista partilhada no Noi ♡');
  String get quickAddShopping => _pick(en: 'Add in one gesture', it: 'Aggiungi con un solo gesto', es: 'Añade con un solo gesto', fr: 'Ajoute en un seul geste', pt: 'Adiciona num só gesto');
  String get whatDoYouNeed => _pick(en: 'What do you need?', it: 'Cosa serve?', es: '¿Qué hace falta?', fr: 'De quoi as-tu besoin ?', pt: 'O que é preciso?');
  String get shoppingItemHint => _pick(en: 'Milk, bread, apples...', it: 'Latte, pane, mele...', es: 'Leche, pan, manzanas...', fr: 'Lait, pain, pommes...', pt: 'Leite, pão, maçãs...');
  String get quantity => _pick(en: 'Quantity', it: 'Quantità', es: 'Cantidad', fr: 'Quantité', pt: 'Quantidade');
  String get quantityHint => _pick(en: '2, 500 g...', it: '2, 500 g...', es: '2, 500 g...', fr: '2, 500 g...', pt: '2, 500 g...');
  String get frequent => _pick(en: 'Frequent', it: 'Frequenti', es: 'Frecuentes', fr: 'Fréquents', pt: 'Frequentes');
  String purchasedTimes(int count) => _pick(en: 'bought $count times', it: 'preso $count volte', es: 'comprado $count veces', fr: 'acheté $count fois', pt: 'comprado $count vezes');
  String get noRecentPurchases => _pick(en: 'No recent purchases', it: 'Nessun acquisto recente', es: 'No hay compras recientes', fr: 'Aucun achat récent', pt: 'Sem compras recentes');
  String get shoppingListEmpty => _pick(en: 'The list is empty', it: 'La lista è vuota', es: 'La lista está vacía', fr: 'La liste est vide', pt: 'A lista está vazia');
  String get purchasedItemsHere => _pick(en: 'Checked items will appear here.', it: 'Gli articoli spuntati compariranno qui.', es: 'Los artículos marcados aparecerán aquí.', fr: 'Les articles cochés apparaîtront ici.', pt: 'Os itens marcados aparecerão aqui.');
  String get sharedShoppingEmpty => _pick(en: 'Add what you need: the list stays synced in Noi ♡.', it: 'Aggiungete quello che serve: la lista resta sincronizzata in Noi ♡.', es: 'Añadid lo que haga falta: la lista se mantiene sincronizada en Noi ♡.', fr: 'Ajoutez ce qu’il faut : la liste reste synchronisée dans Noi ♡.', pt: 'Adicionem o que for preciso: a lista mantém-se sincronizada no Noi ♡.');
  String get privateShoppingEmpty => _pick(en: 'Write what you need above. The category is suggested automatically.', it: 'Scrivi cosa serve qui sopra. La categoria viene suggerita automaticamente.', es: 'Escribe arriba lo que necesitas. La categoría se sugiere automáticamente.', fr: 'Écris ce dont tu as besoin ci-dessus. La catégorie est suggérée automatiquement.', pt: 'Escreve acima o que precisas. A categoria é sugerida automaticamente.');
  String shoppingCategoryLabel(ShoppingCategory category) => switch (category) {
        ShoppingCategory.produce => _pick(en: 'Fruit & vegetables', it: 'Frutta e verdura', es: 'Fruta y verdura', fr: 'Fruits et légumes', pt: 'Fruta e legumes'),
        ShoppingCategory.dairy => _pick(en: 'Dairy', it: 'Latticini', es: 'Lácteos', fr: 'Produits laitiers', pt: 'Laticínios'),
        ShoppingCategory.bakery => _pick(en: 'Bakery', it: 'Pane e forno', es: 'Panadería', fr: 'Boulangerie', pt: 'Padaria'),
        ShoppingCategory.pantry => _pick(en: 'Pantry', it: 'Dispensa', es: 'Despensa', fr: 'Épicerie', pt: 'Despensa'),
        ShoppingCategory.drinks => _pick(en: 'Drinks', it: 'Bevande', es: 'Bebidas', fr: 'Boissons', pt: 'Bebidas'),
        ShoppingCategory.frozen => _pick(en: 'Frozen', it: 'Surgelati', es: 'Congelados', fr: 'Surgelés', pt: 'Congelados'),
        ShoppingCategory.household => _pick(en: 'Household', it: 'Casa', es: 'Hogar', fr: 'Maison', pt: 'Casa'),
        ShoppingCategory.personalCare => _pick(en: 'Personal care', it: 'Cura personale', es: 'Cuidado personal', fr: 'Soins personnels', pt: 'Cuidados pessoais'),
        ShoppingCategory.other => _pick(en: 'Other', it: 'Altro', es: 'Otro', fr: 'Autre', pt: 'Outro'),
      };

  String get birthdays => _pick(en: 'Birthdays', it: 'Compleanni', es: 'Cumpleaños', fr: 'Anniversaires', pt: 'Aniversários');
  String get newBirthday => _pick(en: 'New birthday', it: 'Nuovo compleanno', es: 'Nuevo cumpleaños', fr: 'Nouvel anniversaire', pt: 'Novo aniversário');
  String get editBirthday => _pick(en: 'Edit birthday', it: 'Modifica compleanno', es: 'Editar cumpleaños', fr: 'Modifier l’anniversaire', pt: 'Editar aniversário');
  String get date => _pick(en: 'Date', it: 'Data', es: 'Fecha', fr: 'Date', pt: 'Data');
  String get birthDate => _pick(en: 'Date of birth', it: 'Data di nascita', es: 'Fecha de nacimiento', fr: 'Date de naissance', pt: 'Data de nascimento');
  String get rememberYear => _pick(en: 'Remember the year too', it: 'Ricorda anche l’anno', es: 'Recordar también el año', fr: 'Mémoriser aussi l’année', pt: 'Guardar também o ano');
  String get yearOnlyForAge => _pick(en: 'Only used to show the age.', it: 'Serve solo per mostrare l’età.', es: 'Solo se usa para mostrar la edad.', fr: 'Sert uniquement à afficher l’âge.', pt: 'Serve apenas para mostrar a idade.');
  String get reminder => _pick(en: 'Reminder', it: 'Promemoria', es: 'Recordatorio', fr: 'Rappel', pt: 'Lembrete');
  String get noReminder => _pick(en: 'No reminder', it: 'Nessun promemoria', es: 'Sin recordatorio', fr: 'Aucun rappel', pt: 'Sem lembrete');
  String get reminderSameDayTime => _pick(en: 'Same day · 09:00', it: 'Il giorno stesso · 09:00', es: 'El mismo día · 09:00', fr: 'Le jour même · 09:00', pt: 'No próprio dia · 09:00');
  String reminderDaysBeforeTime(int days) => _pick(en: '$days day${days == 1 ? '' : 's'} before · 09:00', it: '$days ${days == 1 ? 'giorno' : 'giorni'} prima · 09:00', es: '$days ${days == 1 ? 'día' : 'días'} antes · 09:00', fr: '$days ${days == 1 ? 'jour' : 'jours'} avant · 09:00', pt: '$days ${days == 1 ? 'dia' : 'dias'} antes · 09:00');
  String get optionalNote => _pick(en: 'Optional note', it: 'Nota facoltativa', es: 'Nota opcional', fr: 'Note facultative', pt: 'Nota opcional');
  String get moveToTrashQuestion => _pick(en: 'Move to Trash?', it: 'Spostare nel Cestino?', es: '¿Mover a la papelera?', fr: 'Déplacer vers la corbeille ?', pt: 'Mover para o lixo?');
  String get moveToTrash => _pick(en: 'Move to Trash', it: 'Sposta nel Cestino', es: 'Mover a la papelera', fr: 'Déplacer vers la corbeille', pt: 'Mover para o lixo');
  String birthdayTrashDescription(String name) => _pick(en: 'The birthday of “$name” can be restored from Trash.', it: 'Il compleanno di “$name” potrà essere ripristinato dal Cestino.', es: 'El cumpleaños de “$name” podrá restaurarse desde la papelera.', fr: 'L’anniversaire de « $name » pourra être restauré depuis la corbeille.', pt: 'O aniversário de “$name” poderá ser restaurado do lixo.');
  String get noBirthdaysSaved => _pick(en: 'No birthdays saved', it: 'Nessun compleanno salvato', es: 'No hay cumpleaños guardados', fr: 'Aucun anniversaire enregistré', pt: 'Nenhum aniversário guardado');
  String get birthdaysEmptyDescription => _pick(en: 'Add them once: they will appear every year on the right day and in reminders.', it: 'Aggiungili una volta: compariranno ogni anno nella giornata giusta e nei promemoria.', es: 'Añádelos una vez: aparecerán cada año en el día correcto y en los recordatorios.', fr: 'Ajoute-les une fois : ils réapparaîtront chaque année au bon jour et dans les rappels.', pt: 'Adiciona-os uma vez: aparecerão todos os anos no dia certo e nos lembretes.');
  String ageYears(int age) => _pick(en: '$age years', it: '$age anni', es: '$age años', fr: '$age ans', pt: '$age anos');
  String get reminderDisabled => _pick(en: 'Reminder disabled', it: 'Promemoria disattivato', es: 'Recordatorio desactivado', fr: 'Rappel désactivé', pt: 'Lembrete desativado');
  String get reminderSameDay => _pick(en: 'Reminder on the same day', it: 'Promemoria il giorno stesso', es: 'Recordatorio el mismo día', fr: 'Rappel le jour même', pt: 'Lembrete no próprio dia');
  String reminderDaysBeforeShort(int days) => _pick(en: 'Reminder $days day${days == 1 ? '' : 's'} before', it: 'Promemoria $days gg prima', es: 'Recordatorio $days ${days == 1 ? 'día' : 'días'} antes', fr: 'Rappel $days ${days == 1 ? 'jour' : 'jours'} avant', pt: 'Lembrete $days ${days == 1 ? 'dia' : 'dias'} antes');
  String get edit => _pick(en: 'Edit', it: 'Modifica', es: 'Editar', fr: 'Modifier', pt: 'Editar');

  String restoredFromTrash(String title) => _pick(en: '“$title” restored.', it: '“$title” ripristinato.', es: '“$title” restaurado.', fr: '« $title » restauré.', pt: '“$title” restaurado.');
  String restoreFailedTrash(String title) => _pick(en: 'Could not restore “$title”. The content stayed in Trash.', it: 'Impossibile ripristinare “$title”. Il contenuto è rimasto nel Cestino.', es: 'No se pudo restaurar “$title”. El contenido permaneció en la papelera.', fr: 'Impossible de restaurer « $title ». Le contenu est resté dans la corbeille.', pt: 'Não foi possível restaurar “$title”. O conteúdo permaneceu no lixo.');
  String get deletePermanentlyQuestion => _pick(en: 'Delete permanently?', it: 'Eliminare definitivamente?', es: '¿Eliminar definitivamente?', fr: 'Supprimer définitivement ?', pt: 'Eliminar definitivamente?');
  String purgeTrashDescription(String title) => _pick(en: '“$title” will be removed from Trash. A local restore point will be created first.', it: '“$title” verrà rimosso dal Cestino. Prima dell’operazione verrà creato un punto di ripristino locale.', es: '“$title” se eliminará de la papelera. Antes se creará un punto de restauración local.', fr: '« $title » sera supprimé de la corbeille. Un point de restauration local sera créé auparavant.', pt: '“$title” será removido do lixo. Antes será criado um ponto de restauro local.');
  String get deletePermanently => _pick(en: 'Delete permanently', it: 'Elimina definitivamente', es: 'Eliminar definitivamente', fr: 'Supprimer définitivement', pt: 'Eliminar definitivamente');
  String get itemDeletedPermanently => _pick(en: 'Item deleted permanently.', it: 'Elemento eliminato definitivamente.', es: 'Elemento eliminado definitivamente.', fr: 'Élément supprimé définitivement.', pt: 'Item eliminado definitivamente.');
  String get emptyTrashQuestion => _pick(en: 'Empty Trash?', it: 'Svuotare il Cestino?', es: '¿Vaciar la papelera?', fr: 'Vider la corbeille ?', pt: 'Esvaziar o lixo?');
  String emptyTrashDescription(int count) => _pick(en: '$count items will be deleted permanently. Anna’s Diary will create a local restore point first.', it: '$count elementi verranno eliminati definitivamente. Anna’s Diary creerà prima un punto di ripristino locale.', es: '$count elementos se eliminarán definitivamente. Anna’s Diary creará antes un punto de restauración local.', fr: '$count éléments seront supprimés définitivement. Anna’s Diary créera d’abord un point de restauration local.', pt: '$count itens serão eliminados definitivamente. Anna’s Diary criará primeiro um ponto de restauro local.');
  String get emptyTrash => _pick(en: 'Empty', it: 'Svuota', es: 'Vaciar', fr: 'Vider', pt: 'Esvaziar');
  String removedFromTrash(int count) => _pick(en: '$count items removed from Trash.', it: '$count elementi rimossi dal Cestino.', es: '$count elementos eliminados de la papelera.', fr: '$count éléments supprimés de la corbeille.', pt: '$count itens removidos do lixo.');
  String get trashEmpty => _pick(en: 'Trash is empty.', it: 'Il Cestino è vuoto.', es: 'La papelera está vacía.', fr: 'La corbeille est vide.', pt: 'O lixo está vazio.');
  String get trashEmptyDescription => _pick(en: 'Items deleted reversibly will appear here.', it: 'Gli elementi eliminati in modo reversibile compariranno qui.', es: 'Los elementos eliminados de forma reversible aparecerán aquí.', fr: 'Les éléments supprimés de façon réversible apparaîtront ici.', pt: 'Os itens eliminados de forma reversível aparecerão aqui.');
  String get trashActions => _pick(en: 'Trash actions', it: 'Azioni Cestino', es: 'Acciones de la papelera', fr: 'Actions de la corbeille', pt: 'Ações do lixo');
  String get restore => _pick(en: 'Restore', it: 'Ripristina', es: 'Restaurar', fr: 'Restaurer', pt: 'Restaurar');


  String get vaultPrivateNotes => _pick(en: 'Private notes', it: 'Note private', es: 'Notas privadas', fr: 'Notes privées', pt: 'Notas privadas');
  String get vaultNewPrivateNote => _pick(en: 'New note', it: 'Nuova nota', es: 'Nueva nota', fr: 'Nouvelle note', pt: 'Nova nota');
  String get vaultPasswords => _pick(en: 'Passwords', it: 'Password', es: 'Contraseñas', fr: 'Mots de passe', pt: 'Palavras-passe');
  String get vaultNewPassword => _pick(en: 'New password', it: 'Nuova password', es: 'Nueva contraseña', fr: 'Nouveau mot de passe', pt: 'Nova palavra-passe');
  String get vaultEditPassword => _pick(en: 'Edit password', it: 'Modifica password', es: 'Editar contraseña', fr: 'Modifier le mot de passe', pt: 'Editar palavra-passe');
  String get vaultPasswordDetails => _pick(en: 'Password details', it: 'Dettagli password', es: 'Detalles de la contraseña', fr: 'Détails du mot de passe', pt: 'Detalhes da palavra-passe');
  String get vaultServiceName => _pick(en: 'Service name', it: 'Nome servizio', es: 'Nombre del servicio', fr: 'Nom du service', pt: 'Nome do serviço');
  String get vaultServiceHint => _pick(en: 'e.g. Netflix, Google, Amazon', it: 'Es. Netflix, Google, Amazon', es: 'p. ej. Netflix, Google, Amazon', fr: 'ex. Netflix, Google, Amazon', pt: 'ex. Netflix, Google, Amazon');
  String get vaultUsername => _pick(en: 'Username', it: 'Nome utente', es: 'Nombre de usuario', fr: 'Nom d’utilisateur', pt: 'Nome de utilizador');
  String get vaultEmail => 'Email';
  String get vaultPasswordField => _pick(en: 'Password', it: 'Password', es: 'Contraseña', fr: 'Mot de passe', pt: 'Palavra-passe');
  String get vaultNotes => _pick(en: 'Notes', it: 'Note', es: 'Notas', fr: 'Notes', pt: 'Notas');
  String get vaultPasswordNotesHint => _pick(en: 'Optional notes about this account', it: 'Note facoltative su questo account', es: 'Notas opcionales sobre esta cuenta', fr: 'Notes facultatives sur ce compte', pt: 'Notas opcionais sobre esta conta');
  String get vaultNoPasswords => _pick(en: 'No passwords saved', it: 'Nessuna password salvata', es: 'No hay contraseñas guardadas', fr: 'Aucun mot de passe enregistré', pt: 'Nenhuma palavra-passe guardada');
  String get vaultNoPasswordsDescription => _pick(en: 'Save personal credentials here. They stay inside the encrypted private Vault.', it: 'Salva qui le credenziali personali. Restano dentro la Cassaforte privata cifrata.', es: 'Guarda aquí tus credenciales personales. Permanecen dentro de la Caja fuerte privada cifrada.', fr: 'Enregistre ici tes identifiants personnels. Ils restent dans le Coffre privé chiffré.', pt: 'Guarda aqui as credenciais pessoais. Permanecem dentro do Cofre privado cifrado.');
  String get vaultCredentialDeleteQuestion => _pick(en: 'Delete this password?', it: 'Eliminare questa password?', es: '¿Eliminar esta contraseña?', fr: 'Supprimer ce mot de passe ?', pt: 'Eliminar esta palavra-passe?');
  String vaultCredentialDeleteDescription(String service) => _pick(en: '“$service” will be deleted permanently from the private Vault.', it: '“$service” verrà eliminato definitivamente dalla Cassaforte privata.', es: '“$service” se eliminará definitivamente de la Caja fuerte privada.', fr: '« $service » sera supprimé définitivement du Coffre privé.', pt: '“$service” será eliminado definitivamente do Cofre privado.');
  String vaultCopiedToClipboard(String field) => _pick(en: '$field copied. Clipboard will be cleared automatically.', it: '$field copiato. Gli appunti verranno svuotati automaticamente.', es: '$field copiado. El portapapeles se borrará automáticamente.', fr: '$field copié. Le presse-papiers sera effacé automatiquement.', pt: '$field copiado. A área de transferência será limpa automaticamente.');
  String get vaultCopy => _pick(en: 'Copy', it: 'Copia', es: 'Copiar', fr: 'Copier', pt: 'Copiar');
  String get vaultShowPassword => _pick(en: 'Show password', it: 'Mostra password', es: 'Mostrar contraseña', fr: 'Afficher le mot de passe', pt: 'Mostrar palavra-passe');
  String get vaultHidePassword => _pick(en: 'Hide password', it: 'Nascondi password', es: 'Ocultar contraseña', fr: 'Masquer le mot de passe', pt: 'Ocultar palavra-passe');
  String get vaultNoValue => '—';
  String passwordUpdatedAt(String value) => _pick(
        en: 'Updated on $value',
        it: 'Aggiornato in data $value',
        es: 'Actualizado el $value',
        fr: 'Mis à jour le $value',
        pt: 'Atualizado em $value',
      );

  String get vaultTitle => _pick(en: 'Private Vault', it: 'Cassaforte privata', es: 'Caja fuerte privada', fr: 'Coffre privé', pt: 'Cofre privado');
  String get vaultPasswordTooShort => _pick(en: 'Use at least 12 characters.', it: 'Usa almeno 12 caratteri.', es: 'Usa al menos 12 caracteres.', fr: 'Utilise au moins 12 caractères.', pt: 'Usa pelo menos 12 caracteres.');
  String get vaultPasswordsDoNotMatch => _pick(en: 'Passwords do not match.', it: 'Le password non coincidono.', es: 'Las contraseñas no coinciden.', fr: 'Les mots de passe ne correspondent pas.', pt: 'As palavras-passe não coincidem.');
  String get vaultIncorrectPassword => _pick(en: 'Incorrect password.', it: 'Password non corretta.', es: 'Contraseña incorrecta.', fr: 'Mot de passe incorrect.', pt: 'Palavra-passe incorreta.');
  String get vaultCreateFailed => _pick(en: 'Could not create the Vault. Try again.', it: 'Non è stato possibile creare la cassaforte. Riprova.', es: 'No se pudo crear la Caja fuerte. Inténtalo de nuevo.', fr: 'Impossible de créer le Coffre. Réessaie.', pt: 'Não foi possível criar o Cofre. Tenta novamente.');
  String get vaultUnlockReason => _pick(en: 'Unlock your Anna\'s Diary private Vault', it: 'Sblocca la cassaforte privata di Anna\'s Diary', es: 'Desbloquea la Caja fuerte privada de Anna\'s Diary', fr: 'Déverrouille le Coffre privé d’Anna\'s Diary', pt: 'Desbloqueia o Cofre privado do Anna\'s Diary');
  String get vaultBiometricUnavailableUsePassword => _pick(en: 'Biometric unlock is unavailable. Use the password.', it: 'Sblocco biometrico non disponibile. Usa la password.', es: 'El desbloqueo biométrico no está disponible. Usa la contraseña.', fr: 'Le déverrouillage biométrique est indisponible. Utilise le mot de passe.', pt: 'O desbloqueio biométrico não está disponível. Usa a palavra-passe.');
  String get vaultBiometricUnavailable => _pick(en: 'Biometrics unavailable.', it: 'Biometria non disponibile.', es: 'Biometría no disponible.', fr: 'Biométrie indisponible.', pt: 'Biometria indisponível.');
  String get vaultBiometricEnabled => _pick(en: 'Biometric unlock enabled.', it: 'Sblocco biometrico attivato.', es: 'Desbloqueo biométrico activado.', fr: 'Déverrouillage biométrique activé.', pt: 'Desbloqueio biométrico ativado.');
  String get vaultNewPrivateContent => _pick(en: 'New private content', it: 'Nuovo contenuto privato', es: 'Nuevo contenido privado', fr: 'Nouveau contenu privé', pt: 'Novo conteúdo privado');
  String get vaultSetupTitle => _pick(en: 'A space just for you', it: 'Uno spazio solo tuo', es: 'Un espacio solo para ti', fr: 'Un espace rien qu’à toi', pt: 'Um espaço só teu');
  String get vaultSetupDescription => _pick(en: 'Vault content is encrypted before it is saved on the device. It does not enter cloud sync, Noi ♡, search or normal backups.', it: 'I contenuti della cassaforte vengono cifrati prima di essere salvati sul dispositivo. Non entrano nel cloud, in Noi ♡, nella ricerca o nei backup normali.', es: 'El contenido de la Caja fuerte se cifra antes de guardarse en el dispositivo. No entra en la nube, Noi ♡, la búsqueda ni las copias normales.', fr: 'Le contenu du Coffre est chiffré avant d’être enregistré sur l’appareil. Il n’entre pas dans le cloud, Noi ♡, la recherche ni les sauvegardes normales.', pt: 'O conteúdo do Cofre é cifrado antes de ser guardado no dispositivo. Não entra na cloud, Noi ♡, pesquisa ou backups normais.');
  String get vaultDestroyDescription => _pick(en: 'All encrypted Vault content will be deleted permanently. Enter the Vault password to confirm.', it: 'Tutti i contenuti cifrati verranno eliminati definitivamente. Inserisci la password della cassaforte per confermare.', es: 'Todo el contenido cifrado se eliminará definitivamente. Introduce la contraseña de la Caja fuerte para confirmar.', fr: 'Tout le contenu chiffré sera supprimé définitivement. Saisis le mot de passe du Coffre pour confirmer.', pt: 'Todo o conteúdo cifrado será eliminado definitivamente. Introduz a palavra-passe do Cofre para confirmar.');

  String get vaultPrivateTitleField => _pick(en: 'Title', it: 'Titolo', es: 'Título', fr: 'Titre', pt: 'Título');
  String get vaultPrivateContentField => _pick(en: 'Private content', it: 'Contenuto privato', es: 'Contenido privado', fr: 'Contenu privé', pt: 'Conteúdo privado');
  String get vaultDeleteVault => _pick(en: 'Delete Vault', it: 'Elimina cassaforte', es: 'Eliminar Caja fuerte', fr: 'Supprimer le Coffre', pt: 'Eliminar Cofre');
  String get vaultPasswordLabel => _pick(en: 'Vault password', it: 'Password cassaforte', es: 'Contraseña de la Caja fuerte', fr: 'Mot de passe du Coffre', pt: 'Palavra-passe do Cofre');
  String get vaultRepeatPassword => _pick(en: 'Repeat password', it: 'Ripeti password', es: 'Repite la contraseña', fr: 'Répète le mot de passe', pt: 'Repete a palavra-passe');
  String get vaultBiometricUnlock => _pick(en: 'Fingerprint / biometric unlock', it: 'Sblocco con impronta/biometria', es: 'Desbloqueo con huella/biometría', fr: 'Déverrouillage empreinte/biométrie', pt: 'Desbloqueio por impressão digital/biometria');
  String get vaultBiometricRecoveryDescription => _pick(en: 'The password always remains available as recovery.', it: 'La password resta sempre disponibile come recupero.', es: 'La contraseña siempre permanece disponible para recuperación.', fr: 'Le mot de passe reste toujours disponible pour la récupération.', pt: 'A palavra-passe permanece sempre disponível para recuperação.');
  String get vaultCreate => _pick(en: 'Create Vault', it: 'Crea cassaforte', es: 'Crear Caja fuerte', fr: 'Créer le Coffre', pt: 'Criar Cofre');
  String get vaultCreating => _pick(en: 'Creating…', it: 'Creazione…', es: 'Creando…', fr: 'Création…', pt: 'A criar…');
  String get vaultLocked => _pick(en: 'Vault locked', it: 'Cassaforte bloccata', es: 'Caja fuerte bloqueada', fr: 'Coffre verrouillé', pt: 'Cofre bloqueado');
  String get vaultLockedDescription => _pick(en: 'Content remains encrypted until you unlock it.', it: 'Il contenuto resta cifrato finché non la sblocchi.', es: 'El contenido permanece cifrado hasta que lo desbloquees.', fr: 'Le contenu reste chiffré jusqu’à son déverrouillage.', pt: 'O conteúdo permanece cifrado até o desbloqueares.');
  String get vaultUnlock => _pick(en: 'Unlock', it: 'Sblocca', es: 'Desbloquear', fr: 'Déverrouiller', pt: 'Desbloquear');
  String get vaultUnlocking => _pick(en: 'Unlocking…', it: 'Sblocco…', es: 'Desbloqueando…', fr: 'Déverrouillage…', pt: 'A desbloquear…');
  String get vaultUnlockFailed => _pick(en: 'Could not unlock the Vault. Try again.', it: 'Non è stato possibile sbloccare la cassaforte. Riprova.', es: 'No se pudo desbloquear la Caja fuerte. Inténtalo de nuevo.', fr: 'Impossible de déverrouiller le Coffre. Réessaie.', pt: 'Não foi possível desbloquear o Cofre. Tenta novamente.');
  String get vaultOpen => _pick(en: 'Open Vault', it: 'Apri cassaforte', es: 'Abrir Caja fuerte', fr: 'Ouvrir le Coffre', pt: 'Abrir Cofre');
  String get vaultConfigure => _pick(en: 'Set up the private Vault', it: 'Configura la Cassaforte privata', es: 'Configura la Caja fuerte privada', fr: 'Configurer le Coffre privé', pt: 'Configurar o Cofre privado');
  String get vaultUseBiometric => _pick(en: 'Use fingerprint / biometrics', it: 'Usa impronta/biometria', es: 'Usar huella/biometría', fr: 'Utiliser empreinte/biométrie', pt: 'Usar impressão digital/biometria');
  String get vaultEnableBiometric => _pick(en: 'Enable biometrics', it: 'Attiva biometria', es: 'Activar biometría', fr: 'Activer la biométrie', pt: 'Ativar biometria');
  String get vaultLockNow => _pick(en: 'Lock now', it: 'Blocca adesso', es: 'Bloquear ahora', fr: 'Verrouiller maintenant', pt: 'Bloquear agora');
  String get vaultEmpty => _pick(en: 'The Vault is empty', it: 'La cassaforte è vuota', es: 'La Caja fuerte está vacía', fr: 'Le Coffre est vide', pt: 'O Cofre está vazio');
  String get vaultEmptyDescription => _pick(en: 'Add notes and information you want to keep separate from the rest of the app.', it: 'Aggiungi note e informazioni che vuoi tenere separate dal resto dell’app.', es: 'Añade notas e información que quieras mantener separadas del resto de la app.', fr: 'Ajoute des notes et informations à garder séparées du reste de l’app.', pt: 'Adiciona notas e informações que queres manter separadas do resto da app.');
  String get vaultDeletePrivateQuestion => _pick(en: 'Delete from the Vault?', it: 'Eliminare dalla cassaforte?', es: '¿Eliminar de la Caja fuerte?', fr: 'Supprimer du Coffre ?', pt: 'Eliminar do Cofre?');
  String get vaultDeletePrivateDescription => _pick(en: 'The content will be deleted permanently.', it: 'Il contenuto verrà eliminato definitivamente.', es: 'El contenido se eliminará definitivamente.', fr: 'Le contenu sera supprimé définitivement.', pt: 'O conteúdo será eliminado definitivamente.');
  String vaultDeletePrivateNamed(String title) => _pick(en: '“$title” will be deleted permanently.', it: '“$title” verrà eliminato definitivamente.', es: '“$title” se eliminará definitivamente.', fr: '« $title » sera supprimé définitivement.', pt: '“$title” será eliminado definitivamente.');
  String get vaultSharedUpdateFailed => _pick(en: 'Noi ♡ update failed. Check the connection.', it: 'Aggiornamento Noi ♡ non riuscito. Controlla la connessione.', es: 'La actualización de Noi ♡ falló. Comprueba la conexión.', fr: 'La mise à jour Noi ♡ a échoué. Vérifie la connexion.', pt: 'A atualização Noi ♡ falhou. Verifica a ligação.');
  String get vaultSharedDeleteFailed => _pick(en: 'Noi ♡ deletion failed. Check the connection.', it: 'Eliminazione Noi ♡ non riuscita. Controlla la connessione.', es: 'La eliminación de Noi ♡ falló. Comprueba la conexión.', fr: 'La suppression Noi ♡ a échoué. Vérifie la connexion.', pt: 'A eliminação Noi ♡ falhou. Verifica a ligação.');
  String get vaultWebSecurityWarning => _pick(en: 'Web security is reduced: device Keystore and screenshot blocking are unavailable. Use the Vault only on a trusted device.', it: 'Sul Web la protezione è ridotta: Keystore del dispositivo e blocco screenshot non sono disponibili. Usa la Cassaforte solo su un dispositivo fidato.', es: 'En Web la protección es menor: no están disponibles el Keystore del dispositivo ni el bloqueo de capturas. Usa la Caja fuerte solo en un dispositivo de confianza.', fr: 'Sur le Web, la protection est réduite : le Keystore de l’appareil et le blocage des captures ne sont pas disponibles. Utilise le Coffre uniquement sur un appareil de confiance.', pt: 'Na Web a proteção é reduzida: o Keystore do dispositivo e o bloqueio de capturas não estão disponíveis. Usa o Cofre apenas num dispositivo de confiança.');


  String get vaultRecoveryTitle => _pick(en: 'Vault recovery backup', it: 'Backup di recupero Cassaforte', es: 'Copia de recuperación de la Caja fuerte', fr: 'Sauvegarde de récupération du Coffre', pt: 'Backup de recuperação do Cofre');
  String get vaultRecoveryDescription => _pick(en: 'Create a portable encrypted package of the entire Vault. It stays protected by the same Vault password and includes private notes, credentials, cycle data and local encrypted mirrors. Store it outside the app.', it: 'Crea un pacchetto portabile cifrato dell’intera Cassaforte. Resta protetto dalla stessa password della Cassaforte e include note private, credenziali, dati del ciclo e copie locali cifrate. Conservalo fuori dall’app.', es: 'Crea un paquete portátil cifrado de toda la Caja fuerte. Sigue protegido por la misma contraseña de la Caja fuerte e incluye notas privadas, credenciales, datos del ciclo y copias locales cifradas. Guárdalo fuera de la app.', fr: 'Crée un paquet portable chiffré de l’ensemble du Coffre. Il reste protégé par le même mot de passe du Coffre et comprend les notes privées, identifiants, données du cycle et copies locales chiffrées. Conserve-le hors de l’app.', pt: 'Cria um pacote portátil cifrado de todo o Cofre. Continua protegido pela mesma palavra-passe do Cofre e inclui notas privadas, credenciais, dados do ciclo e cópias locais cifradas. Guarda-o fora da app.');
  String get vaultRecoveryCreate => _pick(en: 'Copy encrypted recovery package', it: 'Copia pacchetto di recupero cifrato', es: 'Copiar paquete de recuperación cifrado', fr: 'Copier le paquet de récupération chiffré', pt: 'Copiar pacote de recuperação cifrado');
  String get vaultRecoveryRestore => _pick(en: 'Restore recovery backup', it: 'Ripristina backup di recupero', es: 'Restaurar copia de recuperación', fr: 'Restaurer la sauvegarde de récupération', pt: 'Restaurar backup de recuperação');
  String get vaultRecoveryRestoreDescription => _pick(en: 'Paste the encrypted package and enter the Vault password that protected it. The package is fully verified before local data can be replaced.', it: 'Incolla il pacchetto cifrato e inserisci la password della Cassaforte che lo proteggeva. Il pacchetto viene verificato completamente prima di poter sostituire i dati locali.', es: 'Pega el paquete cifrado e introduce la contraseña de la Caja fuerte que lo protegía. El paquete se verifica completamente antes de poder sustituir los datos locales.', fr: 'Colle le paquet chiffré et saisis le mot de passe du Coffre qui le protégeait. Le paquet est entièrement vérifié avant tout remplacement des données locales.', pt: 'Cola o pacote cifrado e introduz a palavra-passe do Cofre que o protegia. O pacote é totalmente verificado antes de qualquer substituição dos dados locais.');
  String get vaultRecoveryPackage => _pick(en: 'Encrypted recovery package', it: 'Pacchetto di recupero cifrato', es: 'Paquete de recuperación cifrado', fr: 'Paquet de récupération chiffré', pt: 'Pacote de recuperação cifrado');
  String get vaultRecoveryPassword => _pick(en: 'Vault password for this backup', it: 'Password Cassaforte di questo backup', es: 'Contraseña de la Caja fuerte de esta copia', fr: 'Mot de passe du Coffre pour cette sauvegarde', pt: 'Palavra-passe do Cofre deste backup');
  String get vaultRecoveryReplaceTitle => _pick(en: 'Replace the local Vault?', it: 'Sostituire la Cassaforte locale?', es: '¿Sustituir la Caja fuerte local?', fr: 'Remplacer le Coffre local ?', pt: 'Substituir o Cofre local?');
  String get vaultRecoveryReplaceDescription => _pick(en: 'After the recovery package is verified, the current local Vault will be replaced by the recovered encrypted Vault. Create a current recovery backup first if you need to preserve it.', it: 'Dopo la verifica del pacchetto, la Cassaforte locale attuale verrà sostituita da quella cifrata recuperata. Crea prima un backup di recupero della Cassaforte attuale se devi conservarla.', es: 'Tras verificar el paquete, la Caja fuerte local actual será sustituida por la Caja fuerte cifrada recuperada. Crea antes una copia de recuperación de la Caja fuerte actual si necesitas conservarla.', fr: 'Après vérification du paquet, le Coffre local actuel sera remplacé par le Coffre chiffré récupéré. Crée d’abord une sauvegarde de récupération du Coffre actuel si tu dois le conserver.', pt: 'Após a verificação do pacote, o Cofre local atual será substituído pelo Cofre cifrado recuperado. Cria primeiro um backup de recuperação do Cofre atual se precisares de o conservar.');
  String get vaultRecoveryReplaceConfirm => _pick(en: 'Verify and replace', it: 'Verifica e sostituisci', es: 'Verificar y sustituir', fr: 'Vérifier et remplacer', pt: 'Verificar e substituir');
  String get vaultRecoveryInvalid => _pick(en: 'Recovery package or Vault password is invalid or damaged. Nothing was changed.', it: 'Il pacchetto di recupero o la password della Cassaforte non sono validi oppure il pacchetto è danneggiato. Nessun dato è stato modificato.', es: 'El paquete de recuperación o la contraseña de la Caja fuerte no son válidos o el paquete está dañado. No se ha modificado ningún dato.', fr: 'Le paquet de récupération ou le mot de passe du Coffre est invalide, ou le paquet est endommagé. Aucune donnée n’a été modifiée.', pt: 'O pacote de recuperação ou a palavra-passe do Cofre é inválido, ou o pacote está danificado. Nenhum dado foi alterado.');
  String get vaultRecoveryRestored => _pick(en: 'Vault restored and unlocked. Biometrics must be enabled again on this device.', it: 'Cassaforte ripristinata e sbloccata. La biometria va riattivata su questo dispositivo.', es: 'Caja fuerte restaurada y desbloqueada. La biometría debe activarse de nuevo en este dispositivo.', fr: 'Coffre restauré et déverrouillé. La biométrie doit être réactivée sur cet appareil.', pt: 'Cofre restaurado e desbloqueado. A biometria deve ser ativada novamente neste dispositivo.');
  String get vaultRecoveryCopied => _pick(en: 'Encrypted recovery package copied. Store it safely; the clipboard will clear automatically.', it: 'Pacchetto di recupero cifrato copiato. Conservalo in modo sicuro; gli appunti verranno svuotati automaticamente.', es: 'Paquete de recuperación cifrado copiado. Guárdalo de forma segura; el portapapeles se borrará automáticamente.', fr: 'Paquet de récupération chiffré copié. Conserve-le en lieu sûr ; le presse-papiers sera effacé automatiquement.', pt: 'Pacote de recuperação cifrado copiado. Guarda-o em segurança; a área de transferência será limpa automaticamente.');
  String get vaultRecoveryExportFailed => _pick(en: 'Could not create the recovery package.', it: 'Impossibile creare il pacchetto di recupero.', es: 'No se pudo crear el paquete de recuperación.', fr: 'Impossible de créer le paquet de récupération.', pt: 'Não foi possível criar o pacote de recuperação.');
  String get vaultRecoveryImportExisting => _pick(en: 'Restore an existing Vault backup', it: 'Ripristina una Cassaforte esistente', es: 'Restaurar una Caja fuerte existente', fr: 'Restaurer un Coffre existant', pt: 'Restaurar um Cofre existente');
  String get vaultRecoveryRestoreLocked => _pick(en: 'Restore from recovery backup', it: 'Ripristina da backup di recupero', es: 'Restaurar desde copia de recuperación', fr: 'Restaurer depuis une sauvegarde de récupération', pt: 'Restaurar a partir de backup de recuperação');

  String get premiumTitle => _pick(en: 'Anna Premium', it: 'Anna Premium', es: 'Anna Premium', fr: 'Anna Premium', pt: 'Anna Premium');
  String get premiumHeroTitle => _pick(en: 'More depth, same privacy', it: 'Più profondità, stessa privacy', es: 'Más profundidad, la misma privacidad', fr: 'Plus de profondeur, la même confidentialité', pt: 'Mais profundidade, a mesma privacidade');
  String get premiumHeroDescription => _pick(en: 'Premium unlocks advanced private tools without moving your intimate data out of the Vault.', it: 'Premium sblocca strumenti privati avanzati senza spostare i tuoi dati intimi fuori dalla Cassaforte.', es: 'Premium desbloquea herramientas privadas avanzadas sin sacar tus datos íntimos de la Caja fuerte.', fr: 'Premium débloque des outils privés avancés sans sortir tes données intimes du Coffre.', pt: 'Premium desbloqueia ferramentas privadas avançadas sem retirar os teus dados íntimos do Cofre.');
  String get premiumIncludes => _pick(en: 'Included in Premium', it: 'Incluso in Premium', es: 'Incluido en Premium', fr: 'Inclus dans Premium', pt: 'Incluído no Premium');
  String get premiumBenefitInsights => _pick(en: 'Advanced cycle patterns and trends', it: 'Pattern e tendenze avanzate del ciclo', es: 'Patrones y tendencias avanzadas del ciclo', fr: 'Tendances et schémas avancés du cycle', pt: 'Padrões e tendências avançadas do ciclo');
  String get premiumBenefitAdvancedCycle => _pick(en: 'Basal temperature, cervical mucus, sexual activity and ovulation-test tracking', it: 'Temperatura basale, muco cervicale, attività sessuale e test di ovulazione', es: 'Temperatura basal, moco cervical, actividad sexual y tests de ovulación', fr: 'Température basale, glaire cervicale, activité sexuelle et tests d’ovulation', pt: 'Temperatura basal, muco cervical, atividade sexual e testes de ovulação');
  String get premiumBenefitCustomTracking => _pick(en: 'Custom private symptom labels', it: 'Sintomi privati personalizzati', es: 'Síntomas privados personalizados', fr: 'Symptômes privés personnalisés', pt: 'Sintomas privados personalizados');
  String get premiumBenefitPrivateReports => _pick(en: 'Local private cycle reports', it: 'Report privati del ciclo generati in locale', es: 'Informes privados del ciclo generados localmente', fr: 'Rapports privés du cycle générés localement', pt: 'Relatórios privados do ciclo gerados localmente');
  String get premiumBenefitFuture => _pick(en: 'Future Premium modules from the same entitlement', it: 'Futuri moduli Premium con lo stesso abbonamento', es: 'Futuros módulos Premium con el mismo acceso', fr: 'Futurs modules Premium avec le même accès', pt: 'Futuros módulos Premium com o mesmo acesso');
  String get premiumPlans => _pick(en: 'Plans', it: 'Piani', es: 'Planes', fr: 'Formules', pt: 'Planos');
  String get premiumMonthly => _pick(en: 'Monthly Premium', it: 'Premium mensile', es: 'Premium mensual', fr: 'Premium mensuel', pt: 'Premium mensal');
  String get premiumMonthlyDescription => _pick(en: 'Full Premium access while the subscription is active.', it: 'Accesso Premium completo finché l’abbonamento è attivo.', es: 'Acceso Premium completo mientras la suscripción esté activa.', fr: 'Accès Premium complet tant que l’abonnement est actif.', pt: 'Acesso Premium completo enquanto a subscrição estiver ativa.');
  String get premiumLifetime => _pick(en: 'Lifetime Premium', it: 'Premium a vita', es: 'Premium de por vida', fr: 'Premium à vie', pt: 'Premium vitalício');
  String get premiumLifetimeDescription => _pick(en: 'One purchase for permanent Premium access to this entitlement.', it: 'Un solo acquisto per l’accesso Premium permanente a questo entitlement.', es: 'Una sola compra para acceso Premium permanente a este entitlement.', fr: 'Un achat unique pour un accès Premium permanent à cet entitlement.', pt: 'Uma única compra para acesso Premium permanente a este entitlement.');
  String get premiumBestValue => _pick(en: 'Best value', it: 'Miglior valore', es: 'Mejor valor', fr: 'Meilleur choix', pt: 'Melhor valor');
  String get premiumChoosePlan => _pick(en: 'Choose this plan', it: 'Scegli questo piano', es: 'Elegir este plan', fr: 'Choisir cette formule', pt: 'Escolher este plano');
  String get premiumActive => _pick(en: 'Premium active', it: 'Premium attivo', es: 'Premium activo', fr: 'Premium actif', pt: 'Premium ativo');
  String get premiumActiveDescription => _pick(en: 'Your Premium entitlement is active on this account/device.', it: 'Il tuo entitlement Premium è attivo su questo account/dispositivo.', es: 'Tu entitlement Premium está activo en esta cuenta/dispositivo.', fr: 'Ton entitlement Premium est actif sur ce compte/appareil.', pt: 'O teu entitlement Premium está ativo nesta conta/dispositivo.');
  String get premiumPreview => _pick(en: 'Premium preview', it: 'Anteprima Premium', es: 'Vista previa Premium', fr: 'Aperçu Premium', pt: 'Pré-visualização Premium');
  String get premiumPreviewDescription => _pick(en: 'Advanced features are unlocked in this development build while the store configuration is completed.', it: 'Le funzioni avanzate sono sbloccate in questa build di sviluppo mentre viene completata la configurazione dello store.', es: 'Las funciones avanzadas están desbloqueadas en esta build de desarrollo mientras se completa la configuración de la tienda.', fr: 'Les fonctions avancées sont déverrouillées dans cette build de développement pendant la configuration du store.', pt: 'As funções avançadas estão desbloqueadas nesta build de desenvolvimento enquanto a configuração da loja é concluída.');
  String get premiumFree => _pick(en: 'Free plan', it: 'Piano Free', es: 'Plan gratuito', fr: 'Offre gratuite', pt: 'Plano gratuito');
  String get premiumFreeDescription => _pick(en: 'The diary, agenda, Vault and basic cycle tracker remain available without Premium.', it: 'Diario, agenda, Cassaforte e tracciamento base del ciclo restano disponibili senza Premium.', es: 'El diario, la agenda, la Caja fuerte y el seguimiento básico del ciclo siguen disponibles sin Premium.', fr: 'Le journal, l’agenda, le Coffre et le suivi de base du cycle restent disponibles sans Premium.', pt: 'O diário, a agenda, o Cofre e o acompanhamento básico do ciclo continuam disponíveis sem Premium.');
  String get premiumFreeCorePromise => _pick(en: 'Premium adds advanced tools. It never locks your existing diary, agenda, Vault or previously recorded personal data.', it: 'Premium aggiunge strumenti avanzati. Non blocca mai diario, agenda, Cassaforte o dati personali già registrati.', es: 'Premium añade herramientas avanzadas. Nunca bloquea tu diario, agenda, Caja fuerte ni datos personales ya registrados.', fr: 'Premium ajoute des outils avancés. Il ne bloque jamais ton journal, ton agenda, ton Coffre ni tes données personnelles déjà enregistrées.', pt: 'Premium adiciona ferramentas avançadas. Nunca bloqueia o diário, agenda, Cofre ou dados pessoais já registados.');
  String get premiumStoreNotConfigured => _pick(en: 'The Premium store is not configured in this build yet. No purchase can be charged.', it: 'Lo store Premium non è ancora configurato in questa build. Nessun acquisto può essere addebitato.', es: 'La tienda Premium aún no está configurada en esta build. No se puede cobrar ninguna compra.', fr: 'Le store Premium n’est pas encore configuré dans cette build. Aucun achat ne peut être facturé.', pt: 'A loja Premium ainda não está configurada nesta build. Nenhuma compra pode ser cobrada.');
  String get premiumNoProducts => _pick(en: 'The store is connected, but the current RevenueCat offering has no products available.', it: 'Lo store è collegato, ma l’offerta RevenueCat corrente non contiene prodotti disponibili.', es: 'La tienda está conectada, pero la oferta actual de RevenueCat no contiene productos disponibles.', fr: 'Le store est connecté, mais l’offre RevenueCat actuelle ne contient aucun produit disponible.', pt: 'A loja está ligada, mas a oferta RevenueCat atual não contém produtos disponíveis.');
  String get premiumRefreshStore => _pick(en: 'Refresh store', it: 'Aggiorna store', es: 'Actualizar tienda', fr: 'Actualiser le store', pt: 'Atualizar loja');
  String get premiumRestorePurchases => _pick(en: 'Restore purchases', it: 'Ripristina acquisti', es: 'Restaurar compras', fr: 'Restaurer les achats', pt: 'Restaurar compras');
  String get premiumPurchaseSuccess => _pick(en: 'Premium activated.', it: 'Premium attivato.', es: 'Premium activado.', fr: 'Premium activé.', pt: 'Premium ativado.');
  String get premiumPurchaseCancelled => _pick(en: 'Purchase cancelled.', it: 'Acquisto annullato.', es: 'Compra cancelada.', fr: 'Achat annulé.', pt: 'Compra cancelada.');
  String get premiumPurchaseFailed => _pick(en: 'The purchase was not completed. No Premium access was granted.', it: 'L’acquisto non è stato completato. Nessun accesso Premium è stato concesso.', es: 'La compra no se completó. No se concedió acceso Premium.', fr: 'L’achat n’a pas été finalisé. Aucun accès Premium n’a été accordé.', pt: 'A compra não foi concluída. Não foi concedido acesso Premium.');
  String get premiumRestoreSuccess => _pick(en: 'Premium purchase restored.', it: 'Acquisto Premium ripristinato.', es: 'Compra Premium restaurada.', fr: 'Achat Premium restauré.', pt: 'Compra Premium restaurada.');
  String get premiumRestoreNotFound => _pick(en: 'No active Premium entitlement was found for this store account.', it: 'Nessun entitlement Premium attivo trovato per questo account dello store.', es: 'No se encontró ningún entitlement Premium activo para esta cuenta de la tienda.', fr: 'Aucun entitlement Premium actif trouvé pour ce compte du store.', pt: 'Não foi encontrado nenhum entitlement Premium ativo para esta conta da loja.');
  String get premiumStoreUnavailable => _pick(en: 'Premium purchases are not available in this build.', it: 'Gli acquisti Premium non sono disponibili in questa build.', es: 'Las compras Premium no están disponibles en esta build.', fr: 'Les achats Premium ne sont pas disponibles dans cette build.', pt: 'As compras Premium não estão disponíveis nesta build.');
  String get premiumOperationUnsupported => _pick(en: 'This purchase operation is not supported on this platform.', it: 'Questa operazione di acquisto non è supportata su questa piattaforma.', es: 'Esta operación de compra no es compatible con esta plataforma.', fr: 'Cette opération d’achat n’est pas prise en charge sur cette plateforme.', pt: 'Esta operação de compra não é suportada nesta plataforma.');
  String get premiumWebRestoreUnsupported => _pick(en: 'On Web, purchase restoration is handled by the configured web billing provider; the native Restore Purchases action is unavailable.', it: 'Sul Web il ripristino è gestito dal provider di fatturazione Web configurato; l’azione nativa Ripristina acquisti non è disponibile.', es: 'En Web, la restauración la gestiona el proveedor de facturación Web configurado; la acción nativa Restaurar compras no está disponible.', fr: 'Sur le Web, la restauration est gérée par le fournisseur de facturation Web configuré ; l’action native Restaurer les achats n’est pas disponible.', pt: 'Na Web, o restauro é gerido pelo fornecedor de faturação Web configurado; a ação nativa Restaurar compras não está disponível.');
  String get premiumSettingsDescription => _pick(en: 'Manage Premium access, plans and purchase restoration.', it: 'Gestisci accesso Premium, piani e ripristino degli acquisti.', es: 'Gestiona el acceso Premium, los planes y la restauración de compras.', fr: 'Gère l’accès Premium, les formules et la restauration des achats.', pt: 'Gere o acesso Premium, os planos e o restauro de compras.');

  String get cycleTitle => _pick(en: 'My cycle', it: 'Il mio ciclo', es: 'Mi ciclo', fr: 'Mon cycle', pt: 'O meu ciclo');
  String get cycleVaultCardDescription => _pick(en: 'Private menstrual cycle tracking inside the encrypted Vault', it: 'Tracciamento privato del ciclo dentro la Cassaforte cifrata', es: 'Seguimiento privado del ciclo dentro de la Caja fuerte cifrada', fr: 'Suivi privé du cycle dans le Coffre chiffré', pt: 'Acompanhamento privado do ciclo dentro do Cofre cifrado');
  String get cycleOverview => _pick(en: 'Overview', it: 'Panoramica', es: 'Resumen', fr: 'Aperçu', pt: 'Visão geral');
  String get cycleCalendar => _pick(en: 'Calendar', it: 'Calendario', es: 'Calendario', fr: 'Calendrier', pt: 'Calendário');
  String get cycleHistory => _pick(en: 'History', it: 'Storico', es: 'Historial', fr: 'Historique', pt: 'Histórico');
  String get cycleSettings => _pick(en: 'Settings', it: 'Impostazioni', es: 'Ajustes', fr: 'Réglages', pt: 'Definições');
  String get cyclePrivacyBanner => _pick(en: 'These intimate-health data stay inside your encrypted private Vault and are excluded from normal sync, global search and standard backup.', it: 'Questi dati di salute intima restano nella Cassaforte privata cifrata e sono esclusi da sync normale, ricerca globale e backup standard.', es: 'Estos datos de salud íntima permanecen dentro de tu Caja fuerte privada cifrada y están excluidos de la sincronización normal, la búsqueda global y la copia estándar.', fr: 'Ces données de santé intime restent dans ton Coffre privé chiffré et sont exclues de la synchronisation normale, de la recherche globale et de la sauvegarde standard.', pt: 'Estes dados de saúde íntima permanecem dentro do Cofre privado cifrado e ficam excluídos da sincronização normal, pesquisa global e backup padrão.');
  String get cycleNoPrediction => _pick(en: 'Add a period to start', it: 'Registra un ciclo per iniziare', es: 'Registra un periodo para empezar', fr: 'Ajoute des règles pour commencer', pt: 'Regista uma menstruação para começar');
  String get cycleNoData => _pick(en: 'Start your private cycle history', it: 'Inizia il tuo storico privato', es: 'Empieza tu historial privado', fr: 'Commence ton historique privé', pt: 'Começa o teu histórico privado');
  String cycleDayNumber(int day) => _pick(en: 'Cycle day $day', it: 'Giorno $day del ciclo', es: 'Día $day del ciclo', fr: 'Jour $day du cycle', pt: 'Dia $day do ciclo');
  String get cycleNextPeriod => _pick(en: 'Next period', it: 'Prossimo ciclo', es: 'Próxima menstruación', fr: 'Prochaines règles', pt: 'Próxima menstruação');
  String get cycleAverageLength => _pick(en: 'Average cycle', it: 'Ciclo medio', es: 'Ciclo medio', fr: 'Cycle moyen', pt: 'Ciclo médio');
  String get cycleAveragePeriodLength => _pick(en: 'Average period', it: 'Mestruazione media', es: 'Menstruación media', fr: 'Durée moyenne des règles', pt: 'Menstruação média');
  String cycleDays(int days) => _pick(en: '$days days', it: '$days giorni', es: '$days días', fr: '$days jours', pt: '$days dias');
  String get cycleLogToday => _pick(en: 'Log today', it: 'Registra oggi', es: 'Registrar hoy', fr: 'Enregistrer aujourd’hui', pt: 'Registar hoje');
  String get cycleEditToday => _pick(en: 'Edit today', it: 'Modifica oggi', es: 'Editar hoy', fr: 'Modifier aujourd’hui', pt: 'Editar hoje');
  String get cycleTodayRecorded => _pick(en: 'Today is recorded', it: 'Oggi è registrato', es: 'Hoy está registrado', fr: 'Aujourd’hui est enregistré', pt: 'Hoje está registado');
  String get cycleFertileWindow => _pick(en: 'Estimated fertile window', it: 'Finestra fertile stimata', es: 'Ventana fértil estimada', fr: 'Fenêtre fertile estimée', pt: 'Janela fértil estimada');
  String get cyclePredictionDisclaimer => _pick(en: 'Cycle and fertility dates are estimates based on the information you record. They are not contraception, diagnosis or medical advice.', it: 'Le date del ciclo e della fertilità sono stime basate sui dati registrati. Non sono un metodo contraccettivo, una diagnosi o un parere medico.', es: 'Las fechas del ciclo y de fertilidad son estimaciones basadas en los datos registrados. No son anticoncepción, diagnóstico ni consejo médico.', fr: 'Les dates du cycle et de fertilité sont des estimations basées sur les données enregistrées. Elles ne constituent ni contraception, ni diagnostic, ni avis médical.', pt: 'As datas do ciclo e da fertilidade são estimativas baseadas nos dados registados. Não constituem contraceção, diagnóstico nem aconselhamento médico.');
  String get cycleNoLogForDay => _pick(en: 'No private log for this day', it: 'Nessun dato privato per questo giorno', es: 'Sin registro privado para este día', fr: 'Aucune donnée privée pour ce jour', pt: 'Sem registo privado para este dia');
  String get cycleRecordedPeriod => _pick(en: 'Recorded period', it: 'Mestruazione registrata', es: 'Menstruación registrada', fr: 'Règles enregistrées', pt: 'Menstruação registada');
  String get cyclePredictedPeriod => _pick(en: 'Predicted period', it: 'Mestruazione prevista', es: 'Menstruación prevista', fr: 'Règles prévues', pt: 'Menstruação prevista');
  String get cycleNoHistory => _pick(en: 'No cycle history yet', it: 'Nessuno storico del ciclo', es: 'Aún no hay historial del ciclo', fr: 'Aucun historique du cycle', pt: 'Ainda não há histórico do ciclo');
  String get cycleNoHistoryDescription => _pick(en: 'Record menstrual flow on the calendar to build your private history and improve estimates.', it: 'Registra il flusso mestruale nel calendario per creare lo storico privato e migliorare le stime.', es: 'Registra el flujo menstrual en el calendario para crear tu historial privado y mejorar las estimaciones.', fr: 'Enregistre le flux menstruel dans le calendrier pour créer ton historique privé et améliorer les estimations.', pt: 'Regista o fluxo menstrual no calendário para criar o teu histórico privado e melhorar as estimativas.');
  String cyclePeriodLength(int days) => _pick(en: 'Period: $days days', it: 'Mestruazione: $days giorni', es: 'Menstruación: $days días', fr: 'Règles : $days jours', pt: 'Menstruação: $days dias');
  String cycleCycleLength(int days) => _pick(en: 'Cycle: $days days', it: 'Ciclo: $days giorni', es: 'Ciclo: $days días', fr: 'Cycle : $days jours', pt: 'Ciclo: $days dias');
  String get cycleTrackFertility => _pick(en: 'Show fertility estimates', it: 'Mostra stime fertilità', es: 'Mostrar estimaciones de fertilidad', fr: 'Afficher les estimations de fertilité', pt: 'Mostrar estimativas de fertilidade');
  String get cycleFertilityEstimateOnly => _pick(en: 'Estimates only, never a contraceptive method', it: 'Solo stime, mai un metodo contraccettivo', es: 'Solo estimaciones, nunca un método anticonceptivo', fr: 'Estimations uniquement, jamais une méthode contraceptive', pt: 'Apenas estimativas, nunca um método contracetivo');
  String get cyclePeriodReminder => _pick(en: 'Period reminder', it: 'Promemoria ciclo', es: 'Recordatorio del periodo', fr: 'Rappel des règles', pt: 'Lembrete da menstruação');
  String get cyclePeriodReminderDescription => _pick(en: 'Notify before the next estimated period', it: 'Avvisa prima della prossima mestruazione stimata', es: 'Avisar antes de la próxima menstruación estimada', fr: 'Prévenir avant les prochaines règles estimées', pt: 'Avisar antes da próxima menstruação estimada');
  String get cycleDiscreetNotifications => _pick(en: 'Discreet notifications', it: 'Notifiche discrete', es: 'Notificaciones discretas', fr: 'Notifications discrètes', pt: 'Notificações discretas');
  String get cycleDiscreetNotificationsDescription => _pick(en: 'Hide cycle details from the lock screen notification text', it: 'Nasconde i dettagli del ciclo dal testo delle notifiche sulla schermata di blocco', es: 'Oculta los detalles del ciclo del texto de la notificación en la pantalla de bloqueo', fr: 'Masque les détails du cycle dans le texte de notification sur l’écran verrouillé', pt: 'Oculta os detalhes do ciclo no texto da notificação do ecrã bloqueado');
  String get cyclePrivateReminder => _pick(en: 'You have a private reminder in Anna\'s Diary.', it: 'Hai un promemoria privato in Anna\'s Diary.', es: 'Tienes un recordatorio privado en Anna\'s Diary.', fr: 'Tu as un rappel privé dans Anna\'s Diary.', pt: 'Tens um lembrete privado no Anna\'s Diary.');
  String get cyclePeriodReminderBody => _pick(en: 'Your next period is expected soon.', it: 'La prossima mestruazione è prevista a breve.', es: 'Se espera tu próxima menstruación pronto.', fr: 'Tes prochaines règles sont prévues bientôt.', pt: 'A tua próxima menstruação está prevista para breve.');
  String get cycleFlow => _pick(en: 'Flow', it: 'Flusso', es: 'Flujo', fr: 'Flux', pt: 'Fluxo');
  String get cycleFlowNone => _pick(en: 'None', it: 'Nessuno', es: 'Ninguno', fr: 'Aucun', pt: 'Nenhum');
  String get cycleFlowSpotting => _pick(en: 'Spotting', it: 'Spotting', es: 'Manchado', fr: 'Spotting', pt: 'Spotting');
  String get cycleFlowLight => _pick(en: 'Light', it: 'Leggero', es: 'Ligero', fr: 'Léger', pt: 'Ligeiro');
  String get cycleFlowMedium => _pick(en: 'Medium', it: 'Medio', es: 'Medio', fr: 'Moyen', pt: 'Médio');
  String get cycleFlowHeavy => _pick(en: 'Heavy', it: 'Abbondante', es: 'Abundante', fr: 'Abondant', pt: 'Abundante');
  String get cyclePain => _pick(en: 'Pain / cramps', it: 'Dolore / crampi', es: 'Dolor / cólicos', fr: 'Douleur / crampes', pt: 'Dor / cólicas');
  String get cycleEnergy => _pick(en: 'Energy', it: 'Energia', es: 'Energía', fr: 'Énergie', pt: 'Energia');
  String get cycleSymptoms => _pick(en: 'Symptoms', it: 'Sintomi', es: 'Síntomas', fr: 'Symptômes', pt: 'Sintomas');
  String get cycleMood => _pick(en: 'Mood', it: 'Umore', es: 'Estado de ánimo', fr: 'Humeur', pt: 'Humor');
  String get cycleNotes => _pick(en: 'Private notes', it: 'Note private', es: 'Notas privadas', fr: 'Notes privées', pt: 'Notas privadas');
  String get cycleDaySaved => _pick(en: 'Private day log saved', it: 'Giornata privata registrata', es: 'Registro privado guardado', fr: 'Journée privée enregistrée', pt: 'Registo privado guardado');
  String get cyclePhasePeriod => _pick(en: 'Menstrual phase', it: 'Fase mestruale', es: 'Fase menstrual', fr: 'Phase menstruelle', pt: 'Fase menstrual');
  String get cyclePhaseFollicular => _pick(en: 'Follicular phase', it: 'Fase follicolare', es: 'Fase folicular', fr: 'Phase folliculaire', pt: 'Fase folicular');
  String get cyclePhaseFertile => _pick(en: 'Estimated fertile window', it: 'Finestra fertile stimata', es: 'Ventana fértil estimada', fr: 'Fenêtre fertile estimée', pt: 'Janela fértil estimada');
  String get cyclePhaseOvulation => _pick(en: 'Estimated ovulation', it: 'Ovulazione stimata', es: 'Ovulación estimada', fr: 'Ovulation estimée', pt: 'Ovulação estimada');
  String get cyclePhaseLuteal => _pick(en: 'Luteal phase', it: 'Fase luteale', es: 'Fase lútea', fr: 'Phase lutéale', pt: 'Fase lútea');
  String get cyclePhaseUnknown => _pick(en: 'Add more data for an estimate', it: 'Aggiungi dati per ottenere una stima', es: 'Añade más datos para obtener una estimación', fr: 'Ajoute des données pour obtenir une estimation', pt: 'Adiciona mais dados para obter uma estimativa');
  String get cycleSymptomCramps => _pick(en: 'Cramps', it: 'Crampi', es: 'Cólicos', fr: 'Crampes', pt: 'Cólicas');
  String get cycleSymptomBloating => _pick(en: 'Bloating', it: 'Gonfiore', es: 'Hinchazón', fr: 'Ballonnements', pt: 'Inchaço');
  String get cycleSymptomHeadache => _pick(en: 'Headache', it: 'Mal di testa', es: 'Dolor de cabeza', fr: 'Mal de tête', pt: 'Dor de cabeça');
  String get cycleSymptomBreast => _pick(en: 'Breast tenderness', it: 'Seno sensibile', es: 'Sensibilidad mamaria', fr: 'Seins sensibles', pt: 'Sensibilidade mamária');
  String get cycleSymptomFatigue => _pick(en: 'Fatigue', it: 'Stanchezza', es: 'Cansancio', fr: 'Fatigue', pt: 'Cansaço');
  String get cycleSymptomAcne => _pick(en: 'Acne', it: 'Acne', es: 'Acné', fr: 'Acné', pt: 'Acne');
  String get cycleSymptomNausea => _pick(en: 'Nausea', it: 'Nausea', es: 'Náuseas', fr: 'Nausées', pt: 'Náusea');
  String get cycleSymptomBackPain => _pick(en: 'Back pain', it: 'Mal di schiena', es: 'Dolor de espalda', fr: 'Mal de dos', pt: 'Dor nas costas');
  String get cycleMoodCalm => _pick(en: 'Calm', it: 'Tranquilla', es: 'Tranquila', fr: 'Calme', pt: 'Calma');
  String get cycleMoodHappy => _pick(en: 'Happy', it: 'Felice', es: 'Feliz', fr: 'Heureuse', pt: 'Feliz');
  String get cycleMoodSensitive => _pick(en: 'Sensitive', it: 'Sensibile', es: 'Sensible', fr: 'Sensible', pt: 'Sensível');
  String get cycleMoodIrritable => _pick(en: 'Irritable', it: 'Irritabile', es: 'Irritable', fr: 'Irritable', pt: 'Irritável');
  String get cycleMoodSad => _pick(en: 'Sad', it: 'Triste', es: 'Triste', fr: 'Triste', pt: 'Triste');
  String get cycleMoodAnxious => _pick(en: 'Anxious', it: 'Ansiosa', es: 'Ansiosa', fr: 'Anxieuse', pt: 'Ansiosa');
  String get cycleMoodEnergetic => _pick(en: 'Energetic', it: 'Energica', es: 'Enérgica', fr: 'Énergique', pt: 'Energética');

  String get cycleInsights => _pick(en: 'Insights', it: 'Analisi', es: 'Análisis', fr: 'Analyses', pt: 'Análises');
  String get cyclePremiumPreviewDescription => _pick(en: 'Premium cycle features are enabled in preview mode while the app-wide purchase system is prepared.', it: 'Le funzioni Premium del ciclo sono attive in modalità anteprima mentre viene preparato il sistema di acquisto globale dell’app.', es: 'Las funciones Premium del ciclo están activas en modo de vista previa mientras se prepara el sistema de compra global de la app.', fr: 'Les fonctions Premium du cycle sont activées en mode aperçu pendant la préparation du système d’achat global de l’app.', pt: 'As funções Premium do ciclo estão ativas em modo de pré-visualização enquanto é preparado o sistema de compra global da app.');
  String get cyclePremiumPreviewShort => _pick(en: 'Premium preview', it: 'Anteprima Premium', es: 'Vista previa Premium', fr: 'Aperçu Premium', pt: 'Pré-visualização Premium');
  String get cycleInsightsTitle => _pick(en: 'Patterns and trends', it: 'Pattern e tendenze', es: 'Patrones y tendencias', fr: 'Tendances et schémas', pt: 'Padrões e tendências');
  String get cycleLoggedDays => _pick(en: 'Logged days', it: 'Giorni registrati', es: 'Días registrados', fr: 'Jours enregistrés', pt: 'Dias registados');
  String get cycleRecordedCycles => _pick(en: 'Recorded cycles', it: 'Cicli registrati', es: 'Ciclos registrados', fr: 'Cycles enregistrés', pt: 'Ciclos registados');
  String get cycleEstimatedWindow => _pick(en: 'Estimated window', it: 'Finestra stimata', es: 'Ventana estimada', fr: 'Fenêtre estimée', pt: 'Janela estimada');
  String get cycleVariability => _pick(en: 'Cycle range', it: 'Intervallo cicli', es: 'Rango del ciclo', fr: 'Plage des cycles', pt: 'Intervalo dos ciclos');
  String cycleRangeDays(int min, int max) => _pick(en: '$min–$max days', it: '$min–$max giorni', es: '$min–$max días', fr: '$min–$max jours', pt: '$min–$max dias');
  String get cycleSymptomPatterns => _pick(en: 'Symptom patterns', it: 'Pattern dei sintomi', es: 'Patrones de síntomas', fr: 'Schémas des symptômes', pt: 'Padrões de sintomas');
  String get cycleNotEnoughInsightData => _pick(en: 'Add more logs to reveal a pattern.', it: 'Aggiungi altri dati per evidenziare un pattern.', es: 'Añade más registros para mostrar un patrón.', fr: 'Ajoute plus de données pour faire apparaître un schéma.', pt: 'Adiciona mais registos para revelar um padrão.');
  String cycleSymptomPatternDetail(int total, int period) => _pick(en: '$total logged · $period during menstrual-flow days', it: '$total registrazioni · $period nei giorni con flusso mestruale', es: '$total registros · $period durante días con flujo menstrual', fr: '$total enregistrements · $period pendant les jours de flux menstruel', pt: '$total registos · $period durante dias com fluxo menstrual');
  String get cycleFertilityObservations => _pick(en: 'Fertility observations', it: 'Osservazioni fertilità', es: 'Observaciones de fertilidad', fr: 'Observations de fertilité', pt: 'Observações de fertilidade');
  String get cycleBasalTemperature => _pick(en: 'Basal temperature', it: 'Temperatura basale', es: 'Temperatura basal', fr: 'Température basale', pt: 'Temperatura basal');
  String get cycleOvulationTests => _pick(en: 'Positive ovulation tests', it: 'Test ovulazione positivi', es: 'Tests de ovulación positivos', fr: 'Tests d’ovulation positifs', pt: 'Testes de ovulação positivos');
  String get cycleOvulationTest => _pick(en: 'Ovulation test', it: 'Test ovulazione', es: 'Test de ovulación', fr: 'Test d’ovulation', pt: 'Teste de ovulação');
  String get cycleCervicalMucus => _pick(en: 'Cervical mucus', it: 'Muco cervicale', es: 'Moco cervical', fr: 'Glaire cervicale', pt: 'Muco cervical');
  String get cycleSexualActivity => _pick(en: 'Sexual activity', it: 'Attività sessuale', es: 'Actividad sexual', fr: 'Activité sexuelle', pt: 'Atividade sexual');
  String get cycleCopyPrivateReport => _pick(en: 'Copy private report', it: 'Copia report privato', es: 'Copiar informe privado', fr: 'Copier le rapport privé', pt: 'Copiar relatório privado');
  String get cyclePrivateReportTitle => _pick(en: 'Anna\'s Diary · Private cycle report', it: 'Anna\'s Diary · Report privato del ciclo', es: 'Anna\'s Diary · Informe privado del ciclo', fr: 'Anna\'s Diary · Rapport privé du cycle', pt: 'Anna\'s Diary · Relatório privado do ciclo');
  String get cyclePrivateReportCopied => _pick(en: 'Private report copied. The clipboard will clear automatically.', it: 'Report privato copiato. Gli appunti verranno svuotati automaticamente.', es: 'Informe privado copiado. El portapapeles se borrará automáticamente.', fr: 'Rapport privé copié. Le presse-papiers sera effacé automatiquement.', pt: 'Relatório privado copiado. A área de transferência será limpa automaticamente.');
  String get cycleInsightsDisclaimer => _pick(en: 'These are descriptive patterns from your own logs, not diagnoses, causes or medical recommendations.', it: 'Questi sono pattern descrittivi ricavati dai tuoi dati, non diagnosi, cause o raccomandazioni mediche.', es: 'Estos son patrones descriptivos de tus propios registros, no diagnósticos, causas ni recomendaciones médicas.', fr: 'Il s’agit de tendances descriptives issues de tes propres données, et non de diagnostics, causes ou recommandations médicales.', pt: 'Estes são padrões descritivos dos teus próprios registos, não diagnósticos, causas ou recomendações médicas.');
  String get cyclePremiumFeature => _pick(en: 'Premium feature', it: 'Funzione Premium', es: 'Función Premium', fr: 'Fonction Premium', pt: 'Função Premium');
  String cyclePremiumFeatureDescription(String feature) => _pick(en: '$feature belongs to the Premium cycle layer.', it: '$feature fa parte del livello Premium del ciclo.', es: '$feature forma parte del nivel Premium del ciclo.', fr: '$feature fait partie du niveau Premium du cycle.', pt: '$feature faz parte do nível Premium do ciclo.');
  String get cycleAdvancedTracking => _pick(en: 'Advanced tracking', it: 'Tracciamento avanzato', es: 'Seguimiento avanzado', fr: 'Suivi avancé', pt: 'Acompanhamento avançado');
  String get cycleAdvancedDailyTracking => _pick(en: 'Advanced daily tracking', it: 'Tracciamento giornaliero avanzato', es: 'Seguimiento diario avanzado', fr: 'Suivi quotidien avancé', pt: 'Acompanhamento diário avançado');
  String get cycleCustomSymptoms => _pick(en: 'Custom symptoms', it: 'Sintomi personalizzati', es: 'Síntomas personalizados', fr: 'Symptômes personnalisés', pt: 'Sintomas personalizados');
  String get cycleCustomSymptomsDescription => _pick(en: 'Add up to 12 private labels that fit your own tracking needs.', it: 'Aggiungi fino a 12 etichette private adatte alle tue esigenze di monitoraggio.', es: 'Añade hasta 12 etiquetas privadas adaptadas a tus necesidades de seguimiento.', fr: 'Ajoute jusqu’à 12 libellés privés adaptés à tes besoins de suivi.', pt: 'Adiciona até 12 etiquetas privadas adequadas às tuas necessidades de acompanhamento.');
  String get cycleAddCustomSymptom => _pick(en: 'Add custom symptom', it: 'Aggiungi sintomo personalizzato', es: 'Añadir síntoma personalizado', fr: 'Ajouter un symptôme personnalisé', pt: 'Adicionar sintoma personalizado');
  String get cycleCustomSymptomName => _pick(en: 'Symptom name', it: 'Nome sintomo', es: 'Nombre del síntoma', fr: 'Nom du symptôme', pt: 'Nome do sintoma');
  String get cycleObservationNone => _pick(en: 'Not recorded', it: 'Non registrato', es: 'No registrado', fr: 'Non enregistré', pt: 'Não registado');
  String get cycleTestNegative => _pick(en: 'Negative', it: 'Negativo', es: 'Negativo', fr: 'Négatif', pt: 'Negativo');
  String get cycleTestPositive => _pick(en: 'Positive', it: 'Positivo', es: 'Positivo', fr: 'Positif', pt: 'Positivo');
  String get cycleMucusDry => _pick(en: 'Dry', it: 'Secco', es: 'Seco', fr: 'Sec', pt: 'Seco');
  String get cycleMucusSticky => _pick(en: 'Sticky', it: 'Appiccicoso', es: 'Pegajoso', fr: 'Collant', pt: 'Pegajoso');
  String get cycleMucusCreamy => _pick(en: 'Creamy', it: 'Cremoso', es: 'Cremoso', fr: 'Crémeux', pt: 'Cremoso');
  String get cycleMucusWatery => _pick(en: 'Watery', it: 'Acquoso', es: 'Acuoso', fr: 'Aqueux', pt: 'Aquoso');
  String get cycleMucusEggWhite => _pick(en: 'Egg-white like', it: 'Tipo albume', es: 'Tipo clara de huevo', fr: 'Type blanc d’œuf', pt: 'Tipo clara de ovo');

  String get cycleOnboardingTitle => _pick(en: 'Set up your cycle', it: 'Imposta il tuo ciclo', es: 'Configura tu ciclo', fr: 'Configure ton cycle', pt: 'Configura o teu ciclo');
  String get cycleOnboardingDescription => _pick(en: 'A few private details are enough to start the calendar and improve estimates. You can change everything later.', it: 'Bastano pochi dati privati per iniziare il calendario e migliorare le stime. Potrai modificare tutto in seguito.', es: 'Bastan unos pocos datos privados para empezar el calendario y mejorar las estimaciones. Podrás cambiarlo todo más tarde.', fr: 'Quelques informations privées suffisent pour démarrer le calendrier et améliorer les estimations. Tu pourras tout modifier ensuite.', pt: 'Alguns dados privados são suficientes para iniciar o calendário e melhorar as estimativas. Podes alterar tudo mais tarde.');
  String get cycleLastPeriodStart => _pick(en: 'First day of the last period', it: 'Primo giorno dell’ultima mestruazione', es: 'Primer día de la última menstruación', fr: 'Premier jour des dernières règles', pt: 'Primeiro dia da última menstruação');
  String get cycleRegularity => _pick(en: 'Cycle regularity', it: 'Regolarità del ciclo', es: 'Regularidad del ciclo', fr: 'Régularité du cycle', pt: 'Regularidade do ciclo');
  String get cycleRegularityUnknown => _pick(en: 'Not sure yet', it: 'Non lo so ancora', es: 'Aún no lo sé', fr: 'Je ne sais pas encore', pt: 'Ainda não sei');
  String get cycleRegularityRegular => _pick(en: 'Usually regular', it: 'Di solito regolare', es: 'Normalmente regular', fr: 'Habituellement régulier', pt: 'Normalmente regular');
  String get cycleRegularityIrregular => _pick(en: 'Often irregular', it: 'Spesso irregolare', es: 'A menudo irregular', fr: 'Souvent irrégulier', pt: 'Frequentemente irregular');
  String get cycleOnboardingStart => _pick(en: 'Start my private calendar', it: 'Inizia il mio calendario privato', es: 'Iniciar mi calendario privado', fr: 'Commencer mon calendrier privé', pt: 'Iniciar o meu calendário privado');
  String get cycleOnboardingSkip => _pick(en: 'Set up later', it: 'Configura più tardi', es: 'Configurar más tarde', fr: 'Configurer plus tard', pt: 'Configurar mais tarde');
  String get cycleQuickPeriodAction => _pick(en: 'Log period', it: 'Segna ciclo', es: 'Registrar periodo', fr: 'Noter les règles', pt: 'Registar menstruação');
  String get cycleQuickPeriodTitle => _pick(en: 'Log a period range', it: 'Registra intervallo mestruale', es: 'Registrar intervalo menstrual', fr: 'Enregistrer une période de règles', pt: 'Registar intervalo menstrual');
  String get cycleQuickPeriodDescription => _pick(en: 'The selected days are stored as menstrual-flow days in the encrypted Vault. Existing symptoms and notes on those days are preserved.', it: 'I giorni selezionati vengono salvati come giorni di flusso mestruale nella Cassaforte cifrata. Sintomi e note già presenti restano invariati.', es: 'Los días seleccionados se guardan como días de flujo menstrual en la Caja fuerte cifrada. Los síntomas y notas existentes se conservan.', fr: 'Les jours sélectionnés sont enregistrés comme jours de flux menstruel dans le Coffre chiffré. Les symptômes et notes existants sont conservés.', pt: 'Os dias selecionados são guardados como dias de fluxo menstrual no Cofre cifrado. Os sintomas e notas existentes são preservados.');
  String get cyclePeriodStart => _pick(en: 'Period start', it: 'Inizio mestruazione', es: 'Inicio de la menstruación', fr: 'Début des règles', pt: 'Início da menstruação');
  String get cyclePeriodEnd => _pick(en: 'Period end', it: 'Fine mestruazione', es: 'Fin de la menstruación', fr: 'Fin des règles', pt: 'Fim da menstruação');
  String cyclePredictionConfidenceLabel(String value) => _pick(en: 'Estimate confidence: $value', it: 'Affidabilità stima: $value', es: 'Confianza de la estimación: $value', fr: 'Fiabilité de l’estimation : $value', pt: 'Confiança da estimativa: $value');
  String get cycleConfidenceLow => _pick(en: 'low', it: 'bassa', es: 'baja', fr: 'faible', pt: 'baixa');
  String get cycleConfidenceMedium => _pick(en: 'medium', it: 'media', es: 'media', fr: 'moyenne', pt: 'média');
  String get cycleConfidenceHigh => _pick(en: 'high', it: 'alta', es: 'alta', fr: 'élevée', pt: 'alta');
  String get cycleEstimatedOvulation => _pick(en: 'Estimated ovulation', it: 'Ovulazione stimata', es: 'Ovulación estimada', fr: 'Ovulation estimée', pt: 'Ovulação estimada');
  String get cycleSymptomsOrNotes => _pick(en: 'Symptoms / notes', it: 'Sintomi / note', es: 'Síntomas / notas', fr: 'Symptômes / notes', pt: 'Sintomas / notas');
  String get cycleDailyLogReminder => _pick(en: 'Daily private check-in', it: 'Check-in privato giornaliero', es: 'Registro privado diario', fr: 'Suivi privé quotidien', pt: 'Registo privado diário');
  String get cycleDailyLogReminderDescription => _pick(en: 'A daily reminder to log symptoms, mood or flow.', it: 'Un promemoria giornaliero per registrare sintomi, umore o flusso.', es: 'Un recordatorio diario para registrar síntomas, estado de ánimo o flujo.', fr: 'Un rappel quotidien pour noter symptômes, humeur ou flux.', pt: 'Um lembrete diário para registar sintomas, humor ou fluxo.');
  String get cycleDailyLogReminderBody => _pick(en: 'Take a moment to update your private cycle log.', it: 'Prenditi un momento per aggiornare il tuo diario privato del ciclo.', es: 'Dedica un momento a actualizar tu registro privado del ciclo.', fr: 'Prends un moment pour mettre à jour ton suivi privé du cycle.', pt: 'Reserva um momento para atualizar o teu registo privado do ciclo.');
  String get cycleContraceptiveReminder => _pick(en: 'Contraceptive reminder', it: 'Promemoria contraccettivo', es: 'Recordatorio anticonceptivo', fr: 'Rappel contraceptif', pt: 'Lembrete contracetivo');
  String get cycleContraceptiveReminderDescription => _pick(en: 'Optional daily reminder. No medication name is stored or shown by default.', it: 'Promemoria giornaliero opzionale. Nessun nome di farmaco viene salvato o mostrato di default.', es: 'Recordatorio diario opcional. No se guarda ni muestra ningún nombre de medicamento por defecto.', fr: 'Rappel quotidien facultatif. Aucun nom de médicament n’est enregistré ni affiché par défaut.', pt: 'Lembrete diário opcional. Nenhum nome de medicamento é guardado ou mostrado por defeito.');
  String get cycleContraceptiveReminderBody => _pick(en: 'This is your contraceptive reminder.', it: 'Questo è il tuo promemoria contraccettivo.', es: 'Este es tu recordatorio anticonceptivo.', fr: 'Ceci est ton rappel contraceptif.', pt: 'Este é o teu lembrete contracetivo.');
  String get cycleReminderTime => _pick(en: 'Reminder time', it: 'Ora del promemoria', es: 'Hora del recordatorio', fr: 'Heure du rappel', pt: 'Hora do lembrete');

  String get cycleLengthTrend => _pick(en: 'Recent cycle length', it: 'Durata dei cicli recenti', es: 'Duración de ciclos recientes', fr: 'Durée des cycles récents', pt: 'Duração dos ciclos recentes');
  String get cycleTopSymptomsChart => _pick(en: 'Most recorded symptoms', it: 'Sintomi più registrati', es: 'Síntomas más registrados', fr: 'Symptômes les plus enregistrés', pt: 'Sintomas mais registados');

  String get sharedPasswords => _pick(en: 'Shared passwords', it: 'Password Noi ♡', es: 'Contraseñas compartidas', fr: 'Mots de passe partagés', pt: 'Palavras-passe partilhadas');
  String get sharedPasswordNew => _pick(en: 'New shared password', it: 'Nuova password condivisa', es: 'Nueva contraseña compartida', fr: 'Nouveau mot de passe partagé', pt: 'Nova palavra-passe partilhada');
  String get sharedPasswordEdit => _pick(en: 'Edit shared password', it: 'Modifica password condivisa', es: 'Editar contraseña compartida', fr: 'Modifier le mot de passe partagé', pt: 'Editar palavra-passe partilhada');
  String get sharedPasswordsConnect => _pick(en: 'Connect shared passwords', it: 'Collega le password condivise', es: 'Conectar contraseñas compartidas', fr: 'Connecter les mots de passe partagés', pt: 'Ligar palavras-passe partilhadas');
  String get sharedPasswordsConnectDescription => _pick(en: 'This device is already a Noi ♡ member but does not have the password key. Enter the E2EE code generated by the owner.', it: 'Questo dispositivo è già membro di Noi ♡, ma non possiede la chiave delle password. Inserisci il codice E2EE generato dal proprietario.', es: 'Este dispositivo ya pertenece a Noi ♡, pero no tiene la clave de contraseñas. Introduce el código E2EE generado por el propietario.', fr: 'Cet appareil appartient déjà à Noi ♡ mais ne possède pas la clé des mots de passe. Saisis le code E2EE généré par le propriétaire.', pt: 'Este dispositivo já pertence a Noi ♡, mas não possui a chave das palavras-passe. Introduz o código E2EE gerado pelo proprietário.');
  String get sharedPasswordsSecurityCode => _pick(en: 'Security code', it: 'Codice di sicurezza', es: 'Código de seguridad', fr: 'Code de sécurité', pt: 'Código de segurança');
  String get sharedPasswordsEnterCode => _pick(en: 'Enter code', it: 'Inserisci codice', es: 'Introducir código', fr: 'Saisir le code', pt: 'Introduzir código');
  String get sharedPasswordsPairingTitle => _pick(en: 'Noi ♡ password code', it: 'Codice Password Noi ♡', es: 'Código de contraseñas Noi ♡', fr: 'Code des mots de passe Noi ♡', pt: 'Código de palavras-passe Noi ♡');
  String get sharedPasswordsPairingDescription => _pick(en: 'Share it only with someone who is already a Noi ♡ member. It expires after 15 minutes and is invalidated after the first successful use.', it: 'Condividilo solo con una persona già membro di Noi ♡. Scade dopo 15 minuti e viene invalidato al primo utilizzo riuscito.', es: 'Compártelo solo con alguien que ya sea miembro de Noi ♡. Caduca después de 15 minutos y se invalida tras el primer uso correcto.', fr: 'Partage-le uniquement avec une personne déjà membre de Noi ♡. Il expire après 15 minutes et est invalidé après la première utilisation réussie.', pt: 'Partilha-o apenas com alguém que já seja membro de Noi ♡. Expira após 15 minutos e é invalidado após a primeira utilização bem-sucedida.');
  String get sharedPasswordsCopyCode => _pick(en: 'Copy code', it: 'Copia codice', es: 'Copiar código', fr: 'Copier le code', pt: 'Copiar código');
  String get sharedPasswordsE2eeBanner => _pick(en: 'End-to-end encrypted. Noi ♡ is authoritative: changes and deletions are also reflected in the private Vault.', it: 'Cifrate end-to-end. Noi ♡ è la sorgente autorevole: modifiche ed eliminazioni si riflettono anche nella Cassaforte privata.', es: 'Cifradas de extremo a extremo. Noi ♡ es la fuente autorizada: los cambios y eliminaciones también se reflejan en la Caja fuerte privada.', fr: 'Chiffrés de bout en bout. Noi ♡ est la source de référence : les modifications et suppressions sont aussi répercutées dans le Coffre privé.', pt: 'Cifradas ponta a ponta. Noi ♡ é a fonte autoritativa: alterações e eliminações também se refletem no Cofre privado.');
  String get sharedPasswordsEmpty => _pick(en: 'No shared passwords', it: 'Nessuna password condivisa', es: 'No hay contraseñas compartidas', fr: 'Aucun mot de passe partagé', pt: 'Nenhuma palavra-passe partilhada');
  String get sharedPasswordsEmptyDescription => _pick(en: 'Add a service and it will also appear in the private Vault of connected Noi ♡ devices.', it: 'Aggiungi un servizio: comparirà anche nella Cassaforte privata dei dispositivi Noi ♡ collegati.', es: 'Añade un servicio y también aparecerá en la Caja fuerte privada de los dispositivos Noi ♡ conectados.', fr: 'Ajoute un service : il apparaîtra aussi dans le Coffre privé des appareils Noi ♡ connectés.', pt: 'Adiciona um serviço: também aparecerá no Cofre privado dos dispositivos Noi ♡ ligados.');
  String get sharedPasswordsVaultRequired => _pick(en: 'Unlock the private Vault', it: 'Sblocca la Cassaforte privata', es: 'Desbloquea la Caja fuerte privada', fr: 'Déverrouille le Coffre privé', pt: 'Desbloqueia o Cofre privado');
  String get sharedPasswordsVaultDescription => _pick(en: 'Noi ♡ passwords use the Vault to store the E2EE key and the encrypted local mirror.', it: 'Le password Noi ♡ usano la Cassaforte per custodire la chiave E2EE e la copia locale cifrata.', es: 'Las contraseñas Noi ♡ usan la Caja fuerte para guardar la clave E2EE y la copia local cifrada.', fr: 'Les mots de passe Noi ♡ utilisent le Coffre pour conserver la clé E2EE et la copie locale chiffrée.', pt: 'As palavras-passe Noi ♡ usam o Cofre para guardar a chave E2EE e a cópia local cifrada.');
  String get sharedPasswordsDeleteQuestion => _pick(en: 'Delete the shared password?', it: 'Eliminare la password condivisa?', es: '¿Eliminar la contraseña compartida?', fr: 'Supprimer le mot de passe partagé ?', pt: 'Eliminar a palavra-passe partilhada?');
  String sharedPasswordsDeleteDescription(String service) => _pick(en: '“$service” will be deleted from Noi ♡ and from synchronized private Vaults.', it: '“$service” verrà eliminata da Noi ♡ e dalle Cassaforti private sincronizzate.', es: '“$service” se eliminará de Noi ♡ y de las Cajas fuertes privadas sincronizadas.', fr: '« $service » sera supprimé de Noi ♡ et des Coffres privés synchronisés.', pt: '“$service” será eliminada de Noi ♡ e dos Cofres privados sincronizados.');
  String get sharedPasswordsE2ee => _pick(en: 'End-to-end encryption', it: 'Cifratura end-to-end', es: 'Cifrado de extremo a extremo', fr: 'Chiffrement de bout en bout', pt: 'Cifragem ponta a ponta');
  String get sharedPasswordsShareKey => _pick(en: 'Share E2EE key', it: 'Condividi chiave E2EE', es: 'Compartir clave E2EE', fr: 'Partager la clé E2EE', pt: 'Partilhar chave E2EE');
  String get sharedPasswordsInvalidCode => _pick(en: 'Invalid, expired or already used code.', it: 'Codice non valido, scaduto o già usato.', es: 'Código no válido, caducado o ya utilizado.', fr: 'Code invalide, expiré ou déjà utilisé.', pt: 'Código inválido, expirado ou já utilizado.');
  String get sharedPasswordsKeyUnavailable => _pick(en: 'Could not generate the security code.', it: 'Impossibile generare il codice di sicurezza.', es: 'No se pudo generar el código de seguridad.', fr: 'Impossible de générer le code de sécurité.', pt: 'Não foi possível gerar o código de segurança.');
  String get sharedPasswordsPairingInputDescription => _pick(en: 'Enter the security code generated by the owner. It is needed only once to receive the E2EE key.', it: 'Inserisci il codice di sicurezza generato dal proprietario. Serve una sola volta per ricevere la chiave E2EE.', es: 'Introduce el código de seguridad generado por el propietario. Solo se necesita una vez para recibir la clave E2EE.', fr: 'Saisis le code de sécurité généré par le propriétaire. Il ne sert qu’une fois pour recevoir la clé E2EE.', pt: 'Introduz o código de segurança gerado pelo proprietário. Só é necessário uma vez para receber a chave E2EE.');
  String get sharedPasswordsCodeCopied => _pick(en: 'Code copied to the clipboard.', it: 'Codice copiato negli appunti.', es: 'Código copiado al portapapeles.', fr: 'Code copié dans le presse-papiers.', pt: 'Código copiado para a área de transferência.');
  String get sharedPasswordsSaveFailed => _pick(en: 'Save failed. Check the connection.', it: 'Salvataggio non riuscito. Controlla la connessione.', es: 'No se pudo guardar. Comprueba la conexión.', fr: 'Échec de l’enregistrement. Vérifie la connexion.', pt: 'Falha ao guardar. Verifica a ligação.');
  String get sharedPasswordsDeleteFailed => _pick(en: 'Deletion failed. Check the connection.', it: 'Eliminazione non riuscita. Controlla la connessione.', es: 'No se pudo eliminar. Comprueba la conexión.', fr: 'Échec de la suppression. Vérifie la connexion.', pt: 'Falha ao eliminar. Verifica a ligação.');
  String get sharedPasswordsConflict => _pick(en: 'This password changed on another device. The latest version has been reloaded; review it before saving again.', it: 'Questa password è cambiata su un altro dispositivo. Ho ricaricato la versione più recente: controllala prima di salvare di nuovo.', es: 'Esta contraseña cambió en otro dispositivo. Se ha recargado la versión más reciente; revísala antes de volver a guardar.', fr: 'Ce mot de passe a changé sur un autre appareil. La version la plus récente a été rechargée ; vérifie-la avant d’enregistrer à nouveau.', pt: 'Esta palavra-passe mudou noutro dispositivo. A versão mais recente foi recarregada; revê-a antes de guardar novamente.');
  String get sharedPasswordsRecoveryBackup => _pick(en: 'Recovery backup', it: 'Backup di recupero', es: 'Copia de recuperación', fr: 'Sauvegarde de récupération', pt: 'Backup de recuperação');
  String get sharedPasswordsRecoveryDescription => _pick(en: 'Create an encrypted recovery package for the Noi ♡ password key. Store it outside the app and keep its recovery password separate.', it: 'Crea un pacchetto di recupero cifrato per la chiave Password Noi ♡. Conservalo fuori dall’app e tieni separata la password di recupero.', es: 'Crea un paquete de recuperación cifrado para la clave de contraseñas Noi ♡. Guárdalo fuera de la app y mantén separada su contraseña.', fr: 'Crée un paquet de récupération chiffré pour la clé des mots de passe Noi ♡. Conserve-le hors de l’app et garde son mot de passe séparément.', pt: 'Cria um pacote de recuperação cifrado para a chave das palavras-passe Noi ♡. Guarda-o fora da app e mantém a palavra-passe de recuperação separada.');
  String get sharedPasswordsRecoveryPassword => _pick(en: 'Recovery password', it: 'Password di recupero', es: 'Contraseña de recuperación', fr: 'Mot de passe de récupération', pt: 'Palavra-passe de recuperação');
  String get sharedPasswordsRecoveryPackage => _pick(en: 'Recovery package', it: 'Pacchetto di recupero', es: 'Paquete de recuperación', fr: 'Paquet de récupération', pt: 'Pacote de recuperação');
  String get sharedPasswordsCreateRecovery => _pick(en: 'Create recovery backup', it: 'Crea backup di recupero', es: 'Crear copia de recuperación', fr: 'Créer la sauvegarde de récupération', pt: 'Criar backup de recuperação');
  String get sharedPasswordsImportRecovery => _pick(en: 'Import recovery backup', it: 'Importa backup di recupero', es: 'Importar copia de recuperación', fr: 'Importer la sauvegarde de récupération', pt: 'Importar backup de recuperação');
  String get sharedPasswordsRecoveryInvalid => _pick(en: 'Recovery package or password is invalid.', it: 'Pacchetto di recupero o password non validi.', es: 'El paquete o la contraseña de recuperación no son válidos.', fr: 'Le paquet ou le mot de passe de récupération est invalide.', pt: 'O pacote ou a palavra-passe de recuperação são inválidos.');
  String get sharedPasswordsRecoveryCopied => _pick(en: 'Recovery package copied. Store it in a safe place.', it: 'Pacchetto di recupero copiato. Conservalo in un luogo sicuro.', es: 'Paquete de recuperación copiado. Guárdalo en un lugar seguro.', fr: 'Paquet de récupération copié. Conserve-le dans un endroit sûr.', pt: 'Pacote de recuperação copiado. Guarda-o num local seguro.');


  String startTab(StartTab tab) => switch (tab) {
        StartTab.home => navHome,
        StartTab.month => navMonth,
        StartTab.week => navWeek,
        StartTab.today => navToday,
      };
}
