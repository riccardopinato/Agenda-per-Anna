import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';

import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:local_auth/local_auth.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:uuid/uuid.dart';

import 'app_version.dart';
import 'external_calendar_service.dart';
import 'backup_service.dart';
import 'cloud_sync_service.dart';
import 'notification_service.dart';
import 'photo_ocr_service.dart';
import 'local_state_store.dart';
import 'media_asset_store.dart';
import 'push_notification_service.dart';
import 'share_capture_service.dart';
import 'vault_service.dart';
import 'voice_diary_service.dart';
import 'web_push_service.dart';

part 'src/app_shell.dart';
part 'src/domain_models.dart';
part 'src/day_hub_domain.dart';
part 'src/unified_capture.dart';
part 'src/home_widget_bridge.dart';
part 'src/recurring_life_domain.dart';
part 'src/organization_domain.dart';
part 'src/life_archive_domain.dart';
part 'src/shopping_domain.dart';
part 'src/workout_domain.dart';
part 'src/people_domain.dart';
part 'src/search_connections_domain.dart';
part 'src/data_safety_domain.dart';
part 'src/store_signals.dart';
part 'src/store/backup_domain.dart';
part 'src/lifecycle_domain.dart';
part 'src/agenda_store.dart';
part 'src/unified_agenda.dart';
part 'src/screens/universal_identity.dart';
part 'src/screens/private_vault.dart';
part 'src/screens/birthdays_screen.dart';
part 'src/screens/people_screen.dart';
part 'src/screens/shopping_list_screen.dart';
part 'src/screens/workout_screen.dart';
part 'src/screens/home_inbox_search.dart';
part 'src/screens/trash_screen.dart';
part 'src/screens/backup_settings.dart';
part 'src/screens/shared_space.dart';
part 'src/screens/cloud_account.dart';
part 'src/planner_views.dart';
part 'src/widgets_editors.dart';
part 'src/diary/diary_templates.dart';
part 'src/diary/diary_components.dart';
part 'src/diary/diary_memories.dart';
part 'src/diary/diary_sketchbook.dart';
part 'src/shared_memories.dart';

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

String _agendaItemIdFromReminderStableId(String stableId) {
  return stableId.replaceFirst(RegExp(r':(primary|secondary)$'), '');
}

Future<void> _handleLocalReminderAction(
  AgendaStore store,
  String payload,
) async {
  const donePrefix = 'reminder_done:';
  final markDone = payload.startsWith(donePrefix);
  final stableId = markDone ? payload.substring(donePrefix.length) : payload;
  final itemId = _agendaItemIdFromReminderStableId(stableId);

  AgendaItem? item;
  for (final candidate in store.items) {
    if (candidate.id == itemId) {
      item = candidate;
      break;
    }
  }
  if (item == null) return;

  if (markDone) {
    if (!item.done) {
      await store.toggle(item.id);
    }
    return;
  }

  var navigator = appNavigatorKey.currentState;
  if (navigator == null) {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    navigator = appNavigatorKey.currentState;
  }
  if (navigator == null) return;

  await navigator.push(
    MaterialPageRoute<void>(
      builder: (_) => PlannerScreen(
        store: store,
        initialDate: item!.date,
      ),
    ),
  );
}

StreamSubscription<String>? _localNotificationTapSubscription;
StreamSubscription<IncomingShareCapture>? _shareCaptureSubscription;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  PushNotificationService.configureBackgroundHandling();

  try {
    await initializeDateFormatting('it_IT', null);
  } catch (_) {}

  final store = AgendaStore();
  Object? startupStorageError;
  try {
    await store.load();
  } catch (error) {
    startupStorageError = error;
  }

  if (startupStorageError != null) {
    runApp(
      StartupStorageFailureApp(
        error: startupStorageError,
      ),
    );
    return;
  }

  runApp(AgendaApp(store: store));

  Future<void>.delayed(Duration.zero, () async {
    try {
      await ExternalCalendarService.instance.initialize();
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day);
      await ExternalCalendarService.instance.loadRange(
        start,
        start.add(const Duration(days: 45)),
      );
    } catch (_) {
      // L'overlay calendario esterno è opzionale e resta locale al dispositivo.
    }

    try {
      final initialShare = await ShareCaptureService.instance.initialize();
      await _shareCaptureSubscription?.cancel();
      _shareCaptureSubscription = ShareCaptureService.instance.stream.listen(
        (capture) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final context = appNavigatorKey.currentContext;
            if (context != null) {
              unawaited(
                _handleIncomingShareCapture(context, store, capture),
              );
            }
          });
        },
      );

      if (initialShare != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final context = appNavigatorKey.currentContext;
          if (context != null) {
            unawaited(
              _handleIncomingShareCapture(context, store, initialShare),
            );
          }
        });
      }
    } catch (_) {
      // La condivisione esterna è opzionale e non deve bloccare l'avvio.
    }

    try {
      await Future<void>.delayed(const Duration(milliseconds: 700));
      await store.ensurePhotoOcrIndexed(maxPerPass: 8);
    } catch (_) {
      // OCR è una derivazione opzionale: foto e diario restano disponibili.
    }

    try {
      await HomeWidgetBridge.instance.initialize();
      HomeWidgetBridge.instance.onAction = (action) {
        final context = appNavigatorKey.currentContext;
        if (context == null) return;
        if (action == 'quick_capture') {
          unawaited(_showQuickCapture(context, store));
        } else if (action == 'today') {
          unawaited(
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PlannerScreen(
                  store: store,
                  initialDate: DateTime.now(),
                ),
              ),
            ),
          );
        }
      };
      await HomeWidgetBridge.instance.sync(store);
      final initialWidgetAction =
          await HomeWidgetBridge.instance.takeLaunchAction();
      if (initialWidgetAction != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          HomeWidgetBridge.instance.onAction?.call(initialWidgetAction);
        });
      }
    } catch (_) {
      // Il widget è opzionale e non deve impedire l'avvio dell'app.
    }


    try {
      await NotificationService.instance.initialize();
      await _localNotificationTapSubscription?.cancel();
      _localNotificationTapSubscription =
          NotificationService.instance.notificationTapStream.listen(
        (payload) => unawaited(
          _handleLocalReminderAction(store, payload),
        ),
      );

      await store.reconcileReminders();
      await store.reconcileBirthdayReminders();

      final initialLocalPayload =
          NotificationService.instance.takeInitialPayload();
      if (initialLocalPayload != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          unawaited(
            _handleLocalReminderAction(store, initialLocalPayload),
          );
        });
      }
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

      if (kIsWeb) {
        await WebPushService.instance.initialize();
        await store.reconcileReminders();
        await store.reconcileBirthdayReminders();
        final initialWebPushSpace =
            await WebPushService.instance.takeInitialSpaceId();
        if (initialWebPushSpace != null) {
          await _openSharedSpaceFromNotification(
            store,
            initialWebPushSpace,
          );
        }
      }
    } catch (_) {
      // Cloud e push sono opzionali: l'agenda resta pienamente offline.
    }
  });
}


class StartupStorageFailureApp extends StatelessWidget {
  final Object error;

  const StartupStorageFailureApp({
    super.key,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Anna\'s Diary',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFFE86D91),
      ),
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.storage_rounded,
                      size: 56,
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Impossibile aprire i dati locali',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Anna\'s Diary non avvia una copia vuota e non salva in una cartella temporanea quando lo storage persistente non è disponibile. Riavvia l’app; se il problema continua, controlla lo spazio libero del dispositivo.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Dettaglio tecnico: ${error.runtimeType}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
