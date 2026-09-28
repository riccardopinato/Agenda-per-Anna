part of '../main.dart';

extension TrainingAgendaStore on AgendaStore {
  List<TrainingRecord> get trainingSessions {
    final result = trainingRecords.where((record) => record.isSession).toList()
      ..sort((a, b) {
        final date = b.date.compareTo(a.date);
        if (date != 0) return date;
        return b.createdAt.compareTo(a.createdAt);
      });
    return result;
  }

  List<TrainingRecord> get trainingPlans {
    final result = trainingRecords.where((record) => record.isPlan).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  List<TrainingRecord> trainingSessionsForSport(TrainingSport? sport) =>
      trainingSessions
          .where((record) => sport == null || record.sport == sport)
          .toList(growable: false);

  Future<TrainingRecord> saveTrainingRecord(TrainingRecord record) async {
    final index = trainingRecords.indexWhere((value) => value.id == record.id);
    if (index < 0) {
      trainingRecords.add(record);
    } else {
      trainingRecords[index] = record;
    }
    await _persistEntityMutation(
      type: 'training',
      id: record.id,
      payload: record.toJson(),
    );
    _notifyTrainingChanged();
    return record;
  }

  Future<TrainingRecord> addTrainingSession({
    required TrainingSport sport,
    required DateTime date,
    String title = '',
    int durationMinutes = 0,
    double distanceKm = 0,
    int elevationMeters = 0,
    int calories = 0,
    int rpe = 0,
    String details = '',
    String notes = '',
  }) {
    final cleanTitle = title.trim().isEmpty ? sport.label : title.trim();
    return saveTrainingRecord(
      TrainingRecord(
        id: const Uuid().v4(),
        kind: TrainingRecordKind.session,
        sport: sport,
        title: cleanTitle,
        date: DateTime(date.year, date.month, date.day),
        durationMinutes: max(0, durationMinutes),
        distanceKm: max(0, distanceKm),
        elevationMeters: max(0, elevationMeters),
        calories: max(0, calories),
        rpe: rpe.clamp(0, 10),
        details: details.trim(),
        notes: notes.trim(),
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<TrainingRecord> addTrainingPlan({
    required String title,
    required TrainingSport sport,
    required String details,
    String notes = '',
  }) {
    return saveTrainingRecord(
      TrainingRecord(
        id: const Uuid().v4(),
        kind: TrainingRecordKind.plan,
        sport: sport,
        title: title.trim().isEmpty ? 'Scheda ${sport.label}' : title.trim(),
        date: DateTime.now(),
        details: details.trim(),
        notes: notes.trim(),
        createdAt: DateTime.now(),
      ),
    );
  }

  double averageSpeedKmh(TrainingRecord record) {
    if (record.durationMinutes <= 0 || record.distanceKm <= 0) return 0;
    return record.distanceKm / (record.durationMinutes / 60);
  }

  Duration? pacePerKm(TrainingRecord record) {
    if (record.durationMinutes <= 0 || record.distanceKm <= 0) return null;
    final seconds =
        ((record.durationMinutes * 60) / record.distanceKm).round();
    return Duration(seconds: seconds);
  }
}
