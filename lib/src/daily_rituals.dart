part of '../main.dart';

enum DailyRitualKind { morning, evening }

const String dailyRitualMorningReminderId = 'daily_ritual:morning';
const String dailyRitualEveningReminderId = 'daily_ritual:evening';

String dailyRitualTag(DailyRitualKind kind) => 'ritual:${kind.name}';

extension AgendaStoreDailyRituals on AgendaStore {
  bool isDailyRitualEnabled(DailyRitualKind kind) => switch (kind) {
        DailyRitualKind.morning => preferences.morningRitualEnabled,
        DailyRitualKind.evening => preferences.eveningRitualEnabled,
      };

  bool hasStartedDailyRitual(DateTime date, DailyRitualKind kind) {
    final tag = dailyRitualTag(kind);
    return journal(date).blocks.any(
          (block) => !block.archived && block.tags.contains(tag),
        );
  }

  DiaryBlock? dailyRitualBlock(DateTime date, DailyRitualKind kind) {
    final tag = dailyRitualTag(kind);
    for (final block in journal(date).blocks.reversed) {
      if (!block.archived && block.tags.contains(tag)) return block;
    }
    return null;
  }

  Future<DiaryBlock> startDailyRitual(
    DateTime date,
    DailyRitualKind kind,
  ) async {
    final existing = dailyRitualBlock(date, kind);
    if (existing != null) return existing;

    final strings = AnnaStrings.forPreference(preferences.appLanguage);
    final presetId = kind.name;
    final preset = diaryTemplatePresetsFor(strings).firstWhere(
      (candidate) => candidate.id == presetId,
    );
    return applyDiaryTemplate(
      date,
      preset,
      extraTags: <String>[dailyRitualTag(kind)],
    );
  }

  Future<void> reconcileDailyRitualReminders({
    bool requestPermission = false,
  }) async {
    final strings = AnnaStrings.forPreference(preferences.appLanguage);
    final remindersEnabled = preferences.ritualRemindersEnabled;

    if (remindersEnabled && preferences.morningRitualEnabled) {
      await NotificationService.instance.scheduleDaily(
        stableId: dailyRitualMorningReminderId,
        title: strings.d3('ritualMorningReminderTitle'),
        body: strings.d3('ritualMorningReminderBody'),
        hour: preferences.morningRitualHour,
        minute: preferences.morningRitualMinute,
        requestPermission: requestPermission,
      );
    } else {
      await NotificationService.instance.cancel(
        dailyRitualMorningReminderId,
      );
    }

    if (remindersEnabled && preferences.eveningRitualEnabled) {
      await NotificationService.instance.scheduleDaily(
        stableId: dailyRitualEveningReminderId,
        title: strings.d3('ritualEveningReminderTitle'),
        body: strings.d3('ritualEveningReminderBody'),
        hour: preferences.eveningRitualHour,
        minute: preferences.eveningRitualMinute,
        requestPermission: requestPermission,
      );
    } else {
      await NotificationService.instance.cancel(
        dailyRitualEveningReminderId,
      );
    }
  }
}

class DailyRitualCard extends StatelessWidget {
  final AgendaStore store;
  final DateTime date;

  const DailyRitualCard({
    super.key,
    required this.store,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final prefs = store.preferences;
    final strings = AnnaStrings.of(context);
    final kinds = <DailyRitualKind>[
      if (prefs.morningRitualEnabled) DailyRitualKind.morning,
      if (prefs.eveningRitualEnabled) DailyRitualKind.evening,
    ];
    if (kinds.isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final hour = DateTime.now().hour;
    final suggested = hour < 15
        ? DailyRitualKind.morning
        : DailyRitualKind.evening;

    return Container(
      key: const ValueKey<String>('daily-ritual-card'),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              strings.d3('ritualsTitle'),
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            strings.d3('ritualsTodaySubtitle'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          for (final kind in kinds)
            _DailyRitualTile(
              store: store,
              date: date,
              kind: kind,
              suggested: kinds.length > 1 && kind == suggested,
            ),
        ],
      ),
    );
  }
}

class _DailyRitualTile extends StatelessWidget {
  final AgendaStore store;
  final DateTime date;
  final DailyRitualKind kind;
  final bool suggested;

  const _DailyRitualTile({
    required this.store,
    required this.date,
    required this.kind,
    required this.suggested,
  });

  @override
  Widget build(BuildContext context) {
    final strings = AnnaStrings.of(context);
    final prefs = store.preferences;
    final done = store.hasStartedDailyRitual(date, kind);
    final isMorning = kind == DailyRitualKind.morning;
    final time = TimeOfDay(
      hour: isMorning ? prefs.morningRitualHour : prefs.eveningRitualHour,
      minute: isMorning ? prefs.morningRitualMinute : prefs.eveningRitualMinute,
    );
    final title = strings.d3(
      isMorning ? 'ritualMorningTitle' : 'ritualEveningTitle',
    );
    final subtitle = strings.d3Format(
      suggested ? 'ritualSuggestedAt' : 'ritualAvailableAt',
      <String, Object?>{
        'time': MaterialLocalizations.of(context).formatTimeOfDay(time),
      },
    );

    return Semantics(
      identifier: 'daily_ritual_${kind.name}',
      container: true,
      button: !done,
      enabled: !done,
      label: title,
      hint: done ? strings.d3('ritualCompleted') : subtitle,
      excludeSemantics: true,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          child: Icon(
            isMorning
                ? Icons.wb_sunny_outlined
                : Icons.nightlight_outlined,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(subtitle),
        trailing: done
            ? Chip(
                avatar: const Icon(Icons.check, size: 18),
                label: Text(strings.d3('ritualCompleted')),
              )
            : FilledButton.tonal(
                onPressed: () async {
                  await store.startDailyRitual(date, kind);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(strings.d3('ritualStarted')),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                child: Text(strings.d3('ritualStart')),
              ),
        onTap: done
            ? null
            : () async {
                await store.startDailyRitual(date, kind);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(strings.d3('ritualStarted')),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
      ),
    );
  }
}
