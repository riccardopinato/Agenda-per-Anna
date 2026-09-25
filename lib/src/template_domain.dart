part of '../main.dart';

enum PersonalTemplateKind { day, week, month }

extension PersonalTemplateKindUi on PersonalTemplateKind {
  String get label => switch (this) {
        PersonalTemplateKind.day => 'Giornata',
        PersonalTemplateKind.week => 'Settimana',
        PersonalTemplateKind.month => 'Mese',
      };

  IconData get icon => switch (this) {
        PersonalTemplateKind.day => Icons.today_outlined,
        PersonalTemplateKind.week => Icons.view_week_outlined,
        PersonalTemplateKind.month => Icons.calendar_month_outlined,
      };
}

class DayAgendaTemplateItem {
  final String title;
  final String note;
  final ItemType type;
  final AgendaCategory category;
  final TimeOfDay? start;
  final TimeOfDay? end;
  final int? reminderMinutesBefore;
  final int? secondaryReminderMinutesBefore;
  final bool pinned;

  const DayAgendaTemplateItem({
    required this.title,
    required this.note,
    required this.type,
    required this.category,
    this.start,
    this.end,
    this.reminderMinutesBefore,
    this.secondaryReminderMinutesBefore,
    this.pinned = false,
  });

  factory DayAgendaTemplateItem.fromAgendaItem(AgendaItem item) =>
      DayAgendaTemplateItem(
        title: item.title,
        note: item.note,
        type: item.type,
        category: item.category,
        start: item.start,
        end: item.end,
        reminderMinutesBefore: item.reminderMinutesBefore,
        secondaryReminderMinutesBefore: item.secondaryReminderMinutesBefore,
        pinned: item.pinned,
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'note': note,
        'type': type.name,
        'category': category.name,
        'start': start == null ? null : [start!.hour, start!.minute],
        'end': end == null ? null : [end!.hour, end!.minute],
        'reminderMinutesBefore': reminderMinutesBefore,
        'secondaryReminderMinutesBefore': secondaryReminderMinutesBefore,
        'pinned': pinned,
      };

  factory DayAgendaTemplateItem.fromJson(Map<String, dynamic> json) {
    TimeOfDay? parseTime(dynamic value) {
      if (value is List && value.length == 2) {
        final hour = value[0];
        final minute = value[1];
        if (hour is int && minute is int) {
          return TimeOfDay(hour: hour, minute: minute);
        }
      }
      return null;
    }

    return DayAgendaTemplateItem(
      title: json['title'] as String? ?? '',
      note: json['note'] as String? ?? '',
      type: ItemType.values.firstWhere(
        (value) => value.name == json['type'],
        orElse: () => ItemType.task,
      ),
      category: AgendaCategory.values.firstWhere(
        (value) => value.name == json['category'],
        orElse: () => AgendaCategory.personal,
      ),
      start: parseTime(json['start']),
      end: parseTime(json['end']),
      reminderMinutesBefore: json['reminderMinutesBefore'] as int?,
      secondaryReminderMinutesBefore:
          json['secondaryReminderMinutesBefore'] as int?,
      pinned: json['pinned'] as bool? ?? false,
    );
  }

  AgendaItem materialize(DateTime date) => AgendaItem(
        id: const Uuid().v4(),
        title: title,
        note: note,
        date: DateTime(date.year, date.month, date.day),
        type: type,
        category: category,
        start: start,
        end: end,
        reminderMinutesBefore: reminderMinutesBefore,
        secondaryReminderMinutesBefore: secondaryReminderMinutesBefore,
        done: false,
        pinned: pinned,
      );
}

class PersonalTemplate {
  final String id;
  final String name;
  final PersonalTemplateKind kind;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> payload;

  const PersonalTemplate({
    required this.id,
    required this.name,
    required this.kind,
    required this.createdAt,
    required this.updatedAt,
    required this.payload,
  });

  PersonalTemplate copyWith({
    String? name,
    DateTime? updatedAt,
    Map<String, dynamic>? payload,
  }) =>
      PersonalTemplate(
        id: id,
        name: name ?? this.name,
        kind: kind,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        payload: payload ?? this.payload,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'kind': kind.name,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
        'payload': payload,
      };

  factory PersonalTemplate.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    return PersonalTemplate(
      id: json['id'] as String? ?? const Uuid().v4(),
      name: json['name'] as String? ?? 'Modello personale',
      kind: PersonalTemplateKind.values.firstWhere(
        (value) => value.name == json['kind'],
        orElse: () => PersonalTemplateKind.day,
      ),
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '')?.toLocal() ??
              now,
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '')?.toLocal() ??
              now,
      payload: Map<String, dynamic>.from(
        json['payload'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }

  String get summary => switch (kind) {
        PersonalTemplateKind.day =>
          '${(payload['items'] as List? ?? const []).length} elementi',
        PersonalTemplateKind.week =>
          (payload['priorities'] as List? ?? const []).isEmpty
              ? 'Focus settimanale'
              : '${(payload['priorities'] as List).length} priorità',
        PersonalTemplateKind.month =>
          (payload['goals'] as List? ?? const []).isEmpty
              ? 'Pianificazione mensile'
              : '${(payload['goals'] as List).length} obiettivi',
      };
}

class TemplateApplyResult {
  final int createdAgendaItems;
  final bool planningChanged;

  const TemplateApplyResult({
    this.createdAgendaItems = 0,
    this.planningChanged = false,
  });

  int get changeCount => createdAgendaItems + (planningChanged ? 1 : 0);
}

extension AgendaStoreTemplates on AgendaStore {
  PersonalTemplate? templateById(String id) {
    for (final template in templates) {
      if (template.id == id) return template;
    }
    return null;
  }

  List<PersonalTemplate> get sortedTemplates {
    final result = [...templates]
      ..sort((a, b) {
        final byKind = a.kind.index.compareTo(b.kind.index);
        if (byKind != 0) return byKind;
        final byUpdated = b.updatedAt.compareTo(a.updatedAt);
        if (byUpdated != 0) return byUpdated;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    return result;
  }

  Future<void> saveTemplate(PersonalTemplate template) async {
    final name = template.name.trim();
    if (name.isEmpty) {
      throw ArgumentError.value(template.name, 'name', 'Il nome è obbligatorio');
    }
    final normalized = template.copyWith(
      name: name,
      updatedAt: DateTime.now(),
    );
    final index = templates.indexWhere((value) => value.id == normalized.id);
    if (index < 0) {
      templates.add(normalized);
    } else {
      templates[index] = normalized;
    }
    await _persistEntityMutation(
      type: 'template',
      id: normalized.id,
      payload: normalized.toJson(),
    );
    _notifyPlanningChanged();
  }

  Future<PersonalTemplate> createDayTemplate(
    String name,
    DateTime sourceDate,
  ) async {
    final normalized = DateTime(
      sourceDate.year,
      sourceDate.month,
      sourceDate.day,
    );
    final values = items
        .where((item) => AgendaStore.sameDay(item.date, normalized))
        .map(DayAgendaTemplateItem.fromAgendaItem)
        .toList()
      ..sort((a, b) {
        final am = a.start == null ? 24 * 60 : a.start!.hour * 60 + a.start!.minute;
        final bm = b.start == null ? 24 * 60 : b.start!.hour * 60 + b.start!.minute;
        final byTime = am.compareTo(bm);
        if (byTime != 0) return byTime;
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      });
    final now = DateTime.now();
    final template = PersonalTemplate(
      id: const Uuid().v4(),
      name: name,
      kind: PersonalTemplateKind.day,
      createdAt: now,
      updatedAt: now,
      payload: {
        'items': values.map((value) => value.toJson()).toList(),
      },
    );
    await saveTemplate(template);
    return template;
  }

  Future<PersonalTemplate> createWeekTemplate(
    String name,
    DateTime sourceDate,
  ) async {
    final data = week(sourceDate);
    final now = DateTime.now();
    final template = PersonalTemplate(
      id: const Uuid().v4(),
      name: name,
      kind: PersonalTemplateKind.week,
      createdAt: now,
      updatedAt: now,
      payload: {
        'focus': data.focus,
        'priorities': data.priorities,
      },
    );
    await saveTemplate(template);
    return template;
  }

  Future<PersonalTemplate> createMonthTemplate(
    String name,
    DateTime sourceDate,
  ) async {
    final data = month(sourceDate.year, sourceDate.month);
    final now = DateTime.now();
    final template = PersonalTemplate(
      id: const Uuid().v4(),
      name: name,
      kind: PersonalTemplateKind.month,
      createdAt: now,
      updatedAt: now,
      payload: {
        'intention': data.intention,
        'goals': data.goals,
        'books': data.books,
        'films': data.films,
        'hobbies': data.hobbies,
        'wishes': data.wishes,
        'ideas': data.ideas,
        'monthWord': data.monthWord,
        'selfCare': data.selfCare,
        'budgetCents': data.budgetCents,
      },
    );
    await saveTemplate(template);
    return template;
  }

  Future<TemplateApplyResult> applyTemplate(
    PersonalTemplate template,
    DateTime targetDate, {
    bool overwrite = false,
  }) async {
    switch (template.kind) {
      case PersonalTemplateKind.day:
        var created = 0;
        final rawItems = template.payload['items'] as List? ?? const [];
        for (final raw in rawItems) {
          if (raw is! Map) continue;
          final blueprint = DayAgendaTemplateItem.fromJson(
            Map<String, dynamic>.from(raw),
          );
          if (blueprint.title.trim().isEmpty) continue;
          await upsert(blueprint.materialize(targetDate));
          created++;
        }
        return TemplateApplyResult(createdAgendaItems: created);

      case PersonalTemplateKind.week:
        final current = week(targetDate);
        final templateFocus = template.payload['focus'] as String? ?? '';
        final templatePriorities = (template.payload['priorities'] as List? ??
                const [])
            .map((value) => value.toString())
            .where((value) => value.trim().isNotEmpty)
            .toList();
        final updated = current.copyWith(
          focus: overwrite || current.focus.trim().isEmpty
              ? templateFocus
              : current.focus,
          priorities: overwrite || current.priorities.isEmpty
              ? templatePriorities
              : current.priorities,
        );
        final changed =
            jsonEncode(current.toJson()) != jsonEncode(updated.toJson());
        if (changed) await saveWeek(targetDate, updated);
        return TemplateApplyResult(planningChanged: changed);

      case PersonalTemplateKind.month:
        final current = month(targetDate.year, targetDate.month);
        String textValue(String key, String currentValue) {
          final value = template.payload[key] as String? ?? '';
          return overwrite || currentValue.trim().isEmpty ? value : currentValue;
        }

        List<String> listValue(String key, List<String> currentValue) {
          final value = (template.payload[key] as List? ?? const [])
              .map((entry) => entry.toString())
              .where((entry) => entry.trim().isNotEmpty)
              .toList();
          return overwrite || currentValue.isEmpty ? value : currentValue;
        }

        final templateBudget = template.payload['budgetCents'] as int? ?? 0;
        final updated = current.copyWith(
          intention: textValue('intention', current.intention),
          goals: listValue('goals', current.goals),
          books: listValue('books', current.books),
          films: listValue('films', current.films),
          hobbies: listValue('hobbies', current.hobbies),
          wishes: listValue('wishes', current.wishes),
          ideas: listValue('ideas', current.ideas),
          monthWord: textValue('monthWord', current.monthWord),
          selfCare: textValue('selfCare', current.selfCare),
          budgetCents: overwrite || current.budgetCents == 0
              ? templateBudget
              : current.budgetCents,
        );
        final changed =
            jsonEncode(current.toJson()) != jsonEncode(updated.toJson());
        if (changed) {
          await saveMonth(targetDate.year, targetDate.month, updated);
        }
        return TemplateApplyResult(planningChanged: changed);
    }
  }
}
