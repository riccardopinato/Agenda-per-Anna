part of '../main.dart';

enum TrainingSport {
  gym,
  running,
  cycling,
  walking,
  hiking,
  swimming,
  football,
  tennisPadel,
  other,
}

extension TrainingSportUi on TrainingSport {
  String get label => switch (this) {
        TrainingSport.gym => 'Palestra',
        TrainingSport.running => 'Corsa',
        TrainingSport.cycling => 'Bici',
        TrainingSport.walking => 'Camminata',
        TrainingSport.hiking => 'Trekking',
        TrainingSport.swimming => 'Nuoto',
        TrainingSport.football => 'Calcio',
        TrainingSport.tennisPadel => 'Tennis / Padel',
        TrainingSport.other => 'Altro',
      };

  IconData get icon => switch (this) {
        TrainingSport.gym => Icons.fitness_center_outlined,
        TrainingSport.running => Icons.directions_run,
        TrainingSport.cycling => Icons.directions_bike_outlined,
        TrainingSport.walking => Icons.directions_walk,
        TrainingSport.hiking => Icons.hiking_outlined,
        TrainingSport.swimming => Icons.pool_outlined,
        TrainingSport.football => Icons.sports_soccer_outlined,
        TrainingSport.tennisPadel => Icons.sports_tennis_outlined,
        TrainingSport.other => Icons.sports_outlined,
      };
}

class TrainingExercise {
  final String id;
  final String name;
  final int? sets;
  final String reps;
  final double? weightKg;
  final String note;

  const TrainingExercise({
    required this.id,
    required this.name,
    this.sets,
    this.reps = '',
    this.weightKg,
    this.note = '',
  });

  TrainingExercise copyWith({
    String? name,
    int? sets,
    String? reps,
    double? weightKg,
    String? note,
    bool clearSets = false,
    bool clearWeight = false,
  }) =>
      TrainingExercise(
        id: id,
        name: name ?? this.name,
        sets: clearSets ? null : (sets ?? this.sets),
        reps: reps ?? this.reps,
        weightKg: clearWeight ? null : (weightKg ?? this.weightKg),
        note: note ?? this.note,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'sets': sets,
        'reps': reps,
        'weightKg': weightKg,
        'note': note,
      };

  factory TrainingExercise.fromJson(Map<String, dynamic> json) =>
      TrainingExercise(
        id: json['id'] as String? ?? const Uuid().v4(),
        name: json['name'] as String? ?? '',
        sets: (json['sets'] as num?)?.toInt(),
        reps: json['reps'] as String? ?? '',
        weightKg: (json['weightKg'] as num?)?.toDouble(),
        note: json['note'] as String? ?? '',
      );
}

class TrainingPlan {
  final String id;
  final String title;
  final TrainingSport sport;
  final String customSport;
  final String note;
  final List<TrainingExercise> exercises;
  final List<int> weekdays;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool active;
  final String attachmentAssetId;
  final String attachmentBase64;
  final String attachmentName;
  final String attachmentMimeType;
  final int attachmentSizeBytes;
  final DateTime createdAt;

  const TrainingPlan({
    required this.id,
    required this.title,
    required this.sport,
    required this.createdAt,
    this.customSport = '',
    this.note = '',
    this.exercises = const [],
    this.weekdays = const [],
    this.startDate,
    this.endDate,
    this.active = true,
    this.attachmentAssetId = '',
    this.attachmentBase64 = '',
    this.attachmentName = '',
    this.attachmentMimeType = '',
    this.attachmentSizeBytes = 0,
  });

  String get sportLabel =>
      sport == TrainingSport.other && customSport.trim().isNotEmpty
          ? customSport.trim()
          : sport.label;

  bool appliesTo(DateTime date) {
    if (!active) return false;
    final day = DateTime(date.year, date.month, date.day);
    if (startDate != null) {
      final start = DateTime(startDate!.year, startDate!.month, startDate!.day);
      if (day.isBefore(start)) return false;
    }
    if (endDate != null) {
      final end = DateTime(endDate!.year, endDate!.month, endDate!.day);
      if (day.isAfter(end)) return false;
    }
    return weekdays.isNotEmpty && weekdays.contains(day.weekday);
  }

  TrainingPlan copyWith({
    String? title,
    TrainingSport? sport,
    String? customSport,
    String? note,
    List<TrainingExercise>? exercises,
    List<int>? weekdays,
    DateTime? startDate,
    DateTime? endDate,
    bool? active,
    String? attachmentAssetId,
    String? attachmentBase64,
    String? attachmentName,
    String? attachmentMimeType,
    int? attachmentSizeBytes,
    bool clearStartDate = false,
    bool clearEndDate = false,
    bool clearAttachment = false,
  }) =>
      TrainingPlan(
        id: id,
        title: title ?? this.title,
        sport: sport ?? this.sport,
        customSport: customSport ?? this.customSport,
        note: note ?? this.note,
        exercises: exercises ?? this.exercises,
        weekdays: weekdays ?? this.weekdays,
        startDate: clearStartDate ? null : (startDate ?? this.startDate),
        endDate: clearEndDate ? null : (endDate ?? this.endDate),
        active: active ?? this.active,
        attachmentAssetId:
            clearAttachment ? '' : (attachmentAssetId ?? this.attachmentAssetId),
        attachmentBase64:
            clearAttachment ? '' : (attachmentBase64 ?? this.attachmentBase64),
        attachmentName:
            clearAttachment ? '' : (attachmentName ?? this.attachmentName),
        attachmentMimeType: clearAttachment
            ? ''
            : (attachmentMimeType ?? this.attachmentMimeType),
        attachmentSizeBytes: clearAttachment
            ? 0
            : (attachmentSizeBytes ?? this.attachmentSizeBytes),
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'sport': sport.name,
        'customSport': customSport,
        'note': note,
        'exercises': exercises.map((e) => e.toJson()).toList(),
        'weekdays': weekdays,
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'active': active,
        'attachmentAssetId': attachmentAssetId,
        'attachmentBase64': attachmentBase64,
        'attachmentName': attachmentName,
        'attachmentMimeType': attachmentMimeType,
        'attachmentSizeBytes': attachmentSizeBytes,
        'createdAt': createdAt.toIso8601String(),
      };

  Map<String, dynamic> toLocalJson() {
    final value = Map<String, dynamic>.from(toJson());
    value['attachmentBase64'] = '';
    return value;
  }

  factory TrainingPlan.fromJson(Map<String, dynamic> json) => TrainingPlan(
        id: json['id'] as String? ?? const Uuid().v4(),
        title: json['title'] as String? ?? '',
        sport: TrainingSport.values.firstWhere(
          (value) => value.name == json['sport'],
          orElse: () => TrainingSport.other,
        ),
        customSport: json['customSport'] as String? ?? '',
        note: json['note'] as String? ?? '',
        exercises: (json['exercises'] as List? ?? const [])
            .whereType<Map>()
            .map((value) => TrainingExercise.fromJson(
                  Map<String, dynamic>.from(value),
                ))
            .toList(),
        weekdays: (json['weekdays'] as List? ?? const [])
            .map((value) => (value as num).toInt())
            .where((value) => value >= DateTime.monday && value <= DateTime.sunday)
            .toSet()
            .toList()
          ..sort(),
        startDate: DateTime.tryParse(json['startDate'] as String? ?? ''),
        endDate: DateTime.tryParse(json['endDate'] as String? ?? ''),
        active: json['active'] as bool? ?? true,
        attachmentAssetId: json['attachmentAssetId'] as String? ?? '',
        attachmentBase64: json['attachmentBase64'] as String? ?? '',
        attachmentName: json['attachmentName'] as String? ?? '',
        attachmentMimeType: json['attachmentMimeType'] as String? ?? '',
        attachmentSizeBytes:
            (json['attachmentSizeBytes'] as num? ?? 0).toInt(),
        createdAt:
            DateTime.tryParse(json['createdAt'] as String? ?? '') ??
                DateTime.now(),
      );
}

class TrainingSession {
  final String id;
  final String title;
  final TrainingSport sport;
  final String customSport;
  final DateTime date;
  final int durationSeconds;
  final double? distanceKm;
  final int? elevationMeters;
  final String note;
  final List<TrainingExercise> exercises;
  final String planId;
  final DateTime createdAt;

  const TrainingSession({
    required this.id,
    required this.title,
    required this.sport,
    required this.date,
    required this.createdAt,
    this.customSport = '',
    this.durationSeconds = 0,
    this.distanceKm,
    this.elevationMeters,
    this.note = '',
    this.exercises = const [],
    this.planId = '',
  });

  String get sportLabel =>
      sport == TrainingSport.other && customSport.trim().isNotEmpty
          ? customSport.trim()
          : sport.label;

  String get durationLabel {
    if (durationSeconds <= 0) return '';
    final hours = durationSeconds ~/ 3600;
    final minutes = (durationSeconds % 3600) ~/ 60;
    final seconds = durationSeconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  double? get averageSpeedKmh {
    if (distanceKm == null || distanceKm! <= 0 || durationSeconds <= 0) {
      return null;
    }
    return distanceKm! / (durationSeconds / 3600);
  }

  Duration? get averagePacePerKm {
    if (distanceKm == null || distanceKm! <= 0 || durationSeconds <= 0) {
      return null;
    }
    return Duration(seconds: (durationSeconds / distanceKm!).round());
  }

  TrainingSession copyWith({
    String? title,
    TrainingSport? sport,
    String? customSport,
    DateTime? date,
    int? durationSeconds,
    double? distanceKm,
    int? elevationMeters,
    String? note,
    List<TrainingExercise>? exercises,
    String? planId,
    bool clearDistance = false,
    bool clearElevation = false,
    bool clearPlan = false,
  }) =>
      TrainingSession(
        id: id,
        title: title ?? this.title,
        sport: sport ?? this.sport,
        customSport: customSport ?? this.customSport,
        date: date ?? this.date,
        durationSeconds: durationSeconds ?? this.durationSeconds,
        distanceKm: clearDistance ? null : (distanceKm ?? this.distanceKm),
        elevationMeters:
            clearElevation ? null : (elevationMeters ?? this.elevationMeters),
        note: note ?? this.note,
        exercises: exercises ?? this.exercises,
        planId: clearPlan ? '' : (planId ?? this.planId),
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'sport': sport.name,
        'customSport': customSport,
        'date': date.toIso8601String(),
        'durationSeconds': durationSeconds,
        'distanceKm': distanceKm,
        'elevationMeters': elevationMeters,
        'note': note,
        'exercises': exercises.map((e) => e.toJson()).toList(),
        'planId': planId,
        'createdAt': createdAt.toIso8601String(),
      };

  factory TrainingSession.fromJson(Map<String, dynamic> json) =>
      TrainingSession(
        id: json['id'] as String? ?? const Uuid().v4(),
        title: json['title'] as String? ?? '',
        sport: TrainingSport.values.firstWhere(
          (value) => value.name == json['sport'],
          orElse: () => TrainingSport.other,
        ),
        customSport: json['customSport'] as String? ?? '',
        date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
        durationSeconds: (json['durationSeconds'] as num? ?? 0).toInt(),
        distanceKm: (json['distanceKm'] as num?)?.toDouble(),
        elevationMeters: (json['elevationMeters'] as num?)?.toInt(),
        note: json['note'] as String? ?? '',
        exercises: (json['exercises'] as List? ?? const [])
            .whereType<Map>()
            .map((value) => TrainingExercise.fromJson(
                  Map<String, dynamic>.from(value),
                ))
            .toList(),
        planId: json['planId'] as String? ?? '',
        createdAt:
            DateTime.tryParse(json['createdAt'] as String? ?? '') ??
                DateTime.now(),
      );
}

extension TrainingAgendaStore on AgendaStore {
  List<TrainingSession> get trainingHistory {
    final result = [...trainingSessions]
      ..sort((a, b) {
        final date = b.date.compareTo(a.date);
        if (date != 0) return date;
        return b.createdAt.compareTo(a.createdAt);
      });
    return result;
  }

  List<TrainingPlan> trainingPlansForDay(DateTime date) {
    final result = trainingPlans.where((plan) => plan.appliesTo(date)).toList()
      ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    return result;
  }

  TrainingPlan? trainingPlanById(String id) {
    for (final plan in trainingPlans) {
      if (plan.id == id) return plan;
    }
    return null;
  }

  Future<void> saveTrainingPlan(TrainingPlan plan) async {
    final normalized = plan.copyWith(
      title: plan.title.trim(),
      customSport: plan.customSport.trim(),
      note: plan.note.trim(),
      weekdays: [...plan.weekdays]..sort(),
      exercises: plan.exercises
          .map(
            (exercise) => exercise.copyWith(
              name: exercise.name.trim(),
              reps: exercise.reps.trim(),
              note: exercise.note.trim(),
            ),
          )
          .where((exercise) => exercise.name.isNotEmpty)
          .toList(),
    );
    if (normalized.title.isEmpty) {
      throw const FormatException('Inserisci un nome per la scheda.');
    }
    final index = trainingPlans.indexWhere((value) => value.id == normalized.id);
    if (index < 0) {
      trainingPlans.add(normalized);
    } else {
      trainingPlans[index] = normalized;
    }
    await _persistEntityMutation(
      type: 'training_plan',
      id: normalized.id,
      payload: normalized.toLocalJson(),
    );
    _notifyTrainingChanged();
  }

  Future<void> saveTrainingSession(TrainingSession session) async {
    final normalized = session.copyWith(
      title:
          session.title.trim().isEmpty ? session.sportLabel : session.title.trim(),
      customSport: session.customSport.trim(),
      note: session.note.trim(),
      durationSeconds: max(0, session.durationSeconds),
      exercises: session.exercises
          .map(
            (exercise) => exercise.copyWith(
              name: exercise.name.trim(),
              reps: exercise.reps.trim(),
              note: exercise.note.trim(),
            ),
          )
          .where((exercise) => exercise.name.isNotEmpty)
          .toList(),
    );
    final index =
        trainingSessions.indexWhere((value) => value.id == normalized.id);
    if (index < 0) {
      trainingSessions.add(normalized);
    } else {
      trainingSessions[index] = normalized;
    }
    await _persistEntityMutation(
      type: 'training_session',
      id: normalized.id,
      payload: normalized.toJson(),
    );
    _notifyTrainingChanged();
  }
}
