import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

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
}
