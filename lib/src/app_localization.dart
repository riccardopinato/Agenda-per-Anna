part of '../main.dart';

enum AppLanguage {
  system,
  italian,
  english,
  spanish,
  french,
  german,
  portuguese,
}

extension AppLanguageUi on AppLanguage {
  String get nativeLabel => switch (this) {
        AppLanguage.system => 'Sistema / Automatico',
        AppLanguage.italian => 'Italiano',
        AppLanguage.english => 'English',
        AppLanguage.spanish => 'Español',
        AppLanguage.french => 'Français',
        AppLanguage.german => 'Deutsch',
        AppLanguage.portuguese => 'Português',
      };

  String? get languageCode => switch (this) {
        AppLanguage.system => null,
        AppLanguage.italian => 'it',
        AppLanguage.english => 'en',
        AppLanguage.spanish => 'es',
        AppLanguage.french => 'fr',
        AppLanguage.german => 'de',
        AppLanguage.portuguese => 'pt',
      };

  Locale? get locale {
    final code = languageCode;
    return code == null ? null : Locale(code);
  }
}

class AgendaLocalization {
  AgendaLocalization._();

  static const supportedLocales = <Locale>[
    Locale('it'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('de'),
    Locale('pt'),
  ];

  static const localeNames = <String>[
    'it_IT',
    'en_US',
    'es_ES',
    'fr_FR',
    'de_DE',
    'pt_PT',
  ];

  static Locale resolveLocale(Locale? requested) {
    if (requested == null) return const Locale('en');
    final code = requested.languageCode.toLowerCase();
    for (final locale in supportedLocales) {
      if (locale.languageCode == code) return locale;
    }
    return const Locale('en');
  }

  static Locale resolvedForPreference(
    AppLanguage language,
    Locale systemLocale,
  ) =>
      language.locale ?? resolveLocale(systemLocale);

  static String intlLocaleName(Locale locale) => switch (locale.languageCode) {
        'it' => 'it_IT',
        'en' => 'en_US',
        'es' => 'es_ES',
        'fr' => 'fr_FR',
        'de' => 'de_DE',
        'pt' => 'pt_PT',
        _ => 'en_US',
      };

  static void applyIntlLocale(
    AppLanguage language,
    Locale systemLocale,
  ) {
    Intl.defaultLocale =
        intlLocaleName(resolvedForPreference(language, systemLocale));
  }

  static String text(BuildContext context, String key) {
    final code = Localizations.localeOf(context).languageCode;
    final table = _strings[key];
    if (table == null) return key;
    return table[code] ?? table['en'] ?? table['it'] ?? key;
  }

  static const Map<String, Map<String, String>> _strings = {
    'nav.home': {
      'it': 'Home', 'en': 'Home', 'es': 'Inicio', 'fr': 'Accueil',
      'de': 'Start', 'pt': 'Início',
    },
    'nav.month': {
      'it': 'Mese', 'en': 'Month', 'es': 'Mes', 'fr': 'Mois',
      'de': 'Monat', 'pt': 'Mês',
    },
    'nav.week': {
      'it': 'Settimana', 'en': 'Week', 'es': 'Semana', 'fr': 'Semaine',
      'de': 'Woche', 'pt': 'Semana',
    },
    'nav.today': {
      'it': 'Oggi', 'en': 'Today', 'es': 'Hoy', 'fr': 'Aujourd’hui',
      'de': 'Heute', 'pt': 'Hoje',
    },
    'home.add': {
      'it': 'Aggiungi', 'en': 'Add', 'es': 'Añadir', 'fr': 'Ajouter',
      'de': 'Hinzufügen', 'pt': 'Adicionar',
    },
    'home.search': {
      'it': 'Cerca', 'en': 'Search', 'es': 'Buscar', 'fr': 'Rechercher',
      'de': 'Suchen', 'pt': 'Pesquisar',
    },
    'home.archive': {
      'it': 'Archivio', 'en': 'Archive', 'es': 'Archivo', 'fr': 'Archive',
      'de': 'Archiv', 'pt': 'Arquivo',
    },
    'home.backup': {
      'it': 'Backup', 'en': 'Backup', 'es': 'Copia', 'fr': 'Sauvegarde',
      'de': 'Backup', 'pt': 'Backup',
    },
    'home.settings': {
      'it': 'Impostazioni', 'en': 'Settings', 'es': 'Ajustes',
      'fr': 'Réglages', 'de': 'Einstellungen', 'pt': 'Definições',
    },
    'home.myAgenda': {
      'it': 'La mia agenda', 'en': 'My agenda', 'es': 'Mi agenda',
      'fr': 'Mon agenda', 'de': 'Mein Planer', 'pt': 'A minha agenda',
    },
    'home.agendaFor': {
      'it': 'Agenda per', 'en': 'Agenda for', 'es': 'Agenda de',
      'fr': 'Agenda de', 'de': 'Planer für', 'pt': 'Agenda de',
    },
    'onboarding.title': {
      'it': 'La tua agenda, davvero tua.',
      'en': 'Your agenda, truly yours.',
      'es': 'Tu agenda, realmente tuya.',
      'fr': 'Votre agenda, vraiment le vôtre.',
      'de': 'Dein Planer, wirklich deiner.',
      'pt': 'A tua agenda, verdadeiramente tua.',
    },
    'onboarding.body': {
      'it': 'Appuntamenti, diario, abitudini, idee e ricordi in un unico posto. L’app salva prima sul dispositivo e usa il tuo account per sincronizzare automaticamente agenda e Noi ♡.',
      'en': 'Appointments, diary, habits, ideas and memories in one place. The app saves on your device first and uses your account to sync your agenda and Noi ♡.',
      'es': 'Citas, diario, hábitos, ideas y recuerdos en un solo lugar.',
      'fr': 'Rendez-vous, journal, habitudes, idées et souvenirs au même endroit.',
      'de': 'Termine, Tagebuch, Gewohnheiten, Ideen und Erinnerungen an einem Ort.',
      'pt': 'Compromissos, diário, hábitos, ideias e memórias num só lugar.',
    },
    'onboarding.captureTitle': {
      'it': 'Cattura veloce', 'en': 'Quick capture', 'es': 'Captura rápida',
      'fr': 'Capture rapide', 'de': 'Schnellerfassung', 'pt': 'Captura rápida',
    },
    'onboarding.captureSubtitle': {
      'it': 'Aggiungi un pensiero o un impegno in pochi secondi.',
      'en': 'Add a thought or commitment in seconds.',
      'es': 'Añade una idea o compromiso en segundos.',
      'fr': 'Ajoutez une pensée ou un engagement en quelques secondes.',
      'de': 'Gedanken oder Termine in Sekunden erfassen.',
      'pt': 'Adiciona uma ideia ou compromisso em segundos.',
    },
    'onboarding.diaryTitle': {
      'it': 'Diario personale', 'en': 'Personal diary', 'es': 'Diario personal',
      'fr': 'Journal personnel', 'de': 'Persönliches Tagebuch', 'pt': 'Diário pessoal',
    },
    'onboarding.diarySubtitle': {
      'it': 'Mood, cose belle e abitudini quotidiane.',
      'en': 'Mood, good things and daily habits.',
      'es': 'Ánimo, cosas bonitas y hábitos diarios.',
      'fr': 'Humeur, bons moments et habitudes quotidiennes.',
      'de': 'Stimmung, schöne Dinge und tägliche Gewohnheiten.',
      'pt': 'Humor, coisas boas e hábitos diários.',
    },
    'onboarding.privateTitle': {
      'it': 'Privato o Noi ♡', 'en': 'Private or Noi ♡',
      'es': 'Privado o Noi ♡', 'fr': 'Privé ou Noi ♡',
      'de': 'Privat oder Noi ♡', 'pt': 'Privado ou Noi ♡',
    },
    'onboarding.privateSubtitle': {
      'it': 'Privato è sempre il default; condividi solo ciò che scegli esplicitamente.',
      'en': 'Private is always the default; share only what you explicitly choose.',
      'es': 'Privado es siempre la opción predeterminada; comparte solo lo que elijas.',
      'fr': 'Le privé reste le choix par défaut; partagez seulement ce que vous choisissez.',
      'de': 'Privat ist immer Standard; teile nur, was du ausdrücklich auswählst.',
      'pt': 'Privado é sempre o padrão; partilha apenas o que escolheres.',
    },
    'onboarding.privacyTitle': {
      'it': 'Privacy opzionale', 'en': 'Optional privacy', 'es': 'Privacidad opcional',
      'fr': 'Confidentialité optionnelle', 'de': 'Optionaler Datenschutz', 'pt': 'Privacidade opcional',
    },
    'onboarding.privacySubtitle': {
      'it': 'PIN e biometria se vuoi proteggere l’agenda.',
      'en': 'PIN and biometrics if you want to protect your agenda.',
      'es': 'PIN y biometría si quieres proteger tu agenda.',
      'fr': 'PIN et biométrie pour protéger votre agenda.',
      'de': 'PIN und Biometrie zum Schutz deines Planers.',
      'pt': 'PIN e biometria para proteger a tua agenda.',
    },
    'onboarding.start': {
      'it': 'Inizia', 'en': 'Start', 'es': 'Empezar', 'fr': 'Commencer',
      'de': 'Starten', 'pt': 'Começar',
    },
    'settings.title': {
      'it': 'Impostazioni', 'en': 'Settings', 'es': 'Ajustes',
      'fr': 'Réglages', 'de': 'Einstellungen', 'pt': 'Definições',
    },
    'settings.language': {
      'it': 'Lingua', 'en': 'Language', 'es': 'Idioma', 'fr': 'Langue',
      'de': 'Sprache', 'pt': 'Idioma',
    },
    'settings.languageHelp': {
      'it': 'Automatico usa la lingua del dispositivo. Se non è supportata, viene usato l’inglese.',
      'en': 'Automatic uses the device language. Unsupported languages fall back to English.',
      'es': 'Automático usa el idioma del dispositivo. Los idiomas no compatibles usan inglés.',
      'fr': 'Automatique utilise la langue de l’appareil. Sinon, l’anglais est utilisé.',
      'de': 'Automatisch nutzt die Gerätesprache. Nicht unterstützte Sprachen fallen auf Englisch zurück.',
      'pt': 'Automático usa o idioma do dispositivo. Idiomas não suportados usam inglês.',
    },
    'archive.openTitle': {
      'it': 'Open Life Archive', 'en': 'Open Life Archive',
      'es': 'Open Life Archive', 'fr': 'Open Life Archive',
      'de': 'Open Life Archive', 'pt': 'Open Life Archive',
    },
    'archive.openSubtitle': {
      'it': 'ZIP leggibile con testo, JSON aperto, capitoli annuali e media originali. Non è un backup di ripristino.',
      'en': 'Readable ZIP with text, open JSON, yearly chapters and original media. It is not a restore backup.',
      'es': 'ZIP legible con texto, JSON abierto, capítulos anuales y archivos originales.',
      'fr': 'ZIP lisible avec texte, JSON ouvert, chapitres annuels et médias originaux.',
      'de': 'Lesbares ZIP mit Text, offenem JSON, Jahreskapiteln und Originalmedien.',
      'pt': 'ZIP legível com texto, JSON aberto, capítulos anuais e media originais.',
    },
    'archive.export': {
      'it': 'Esporta archivio', 'en': 'Export archive', 'es': 'Exportar archivo',
      'fr': 'Exporter l’archive', 'de': 'Archiv exportieren', 'pt': 'Exportar arquivo',
    },
  };
}
