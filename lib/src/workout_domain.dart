part of '../main.dart';

extension WorkoutAgendaStore on AgendaStore {
  List<WorkoutSession> get workoutHistory {
    final result = List<WorkoutSession>.from(workoutSessions)
      ..sort((a, b) {
        final date = b.date.compareTo(a.date);
        if (date != 0) return date;
        return b.createdAt.compareTo(a.createdAt);
      });
    return result;
  }

  List<WorkoutPlan> get workoutPlansSorted {
    final result = List<WorkoutPlan>.from(workoutPlans)
      ..sort((a, b) {
        final updated = b.updatedAt.compareTo(a.updatedAt);
        if (updated != 0) return updated;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    return result;
  }

  List<WorkoutSession> workoutHistoryForSport(WorkoutSport sport) =>
      workoutHistory.where((session) => session.sport == sport).toList();

  Future<WorkoutSession> saveWorkoutSession(WorkoutSession session) async {
    final cleanTitle = session.title.trim();
    final normalized = session.copyWith(
      title: cleanTitle,
      durationSeconds: max(0, session.durationSeconds),
      distanceKm: session.distanceKm != null && session.distanceKm! > 0
          ? session.distanceKm
          : null,
      clearDistance:
          session.distanceKm == null || session.distanceKm! <= 0,
      elevationGainM:
          session.elevationGainM != null && session.elevationGainM! >= 0
              ? session.elevationGainM
              : null,
      clearElevation:
          session.elevationGainM == null || session.elevationGainM! < 0,
      effort: session.effort?.clamp(1, 10).toInt(),
      clearEffort: session.effort == null,
      note: session.note.trim(),
      planName: session.planName.trim(),
      exercises: session.exercises
          .where((exercise) => exercise.name.trim().isNotEmpty)
          .map(
            (exercise) => exercise.copyWith(
              name: exercise.name.trim(),
              reps: exercise.reps.trim(),
              note: exercise.note.trim(),
            ),
          )
          .toList(growable: false),
    );
    final index =
        workoutSessions.indexWhere((value) => value.id == normalized.id);
    if (index < 0) {
      workoutSessions.add(normalized);
    } else {
      workoutSessions[index] = normalized;
    }
    await _persistEntityMutation(
      type: 'workout_session',
      id: normalized.id,
      payload: normalized.toJson(),
    );
    _notifyWorkoutChanged();
    return normalized;
  }

  Future<WorkoutSession> addWorkoutSession({
    required WorkoutSport sport,
    required DateTime date,
    String title = '',
    int durationSeconds = 0,
    double? distanceKm,
    int? elevationGainM,
    int? effort,
    String note = '',
    WorkoutPlan? plan,
  }) =>
      saveWorkoutSession(
        WorkoutSession(
          id: const Uuid().v4(),
          sport: sport,
          title: title.trim(),
          date: date,
          durationSeconds: durationSeconds,
          distanceKm: distanceKm,
          elevationGainM: elevationGainM,
          effort: effort,
          note: note,
          planName: plan?.name ?? '',
          exercises: plan?.exercises ?? const [],
          createdAt: DateTime.now(),
        ),
      );

  Future<WorkoutPlan> saveWorkoutPlan(WorkoutPlan plan) async {
    final normalized = plan.copyWith(
      name: plan.name.trim(),
      note: plan.note.trim(),
      exercises: plan.exercises
          .where((exercise) => exercise.name.trim().isNotEmpty)
          .map(
            (exercise) => exercise.copyWith(
              name: exercise.name.trim(),
              reps: exercise.reps.trim(),
              note: exercise.note.trim(),
            ),
          )
          .toList(growable: false),
      updatedAt: DateTime.now(),
    );
    final index = workoutPlans.indexWhere((value) => value.id == normalized.id);
    if (index < 0) {
      workoutPlans.add(normalized);
    } else {
      workoutPlans[index] = normalized;
    }
    await _persistEntityMutation(
      type: 'workout_plan',
      id: normalized.id,
      payload: normalized.toJson(),
    );
    _notifyWorkoutChanged();
    return normalized;
  }

  Future<WorkoutPlan> addWorkoutPlan({
    required String name,
    required WorkoutSport sport,
    String note = '',
    List<WorkoutExercise> exercises = const [],
  }) {
    final now = DateTime.now();
    return saveWorkoutPlan(
      WorkoutPlan(
        id: const Uuid().v4(),
        name: name.trim(),
        sport: sport,
        note: note,
        exercises: exercises,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  List<WorkoutExercise> parseWorkoutPlanText(String raw) {
    final result = <WorkoutExercise>[];
    for (final sourceLine in const LineSplitter().convert(raw)) {
      final line = sourceLine.trim();
      if (line.isEmpty) continue;

      var name = line;
      var sets = 0;
      var reps = '';
      double? loadKg;

      final match = RegExp(
        r'^(.*?)(?:\s+|\s*[|;,]\s*)(\d+)\s*[xX×]\s*([\d\-–]+)(?:\s*(?:@|x)?\s*([\d.,]+)\s*kg)?$',
        caseSensitive: false,
      ).firstMatch(line);
      if (match != null) {
        name = match.group(1)?.trim() ?? line;
        sets = int.tryParse(match.group(2) ?? '') ?? 0;
        reps = match.group(3)?.trim() ?? '';
        loadKg =
            double.tryParse((match.group(4) ?? '').replaceAll(',', '.'));
      } else {
        final cells = line
            .split(RegExp(r'\s*[|;]\s*'))
            .where((cell) => cell.trim().isNotEmpty)
            .toList();
        if (cells.length >= 2) {
          name = cells[0].trim();
          sets = int.tryParse(cells[1].trim()) ?? 0;
          reps = cells.length > 2 ? cells[2].trim() : '';
          final load = (cells.length > 3 ? cells[3] : '')
              .replaceAll(RegExp(r'kg', caseSensitive: false), '')
              .replaceAll(',', '.')
              .trim();
          loadKg = double.tryParse(load);
        }
      }

      if (name.isEmpty) continue;
      result.add(
        WorkoutExercise(
          id: const Uuid().v4(),
          name: name,
          sets: sets,
          reps: reps,
          loadKg: loadKg,
        ),
      );
      if (result.length >= 80) break;
    }
    return result;
  }

  String formatWorkoutDuration(int seconds) {
    final safe = max(0, seconds);
    final hours = safe ~/ 3600;
    final minutes = (safe % 3600) ~/ 60;
    final secs = safe % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:'
        '${secs.toString().padLeft(2, '0')}';
  }

  String? workoutPerformanceLabel(WorkoutSession session) {
    if (session.distanceKm == null ||
        session.distanceKm! <= 0 ||
        session.durationSeconds <= 0) {
      return null;
    }
    if (session.sport.prefersPace) {
      final pace = session.paceSecondsPerKm;
      if (pace == null) return null;
      final minutes = pace ~/ 60;
      final seconds = pace % 60;
      return '$minutes:${seconds.toString().padLeft(2, '0')} /km';
    }
    final speed = session.averageSpeedKmh;
    if (speed == null) return null;
    return '${speed.toStringAsFixed(1)} km/h';
  }
}
