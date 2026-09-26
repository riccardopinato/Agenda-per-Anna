part of '../main.dart';

class HomeWidgetBridge {
  HomeWidgetBridge._();

  static final HomeWidgetBridge instance = HomeWidgetBridge._();
  static const MethodChannel _channel =
      MethodChannel('annas_diary/home_widget');

  bool _initialized = false;
  ValueChanged<String>? onAction;

  bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> initialize() async {
    if (!supported || _initialized) return;
    _initialized = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method != 'homeWidgetAction') return;
      final action = call.arguments?.toString().trim() ?? '';
      if (action.isNotEmpty) onAction?.call(action);
    });
  }

  Future<String?> takeLaunchAction() async {
    if (!supported) return null;
    try {
      final value = await _channel.invokeMethod<String>('takeLaunchAction');
      final action = value?.trim() ?? '';
      return action.isEmpty ? null : action;
    } catch (_) {
      return null;
    }
  }

  Future<void> sync(AgendaStore store) async {
    if (!supported) return;

    final now = DateTime.now();
    final upcoming = store.unifiedUpcoming(now);
    final birthdays = store.upcomingBirthdays(from: now, limit: 1);
    final next = upcoming.isEmpty ? null : upcoming.first;
    final birthday = birthdays.isEmpty ? null : birthdays.first;

    String nextText = 'Nessun impegno in arrivo';
    if (next != null) {
      final date = next.date;
      final day = isSameDay(date, now)
          ? 'Oggi'
          : DateFormat('EEE d MMM', 'it_IT').format(date);
      final time = next.start == null ? '' : ' · ${formatTime(next.start!)}';
      nextText = '$day$time · ${next.title}';
    }

    String birthdayText = 'Nessun compleanno vicino';
    if (birthday != null) {
      final date = birthday.date;
      birthdayText =
          '${birthday.birthday.name} · ${DateFormat('d MMM', 'it_IT').format(date)}';
    }

    try {
      await _channel.invokeMethod<void>('updateWidget', {
        'title': "Anna's Diary",
        'next': nextText,
        'birthday': birthdayText,
        'tasks': store.pendingUnifiedTaskCount,
        'inbox': store.inbox.where((entry) => !entry.archived).length,
      });
    } catch (_) {
      // Il widget non deve mai bloccare l'app.
    }
  }
}
