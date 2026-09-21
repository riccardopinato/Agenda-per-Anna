import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:local_auth/local_auth.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:uuid/uuid.dart';

import 'backup_service.dart';
import 'cloud_sync_service.dart';
import 'notification_service.dart';

part 'src/app_shell.dart';
part 'src/domain_models.dart';
part 'src/agenda_store.dart';
part 'src/unified_agenda.dart';
part 'src/screens_core.dart';
part 'src/planner_views.dart';
part 'src/widgets_editors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await initializeDateFormatting('it_IT', null);
  } catch (_) {}

  final store = AgendaStore();
  try {
    await store.load();
  } catch (_) {}

  runApp(AgendaApp(store: store));

  Future<void>.delayed(Duration.zero, () async {
    try {
      await NotificationService.instance.initialize();
      await store.reconcileReminders();
    } catch (_) {
      // Le notifiche non devono mai impedire l'avvio dell'agenda.
    }

    try {
      await CloudSyncService.instance.initialize();
      await store.initializeCloudSync();
    } catch (_) {
      // Il cloud è opzionale: l'agenda deve restare pienamente offline.
    }
  });
}
