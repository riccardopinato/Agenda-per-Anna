part of '../main.dart';

extension TrainingAgendaStore on AgendaStore {
  List<TrainingEntry> get trainingSessions {
    final result = trainingEntries
        .where((entry) => entry.kind == TrainingEntryKind.session)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return result;
  }

  List<TrainingEntry> get trainingPlans {
    final result = trainingEntries
        .where((entry) => entry.kind == TrainingEntryKind.plan)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  List<TrainingEntry> trainingSessionsForSport(TrainingSport sport) =>
      trainingSessions
          .where((entry) => entry.sport == sport)
          .toList(growable: false);

  double trainingDistanceForSport(TrainingSport sport) => trainingSessions
      .where((entry) => entry.sport == sport && entry.distanceKm != null)
      .fold<double>(0, (sum, entry) => sum + entry.distanceKm!);

  int trainingDurationForSport(TrainingSport sport) => trainingSessions
      .where((entry) => entry.sport == sport)
      .fold<int>(0, (sum, entry) => sum + entry.durationSeconds);

  TrainingEntry? trainingPlanById(String id) {
    if (id.isEmpty) return null;
    for (final entry in trainingEntries) {
      if (entry.id == id && entry.kind == TrainingEntryKind.plan) return entry;
    }
    return null;
  }

  Future<TrainingEntry> saveTrainingEntry(TrainingEntry entry) async {
    final index = trainingEntries.indexWhere((value) => value.id == entry.id);
    if (index < 0) {
      trainingEntries.add(entry);
    } else {
      trainingEntries[index] = entry;
    }
    await _persistEntityMutation(
      type: 'training',
      id: entry.id,
      payload: entry.toJson(),
    );
    _notifyTrainingChanged();
    return entry;
  }

  Future<TrainingEntry> createTrainingSession({
    required TrainingSport sport,
    required DateTime date,
    String title = '',
    int durationSeconds = 0,
    double? distanceKm,
    double? elevationMeters,
    int effort = 0,
    String notes = '',
    String planId = '',
    List<TrainingExercise> exercises = const [],
  }) =>
      saveTrainingEntry(
        TrainingEntry(
          id: const Uuid().v4(),
          kind: TrainingEntryKind.session,
          sport: sport,
          title: title.trim().isEmpty ? sport.label : title.trim(),
          date: DateTime(date.year, date.month, date.day),
          durationSeconds: max(0, durationSeconds),
          distanceKm:
              distanceKm != null && distanceKm > 0 ? distanceKm : null,
          elevationMeters:
              elevationMeters != null && elevationMeters > 0
                  ? elevationMeters
                  : null,
          effort: effort.clamp(0, 10),
          notes: notes.trim(),
          planId: planId,
          exercises: exercises,
          createdAt: DateTime.now(),
        ),
      );

  Future<TrainingEntry> createTrainingPlan({
    required String title,
    required TrainingSport sport,
    String notes = '',
    List<TrainingExercise> exercises = const [],
    String attachmentName = '',
    String attachmentMimeType = '',
    String attachmentBase64 = '',
  }) =>
      saveTrainingEntry(
        TrainingEntry(
          id: const Uuid().v4(),
          kind: TrainingEntryKind.plan,
          sport: sport,
          title: title.trim(),
          date: DateTime.now(),
          notes: notes.trim(),
          exercises: exercises,
          attachmentName: attachmentName,
          attachmentMimeType: attachmentMimeType,
          attachmentBase64: attachmentBase64,
          createdAt: DateTime.now(),
        ),
      );
}
