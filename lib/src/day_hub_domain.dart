part of '../main.dart';

class BirthdayEntry {
  final String id;
  final String name;
  final int day;
  final int month;
  final int? year;
  final String note;
  final int? reminderDaysBefore;

  const BirthdayEntry({
    required this.id,
    required this.name,
    required this.day,
    required this.month,
    this.year,
    this.note = '',
    this.reminderDaysBefore = 1,
  });

  BirthdayEntry copyWith({
    String? name,
    int? day,
    int? month,
    int? year,
    String? note,
    int? reminderDaysBefore,
    bool clearYear = false,
    bool clearReminder = false,
  }) =>
      BirthdayEntry(
        id: id,
        name: name ?? this.name,
        day: day ?? this.day,
        month: month ?? this.month,
        year: clearYear ? null : (year ?? this.year),
        note: note ?? this.note,
        reminderDaysBefore:
            clearReminder ? null : (reminderDaysBefore ?? this.reminderDaysBefore),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'day': day,
        'month': month,
        'year': year,
        'note': note,
        'reminderDaysBefore': reminderDaysBefore,
      };

  factory BirthdayEntry.fromJson(Map<String, dynamic> json) {
    final day = (json['day'] as int? ?? 1).clamp(1, 31).toInt();
    final month = (json['month'] as int? ?? 1).clamp(1, 12).toInt();
    final year = json['year'] as int?;
    return BirthdayEntry(
      id: json['id'] as String? ?? const Uuid().v4(),
      name: json['name'] as String? ?? '',
      day: day,
      month: month,
      year: year,
      note: json['note'] as String? ?? '',
      reminderDaysBefore: json.containsKey('reminderDaysBefore')
          ? json['reminderDaysBefore'] as int?
          : 1,
    );
  }
}

class BirthdayOccurrence {
  final BirthdayEntry birthday;
  final DateTime date;
  final int? age;

  const BirthdayOccurrence({
    required this.birthday,
    required this.date,
    required this.age,
  });
}

enum DayLifeEntryKind { agenda, birthday, workout, diaryBlock }

class DayLifeEntry {
  final DayLifeEntryKind kind;
  final UnifiedAgendaEntry? agenda;
  final BirthdayOccurrence? birthday;
  final WorkoutSession? workout;
  final DiaryBlock? diaryBlock;

  const DayLifeEntry.agenda(this.agenda)
      : kind = DayLifeEntryKind.agenda,
        birthday = null,
        workout = null,
        diaryBlock = null;

  const DayLifeEntry.birthday(this.birthday)
      : kind = DayLifeEntryKind.birthday,
        agenda = null,
        workout = null,
        diaryBlock = null;

  const DayLifeEntry.workout(this.workout)
      : kind = DayLifeEntryKind.workout,
        agenda = null,
        birthday = null,
        diaryBlock = null;

  const DayLifeEntry.diaryBlock(this.diaryBlock)
      : kind = DayLifeEntryKind.diaryBlock,
        agenda = null,
        birthday = null,
        workout = null;

  String get id => switch (kind) {
        DayLifeEntryKind.agenda => 'agenda:${agenda!.id}',
        DayLifeEntryKind.birthday => 'birthday:${birthday!.birthday.id}',
        DayLifeEntryKind.workout => 'workout:${workout!.id}',
        DayLifeEntryKind.diaryBlock => 'diary:${diaryBlock!.id}',
      };

  DateTime sortAt(DateTime day) {
    final base = DateTime(day.year, day.month, day.day);
    return switch (kind) {
      DayLifeEntryKind.agenda => agenda!.start == null
          ? base
          : DateTime(
              day.year,
              day.month,
              day.day,
              agenda!.start!.hour,
              agenda!.start!.minute,
            ),
      DayLifeEntryKind.birthday => base,
      DayLifeEntryKind.workout => _sameCivilDay(workout!.createdAt, day)
          ? workout!.createdAt
          : base.add(const Duration(hours: 18)),
      DayLifeEntryKind.diaryBlock => _sameCivilDay(diaryBlock!.createdAt, day)
          ? diaryBlock!.createdAt
          : base.add(const Duration(hours: 20)),
    };
  }

  static bool _sameCivilDay(DateTime left, DateTime right) =>
      left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}

class DayHubSnapshot {
  final DateTime date;
  final List<UnifiedAgendaEntry> agenda;
  final List<BirthdayOccurrence> birthdays;
  final List<WorkoutSession> workouts;
  final int pendingTaskCount;
  final int appointmentCount;
  final DayJournal journal;

  const DayHubSnapshot({
    required this.date,
    required this.agenda,
    required this.birthdays,
    required this.workouts,
    required this.pendingTaskCount,
    required this.appointmentCount,
    required this.journal,
  });

  bool get hasJournalContent =>
      journal.beautiful.trim().isNotEmpty ||
      journal.note.trim().isNotEmpty ||
      journal.gratitude.any((entry) => entry.trim().isNotEmpty) ||
      journal.mood != null ||
      journal.blocks.any((block) => !block.archived);

  List<DayLifeEntry> get lifeEntries {
    final result = <DayLifeEntry>[
      ...agenda.map(DayLifeEntry.agenda),
      ...birthdays.map(DayLifeEntry.birthday),
      ...workouts.map(DayLifeEntry.workout),
      ...journal.blocks
          .where((block) => !block.archived)
          .map(DayLifeEntry.diaryBlock),
    ];
    result.sort((left, right) {
      final time = left.sortAt(date).compareTo(right.sortAt(date));
      if (time != 0) return time;
      return left.id.compareTo(right.id);
    });
    return List<DayLifeEntry>.unmodifiable(result);
  }

  bool get isEmpty =>
      agenda.isEmpty &&
      birthdays.isEmpty &&
      workouts.isEmpty &&
      !hasJournalContent;
}

extension AgendaStoreDayHub on AgendaStore {
  static DateTime _birthdayDateForYear(
    int year,
    int month,
    int day,
  ) {
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, min(day, lastDay));
  }

  BirthdayOccurrence birthdayOccurrence(
    BirthdayEntry birthday,
    int year,
  ) {
    final date = _birthdayDateForYear(year, birthday.month, birthday.day);
    final age = birthday.year == null || year < birthday.year!
        ? null
        : year - birthday.year!;
    return BirthdayOccurrence(
      birthday: birthday,
      date: date,
      age: age,
    );
  }

  List<BirthdayOccurrence> birthdaysForDay(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final result = birthdays
        .map((birthday) => birthdayOccurrence(birthday, normalized.year))
        .where((occurrence) => AgendaStore.sameDay(occurrence.date, normalized))
        .toList()
      ..sort((a, b) => a.birthday.name
          .toLowerCase()
          .compareTo(b.birthday.name.toLowerCase()));
    return result;
  }

  List<BirthdayOccurrence> upcomingBirthdays({
    DateTime? from,
    int limit = 6,
  }) {
    final anchor = from ?? DateTime.now();
    final today = DateTime(anchor.year, anchor.month, anchor.day);
    final result = <BirthdayOccurrence>[];

    for (final birthday in birthdays) {
      var occurrence = birthdayOccurrence(birthday, today.year);
      if (occurrence.date.isBefore(today)) {
        occurrence = birthdayOccurrence(birthday, today.year + 1);
      }
      result.add(occurrence);
    }

    result.sort((a, b) {
      final date = a.date.compareTo(b.date);
      if (date != 0) return date;
      return a.birthday.name
          .toLowerCase()
          .compareTo(b.birthday.name.toLowerCase());
    });
    return result.take(max(0, limit)).toList();
  }

  DayHubSnapshot dayHubSnapshot(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final agenda = agendaEntriesForDayWithExternal(this, normalized);
    final workoutsForDay = workoutSessions
        .where((session) => AgendaStore.sameDay(session.date, normalized))
        .toList()
      ..sort((left, right) => left.createdAt.compareTo(right.createdAt));
    return DayHubSnapshot(
      date: normalized,
      agenda: agenda,
      birthdays: birthdaysForDay(normalized),
      workouts: List<WorkoutSession>.unmodifiable(workoutsForDay),
      pendingTaskCount: agenda
          .where((entry) => entry.type == ItemType.task && !entry.done)
          .length,
      appointmentCount:
          agenda.where((entry) => entry.type == ItemType.appointment).length,
      journal: journal(normalized),
    );
  }

  Future<void> saveBirthday(BirthdayEntry birthday) async {
    final value = birthday.copyWith(
      name: birthday.name.trim(),
      note: birthday.note.trim(),
    );
    if (value.name.isEmpty) {
      throw const FormatException('Il nome del compleanno non può essere vuoto.');
    }

    final index = birthdays.indexWhere((entry) => entry.id == value.id);
    if (index < 0) {
      birthdays.add(value);
    } else {
      birthdays[index] = value;
    }
    birthdays.sort((a, b) {
      final month = a.month.compareTo(b.month);
      if (month != 0) return month;
      final day = a.day.compareTo(b.day);
      if (day != 0) return day;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    await _persistEntityMutation(
      type: 'birthday',
      id: value.id,
      payload: value.toJson(),
    );
    await _syncBirthdayReminder(value, requestPermission: true);
    _notifyPlanningChanged();
  }

  Future<void> _cancelBirthdayReminder(String birthdayId) async {
    final stableId = 'birthday:$birthdayId';
    if (kIsWeb) {
      final cloud = CloudSyncService.instance;
      if (cloud.signedIn) {
        try {
          await cloud.cancelWebPushReminder(stableId);
        } catch (_) {}
      }
    } else {
      await NotificationService.instance.cancel(stableId);
    }
  }

  Future<void> _syncBirthdayReminder(
    BirthdayEntry birthday, {
    bool requestPermission = false,
  }) async {
    final daysBefore = birthday.reminderDaysBefore;
    if (daysBefore == null) {
      await _cancelBirthdayReminder(birthday.id);
      return;
    }

    final now = DateTime.now();
    var occurrence = birthdayOccurrence(birthday, now.year);
    var reminderAt = DateTime(
      occurrence.date.year,
      occurrence.date.month,
      occurrence.date.day,
      9,
    ).subtract(Duration(days: max(0, daysBefore)));

    if (!reminderAt.isAfter(now)) {
      occurrence = birthdayOccurrence(birthday, now.year + 1);
      reminderAt = DateTime(
        occurrence.date.year,
        occurrence.date.month,
        occurrence.date.day,
        9,
      ).subtract(Duration(days: max(0, daysBefore)));
    }

    final ageText = occurrence.age == null ? '' : ' · ${occurrence.age} anni';
    final leadText = daysBefore == 0
        ? 'Oggi'
        : daysBefore == 1
            ? 'Domani'
            : 'Tra $daysBefore giorni';
    final title = '🎂 ${birthday.name}$ageText';
    final body = '$leadText è il compleanno di ${birthday.name}.';
    final stableId = 'birthday:${birthday.id}';

    if (kIsWeb) {
      final cloud = CloudSyncService.instance;
      if (!cloud.signedIn) return;
      try {
        await cloud.upsertWebPushReminder(
          stableId: stableId,
          title: title,
          body: body,
          when: reminderAt,
        );
      } catch (_) {}
      return;
    }

    await NotificationService.instance.schedule(
      stableId: stableId,
      title: title,
      body: body,
      when: reminderAt,
      requestPermission: requestPermission,
    );
  }

  Future<void> reconcileBirthdayReminders({
    bool requestPermission = false,
  }) async {
    for (final birthday in birthdays) {
      await _syncBirthdayReminder(
        birthday,
        requestPermission: requestPermission,
      );
    }
  }
}
