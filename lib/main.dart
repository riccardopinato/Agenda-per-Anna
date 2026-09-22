import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:local_auth/local_auth.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:uuid/uuid.dart';

import 'backup_service.dart';
import 'cloud_sync_service.dart';
import 'notification_service.dart';
import 'push_notification_service.dart';

part 'src/app_shell.dart';
part 'src/domain_models.dart';
part 'src/agenda_store.dart';
part 'src/unified_agenda.dart';
part 'src/screens_core.dart';
part 'src/planner_views.dart';
part 'src/widgets_editors.dart';
part 'src/diary_media.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

Future<void> _openSharedSpaceFromNotification(
  AgendaStore store,
  String spaceId,
) async {
  final cloud = CloudSyncService.instance;

  if (cloud.signedIn) {
    try {
      if (store.activeAccountId != cloud.userId) {
        await store.activateCloudAccount(cloud.userId);
      }
      await store.refreshSharedAgendaCache(pullRemote: true);
    } catch (_) {
      // La navigazione usa comunque la cache locale disponibile.
    }
  }

  await store.markSharedSpaceRead(spaceId);

  NavigatorState? navigator = appNavigatorKey.currentState;
  if (navigator == null) {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    navigator = appNavigatorKey.currentState;
  }
  if (navigator == null) return;

  SharedSpace? target;
  for (final space in store.sharedAgendaSpaces) {
    if (space.id == spaceId) {
      target = space;
      break;
    }
  }

  await navigator.push(
    MaterialPageRoute<void>(
      builder: (_) => target == null
          ? SharedSpaceHubScreen(store: store)
          : SharedSpaceScreen(
              store: store,
              space: target,
            ),
    ),
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  PushNotificationService.configureBackgroundHandling();

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
      await PushNotificationService.instance.initialize(
        onSharedPushReceived: (spaceId, eventId) async {
          await store.markSharedSpaceUnread(spaceId);
        },
        onSharedPushOpened: (spaceId) =>
            _openSharedSpaceFromNotification(store, spaceId),
      );
    } catch (_) {
      // Cloud e push sono opzionali: l'agenda resta pienamente offline.
    }
  });
}
