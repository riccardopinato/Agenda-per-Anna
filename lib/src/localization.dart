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

  String startTab(StartTab tab) => switch (tab) {
        StartTab.home => navHome,
        StartTab.month => navMonth,
        StartTab.week => navWeek,
        StartTab.today => navToday,
      };
}
