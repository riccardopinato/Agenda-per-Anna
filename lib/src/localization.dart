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

  String startTab(StartTab tab) => switch (tab) {
        StartTab.home => navHome,
        StartTab.month => navMonth,
        StartTab.week => navWeek,
        StartTab.today => navToday,
      };
}
