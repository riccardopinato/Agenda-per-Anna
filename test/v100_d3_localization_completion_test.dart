import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:agenda_per_anna/main.dart';

String _source(String path) => File(path).readAsStringSync();

void main() {
  test('v1.00-D3 critical catalog keys resolve in every supported language', () {
    const languages = <String>['en', 'it', 'es', 'fr', 'pt'];
    const keys = <String>[
      'onboardingTitle',
      'optionalPrivacy',
      'sharedSpace',
      'accountAndSync',
      'plannerSevenDays',
      'plannerExpensesRecorded',
      'editor_howFeel',
      'chooseVoiceNote',
      'exportSketch',
      'mem_ourMemories',
      'unified_whereSave',
      'backup_saveBackupDialog',
      'exportOpenTitle',
      'readableMood',
      'workoutDurationExample',
      'external_untitledEvent',
      'notification_reminders',
      'reminderNow',
      'widget_noUpcoming',
      'shared_editedByYou',
      'snapshotBeforeRestore',
      'snapshotBeforeCloudSync',
    ];

    for (final language in languages) {
      final strings = AnnaStrings(language);
      for (final key in keys) {
        final value = strings.d3(key);
        expect(value, isNotEmpty);
        expect(value, isNot(key));
      }
    }
  });

  test(
    'snapshot labels are locale-neutral at rest and localized at render time',
    () {
      expect(
        const AnnaStrings('en').snapshotLabel('@snapshot:before_restore'),
        'Before restore',
      );
      expect(
        const AnnaStrings('it').snapshotLabel('@snapshot:before_restore'),
        'Prima del ripristino',
      );
      expect(
        const AnnaStrings('es').snapshotLabel('@snapshot:before_sign_out'),
        'Antes de desconectar la cuenta',
      );
      expect(
        const AnnaStrings('fr').snapshotLabel('Backup automatico'),
        'Sauvegarde automatique',
      );
      expect(
        const AnnaStrings('pt').snapshotLabel('Prima di svuotare il Cestino'),
        'Antes de esvaziar o Lixo',
      );

      final store = _source('lib/src/agenda_store.dart');
      final cloud = _source('lib/src/screens/cloud_account.dart');
      final lifecycle = _source('lib/src/lifecycle_domain.dart');
      final backup = _source('lib/src/screens/backup_settings.dart');

      expect(store, contains("label: '@snapshot:auto'"));
      expect(store, contains("label: '@snapshot:before_restore'"));
      expect(store, contains("label: '@snapshot:before_cloud_sync'"));
      expect(cloud, contains("label: '@snapshot:before_sign_out'"));
      expect(lifecycle, contains("label: '@snapshot:before_empty_trash'"));
      expect(backup, contains('snapshotLabel(snapshot.label)'));
    },
  );

  test(
    'native and background surfaces do not hardcode Italian presentation',
    () {
      final notifications = _source('lib/notification_service.dart');
      final widget = _source('lib/src/home_widget_bridge.dart');
      final backup = _source('lib/backup_service.dart');
      final calendar = _source('lib/external_calendar_service.dart');
      final agendaStore = _source('lib/src/agenda_store.dart');

      for (final forbidden in <String>[
        'Test immediato: notifiche locali attive',
        "Promemoria di Anna's Diary per appuntamenti e cose da fare",
        'Push Firebase ricevuta correttamente',
        'Promemoria posticipato di 1 ora',
        'Promemoria posticipato di {minutes} minuti',
      ]) {
        expect(notifications, isNot(contains(forbidden)));
      }

      for (final forbidden in <String>[
        'Nessun impegno in arrivo',
        'Nessun compleanno vicino',
        "'it_IT'",
      ]) {
        expect(widget, isNot(contains(forbidden)));
      }

      for (final forbidden in <String>[
        "Salva backup Anna's Diary",
        "Scegli un backup Anna's Diary",
        "Esporta archivio aperto Anna's Diary",
        'Il backup è troppo grande',
        'Contenuto media del backup non valido',
      ]) {
        expect(backup, isNot(contains(forbidden)));
      }

      expect(calendar, isNot(contains("'Calendario esterno'")));
      expect(calendar, isNot(contains("'Evento senza titolo'")));
      expect(agendaStore, isNot(contains('È il momento di iniziare.')));

      final voice = _source('lib/voice_diary_service.dart');
      expect(
        voice,
        isNot(contains('La riproduzione diretta non è disponibile sul web.')),
      );
      expect(voice, contains("message: 'voice_playback_unsupported'"));
    },
  );

  test(
    'migrated Flutter surfaces do not use Italian locale or legacy enum labels',
    () {
      final sources = <String, String>{
        'planner': _source('lib/src/planner_views.dart'),
        'editors': _source('lib/src/widgets_editors.dart'),
        'diary': _source('lib/src/diary/diary_components.dart'),
        'sketchbook': _source('lib/src/diary/diary_sketchbook.dart'),
        'shared': _source('lib/src/screens/shared_space.dart'),
        'memories': _source('lib/src/shared_memories.dart'),
        'unified': _source('lib/src/unified_agenda.dart'),
        'cloud': _source('lib/src/screens/cloud_account.dart'),
        'backup': _source('lib/src/screens/backup_settings.dart'),
        'workout': _source('lib/src/screens/workout_screen.dart'),
        'search': _source('lib/src/search_connections_domain.dart'),
        'archive': _source('lib/src/life_archive_domain.dart'),
      };

      for (final source in sources.values) {
        expect(source, isNot(contains("'it_IT'")));
      }

      expect(sources['planner'], isNot(contains('.category.label')));
      expect(sources['planner'], isNot(contains('.mood.label')));
      expect(sources['editors'], isNot(contains('.category.label')));
      expect(sources['editors'], isNot(contains('.recurrenceRule.label')));
      expect(sources['memories'], isNot(contains('entry.type.label')));
      expect(sources['workout'], isNot(contains('sport.label')));
      expect(sources['search'], isNot(contains('journal.mood?.label')));
      expect(sources['planner'], isNot(contains("'Spese registrate'")));
      expect(sources['workout'], isNot(contains("'es. 1:05:20'")));
      expect(sources['workout'], isNot(contains("'es. 15'")));
    },
  );

  test(
    'shared space no longer persists or renders Italian generic fallbacks',
    () {
      final shared = _source('lib/src/screens/shared_space.dart');
      final cloud = _source('lib/cloud_sync_service.dart');

      for (final forbidden in <String>[
        "'Modificato da te'",
        "'Operazione non riuscita.'",
        "'Gli altri possono vedere, commentare e reagire.'",
        "? 'Utente'",
      ]) {
        expect(shared, isNot(contains(forbidden)));
      }
      expect(cloud, isNot(contains(": 'Persona'")));
    },
  );

  test('Android generator localizes widget and calendar native copy', () {
    final generator = _source('tool/prepare_android_platform.py');
    final localizationIndex = generator.indexOf('    localized = {');
    expect(localizationIndex, greaterThan(0));
    final generatedCode = generator.substring(0, localizationIndex);

    for (final forbidden in <String>[
      "Consenti l'accesso al microfono e riprova.",
      "Consenti l'accesso in lettura al calendario e riprova.",
      'Una richiesta di accesso al calendario è già in corso.',
      'Apri l’app per aggiornare',
      'Da fare:',
      'android:text="+ Aggiungi"',
      'android:text="Oggi"',
    ]) {
      expect(generatedCode, isNot(contains(forbidden)));
    }

    expect(
      generator,
      contains('getString(R.string.calendar_permission_required)'),
    );
    expect(generator, contains('R.string.widget_counters'));
    expect(generator, contains('android:text="@string/widget_capture"'));
    expect(generator, contains('android:text="@string/widget_today"'));
    for (final folder in <String>[
      '"values"',
      '"values-it"',
      '"values-es"',
      '"values-fr"',
      '"values-pt"',
    ]) {
      expect(generator, contains(folder));
    }
  });

  test('every D3 catalog entry defines all five supported languages', () {
    final source = _source('lib/src/localization_d3.dart');
    final catalogEnd = source.indexOf(
      'NotificationLocalization notificationLocalizationForPreference',
    );
    expect(catalogEnd, greaterThan(0));
    final catalog = source.substring(0, catalogEnd);
    final rows = RegExp(
      r'^\s*"([^"]+)":\s*<String, String>\{(.*)\},?$',
      multiLine: true,
    ).allMatches(catalog).toList();

    expect(rows, isNotEmpty);
    for (final row in rows) {
      final values = row.group(2)!;
      for (final language in const <String>['en', 'it', 'es', 'fr', 'pt']) {
        expect(values, contains('"$language":'));
      }
    }
  });

  test('Sketchbook colors and restore integrity errors are locale-safe', () {
    final sketchbook = _source('lib/src/diary/diary_sketchbook.dart');
    final restore = _source('lib/src/data_safety_restore.dart');

    expect(sketchbook, isNot(contains('_colorNames')));
    expect(sketchbook, contains('sketchColorName(index)'));
    expect(sketchbook, contains('sketchColorSemantic('));
    expect(sketchbook, isNot(contains("'Colore ")));

    expect(
      restore,
      isNot(contains('Reference media senza file integro')),
    );
    expect(
      restore,
      contains('backup_missing_referenced_media:'),
    );
  });

  test('D3 localization source has one definition per critical helper', () {
    final source = _source('lib/src/localization_d3.dart');
    for (final helper in <String>[
      'd3',
      'd3Format',
      'd3BackupError',
      'sharedEntryTypeLabel',
      'sharedMemorySearchTokens',
      'lifeArchiveKindLabel',
      'agendaPaletteLabel',
      'trashKindLabel',
      'trashConflict',
      'sharedPasswordServiceError',
      'vaultServiceError',
      'cloudServiceError',
      'snapshotLabel',
      'sketchColorName',
      'sketchColorSemantic',
    ]) {
      expect(source.split('String $helper(').length - 1, 1);
    }

    expect(source, isNot(contains('"sharedMemory_')));

    final keyMatches = RegExp(
      r'^\s*"([^"]+)":\s*<String, String>',
      multiLine: true,
    ).allMatches(source).map((match) => match.group(1)!).toList();
    expect(keyMatches.toSet().length, keyMatches.length);
  });

  test('D3 notification bundle follows the selected language', () {
    final es = notificationLocalizationForPreference(AppLanguage.spanish);
    final fr = notificationLocalizationForPreference(AppLanguage.french);
    final pt = notificationLocalizationForPreference(AppLanguage.portuguese);

    expect(
      es.reminderChannelName,
      const AnnaStrings('es').d3('notification_reminders'),
    );
    expect(
      fr.sharedBody,
      const AnnaStrings('fr').d3('notification_sharedBody'),
    );
    expect(
      pt.snoozeHourBody,
      const AnnaStrings('pt').d3('notification_snoozeHour'),
    );
    expect(es.reminderChannelName, isNot('Promemoria'));
  });

  test('D3 readable and open exports follow the selected app language',
      () async {
    await initializeDateFormatting('fr');

    final store = AgendaStore();
    store.preferences = const AgendaPreferences(
      appLanguage: AppLanguage.french,
    );

    const fr = AnnaStrings('fr');
    const it = AnnaStrings('it');

    final readable = store.createReadableExport();
    expect(readable, contains(fr.d3('readableCommitments')));
    expect(readable, contains(fr.d3('readableImportantPeople')));
    expect(readable, isNot(contains(it.d3('readableCommitments'))));

    final bytes = await store.createOpenExportZip();
    final archive = ZipDecoder().decodeBytes(bytes, verify: true);
    final readmeEntry = archive.files.firstWhere(
      (entry) => entry.isFile && entry.name == 'README.md',
    );
    final readme = utf8.decode(readmeEntry.readBytes()!);

    expect(readme, contains(fr.d3('exportOpenTitle')));
    expect(readme, contains(fr.d3('exportContent')));
    expect(readme, isNot(contains(it.d3('exportOpenTitle'))));

    store.dispose();
  });

  test('D3 canonical domains no longer own locale-bound presentation labels',
      () {
    final domain = _source('lib/src/domain_models.dart');
    final recurring = _source('lib/src/recurring_life_domain.dart');
    final lifecycle = _source('lib/src/lifecycle_domain.dart');

    for (final forbidden in const <String>[
      "AgendaPalette.rose => 'Rosa'",
      "StartTab.month => 'Mese'",
      "RecurrenceRule.daily => 'Ogni giorno'",
      "AgendaCategory.personal => 'Personale'",
      "ShoppingCategory.produce => 'Frutta e verdura'",
      "WorkoutSport.gym => 'Palestra'",
      "DayMood.great => 'Benissimo'",
      "SharedEntryType.appointment => 'Appuntamento'",
    ]) {
      expect(domain, isNot(contains(forbidden)));
    }
    expect(
      recurring,
      isNot(contains("RecurringEditScope.single => 'Solo questa'")),
    );
    expect(
      lifecycle,
      isNot(contains("TrashEntityKind.diaryBlock => 'Ricordo'")),
    );
  });

  test('D3 legacy expense keys remain stable but display is localized', () {
    expect(const AnnaStrings('en').editorExpenseCategoryLabel('Cibo'), 'Food');
    expect(
      const AnnaStrings('es').editorExpenseCategoryLabel('Trasporti'),
      'Transporte',
    );
    expect(
      const AnnaStrings('fr').editorExpenseCategoryLabel('Regali'),
      'Cadeaux',
    );
    expect(
      const AnnaStrings('pt').editorExpenseCategoryLabel('Altro'),
      'Outro',
    );

    final editors = _source('lib/src/widgets_editors.dart');
    expect(editors, contains("const ['Cibo', 'Casa', 'Salute'"));
    expect(editors, contains('editorExpenseCategoryLabel(value)'));
  });

  test('D3 restore and media-store errors are locale-neutral codes', () {
    final restore = _source('lib/src/data_safety_restore.dart');
    final mediaStore = _source('lib/media_asset_store.dart');

    for (final forbidden in const <String>[
      'Staging media non integro',
      'Media in staging non disponibile',
      'Asset locale con stesso ID ma contenuto diverso',
    ]) {
      expect(restore, isNot(contains(forbidden)));
    }
    expect(restore, contains('restore_staging_media_hash_invalid:'));
    expect(restore, contains('restore_staging_media_missing:'));
    expect(restore, contains('restore_canonical_media_collision:'));

    expect(mediaStore, isNot(contains('Media asset non valido.')));
    expect(mediaStore, contains('media_asset_invalid'));
  });
  test('D3 final visible copy uses localization paths', () {
    final diary = _source('lib/src/diary/diary_components.dart');
    final sketchbook = _source('lib/src/diary/diary_sketchbook.dart');
    final shared = _source('lib/src/screens/shared_space.dart');
    final home = _source('lib/src/screens/home_inbox_search.dart');
    final people = _source('lib/src/screens/people_screen.dart');
    final memories = _source('lib/src/shared_memories.dart');
    final lifecycle = _source('lib/src/lifecycle_domain.dart');
    final trash = _source('lib/src/screens/trash_screen.dart');
    final completion = _source('lib/src/localization_d3_completion.dart');

    for (final forbidden in const <String>[
      "hintText: 'es. Lago di Braies'",
      "label: const Text('Sketch')",
      "'\${outgoing.length} collegati'",
      "'\${backlinks.length} backlink'",
      "'Sketch · \${block.pages.length} pagine'",
      "subtitle: 'Sketch · \$time'",
    ]) {
      expect(diary, isNot(contains(forbidden)));
    }

    expect(sketchbook, isNot(contains("child: const Text('Reset')")));
    expect(shared, isNot(contains("title: const Text('Sketch')")));
    expect(home, isNot(contains("tooltip: 'Inbox'")));
    expect(people, isNot(contains("child: const Text('OK')")));
    expect(memories, isNot(contains("child: const Text('OK')")));
    expect(lifecycle, isNot(contains("?? 'Deleted item'")));
    expect(trash, contains("title == 'Deleted item'"));

    expect(completion.split('String d3LinkedCount(').length - 1, 1);
    expect(completion.split('String d3BacklinksCount(').length - 1, 1);
    expect(completion.split('String d3SketchPages(').length - 1, 1);
    expect(completion.split('String d3SketchTimed(').length - 1, 1);
  });

  test('D3 domain defaults and diagnostics remain locale-neutral at rest', () {
    final agenda = _source('lib/src/agenda_store.dart');
    final cloud = _source('lib/cloud_sync_service.dart');
    final push = _source('lib/push_notification_service.dart');
    final pushUi = _source('lib/src/screens/backup_settings.dart');
    final backup = _source('lib/backup_service.dart');
    final webPush = _source('web_push/annas-diary-push-sw.js');

    for (final forbidden in const <String>[
      "name: 'Bere abbastanza'",
      "name: 'Muovermi un po’'",
      "name: 'Tempo per me'",
      'Il PIN deve contenere da 4 a 8 cifre.',
    ]) {
      expect(agenda, isNot(contains(forbidden)));
    }
    expect(agenda, contains("FormatException('pin_invalid_format')"));
    expect(agenda, contains('_starterHabits()'));

    for (final forbidden in const <String>[
      'Google sign-in could not be started.',
      'Cloud non ancora inizializzato.',
      'Cloud non configurato in questa build.',
    ]) {
      expect(cloud, isNot(contains(forbidden)));
    }
    expect(cloud, contains('cloud_google_sign_in_start_failed'));
    expect(cloud, contains('cloud_not_initialized'));
    expect(cloud, contains('cloud_not_configured'));

    expect(push, isNot(contains("'non configurato'")));
    expect(push, isNot(contains("'sconosciuto'")));
    expect(push, contains("permissionStatus: 'not_configured'"));
    expect(push, contains("var permissionStatus = 'unknown'"));
    expect(pushUi, contains('.d3PermissionStatus('));

    expect(backup, isNot(contains('String dialogTitle =')));
    expect(webPush, isNot(contains('Nuovo aggiornamento')));
    expect(webPush, isNot(contains('Hai un nuovo aggiornamento.')));
  });

  test('D3 domain localization helpers cover all supported locales', () {
    const languages = <String>['en', 'it', 'es', 'fr', 'pt'];
    for (final language in languages) {
      final strings = AnnaStrings(language);
      expect(strings.d3StarterHabitWater.trim(), isNotEmpty);
      expect(strings.d3StarterHabitMove.trim(), isNotEmpty);
      expect(strings.d3StarterHabitMe.trim(), isNotEmpty);
      expect(strings.d3PermissionStatus('not_configured').trim(), isNotEmpty);
      expect(strings.d3PermissionStatus('denied').trim(), isNotEmpty);
    }

    expect(const AnnaStrings('es').d3StarterHabitWater, 'Beber suficiente agua');
    expect(const AnnaStrings('fr').d3StarterHabitMove, 'Bouger un peu');
    expect(const AnnaStrings('pt').d3StarterHabitMe, 'Tempo para mim');
    expect(
      const AnnaStrings('fr').d3PermissionStatus('denied'),
      'autorisation : refusée',
    );
  });

  test('D3 Vault back navigation is explicit for AppLab', () {
    final vault = _source('lib/src/screens/private_vault.dart');
    final flow = _source('.maestro/applab-smoke.yaml');

    expect(vault, contains("identifier: 'vault_back_button'"));
    expect(vault, contains('Navigator.of(context).pop()'));

    final screenState = vault.indexOf(
      'class _PrivateVaultScreenState extends State<PrivateVaultScreen>',
    );
    final helper = vault.indexOf('Widget? _vaultBackButton(BuildContext context)');
    expect(screenState, greaterThanOrEqualTo(0));
    expect(helper, greaterThan(screenState));

    expect(
      flow,
      contains("id: 'vault_back_button'"),
    );
  });

  test('D3 visual AppLab journey accepts every supported locale', () {
    final week = _source('.maestro/journey/week.yaml');
    final today = _source('.maestro/journey/today.yaml');
    final account = _source('.maestro/journey/account.yaml');

    for (final text in const <String>[
      'Settimana',
      'Week',
      'Semana',
      'Semaine',
    ]) {
      expect(week, contains(text));
    }
    expect(week, contains("id: 'calendar-week-view'"));

    // UI5 shows the day overview even without any diary entry.
    for (final text in const <String>[
      'La mia giornata',
      'My day',
      'Mi día',
      'Ma journée',
      'O meu dia',
    ]) {
      expect(today, contains(text));
    }
    expect(today, contains("id: 'ui5-today-date-strip'"));
    expect(today, contains("id: 'main-nav-create'"));
    expect(today, isNot(contains('Pensieri e note|Thoughts and notes')));
    expect(today, isNot(contains('Momenti del giorno|Moments of the day')));

    for (final text in const <String>[
      'Account e sincronizzazione',
      'Account and sync',
      'Cuenta y sincronización',
      'Compte et synchronisation',
      'Conta e sincronização',
    ]) {
      expect(account, contains(text));
    }
  });


  test('D3 AppLab onboarding accepts every supported locale', () {
    final flow = _source('.maestro/applab-smoke.yaml');
    for (final text in const <String>[
      'La tua agenda, davvero tua',
      'Your agenda, truly yours',
      'Tu agenda, de verdad tuya',
      'Ton agenda, vraiment à toi',
      'A tua agenda, verdadeiramente tua',
      'Inizia con qualcosa di utile',
      'Start with something useful',
      'Empieza con algo útil',
      'Commence par quelque chose d’utile',
      'Começa com algo útil',
    ]) {
      expect(flow, contains(text));
    }
    for (final id in const <String>[
      "id: 'onboarding_preset_complete'",
      "id: 'onboarding_continue'",
      "id: 'onboarding_open_agenda'",
    ]) {
      expect(flow, contains(id));
    }
  });


}
