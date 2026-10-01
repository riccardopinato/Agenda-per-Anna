import 'dart:math' as math;

enum CycleFlow { none, spotting, light, medium, heavy }

extension CycleFlowX on CycleFlow {
  bool get isPeriodFlow =>
      this == CycleFlow.light ||
      this == CycleFlow.medium ||
      this == CycleFlow.heavy;
}

enum CyclePredictionConfidence { low, medium, high }

enum CyclePhase { period, follicular, fertile, ovulation, luteal, unknown }

DateTime cycleDateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

String cycleDateKey(DateTime value) {
  final date = cycleDateOnly(value);
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

class CycleDayLog {
  final DateTime date;
  final CycleFlow flow;
  final int painLevel;
  final int energyLevel;
  final List<String> symptoms;
  final List<String> moods;
  final String discharge;
  final bool hadSex;
  final double? basalTemperature;
  final String ovulationTest;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CycleDayLog({
    required this.date,
    this.flow = CycleFlow.none,
    this.painLevel = 0,
    this.energyLevel = 3,
    this.symptoms = const [],
    this.moods = const [],
    this.discharge = '',
    this.hadSex = false,
    this.basalTemperature,
    this.ovulationTest = '',
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'date': cycleDateKey(date),
        'flow': flow.name,
        'painLevel': painLevel,
        'energyLevel': energyLevel,
        'symptoms': symptoms,
        'moods': moods,
        'discharge': discharge,
        'hadSex': hadSex,
        if (basalTemperature != null) 'basalTemperature': basalTemperature,
        'ovulationTest': ovulationTest,
        'notes': notes,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
      };

  factory CycleDayLog.fromJson(Map<String, dynamic> json) {
    final rawDate = DateTime.tryParse(json['date']?.toString() ?? '');
    final rawFlow = json['flow']?.toString();
    return CycleDayLog(
      date: cycleDateOnly(rawDate ?? DateTime.now()),
      flow: CycleFlow.values.firstWhere(
        (value) => value.name == rawFlow,
        orElse: () => CycleFlow.none,
      ),
      painLevel: ((json['painLevel'] as num?)?.toInt() ?? 0).clamp(0, 5),
      energyLevel: ((json['energyLevel'] as num?)?.toInt() ?? 3).clamp(0, 5),
      symptoms: (json['symptoms'] as List? ?? const [])
          .map((value) => value.toString())
          .where((value) => value.isNotEmpty)
          .toList(growable: false),
      moods: (json['moods'] as List? ?? const [])
          .map((value) => value.toString())
          .where((value) => value.isNotEmpty)
          .toList(growable: false),
      discharge: json['discharge']?.toString() ?? '',
      hadSex: json['hadSex'] == true,
      basalTemperature: (json['basalTemperature'] as num?)?.toDouble(),
      ovulationTest: json['ovulationTest']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '')
              ?.toLocal() ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '')
              ?.toLocal() ??
          DateTime.now(),
    );
  }
}

class CycleSettings {
  final int averageCycleLength;
  final int averagePeriodLength;
  final String regularityMode;
  final bool trackFertility;
  final bool trackSexualActivity;
  final bool trackBasalTemperature;
  final bool trackCervicalMucus;
  final bool discreetNotifications;
  final bool periodReminderEnabled;
  final int periodReminderDaysBefore;
  final bool dailyLogReminderEnabled;
  final int dailyLogReminderHour;
  final int dailyLogReminderMinute;

  const CycleSettings({
    this.averageCycleLength = 28,
    this.averagePeriodLength = 5,
    this.regularityMode = 'unknown',
    this.trackFertility = true,
    this.trackSexualActivity = false,
    this.trackBasalTemperature = false,
    this.trackCervicalMucus = false,
    this.discreetNotifications = true,
    this.periodReminderEnabled = false,
    this.periodReminderDaysBefore = 2,
    this.dailyLogReminderEnabled = false,
    this.dailyLogReminderHour = 20,
    this.dailyLogReminderMinute = 0,
  });

  CycleSettings copyWith({
    int? averageCycleLength,
    int? averagePeriodLength,
    String? regularityMode,
    bool? trackFertility,
    bool? trackSexualActivity,
    bool? trackBasalTemperature,
    bool? trackCervicalMucus,
    bool? discreetNotifications,
    bool? periodReminderEnabled,
    int? periodReminderDaysBefore,
    bool? dailyLogReminderEnabled,
    int? dailyLogReminderHour,
    int? dailyLogReminderMinute,
  }) =>
      CycleSettings(
        averageCycleLength: averageCycleLength ?? this.averageCycleLength,
        averagePeriodLength: averagePeriodLength ?? this.averagePeriodLength,
        regularityMode: regularityMode ?? this.regularityMode,
        trackFertility: trackFertility ?? this.trackFertility,
        trackSexualActivity:
            trackSexualActivity ?? this.trackSexualActivity,
        trackBasalTemperature:
            trackBasalTemperature ?? this.trackBasalTemperature,
        trackCervicalMucus:
            trackCervicalMucus ?? this.trackCervicalMucus,
        discreetNotifications:
            discreetNotifications ?? this.discreetNotifications,
        periodReminderEnabled:
            periodReminderEnabled ?? this.periodReminderEnabled,
        periodReminderDaysBefore:
            periodReminderDaysBefore ?? this.periodReminderDaysBefore,
        dailyLogReminderEnabled:
            dailyLogReminderEnabled ?? this.dailyLogReminderEnabled,
        dailyLogReminderHour:
            dailyLogReminderHour ?? this.dailyLogReminderHour,
        dailyLogReminderMinute:
            dailyLogReminderMinute ?? this.dailyLogReminderMinute,
      );

  Map<String, dynamic> toJson() => {
        'averageCycleLength': averageCycleLength,
        'averagePeriodLength': averagePeriodLength,
        'regularityMode': regularityMode,
        'trackFertility': trackFertility,
        'trackSexualActivity': trackSexualActivity,
        'trackBasalTemperature': trackBasalTemperature,
        'trackCervicalMucus': trackCervicalMucus,
        'discreetNotifications': discreetNotifications,
        'periodReminderEnabled': periodReminderEnabled,
        'periodReminderDaysBefore': periodReminderDaysBefore,
        'dailyLogReminderEnabled': dailyLogReminderEnabled,
        'dailyLogReminderHour': dailyLogReminderHour,
        'dailyLogReminderMinute': dailyLogReminderMinute,
      };

  factory CycleSettings.fromJson(Map<String, dynamic> json) => CycleSettings(
        averageCycleLength:
            ((json['averageCycleLength'] as num?)?.toInt() ?? 28).clamp(15, 60),
        averagePeriodLength:
            ((json['averagePeriodLength'] as num?)?.toInt() ?? 5).clamp(1, 14),
        regularityMode: json['regularityMode']?.toString() ?? 'unknown',
        trackFertility: json['trackFertility'] != false,
        trackSexualActivity: json['trackSexualActivity'] == true,
        trackBasalTemperature: json['trackBasalTemperature'] == true,
        trackCervicalMucus: json['trackCervicalMucus'] == true,
        discreetNotifications: json['discreetNotifications'] != false,
        periodReminderEnabled: json['periodReminderEnabled'] == true,
        periodReminderDaysBefore:
            ((json['periodReminderDaysBefore'] as num?)?.toInt() ?? 2)
                .clamp(0, 7),
        dailyLogReminderEnabled: json['dailyLogReminderEnabled'] == true,
        dailyLogReminderHour:
            ((json['dailyLogReminderHour'] as num?)?.toInt() ?? 20)
                .clamp(0, 23),
        dailyLogReminderMinute:
            ((json['dailyLogReminderMinute'] as num?)?.toInt() ?? 0)
                .clamp(0, 59),
      );
}

class CycleTrackerState {
  static const int currentVersion = 1;

  final int version;
  final CycleSettings settings;
  final Map<String, CycleDayLog> dayLogs;

  const CycleTrackerState({
    this.version = currentVersion,
    this.settings = const CycleSettings(),
    this.dayLogs = const {},
  });

  CycleDayLog? logFor(DateTime date) => dayLogs[cycleDateKey(date)];

  CycleTrackerState upsertLog(CycleDayLog log) {
    final next = Map<String, CycleDayLog>.from(dayLogs)
      ..[cycleDateKey(log.date)] = log;
    return CycleTrackerState(
      version: currentVersion,
      settings: settings,
      dayLogs: Map.unmodifiable(next),
    );
  }

  CycleTrackerState removeLog(DateTime date) {
    final next = Map<String, CycleDayLog>.from(dayLogs)
      ..remove(cycleDateKey(date));
    return CycleTrackerState(
      version: currentVersion,
      settings: settings,
      dayLogs: Map.unmodifiable(next),
    );
  }

  CycleTrackerState withSettings(CycleSettings value) => CycleTrackerState(
        version: currentVersion,
        settings: value,
        dayLogs: dayLogs,
      );

  Map<String, dynamic> toJson() => {
        'v': currentVersion,
        'settings': settings.toJson(),
        'dayLogs': [
          for (final key in (dayLogs.keys.toList()..sort()))
            dayLogs[key]!.toJson(),
        ],
      };

  factory CycleTrackerState.fromJson(Map<String, dynamic> json) {
    final settingsRaw = json['settings'];
    final logs = <String, CycleDayLog>{};
    for (final raw in json['dayLogs'] as List? ?? const []) {
      try {
        final log = CycleDayLog.fromJson(
          Map<String, dynamic>.from(raw as Map),
        );
        logs[cycleDateKey(log.date)] = log;
      } catch (_) {}
    }
    return CycleTrackerState(
      version: (json['v'] as num?)?.toInt() ?? currentVersion,
      settings: settingsRaw is Map
          ? CycleSettings.fromJson(Map<String, dynamic>.from(settingsRaw))
          : const CycleSettings(),
      dayLogs: Map.unmodifiable(logs),
    );
  }
}

class CyclePeriod {
  final DateTime start;
  final DateTime end;
  final int periodLength;
  final int? cycleLength;

  const CyclePeriod({
    required this.start,
    required this.end,
    required this.periodLength,
    this.cycleLength,
  });
}

class CyclePrediction {
  final DateTime? lastPeriodStart;
  final DateTime? nextPeriodStart;
  final DateTime? ovulationDate;
  final DateTime? fertileStart;
  final DateTime? fertileEnd;
  final int averageCycleLength;
  final int averagePeriodLength;
  final int? currentCycleDay;
  final CyclePredictionConfidence confidence;
  final CyclePhase phase;

  const CyclePrediction({
    required this.lastPeriodStart,
    required this.nextPeriodStart,
    required this.ovulationDate,
    required this.fertileStart,
    required this.fertileEnd,
    required this.averageCycleLength,
    required this.averagePeriodLength,
    required this.currentCycleDay,
    required this.confidence,
    required this.phase,
  });

  bool predictedPeriodContains(DateTime value) {
    final start = nextPeriodStart;
    if (start == null) return false;
    final day = cycleDateOnly(value);
    final end = start.add(Duration(days: averagePeriodLength - 1));
    return !day.isBefore(start) && !day.isAfter(end);
  }

  bool fertileContains(DateTime value) {
    final start = fertileStart;
    final end = fertileEnd;
    if (start == null || end == null) return false;
    final day = cycleDateOnly(value);
    return !day.isBefore(start) && !day.isAfter(end);
  }
}

class CycleTrackerEngine {
  static List<CyclePeriod> periods(CycleTrackerState state) {
    final logs = state.dayLogs.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final bleeding = logs.where((log) => log.flow != CycleFlow.none).toList();
    if (bleeding.isEmpty) return const [];

    final groups = <List<CycleDayLog>>[];
    var current = <CycleDayLog>[];
    for (final log in bleeding) {
      if (current.isEmpty) {
        current = [log];
        continue;
      }
      final gap = cycleDateOnly(log.date)
          .difference(cycleDateOnly(current.last.date))
          .inDays;
      if (gap <= 1) {
        current.add(log);
      } else {
        groups.add(current);
        current = [log];
      }
    }
    if (current.isNotEmpty) groups.add(current);

    final validGroups = groups
        .where((group) => group.any((log) => log.flow.isPeriodFlow))
        .toList();
    final result = <CyclePeriod>[];
    for (var index = 0; index < validGroups.length; index++) {
      final group = validGroups[index];
      final start = cycleDateOnly(group.first.date);
      final end = cycleDateOnly(group.last.date);
      int? cycleLength;
      if (index > 0) {
        cycleLength =
            start.difference(cycleDateOnly(validGroups[index - 1].first.date)).inDays;
      }
      result.add(
        CyclePeriod(
          start: start,
          end: end,
          periodLength: end.difference(start).inDays + 1,
          cycleLength: cycleLength,
        ),
      );
    }
    return result;
  }

  static CyclePrediction predict(
    CycleTrackerState state, {
    DateTime? referenceDate,
  }) {
    final today = cycleDateOnly(referenceDate ?? DateTime.now());
    final history = periods(state);

    final validCycleLengths = history
        .map((period) => period.cycleLength)
        .whereType<int>()
        .where((value) => value >= 15 && value <= 60)
        .toList();
    final recentCycleLengths = validCycleLengths.length <= 6
        ? validCycleLengths
        : validCycleLengths.sublist(validCycleLengths.length - 6);
    final averageCycleLength = recentCycleLengths.isEmpty
        ? state.settings.averageCycleLength
        : (recentCycleLengths.reduce((a, b) => a + b) /
                recentCycleLengths.length)
            .round()
            .clamp(15, 60);

    final periodLengths = history
        .map((period) => period.periodLength)
        .where((value) => value >= 1 && value <= 14)
        .toList();
    final recentPeriodLengths = periodLengths.length <= 6
        ? periodLengths
        : periodLengths.sublist(periodLengths.length - 6);
    final averagePeriodLength = recentPeriodLengths.isEmpty
        ? state.settings.averagePeriodLength
        : (recentPeriodLengths.reduce((a, b) => a + b) /
                recentPeriodLengths.length)
            .round()
            .clamp(1, 14);

    if (history.isEmpty) {
      return CyclePrediction(
        lastPeriodStart: null,
        nextPeriodStart: null,
        ovulationDate: null,
        fertileStart: null,
        fertileEnd: null,
        averageCycleLength: averageCycleLength,
        averagePeriodLength: averagePeriodLength,
        currentCycleDay: null,
        confidence: CyclePredictionConfidence.low,
        phase: CyclePhase.unknown,
      );
    }

    final lastPeriod = history.last;
    var nextPeriodStart =
        lastPeriod.start.add(Duration(days: averageCycleLength));
    while (!nextPeriodStart.isAfter(today) &&
        today.difference(nextPeriodStart).inDays >= averageCycleLength) {
      nextPeriodStart =
          nextPeriodStart.add(Duration(days: averageCycleLength));
    }

    final ovulationDate = nextPeriodStart.subtract(const Duration(days: 14));
    final fertileStart = ovulationDate.subtract(const Duration(days: 5));
    final fertileEnd = ovulationDate.add(const Duration(days: 1));
    final currentCycleDay = today.difference(lastPeriod.start).inDays + 1;

    final confidence = _confidence(recentCycleLengths);
    final phase = _phase(
      today: today,
      history: history,
      fertileStart: fertileStart,
      fertileEnd: fertileEnd,
      ovulationDate: ovulationDate,
      nextPeriodStart: nextPeriodStart,
    );

    return CyclePrediction(
      lastPeriodStart: lastPeriod.start,
      nextPeriodStart: nextPeriodStart,
      ovulationDate: ovulationDate,
      fertileStart: fertileStart,
      fertileEnd: fertileEnd,
      averageCycleLength: averageCycleLength,
      averagePeriodLength: averagePeriodLength,
      currentCycleDay: currentCycleDay > 0 ? currentCycleDay : null,
      confidence: confidence,
      phase: phase,
    );
  }

  static CyclePredictionConfidence _confidence(List<int> cycleLengths) {
    if (cycleLengths.length < 2) return CyclePredictionConfidence.low;
    final mean =
        cycleLengths.reduce((a, b) => a + b) / cycleLengths.length;
    final variance = cycleLengths
            .map((value) => math.pow(value - mean, 2).toDouble())
            .reduce((a, b) => a + b) /
        cycleLengths.length;
    final deviation = math.sqrt(variance);
    if (cycleLengths.length >= 3 && deviation <= 2) {
      return CyclePredictionConfidence.high;
    }
    if (deviation <= 5) return CyclePredictionConfidence.medium;
    return CyclePredictionConfidence.low;
  }

  static CyclePhase _phase({
    required DateTime today,
    required List<CyclePeriod> history,
    required DateTime fertileStart,
    required DateTime fertileEnd,
    required DateTime ovulationDate,
    required DateTime nextPeriodStart,
  }) {
    for (final period in history.reversed) {
      if (!today.isBefore(period.start) && !today.isAfter(period.end)) {
        return CyclePhase.period;
      }
    }
    if (today == ovulationDate) return CyclePhase.ovulation;
    if (!today.isBefore(fertileStart) && !today.isAfter(fertileEnd)) {
      return CyclePhase.fertile;
    }
    final lastPeriodEnd = history.last.end;
    if (today.isAfter(lastPeriodEnd) && today.isBefore(fertileStart)) {
      return CyclePhase.follicular;
    }
    if (today.isAfter(fertileEnd) && today.isBefore(nextPeriodStart)) {
      return CyclePhase.luteal;
    }
    return CyclePhase.unknown;
  }
}
