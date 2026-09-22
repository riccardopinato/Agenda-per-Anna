part of '../main.dart';

enum AgendaThemeMode { system, light, dark }

enum AgendaPalette { rose, lilac, sage, peach, sky }

extension AgendaPaletteUi on AgendaPalette {
  String get label => switch (this) {
        AgendaPalette.rose => 'Rosa',
        AgendaPalette.lilac => 'Lilla',
        AgendaPalette.sage => 'Salvia',
        AgendaPalette.peach => 'Pesca',
        AgendaPalette.sky => 'Cielo',
      };

  Color get seed => switch (this) {
        AgendaPalette.rose => const Color(0xFFE98FAA),
        AgendaPalette.lilac => const Color(0xFF9A8ED0),
        AgendaPalette.sage => const Color(0xFF7FAF98),
        AgendaPalette.peach => const Color(0xFFE9A47D),
        AgendaPalette.sky => const Color(0xFF78A9D1),
      };
}

enum StartTab { home, month, week, today }

extension StartTabUi on StartTab {
  String get label => switch (this) {
        StartTab.home => 'Home',
        StartTab.month => 'Mese',
        StartTab.week => 'Settimana',
        StartTab.today => 'Oggi',
      };
}

class AgendaPreferences {
  final String displayName;
  final AgendaThemeMode themeMode;
  final AgendaPalette palette;
  final bool showDailyQuote;
  final StartTab startTab;
  final AgendaCategory defaultCategory;
  final int defaultEventMinutes;
  final int? defaultPrimaryReminder;
  final int? defaultSecondaryReminder;
  final bool privacyLockEnabled;
  final bool biometricUnlock;
  final int autoLockMinutes;
  final bool hideHomeDetails;
  final String? pinSalt;
  final String? pinHash;
  final bool onboardingDone;

  const AgendaPreferences({
    this.displayName = 'Anna',
    this.themeMode = AgendaThemeMode.system,
    this.palette = AgendaPalette.rose,
    this.showDailyQuote = true,
    this.startTab = StartTab.home,
    this.defaultCategory = AgendaCategory.personal,
    this.defaultEventMinutes = 60,
    this.defaultPrimaryReminder = 30,
    this.defaultSecondaryReminder,
    this.privacyLockEnabled = false,
    this.biometricUnlock = false,
    this.autoLockMinutes = 2,
    this.hideHomeDetails = false,
    this.pinSalt,
    this.pinHash,
    this.onboardingDone = true,
  });

  AgendaPreferences copyWith({
    String? displayName,
    AgendaThemeMode? themeMode,
    AgendaPalette? palette,
    bool? showDailyQuote,
    StartTab? startTab,
    AgendaCategory? defaultCategory,
    int? defaultEventMinutes,
    int? defaultPrimaryReminder,
    int? defaultSecondaryReminder,
    bool? privacyLockEnabled,
    bool? biometricUnlock,
    int? autoLockMinutes,
    bool? hideHomeDetails,
    String? pinSalt,
    String? pinHash,
    bool? onboardingDone,
    bool clearPrimaryReminder = false,
    bool clearSecondaryReminder = false,
    bool clearPin = false,
  }) {
    return AgendaPreferences(
      displayName: displayName ?? this.displayName,
      themeMode: themeMode ?? this.themeMode,
      palette: palette ?? this.palette,
      showDailyQuote: showDailyQuote ?? this.showDailyQuote,
      startTab: startTab ?? this.startTab,
      defaultCategory: defaultCategory ?? this.defaultCategory,
      defaultEventMinutes: defaultEventMinutes ?? this.defaultEventMinutes,
      defaultPrimaryReminder: clearPrimaryReminder
          ? null
          : (defaultPrimaryReminder ?? this.defaultPrimaryReminder),
      defaultSecondaryReminder: clearSecondaryReminder
          ? null
          : (defaultSecondaryReminder ?? this.defaultSecondaryReminder),
      privacyLockEnabled:
          privacyLockEnabled ?? this.privacyLockEnabled,
      biometricUnlock: biometricUnlock ?? this.biometricUnlock,
      autoLockMinutes: autoLockMinutes ?? this.autoLockMinutes,
      hideHomeDetails: hideHomeDetails ?? this.hideHomeDetails,
      pinSalt: clearPin ? null : (pinSalt ?? this.pinSalt),
      pinHash: clearPin ? null : (pinHash ?? this.pinHash),
      onboardingDone: onboardingDone ?? this.onboardingDone,
    );
  }

  Map<String, dynamic> toJson() => {
        'displayName': displayName,
        'themeMode': themeMode.name,
        'palette': palette.name,
        'showDailyQuote': showDailyQuote,
        'startTab': startTab.name,
        'defaultCategory': defaultCategory.name,
        'defaultEventMinutes': defaultEventMinutes,
        'defaultPrimaryReminder': defaultPrimaryReminder,
        'defaultSecondaryReminder': defaultSecondaryReminder,
        'privacyLockEnabled': privacyLockEnabled,
        'biometricUnlock': biometricUnlock,
        'autoLockMinutes': autoLockMinutes,
        'hideHomeDetails': hideHomeDetails,
        'pinSalt': pinSalt,
        'pinHash': pinHash,
        'onboardingDone': onboardingDone,
      };

  factory AgendaPreferences.fromJson(Map<String, dynamic> json) =>
      AgendaPreferences(
        displayName: (json['displayName'] as String? ?? 'Anna').trim().isEmpty
            ? 'Anna'
            : (json['displayName'] as String? ?? 'Anna').trim(),
        themeMode: AgendaThemeMode.values.firstWhere(
          (e) => e.name == json['themeMode'],
          orElse: () => AgendaThemeMode.system,
        ),
        palette: AgendaPalette.values.firstWhere(
          (e) => e.name == json['palette'],
          orElse: () => AgendaPalette.rose,
        ),
        showDailyQuote: json['showDailyQuote'] as bool? ?? true,
        startTab: StartTab.values.firstWhere(
          (e) => e.name == json['startTab'],
          orElse: () => StartTab.home,
        ),
        defaultCategory: AgendaCategory.values.firstWhere(
          (e) => e.name == json['defaultCategory'],
          orElse: () => AgendaCategory.personal,
        ),
        defaultEventMinutes:
            (json['defaultEventMinutes'] as int? ?? 60).clamp(15, 240).toInt(),
        defaultPrimaryReminder: json['defaultPrimaryReminder'] as int?,
        defaultSecondaryReminder:
            json['defaultSecondaryReminder'] as int?,
        privacyLockEnabled:
            json['privacyLockEnabled'] as bool? ?? false,
        biometricUnlock:
            json['biometricUnlock'] as bool? ?? false,
        autoLockMinutes:
            (json['autoLockMinutes'] as int? ?? 2).clamp(0, 60).toInt(),
        hideHomeDetails:
            json['hideHomeDetails'] as bool? ?? false,
        pinSalt: json['pinSalt'] as String?,
        pinHash: json['pinHash'] as String?,
        onboardingDone: json['onboardingDone'] as bool? ?? true,
      );
}

enum ItemType { appointment, task }

enum RecurrenceRule { none, daily, weekly, monthly }

extension RecurrenceRuleUi on RecurrenceRule {
  String get label => switch (this) {
        RecurrenceRule.none => 'Non ripetere',
        RecurrenceRule.daily => 'Ogni giorno',
        RecurrenceRule.weekly => 'Ogni settimana',
        RecurrenceRule.monthly => 'Ogni mese',
      };

  IconData get icon => switch (this) {
        RecurrenceRule.none => Icons.repeat_outlined,
        RecurrenceRule.daily => Icons.today_outlined,
        RecurrenceRule.weekly => Icons.view_week_outlined,
        RecurrenceRule.monthly => Icons.calendar_month_outlined,
      };
}

enum AgendaCategory {
  personal,
  study,
  work,
  health,
  couple,
  leisure,
  other,
}

extension AgendaCategoryUi on AgendaCategory {
  String get label => switch (this) {
        AgendaCategory.personal => 'Personale',
        AgendaCategory.study => 'Studio',
        AgendaCategory.work => 'Lavoro',
        AgendaCategory.health => 'Salute',
        AgendaCategory.couple => 'Noi ♡',
        AgendaCategory.leisure => 'Tempo libero',
        AgendaCategory.other => 'Altro',
      };

  IconData get icon => switch (this) {
        AgendaCategory.personal => Icons.favorite_outline,
        AgendaCategory.study => Icons.menu_book_outlined,
        AgendaCategory.work => Icons.work_outline,
        AgendaCategory.health => Icons.spa_outlined,
        AgendaCategory.couple => Icons.favorite_border,
        AgendaCategory.leisure => Icons.celebration_outlined,
        AgendaCategory.other => Icons.label_outline,
      };

  Color get color => switch (this) {
        AgendaCategory.personal => const Color(0xFFE88CA8),
        AgendaCategory.study => const Color(0xFF8F8BD8),
        AgendaCategory.work => const Color(0xFF6C9DC6),
        AgendaCategory.health => const Color(0xFF70B69A),
        AgendaCategory.couple => const Color(0xFFE07C93),
        AgendaCategory.leisure => const Color(0xFFE7A85D),
        AgendaCategory.other => const Color(0xFF9B93A6),
      };
}

class AgendaItem {
  final String id;
  final String title;
  final String note;
  final DateTime date;
  final TimeOfDay? start;
  final TimeOfDay? end;
  final ItemType type;
  final AgendaCategory category;
  final int? reminderMinutesBefore;
  final int? secondaryReminderMinutesBefore;
  final bool done;
  final bool pinned;

  const AgendaItem({
    required this.id,
    required this.title,
    required this.note,
    required this.date,
    required this.type,
    this.category = AgendaCategory.personal,
    this.reminderMinutesBefore,
    this.secondaryReminderMinutesBefore,
    this.start,
    this.end,
    this.done = false,
    this.pinned = false,
  });

  AgendaItem copyWith({
    String? title,
    String? note,
    DateTime? date,
    TimeOfDay? start,
    TimeOfDay? end,
    ItemType? type,
    AgendaCategory? category,
    int? reminderMinutesBefore,
    int? secondaryReminderMinutesBefore,
    bool? done,
    bool? pinned,
    bool clearTime = false,
    bool clearReminder = false,
    bool clearSecondaryReminder = false,
  }) {
    return AgendaItem(
      id: id,
      title: title ?? this.title,
      note: note ?? this.note,
      date: date ?? this.date,
      type: type ?? this.type,
      category: category ?? this.category,
      reminderMinutesBefore:
          clearReminder ? null : (reminderMinutesBefore ?? this.reminderMinutesBefore),
      secondaryReminderMinutesBefore: clearSecondaryReminder
          ? null
          : (secondaryReminderMinutesBefore ?? this.secondaryReminderMinutesBefore),
      start: clearTime ? null : (start ?? this.start),
      end: clearTime ? null : (end ?? this.end),
      done: done ?? this.done,
      pinned: pinned ?? this.pinned,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'note': note,
        'date': date.toIso8601String(),
        'type': type.name,
        'category': category.name,
        'reminderMinutesBefore': reminderMinutesBefore,
        'secondaryReminderMinutesBefore': secondaryReminderMinutesBefore,
        'done': done,
        'pinned': pinned,
        'start': start == null ? null : [start!.hour, start!.minute],
        'end': end == null ? null : [end!.hour, end!.minute],
      };

  factory AgendaItem.fromJson(Map<String, dynamic> json) {
    TimeOfDay? parseTime(dynamic value) {
      if (value is List && value.length == 2) {
        return TimeOfDay(hour: value[0] as int, minute: value[1] as int);
      }
      return null;
    }

    return AgendaItem(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      note: json['note'] as String? ?? '',
      date: DateTime.parse(json['date'] as String),
      type: ItemType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ItemType.appointment,
      ),
      category: AgendaCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => AgendaCategory.personal,
      ),
      reminderMinutesBefore: json['reminderMinutesBefore'] as int?,
      secondaryReminderMinutesBefore:
          json['secondaryReminderMinutesBefore'] as int?,
      done: json['done'] as bool? ?? false,
      pinned: json['pinned'] as bool? ?? false,
      start: parseTime(json['start']),
      end: parseTime(json['end']),
    );
  }
}

class InboxEntry {
  final String id;
  final String text;
  final DateTime createdAt;
  final bool pinned;

  const InboxEntry({
    required this.id,
    required this.text,
    required this.createdAt,
    this.pinned = false,
  });

  InboxEntry copyWith({
    String? text,
    bool? pinned,
  }) =>
      InboxEntry(
        id: id,
        text: text ?? this.text,
        createdAt: createdAt,
        pinned: pinned ?? this.pinned,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
        'pinned': pinned,
      };

  factory InboxEntry.fromJson(Map<String, dynamic> json) => InboxEntry(
        id: json['id'] as String,
        text: json['text'] as String? ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
        pinned: json['pinned'] as bool? ?? false,
      );
}

enum DayMood { great, good, neutral, low, hard }

extension DayMoodUi on DayMood {
  String get label => switch (this) {
        DayMood.great => 'Benissimo',
        DayMood.good => 'Bene',
        DayMood.neutral => 'Così così',
        DayMood.low => 'Giù',
        DayMood.hard => 'Difficile',
      };

  String get emoji => switch (this) {
        DayMood.great => '😍',
        DayMood.good => '😊',
        DayMood.neutral => '😐',
        DayMood.low => '😔',
        DayMood.hard => '😣',
      };

  Color get color => switch (this) {
        DayMood.great => const Color(0xFFE789A7),
        DayMood.good => const Color(0xFF79B697),
        DayMood.neutral => const Color(0xFFE0A85C),
        DayMood.low => const Color(0xFF8C9BC7),
        DayMood.hard => const Color(0xFF9B8A9D),
      };
}

class HabitDefinition {
  final String id;
  final String name;

  const HabitDefinition({
    required this.id,
    required this.name,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
      };

  factory HabitDefinition.fromJson(Map<String, dynamic> json) =>
      HabitDefinition(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
      );
}

enum DiaryBlockType { note, sketch, photo }

enum DiarySketchTool {
  pen,
  highlighter,
  eraser,
  line,
  rectangle,
  ellipse,
  select,
  lasso,
  hand,
}

enum DiarySketchPaper { plain, ruled, grid, dots }

class DiarySketchPoint {
  final double x;
  final double y;

  const DiarySketchPoint(this.x, this.y);

  Map<String, dynamic> toJson() => {'x': x, 'y': y};

  factory DiarySketchPoint.fromJson(Map<String, dynamic> json) =>
      DiarySketchPoint(
        (json['x'] as num? ?? 0).toDouble(),
        (json['y'] as num? ?? 0).toDouble(),
      );
}

class DiarySketchStroke {
  final DiarySketchTool tool;
  final int colorValue;
  final double width;
  final List<DiarySketchPoint> points;

  const DiarySketchStroke({
    required this.tool,
    required this.colorValue,
    required this.width,
    required this.points,
  });

  DiarySketchStroke copyWith({
    List<DiarySketchPoint>? points,
  }) =>
      DiarySketchStroke(
        tool: tool,
        colorValue: colorValue,
        width: width,
        points: points ?? this.points,
      );

  Map<String, dynamic> toJson() => {
        'tool': tool.name,
        'colorValue': colorValue,
        'width': width,
        'points': points.map((point) => point.toJson()).toList(),
      };

  factory DiarySketchStroke.fromJson(Map<String, dynamic> json) =>
      DiarySketchStroke(
        tool: DiarySketchTool.values.firstWhere(
          (value) => value.name == json['tool'],
          orElse: () => DiarySketchTool.pen,
        ),
        colorValue: json['colorValue'] as int? ?? 0xFF222222,
        width: (json['width'] as num? ?? 3).toDouble(),
        points: (json['points'] as List? ?? const [])
            .whereType<Map>()
            .map(
              (point) => DiarySketchPoint.fromJson(
                Map<String, dynamic>.from(point),
              ),
            )
            .toList(),
      );
}

class DiarySketchTextElement {
  final String id;
  final String text;
  final double x;
  final double y;
  final double fontSize;
  final int colorValue;

  const DiarySketchTextElement({
    required this.id,
    required this.text,
    required this.x,
    required this.y,
    this.fontSize = 22,
    this.colorValue = 0xFF222222,
  });

  DiarySketchTextElement copyWith({
    String? text,
    double? x,
    double? y,
    double? fontSize,
    int? colorValue,
  }) =>
      DiarySketchTextElement(
        id: id,
        text: text ?? this.text,
        x: x ?? this.x,
        y: y ?? this.y,
        fontSize: fontSize ?? this.fontSize,
        colorValue: colorValue ?? this.colorValue,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'x': x,
        'y': y,
        'fontSize': fontSize,
        'colorValue': colorValue,
      };

  factory DiarySketchTextElement.fromJson(Map<String, dynamic> json) =>
      DiarySketchTextElement(
        id: json['id'] as String? ?? const Uuid().v4(),
        text: json['text'] as String? ?? '',
        x: (json['x'] as num? ?? 0.12).toDouble(),
        y: (json['y'] as num? ?? 0.12).toDouble(),
        fontSize: (json['fontSize'] as num? ?? 22).toDouble(),
        colorValue: json['colorValue'] as int? ?? 0xFF222222,
      );
}

class DiarySketchImageElement {
  final String id;
  final String imageBase64;
  final double x;
  final double y;
  final double width;
  final double height;

  const DiarySketchImageElement({
    required this.id,
    required this.imageBase64,
    required this.x,
    required this.y,
    this.width = 0.52,
    this.height = 0.34,
  });

  DiarySketchImageElement copyWith({
    String? imageBase64,
    double? x,
    double? y,
    double? width,
    double? height,
  }) =>
      DiarySketchImageElement(
        id: id,
        imageBase64: imageBase64 ?? this.imageBase64,
        x: x ?? this.x,
        y: y ?? this.y,
        width: width ?? this.width,
        height: height ?? this.height,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'imageBase64': imageBase64,
        'x': x,
        'y': y,
        'width': width,
        'height': height,
      };

  factory DiarySketchImageElement.fromJson(Map<String, dynamic> json) =>
      DiarySketchImageElement(
        id: json['id'] as String? ?? const Uuid().v4(),
        imageBase64: json['imageBase64'] as String? ?? '',
        x: (json['x'] as num? ?? 0.12).toDouble(),
        y: (json['y'] as num? ?? 0.12).toDouble(),
        width: (json['width'] as num? ?? 0.52).toDouble(),
        height: (json['height'] as num? ?? 0.34).toDouble(),
      );
}

class DiarySketchPage {
  final String id;
  final DiarySketchPaper paper;
  final List<DiarySketchStroke> strokes;
  final List<DiarySketchTextElement> textElements;
  final List<DiarySketchImageElement> imageElements;

  const DiarySketchPage({
    required this.id,
    this.paper = DiarySketchPaper.plain,
    this.strokes = const [],
    this.textElements = const [],
    this.imageElements = const [],
  });

  DiarySketchPage copyWith({
    DiarySketchPaper? paper,
    List<DiarySketchStroke>? strokes,
    List<DiarySketchTextElement>? textElements,
    List<DiarySketchImageElement>? imageElements,
  }) =>
      DiarySketchPage(
        id: id,
        paper: paper ?? this.paper,
        strokes: strokes ?? this.strokes,
        textElements: textElements ?? this.textElements,
        imageElements: imageElements ?? this.imageElements,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'paper': paper.name,
        'strokes': strokes.map((stroke) => stroke.toJson()).toList(),
        'textElements':
            textElements.map((element) => element.toJson()).toList(),
        'imageElements':
            imageElements.map((element) => element.toJson()).toList(),
      };

  factory DiarySketchPage.fromJson(Map<String, dynamic> json) =>
      DiarySketchPage(
        id: json['id'] as String? ?? const Uuid().v4(),
        paper: DiarySketchPaper.values.firstWhere(
          (value) => value.name == json['paper'],
          orElse: () => DiarySketchPaper.plain,
        ),
        strokes: (json['strokes'] as List? ?? const [])
            .whereType<Map>()
            .map(
              (stroke) => DiarySketchStroke.fromJson(
                Map<String, dynamic>.from(stroke),
              ),
            )
            .toList(),
        textElements: (json['textElements'] as List? ?? const [])
            .whereType<Map>()
            .map(
              (element) => DiarySketchTextElement.fromJson(
                Map<String, dynamic>.from(element),
              ),
            )
            .toList(),
        imageElements: (json['imageElements'] as List? ?? const [])
            .whereType<Map>()
            .map(
              (element) => DiarySketchImageElement.fromJson(
                Map<String, dynamic>.from(element),
              ),
            )
            .toList(),
      );
}

class DiaryBlock {
  final String id;
  final DiaryBlockType type;
  final DateTime createdAt;
  final String text;
  final String imageBase64;
  final List<DiarySketchPage> pages;

  const DiaryBlock({
    required this.id,
    required this.type,
    required this.createdAt,
    this.text = '',
    this.imageBase64 = '',
    this.pages = const [],
  });

  DiaryBlock copyWith({
    String? text,
    String? imageBase64,
    List<DiarySketchPage>? pages,
  }) =>
      DiaryBlock(
        id: id,
        type: type,
        createdAt: createdAt,
        text: text ?? this.text,
        imageBase64: imageBase64 ?? this.imageBase64,
        pages: pages ?? this.pages,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'text': text,
        'imageBase64': imageBase64,
        'pages': pages.map((page) => page.toJson()).toList(),
      };

  factory DiaryBlock.fromJson(Map<String, dynamic> json) => DiaryBlock(
        id: json['id'] as String? ?? const Uuid().v4(),
        type: DiaryBlockType.values.firstWhere(
          (value) => value.name == json['type'],
          orElse: () => DiaryBlockType.note,
        ),
        createdAt:
            DateTime.tryParse(json['createdAt'] as String? ?? '')?.toLocal() ??
                DateTime.now(),
        text: json['text'] as String? ?? '',
        imageBase64: json['imageBase64'] as String? ?? '',
        pages: (json['pages'] as List? ?? const [])
            .whereType<Map>()
            .map(
              (page) => DiarySketchPage.fromJson(
                Map<String, dynamic>.from(page),
              ),
            )
            .toList(),
      );
}

class DayJournal {
  final String beautiful;
  final String note;
  final DayMood? mood;
  final List<String> gratitude;
  final List<String> completedHabitIds;
  final List<DiaryBlock> blocks;

  const DayJournal({
    this.beautiful = '',
    this.note = '',
    this.mood,
    this.gratitude = const [],
    this.completedHabitIds = const [],
    this.blocks = const [],
  });

  DayJournal copyWith({
    String? beautiful,
    String? note,
    DayMood? mood,
    List<String>? gratitude,
    List<String>? completedHabitIds,
    List<DiaryBlock>? blocks,
    bool clearMood = false,
  }) {
    return DayJournal(
      beautiful: beautiful ?? this.beautiful,
      note: note ?? this.note,
      mood: clearMood ? null : (mood ?? this.mood),
      gratitude: gratitude ?? this.gratitude,
      completedHabitIds: completedHabitIds ?? this.completedHabitIds,
      blocks: blocks ?? this.blocks,
    );
  }

  Map<String, dynamic> toJson() => {
        'beautiful': beautiful,
        'note': note,
        'mood': mood?.name,
        'gratitude': gratitude,
        'completedHabitIds': completedHabitIds,
        'blocks': blocks.map((block) => block.toJson()).toList(),
      };

  factory DayJournal.fromJson(Map<String, dynamic> json) => DayJournal(
        beautiful: json['beautiful'] as String? ?? '',
        note: json['note'] as String? ?? '',
        mood: json['mood'] == null
            ? null
            : DayMood.values.firstWhere(
                (e) => e.name == json['mood'],
                orElse: () => DayMood.neutral,
              ),
        gratitude:
            List<String>.from(json['gratitude'] as List? ?? const []),
        completedHabitIds: List<String>.from(
          json['completedHabitIds'] as List? ?? const [],
        ),
        blocks: (json['blocks'] as List? ?? const [])
            .whereType<Map>()
            .map(
              (block) => DiaryBlock.fromJson(
                Map<String, dynamic>.from(block),
              ),
            )
            .toList(),
      );
}

class WeekData {
  final String focus;
  final List<String> priorities;
  final String bestThing;
  final String reflection;

  const WeekData({
    this.focus = '',
    this.priorities = const [],
    this.bestThing = '',
    this.reflection = '',
  });

  WeekData copyWith({
    String? focus,
    List<String>? priorities,
    String? bestThing,
    String? reflection,
  }) {
    return WeekData(
      focus: focus ?? this.focus,
      priorities: priorities ?? this.priorities,
      bestThing: bestThing ?? this.bestThing,
      reflection: reflection ?? this.reflection,
    );
  }

  Map<String, dynamic> toJson() => {
        'focus': focus,
        'priorities': priorities,
        'bestThing': bestThing,
        'reflection': reflection,
      };

  factory WeekData.fromJson(Map<String, dynamic> json) => WeekData(
        focus: json['focus'] as String? ?? '',
        priorities: List<String>.from(json['priorities'] as List? ?? const []),
        bestThing: json['bestThing'] as String? ?? '',
        reflection: json['reflection'] as String? ?? '',
      );
}

class MonthlyData {
  final String intention;
  final List<String> goals;
  final List<String> books;
  final List<String> films;
  final List<String> hobbies;
  final List<String> wishes;
  final List<String> ideas;
  final String monthWord;
  final String selfCare;
  final int budgetCents;
  final List<ExpenseEntry> expenses;
  final String bestMoment;
  final String lesson;
  final String challenge;
  final String nextMonth;
  final String reflection;

  const MonthlyData({
    this.intention = '',
    this.goals = const [],
    this.books = const [],
    this.films = const [],
    this.hobbies = const [],
    this.wishes = const [],
    this.ideas = const [],
    this.monthWord = '',
    this.selfCare = '',
    this.budgetCents = 0,
    this.expenses = const [],
    this.bestMoment = '',
    this.lesson = '',
    this.challenge = '',
    this.nextMonth = '',
    this.reflection = '',
  });

  MonthlyData copyWith({
    String? intention,
    List<String>? goals,
    List<String>? books,
    List<String>? films,
    List<String>? hobbies,
    List<String>? wishes,
    List<String>? ideas,
    String? monthWord,
    String? selfCare,
    int? budgetCents,
    List<ExpenseEntry>? expenses,
    String? bestMoment,
    String? lesson,
    String? challenge,
    String? nextMonth,
    String? reflection,
  }) {
    return MonthlyData(
      intention: intention ?? this.intention,
      goals: goals ?? this.goals,
      books: books ?? this.books,
      films: films ?? this.films,
      hobbies: hobbies ?? this.hobbies,
      wishes: wishes ?? this.wishes,
      ideas: ideas ?? this.ideas,
      monthWord: monthWord ?? this.monthWord,
      selfCare: selfCare ?? this.selfCare,
      budgetCents: budgetCents ?? this.budgetCents,
      expenses: expenses ?? this.expenses,
      bestMoment: bestMoment ?? this.bestMoment,
      lesson: lesson ?? this.lesson,
      challenge: challenge ?? this.challenge,
      nextMonth: nextMonth ?? this.nextMonth,
      reflection: reflection ?? this.reflection,
    );
  }

  Map<String, dynamic> toJson() => {
        'intention': intention,
        'goals': goals,
        'books': books,
        'films': films,
        'hobbies': hobbies,
        'wishes': wishes,
        'ideas': ideas,
        'monthWord': monthWord,
        'selfCare': selfCare,
        'budgetCents': budgetCents,
        'expenses': expenses.map((e) => e.toJson()).toList(),
        'bestMoment': bestMoment,
        'lesson': lesson,
        'challenge': challenge,
        'nextMonth': nextMonth,
        'reflection': reflection,
      };

  factory MonthlyData.fromJson(Map<String, dynamic> json) => MonthlyData(
        intention: json['intention'] as String? ?? '',
        goals: List<String>.from(json['goals'] as List? ?? const []),
        books: List<String>.from(json['books'] as List? ?? const []),
        films: List<String>.from(json['films'] as List? ?? const []),
        hobbies: List<String>.from(json['hobbies'] as List? ?? const []),
        wishes: List<String>.from(json['wishes'] as List? ?? const []),
        ideas: List<String>.from(json['ideas'] as List? ?? const []),
        monthWord: json['monthWord'] as String? ?? '',
        selfCare: json['selfCare'] as String? ?? '',
        budgetCents: json['budgetCents'] as int? ?? 0,
        expenses: (json['expenses'] as List? ?? const [])
            .map((e) => ExpenseEntry.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        bestMoment: json['bestMoment'] as String? ?? '',
        lesson: json['lesson'] as String? ?? '',
        challenge: json['challenge'] as String? ?? '',
        nextMonth: json['nextMonth'] as String? ?? '',
        reflection: json['reflection'] as String? ?? '',
      );
}

class ExpenseEntry {
  final String id;
  final int cents;
  final String category;
  final String note;
  final DateTime date;

  const ExpenseEntry({
    required this.id,
    required this.cents,
    required this.category,
    required this.note,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'cents': cents,
        'category': category,
        'note': note,
        'date': date.toIso8601String(),
      };

  factory ExpenseEntry.fromJson(Map<String, dynamic> json) => ExpenseEntry(
        id: json['id'] as String,
        cents: json['cents'] as int? ?? 0,
        category: json['category'] as String? ?? 'Altro',
        note: json['note'] as String? ?? '',
        date: DateTime.parse(json['date'] as String),
      );
}

class _LocalSyncEntity {
  final String entityType;
  final String entityId;
  final Map<String, dynamic> payload;

  const _LocalSyncEntity({
    required this.entityType,
    required this.entityId,
    required this.payload,
  });

  String get localKey => '$entityType:$entityId';
}

enum SharedEntryType { appointment, task, note, photo, sketch }

extension SharedEntryTypeUi on SharedEntryType {
  String get label => switch (this) {
        SharedEntryType.appointment => 'Appuntamento',
        SharedEntryType.task => 'Da fare',
        SharedEntryType.note => 'Nota',
        SharedEntryType.photo => 'Foto',
        SharedEntryType.sketch => 'Sketch',
      };

  IconData get icon => switch (this) {
        SharedEntryType.appointment => Icons.event_outlined,
        SharedEntryType.task => Icons.check_circle_outline,
        SharedEntryType.note => Icons.sticky_note_2_outlined,
        SharedEntryType.photo => Icons.photo_outlined,
        SharedEntryType.sketch => Icons.draw_outlined,
      };

  bool get supportsTime =>
      this == SharedEntryType.appointment || this == SharedEntryType.task;

  bool get isMedia =>
      this == SharedEntryType.photo || this == SharedEntryType.sketch;
}

class SharedEntry {
  final String id;
  final SharedEntryType type;
  final String title;
  final String note;
  final DateTime date;
  final TimeOfDay? start;
  final TimeOfDay? end;
  final bool done;
  final String? updatedBy;
  final DateTime? updatedAt;
  final String editorName;
  final String mediaPath;
  final String mediaThumbnailBase64;
  final List<DiarySketchPage> sketchPages;

  const SharedEntry({
    required this.id,
    required this.type,
    required this.title,
    required this.note,
    required this.date,
    this.start,
    this.end,
    this.done = false,
    this.updatedBy,
    this.updatedAt,
    this.editorName = '',
    this.mediaPath = '',
    this.mediaThumbnailBase64 = '',
    this.sketchPages = const [],
  });

  SharedEntry copyWith({
    SharedEntryType? type,
    String? title,
    String? note,
    DateTime? date,
    TimeOfDay? start,
    TimeOfDay? end,
    bool? done,
    String? updatedBy,
    DateTime? updatedAt,
    String? editorName,
    String? mediaPath,
    String? mediaThumbnailBase64,
    List<DiarySketchPage>? sketchPages,
    bool clearTime = false,
    bool clearUpdatedBy = false,
    bool clearMedia = false,
    bool clearSketch = false,
  }) =>
      SharedEntry(
        id: id,
        type: type ?? this.type,
        title: title ?? this.title,
        note: note ?? this.note,
        date: date ?? this.date,
        start: clearTime ? null : (start ?? this.start),
        end: clearTime ? null : (end ?? this.end),
        done: done ?? this.done,
        updatedBy: clearUpdatedBy ? null : (updatedBy ?? this.updatedBy),
        updatedAt: updatedAt ?? this.updatedAt,
        editorName: editorName ?? this.editorName,
        mediaPath: clearMedia ? '' : (mediaPath ?? this.mediaPath),
        mediaThumbnailBase64: clearMedia
            ? ''
            : (mediaThumbnailBase64 ?? this.mediaThumbnailBase64),
        sketchPages:
            clearSketch ? const [] : (sketchPages ?? this.sketchPages),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'note': note,
        'date': date.toIso8601String(),
        'start': start == null
            ? null
            : {'hour': start!.hour, 'minute': start!.minute},
        'end': end == null
            ? null
            : {'hour': end!.hour, 'minute': end!.minute},
        'done': done,
        'editorName': editorName,
        'mediaPath': mediaPath,
        'mediaThumbnailBase64': mediaThumbnailBase64,
        'sketchPages': sketchPages.map((page) => page.toJson()).toList(),
      };

  Map<String, dynamic> toCacheJson() => {
        ...toJson(),
        '_updatedBy': updatedBy,
        '_updatedAt': updatedAt?.toUtc().toIso8601String(),
      };

  factory SharedEntry.fromCacheJson(Map<String, dynamic> json) =>
      SharedEntry.fromJson(
        json,
        updatedBy: json['_updatedBy'] as String?,
        updatedAt: DateTime.tryParse(json['_updatedAt'] as String? ?? ''),
      );

  factory SharedEntry.fromJson(
    Map<String, dynamic> json, {
    String? updatedBy,
    DateTime? updatedAt,
  }) {
    TimeOfDay? parseTime(dynamic raw) {
      if (raw is! Map) return null;
      final map = Map<String, dynamic>.from(raw);
      return TimeOfDay(
        hour: map['hour'] as int? ?? 0,
        minute: map['minute'] as int? ?? 0,
      );
    }

    return SharedEntry(
      id: json['id'] as String,
      type: SharedEntryType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => SharedEntryType.appointment,
      ),
      title: json['title'] as String? ?? '',
      note: json['note'] as String? ?? '',
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      start: parseTime(json['start']),
      end: parseTime(json['end']),
      done: json['done'] as bool? ?? false,
      updatedBy: updatedBy,
      updatedAt: updatedAt,
      editorName: json['editorName'] as String? ?? '',
      mediaPath: json['mediaPath'] as String? ?? '',
      mediaThumbnailBase64: json['mediaThumbnailBase64'] as String? ?? '',
      sketchPages: (json['sketchPages'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (page) => DiarySketchPage.fromJson(
              Map<String, dynamic>.from(page),
            ),
          )
          .toList(),
    );
  }
}

enum SharedPendingAction { upsert, delete }

class SharedPendingOperation {
  final SharedPendingAction action;
  final String entityId;
  final Map<String, dynamic>? payload;
  final DateTime updatedAt;

  const SharedPendingOperation({
    required this.action,
    required this.entityId,
    required this.updatedAt,
    this.payload,
  });

  Map<String, dynamic> toJson() => {
        'action': action.name,
        'entityId': entityId,
        'payload': payload,
        'updatedAt': updatedAt.toUtc().toIso8601String(),
      };

  factory SharedPendingOperation.fromJson(Map<String, dynamic> json) {
    final actionName = json['action'] as String? ?? 'upsert';
    return SharedPendingOperation(
      action: SharedPendingAction.values.firstWhere(
        (value) => value.name == actionName,
        orElse: () => SharedPendingAction.upsert,
      ),
      entityId: json['entityId'] as String? ?? '',
      payload: json['payload'] is Map
          ? Map<String, dynamic>.from(json['payload'] as Map)
          : null,
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }
}
class BackupSummary {
  final DateTime exportedAt;
  final int itemCount;
  final int journalCount;
  final int monthCount;
  final int weekCount;
  final int habitCount;

  const BackupSummary({
    required this.exportedAt,
    required this.itemCount,
    required this.journalCount,
    required this.monthCount,
    required this.weekCount,
    required this.habitCount,
  });
}

class LocalBackupSnapshot {
  final String id;
  final DateTime createdAt;
  final String label;
  final Map<String, dynamic> data;

  const LocalBackupSnapshot({
    required this.id,
    required this.createdAt,
    required this.label,
    required this.data,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'label': label,
        'data': data,
      };

  factory LocalBackupSnapshot.fromJson(Map<String, dynamic> json) =>
      LocalBackupSnapshot(
        id: json['id'] as String? ?? const Uuid().v4(),
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
        label: json['label'] as String? ?? 'Backup automatico',
        data: Map<String, dynamic>.from(json['data'] as Map? ?? const {}),
      );
}
