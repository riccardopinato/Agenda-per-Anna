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

  String startTab(StartTab tab) => switch (tab) {
        StartTab.home => navHome,
        StartTab.month => navMonth,
        StartTab.week => navWeek,
        StartTab.today => navToday,
      };
}
