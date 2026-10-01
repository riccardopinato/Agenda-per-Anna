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

List<String> normalizeCycleCustomSymptoms(Iterable<String> values) {
  final result = <String>[];
  final seen = <String>{};
  for (final raw in values) {
    final value = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (value.isEmpty) continue;
    final normalized = value.toLowerCase();
    if (!seen.add(normalized)) continue;
    result.add(value.length > 40 ? value.substring(0, 40) : value);
    if (result.length >= 12) break;
  }
  return List<String>.unmodifiable(result);
}

List<String> _cycleCustomSymptomsFromJson(Object? raw) {
  if (raw is! List) return const [];
  return normalizeCycleCustomSymptoms(raw.map((value) => value.toString()));
}

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
      painLevel: ((json['painLevel'] as num?)?.toInt() ?? 0).clamp(0, 5).toInt(),
      energyLevel: ((json['energyLevel'] as num?)?.toInt() ?? 3).clamp(0, 5).toInt(),
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
  final List<String> customSymptoms;
  final bool onboardingComplete;
  final bool discreetNotifications;
  final bool periodReminderEnabled;
  final int periodReminderDaysBefore;
  final bool dailyLogReminderEnabled;
  final int dailyLogReminderHour;
  final int dailyLogReminderMinute;
  final bool contraceptiveReminderEnabled;
  final int contraceptiveReminderHour;
  final int contraceptiveReminderMinute;

  const CycleSettings({
    this.averageCycleLength = 28,
    this.averagePeriodLength = 5,
    this.regularityMode = 'unknown',
    this.trackFertility = true,
    this.trackSexualActivity = false,
    this.trackBasalTemperature = false,
    this.trackCervicalMucus = false,
    this.customSymptoms = const [],
    this.onboardingComplete = false,
    this.discreetNotifications = true,
    this.periodReminderEnabled = false,
    this.periodReminderDaysBefore = 2,
    this.dailyLogReminderEnabled = false,
    this.dailyLogReminderHour = 20,
    this.dailyLogReminderMinute = 0,
    this.contraceptiveReminderEnabled = false,
    this.contraceptiveReminderHour = 21,
    this.contraceptiveReminderMinute = 0,
  });

  CycleSettings copyWith({
    int? averageCycleLength,
    int? averagePeriodLength,
    String? regularityMode,
    bool? trackFertility,
    bool? trackSexualActivity,
    bool? trackBasalTemperature,
    bool? trackCervicalMucus,
    List<String>? customSymptoms,
    bool? onboardingComplete,
    bool? discreetNotifications,
    bool? periodReminderEnabled,
    int? periodReminderDaysBefore,
    bool? dailyLogReminderEnabled,
    int? dailyLogReminderHour,
    int? dailyLogReminderMinute,
    bool? contraceptiveReminderEnabled,
    int? contraceptiveReminderHour,
    int? contraceptiveReminderMinute,
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
        customSymptoms: normalizeCycleCustomSymptoms(
          customSymptoms ?? this.customSymptoms,
        ),
        onboardingComplete: onboardingComplete ?? this.onboardingComplete,
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
        contraceptiveReminderEnabled:
            contraceptiveReminderEnabled ?? this.contraceptiveReminderEnabled,
        contraceptiveReminderHour:
            contraceptiveReminderHour ?? this.contraceptiveReminderHour,
        contraceptiveReminderMinute:
            contraceptiveReminderMinute ?? this.contraceptiveReminderMinute,
      );

  Map<String, dynamic> toJson() => {
        'averageCycleLength': averageCycleLength,
        'averagePeriodLength': averagePeriodLength,
        'regularityMode': regularityMode,
        'trackFertility': trackFertility,
        'trackSexualActivity': trackSexualActivity,
        'trackBasalTemperature': trackBasalTemperature,
        'trackCervicalMucus': trackCervicalMucus,
        'customSymptoms': customSymptoms,
        'onboardingComplete': onboardingComplete,
        'discreetNotifications': discreetNotifications,
        'periodReminderEnabled': periodReminderEnabled,
        'periodReminderDaysBefore': periodReminderDaysBefore,
        'dailyLogReminderEnabled': dailyLogReminderEnabled,
        'dailyLogReminderHour': dailyLogReminderHour,
        'dailyLogReminderMinute': dailyLogReminderMinute,
        'contraceptiveReminderEnabled': contraceptiveReminderEnabled,
        'contraceptiveReminderHour': contraceptiveReminderHour,
        'contraceptiveReminderMinute': contraceptiveReminderMinute,
      };

  factory CycleSettings.fromJson(Map<String, dynamic> json) => CycleSettings(
        averageCycleLength:
            ((json['averageCycleLength'] as num?)?.toInt() ?? 28).clamp(15, 60).toInt(),
        averagePeriodLength:
            ((json['averagePeriodLength'] as num?)?.toInt() ?? 5).clamp(1, 14).toInt(),
        regularityMode: json['regularityMode']?.toString() ?? 'unknown',
        trackFertility: json['trackFertility'] != false,
        trackSexualActivity: json['trackSexualActivity'] == true,
        trackBasalTemperature: json['trackBasalTemperature'] == true,
        trackCervicalMucus: json['trackCervicalMucus'] == true,
        customSymptoms: _cycleCustomSymptomsFromJson(json['customSymptoms']),
        onboardingComplete: json['onboardingComplete'] == true,
        discreetNotifications: json['discreetNotifications'] != false,
        periodReminderEnabled: json['periodReminderEnabled'] == true,
        periodReminderDaysBefore:
            ((json['periodReminderDaysBefore'] as num?)?.toInt() ?? 2)
                .clamp(0, 7).toInt(),
        dailyLogReminderEnabled: json['dailyLogReminderEnabled'] == true,
        dailyLogReminderHour:
            ((json['dailyLogReminderHour'] as num?)?.toInt() ?? 20)
                .clamp(0, 23).toInt(),
        dailyLogReminderMinute:
            ((json['dailyLogReminderMinute'] as num?)?.toInt() ?? 0)
                .clamp(0, 59).toInt(),
        contraceptiveReminderEnabled:
            json['contraceptiveReminderEnabled'] == true,
        contraceptiveReminderHour:
            ((json['contraceptiveReminderHour'] as num?)?.toInt() ?? 21)
                .clamp(0, 23).toInt(),
        contraceptiveReminderMinute:
            ((json['contraceptiveReminderMinute'] as num?)?.toInt() ?? 0)
                .clamp(0, 59).toInt(),
      );
}

class CycleTrackerState {
  static const int currentVersion = 3;

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

  CycleTrackerState upsertLogs(Iterable<CycleDayLog> logs) {
    final next = Map<String, CycleDayLog>.from(dayLogs);
    for (final log in logs) {
      next[cycleDateKey(log.date)] = log;
    }
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
  final DateTime? periodWindowStart;
  final DateTime? periodWindowEnd;
  final double variabilityDays;

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
    this.periodWindowStart,
    this.periodWindowEnd,
    this.variabilityDays = 0,
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
    final averageCycleLength = _weightedAverageRecent(
      recentCycleLengths,
      fallback: state.settings.averageCycleLength,
      min: 15,
      max: 60,
    );

    final periodLengths = history
        .map((period) => period.periodLength)
        .where((value) => value >= 1 && value <= 14)
        .toList();
    final recentPeriodLengths = periodLengths.length <= 6
        ? periodLengths
        : periodLengths.sublist(periodLengths.length - 6);
    final averagePeriodLength = _weightedAverageRecent(
      recentPeriodLengths,
      fallback: state.settings.averagePeriodLength,
      min: 1,
      max: 14,
    );

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
        periodWindowStart: null,
        periodWindowEnd: null,
        variabilityDays: 0,
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

    final variability = _standardDeviation(recentCycleLengths);
    final spreadDays = recentCycleLengths.length < 2
        ? 3
        : variability.ceil().clamp(1, 7).toInt();
    var confidence = _confidence(recentCycleLengths);
    if (state.settings.regularityMode == 'irregular' &&
        confidence == CyclePredictionConfidence.high) {
      confidence = CyclePredictionConfidence.medium;
    }
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
      periodWindowStart:
          nextPeriodStart.subtract(Duration(days: spreadDays)),
      periodWindowEnd: nextPeriodStart.add(Duration(days: spreadDays)),
      variabilityDays: variability,
    );
  }

  static int _weightedAverageRecent(
    List<int> values, {
    required int fallback,
    required int min,
    required int max,
  }) {
    if (values.isEmpty) return fallback.clamp(min, max).toInt();
    var weightedTotal = 0;
    var totalWeight = 0;
    for (var index = 0; index < values.length; index++) {
      final weight = index + 1;
      weightedTotal += values[index] * weight;
      totalWeight += weight;
    }
    return (weightedTotal / totalWeight).round().clamp(min, max).toInt();
  }

  static double _standardDeviation(List<int> values) {
    if (values.length < 2) return 0;
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values
            .map((value) => math.pow(value - mean, 2).toDouble())
            .reduce((a, b) => a + b) /
        values.length;
    return math.sqrt(variance);
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


class CycleFrequencyItem {
  final String key;
  final int count;

  const CycleFrequencyItem(this.key, this.count);
}

class CycleSymptomPattern {
  final String key;
  final int totalCount;
  final int periodCount;
  final int outsidePeriodCount;

  const CycleSymptomPattern({
    required this.key,
    required this.totalCount,
    required this.periodCount,
    required this.outsidePeriodCount,
  });

  bool get mostlyDuringPeriod => periodCount > outsidePeriodCount;
}

class CycleInsightSummary {
  final int loggedDays;
  final int periodCount;
  final double averageRecordedPain;
  final int? shortestCycle;
  final int? longestCycle;
  final double cycleVariabilityDays;
  final DateTime? estimatedWindowStart;
  final DateTime? estimatedWindowEnd;
  final List<CycleFrequencyItem> topSymptoms;
  final List<CycleFrequencyItem> topMoods;
  final List<CycleSymptomPattern> symptomPatterns;
  final int basalTemperatureEntries;
  final int positiveOvulationTests;
  final int cervicalMucusEntries;
  final int sexualActivityEntries;

  const CycleInsightSummary({
    required this.loggedDays,
    required this.periodCount,
    required this.averageRecordedPain,
    required this.shortestCycle,
    required this.longestCycle,
    required this.cycleVariabilityDays,
    required this.estimatedWindowStart,
    required this.estimatedWindowEnd,
    required this.topSymptoms,
    required this.topMoods,
    required this.symptomPatterns,
    required this.basalTemperatureEntries,
    required this.positiveOvulationTests,
    required this.cervicalMucusEntries,
    required this.sexualActivityEntries,
  });
}

class CyclePremiumAnalytics {
  static CycleInsightSummary insights(
    CycleTrackerState state, {
    DateTime? referenceDate,
  }) {
    final logs = state.dayLogs.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final history = CycleTrackerEngine.periods(state);
    final prediction = CycleTrackerEngine.predict(
      state,
      referenceDate: referenceDate,
    );

    final cycleLengths = history
        .map((period) => period.cycleLength)
        .whereType<int>()
        .where((value) => value >= 15 && value <= 60)
        .toList();

    double variability = 0;
    if (cycleLengths.length >= 2) {
      final mean =
          cycleLengths.reduce((a, b) => a + b) / cycleLengths.length;
      final variance = cycleLengths
              .map((value) => math.pow(value - mean, 2).toDouble())
              .reduce((a, b) => a + b) /
          cycleLengths.length;
      variability = math.sqrt(variance);
    }

    final spreadDays = cycleLengths.length < 2
        ? 3
        : variability.ceil().clamp(1, 7).toInt();
    final next = prediction.nextPeriodStart;

    final painValues = logs
        .where((log) => log.painLevel > 0)
        .map((log) => log.painLevel)
        .toList();
    final averagePain = painValues.isEmpty
        ? 0.0
        : painValues.reduce((a, b) => a + b) / painValues.length;

    final symptomCounts = <String, int>{};
    final moodCounts = <String, int>{};
    final symptomPeriodCounts = <String, int>{};
    final symptomOutsideCounts = <String, int>{};
    var basalTemperatureEntries = 0;
    var positiveOvulationTests = 0;
    var cervicalMucusEntries = 0;
    var sexualActivityEntries = 0;

    for (final log in logs) {
      final duringPeriod =
          log.flow.isPeriodFlow || log.flow == CycleFlow.spotting;
      for (final symptom in log.symptoms) {
        symptomCounts[symptom] = (symptomCounts[symptom] ?? 0) + 1;
        final bucket =
            duringPeriod ? symptomPeriodCounts : symptomOutsideCounts;
        bucket[symptom] = (bucket[symptom] ?? 0) + 1;
      }
      for (final mood in log.moods) {
        moodCounts[mood] = (moodCounts[mood] ?? 0) + 1;
      }
      if (log.basalTemperature != null) basalTemperatureEntries++;
      if (log.ovulationTest.trim().toLowerCase() == 'positive') {
        positiveOvulationTests++;
      }
      if (log.discharge.trim().isNotEmpty) cervicalMucusEntries++;
      if (log.hadSex) sexualActivityEntries++;
    }

    List<CycleFrequencyItem> top(Map<String, int> source) {
      final entries = source.entries.toList()
        ..sort((a, b) {
          final byCount = b.value.compareTo(a.value);
          return byCount != 0 ? byCount : a.key.compareTo(b.key);
        });
      return List<CycleFrequencyItem>.unmodifiable(
        entries.take(5).map((entry) => CycleFrequencyItem(
              entry.key,
              entry.value,
            )),
      );
    }

    final symptomPatterns = symptomCounts.entries
        .map(
          (entry) => CycleSymptomPattern(
            key: entry.key,
            totalCount: entry.value,
            periodCount: symptomPeriodCounts[entry.key] ?? 0,
            outsidePeriodCount: symptomOutsideCounts[entry.key] ?? 0,
          ),
        )
        .toList()
      ..sort((a, b) {
        final byTotal = b.totalCount.compareTo(a.totalCount);
        return byTotal != 0 ? byTotal : a.key.compareTo(b.key);
      });

    return CycleInsightSummary(
      loggedDays: logs.length,
      periodCount: history.length,
      averageRecordedPain: averagePain,
      shortestCycle:
          cycleLengths.isEmpty ? null : cycleLengths.reduce(math.min),
      longestCycle:
          cycleLengths.isEmpty ? null : cycleLengths.reduce(math.max),
      cycleVariabilityDays: variability,
      estimatedWindowStart:
          next?.subtract(Duration(days: spreadDays)),
      estimatedWindowEnd: next?.add(Duration(days: spreadDays)),
      topSymptoms: top(symptomCounts),
      topMoods: top(moodCounts),
      symptomPatterns: List<CycleSymptomPattern>.unmodifiable(
        symptomPatterns.take(5),
      ),
      basalTemperatureEntries: basalTemperatureEntries,
      positiveOvulationTests: positiveOvulationTests,
      cervicalMucusEntries: cervicalMucusEntries,
      sexualActivityEntries: sexualActivityEntries,
    );
  }
}
