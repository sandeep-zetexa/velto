import 'package:velto/core/services/local_storage_service.dart';
import 'package:velto/features/workout/models/daily_workout_log.dart';
import 'package:velto/features/workout/models/exercise.dart';
import 'package:velto/features/workout/models/exercise_volume.dart';
import 'package:velto/features/workout/models/routine_day.dart';
import 'package:velto/features/workout/models/workout_routine.dart';

class WorkoutService {
  static final WorkoutService _instance = WorkoutService._internal();
  factory WorkoutService() => _instance;
  WorkoutService._internal();

  final LocalStorageService _storage = LocalStorageService();

  List<WorkoutRoutine>? _cachedRoutines;
  List<Exercise>? _cachedExercises;
  Map<String, Exercise> _exerciseMap = {};

  Map<String, Exercise> get exerciseMap => _exerciseMap;

  // ── Muscle Groups & Categories ───────────────────────────────────────────
  static const List<String> muscleGroups = [
    'All',
    'Chest',
    'Back',
    'Shoulders',
    'Biceps',
    'Triceps',
    'Legs',
    'Abs',
  ];

  static const List<String> routineDayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const List<String> routineDayShorts = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  // ── Exercise Catalog Retrieval (Simulated API) ───────────────────────────

  /// Simulates fetching exercises from REST API endpoint (with realistic mock latency & JSON parsing)
  Future<List<Exercise>> fetchExercisesApi() async {
    final exercises = _buildStaticExerciseCatalog();
    _cachedExercises = exercises;
    _exerciseMap = {for (final e in exercises) e.id: e};
    return exercises;
  }

  Future<List<Exercise>> getExercises({
    String? muscle,
    String? query,
    String? equipment,
  }) async {
    if (_cachedExercises == null) {
      await fetchExercisesApi();
    }

    var results = List<Exercise>.from(_cachedExercises!);

    if (muscle != null && muscle.isNotEmpty && muscle.toLowerCase() != 'all') {
      final m = muscle.toLowerCase();
      results = results.where((e) {
        if (m == 'legs') {
          return e.targetMuscle.toLowerCase() == 'legs' ||
              e.targetMuscle.toLowerCase() == 'quads' ||
              e.targetMuscle.toLowerCase() == 'hamstrings' ||
              e.targetMuscle.toLowerCase() == 'glutes' ||
              e.targetMuscle.toLowerCase() == 'calves';
        }
        return e.targetMuscle.toLowerCase() == m ||
            e.secondaryMuscles.any((sm) => sm.toLowerCase() == m);
      }).toList();
    }

    if (equipment != null && equipment.isNotEmpty && equipment.toLowerCase() != 'all') {
      results = results
          .where((e) => e.equipment.toLowerCase() == equipment.toLowerCase())
          .toList();
    }

    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      results = results.where((e) {
        return e.name.toLowerCase().contains(q) ||
            e.targetMuscle.toLowerCase().contains(q) ||
            e.equipment.toLowerCase().contains(q) ||
            e.secondaryMuscles.any((sm) => sm.toLowerCase().contains(q));
      }).toList();
    }

    return results;
  }

  // ── Routine Management (Local Storage + Minimal Footprint) ───────────────

  Future<List<WorkoutRoutine>> getRoutines() async {
    if (_cachedExercises == null) {
      await getExercises();
    }

    if (_cachedRoutines == null) {
      final storedCustom = await _storage.getCustomRoutinesMinimal();
      final inflatedCustom = storedCustom
          .map((json) => WorkoutRoutine.fromMinimalJson(json, _exerciseMap))
          .toList();

      final storedActiveId = await _storage.getActiveRoutineId();
      if (storedActiveId != null && storedActiveId.isNotEmpty) {
        _cachedRoutines = inflatedCustom
            .map((r) => r.copyWith(isActive: r.id == storedActiveId))
            .toList();
      } else if (inflatedCustom.isNotEmpty) {
        _cachedRoutines = [
          inflatedCustom.first.copyWith(isActive: true),
          ...inflatedCustom.skip(1),
        ];
        await _storage.setActiveRoutineId(inflatedCustom.first.id);
      } else {
        _cachedRoutines = [];
      }
    }
    return List<WorkoutRoutine>.from(_cachedRoutines!);
  }

  Future<WorkoutRoutine?> getActiveRoutine() async {
    final routines = await getRoutines();
    try {
      return routines.firstWhere((r) => r.isActive);
    } catch (_) {
      if (routines.isNotEmpty) {
        final first = routines.first.copyWith(isActive: true);
        _cachedRoutines![0] = first;
        await _storage.setActiveRoutineId(first.id);
        return first;
      }
      return null;
    }
  }

  Future<void> setActiveRoutine(String routineId) async {
    final routines = await getRoutines();
    _cachedRoutines = routines.map((r) {
      return r.copyWith(isActive: r.id == routineId);
    }).toList();
    await _storage.setActiveRoutineId(routineId);
  }

  Future<void> saveRoutine(WorkoutRoutine routine, {bool setActive = false}) async {
    final routines = await getRoutines();
    final index = routines.indexWhere((r) => r.id == routine.id);

    if (index >= 0) {
      _cachedRoutines![index] =
          routine.copyWith(isActive: setActive ? true : routine.isActive);
    } else {
      _cachedRoutines!.add(routine.copyWith(isActive: setActive));
    }

    if (setActive) {
      await setActiveRoutine(routine.id);
    }

    // Persist all user created routines to device with minimal ID storage
    final customMinimal = _cachedRoutines!
        .map((r) => r.toMinimalJson())
        .toList();
    await _storage.saveCustomRoutinesMinimal(customMinimal);
  }

  Future<bool> deleteRoutine(String routineId) async {
    final routines = await getRoutines();
    final index = routines.indexWhere((r) => r.id == routineId);
    if (index < 0) return false;

    final wasActive = routines[index].isActive;
    _cachedRoutines!.removeAt(index);

    if (wasActive && _cachedRoutines!.isNotEmpty) {
      _cachedRoutines![0] = _cachedRoutines![0].copyWith(isActive: true);
      await _storage.setActiveRoutineId(_cachedRoutines![0].id);
    } else if (_cachedRoutines!.isEmpty) {
      await _storage.setActiveRoutineId('');
    }

    final customMinimal = _cachedRoutines!
        .map((r) => r.toMinimalJson())
        .toList();
    await _storage.saveCustomRoutinesMinimal(customMinimal);
    return true;
  }

  // ── Daily Workout Progress Logs (Date-Keyed History & Ticks) ──────────────

  /// Retrieves the logged routine, exercises, and completed ticks for a specific calendar date.
  Future<DailyWorkoutLog?> getDailyLog(String dateKey) async {
    if (_cachedExercises == null) {
      await getExercises();
    }
    final raw = await _storage.getWorkoutDailyLog(dateKey);
    if (raw == null) return null;
    try {
      return DailyWorkoutLog.fromMinimalJson(raw, _exerciseMap);
    } catch (_) {
      return null;
    }
  }

  /// Persists progress, set completion ticks, and active routine for a calendar date.
  Future<void> saveDailyLog(DailyWorkoutLog log) async {
    await _storage.saveWorkoutDailyLog(log.date, log.toMinimalJson());
  }

  // ── Exercise volume table ──────────────────────────────────────────────────
  // One row per (exerciseId, date). Rewriting the same day replaces that row.

  Future<void> upsertExerciseVolume(ExerciseVolumeRecord record) async {
    final table = await _storage.getExerciseVolumeTable();
    final rows = List<Map<String, dynamic>>.from(table[record.exerciseId] ?? const []);
    rows.removeWhere((row) => row['date'] == record.date);

    if (!record.isEmpty) {
      rows.add(record.toJson());
      rows.sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
    }

    if (rows.isEmpty) {
      table.remove(record.exerciseId);
    } else {
      table[record.exerciseId] = rows;
    }
    await _storage.saveExerciseVolumeTable(table);
  }

  /// Sets from the latest day this exercise was logged.
  /// Completion is cleared so the next session starts unchecked.
  /// [beforeDate] excludes that day and anything after it.
  Future<List<ExerciseSet>?> latestSetsForExercise(
    String exerciseId, {
    String? beforeDate,
  }) async {
    final logs = await getAllDailyLogs();
    String? bestDate;
    List<ExerciseSet>? best;

    for (final entry in logs.entries) {
      if (beforeDate != null && entry.key.compareTo(beforeDate) >= 0) continue;
      WorkoutExerciseItem? match;
      for (final item in entry.value.exercises.reversed) {
        if (item.exercise.id == exerciseId && item.sets.isNotEmpty) {
          match = item;
          break;
        }
      }
      if (match == null) continue;
      if (bestDate != null && entry.key.compareTo(bestDate) <= 0) continue;
      bestDate = entry.key;
      best = match.sets;
    }

    if (best == null) return null;
    return [
      for (var i = 0; i < best.length; i++)
        best[i].copyWith(setNumber: i + 1, isCompleted: false),
    ];
  }

  /// First time uses the catalog defaults. Later sessions copy the last logged sets.
  Future<WorkoutExerciseItem> rememberOrCreate(
    Exercise exercise, {
    String? beforeDate,
  }) async {
    final last = await latestSetsForExercise(exercise.id, beforeDate: beforeDate);
    if (last == null || last.isEmpty) {
      return WorkoutExerciseItem.create(exercise: exercise);
    }
    return WorkoutExerciseItem(
      id: '${exercise.id}_${DateTime.now().microsecondsSinceEpoch}',
      exercise: exercise,
      targetSets: last.length,
      targetReps: last.last.reps,
      targetWeight: last.last.weight,
      sets: last,
    );
  }

  /// Keeps the plan item, but fills its sets from the last time it was logged.
  Future<WorkoutExerciseItem> withRememberedSets(
    WorkoutExerciseItem item, {
    String? beforeDate,
  }) async {
    final last = await latestSetsForExercise(item.exercise.id, beforeDate: beforeDate);
    if (last == null || last.isEmpty) return item;
    return item.copyWith(
      targetSets: last.length,
      targetReps: last.last.reps,
      targetWeight: last.last.weight,
      sets: last,
    );
  }

  /// Latest session for [exerciseId] strictly before [beforeDate] (yyyy-MM-dd).
  Future<ExerciseVolumeRecord?> previousExerciseVolume({
    required String exerciseId,
    required String beforeDate,
  }) async {
    final table = await _storage.getExerciseVolumeTable();
    final rows = table[exerciseId];
    if (rows == null || rows.isEmpty) return null;

    ExerciseVolumeRecord? latest;
    for (final row in rows) {
      final record = ExerciseVolumeRecord.fromJson(exerciseId, row);
      if (record.isEmpty || record.date.compareTo(beforeDate) >= 0) continue;
      if (latest == null || record.date.compareTo(latest.date) > 0) {
        latest = record;
      }
    }
    return latest;
  }

  /// All persisted daily workout logs, keyed by "yyyy-MM-dd".
  Future<Map<String, DailyWorkoutLog>> getAllDailyLogs() async {
    if (_cachedExercises == null) {
      await getExercises();
    }
    final raw = await _storage.getAllWorkoutDailyLogs();
    final result = <String, DailyWorkoutLog>{};
    for (final entry in raw.entries) {
      try {
        result[entry.key] = DailyWorkoutLog.fromMinimalJson(entry.value, _exerciseMap);
      } catch (_) {}
    }
    return result;
  }

  /// Updates weight, reps, or sets for a specific exercise in a routine day
  Future<void> updateExerciseInRoutineDay({
    required String routineId,
    required String dayName,
    required String exerciseItemId,
    int? sets,
    int? reps,
    double? weight,
    int? completedSetIndex,
    bool? isCompleted,
  }) async {
    final routines = await getRoutines();
    final routineIndex = routines.indexWhere((r) => r.id == routineId);
    if (routineIndex < 0) return;

    final routine = routines[routineIndex];
    final dayIndex = routine.days.indexWhere(
      (d) => d.dayName.toLowerCase() == dayName.toLowerCase(),
    );
    if (dayIndex < 0) return;

    final day = routine.days[dayIndex];
    final exerciseIndex = day.exercises.indexWhere((e) => e.id == exerciseItemId);
    if (exerciseIndex < 0) return;

    final currentItem = day.exercises[exerciseIndex];

    var updatedSets = List<ExerciseSet>.from(currentItem.sets);
    final targetSets = sets ?? currentItem.targetSets;
    final targetReps = reps ?? currentItem.targetReps;
    final targetWeight = weight ?? currentItem.targetWeight;

    // Adjust set items if sets count changed
    if (targetSets != updatedSets.length) {
      if (targetSets > updatedSets.length) {
        for (int i = updatedSets.length; i < targetSets; i++) {
          updatedSets.add(ExerciseSet(
            setNumber: i + 1,
            reps: targetReps,
            weight: targetWeight,
          ));
        }
      } else {
        updatedSets = updatedSets.sublist(0, targetSets);
      }
    }

    // Update weight or reps across all sets if updated globally
    if (weight != null || reps != null) {
      updatedSets = updatedSets.map((s) {
        return s.copyWith(
          weight: weight ?? s.weight,
          reps: reps ?? s.reps,
        );
      }).toList();
    }

    // Toggle specific set completion if requested
    if (completedSetIndex != null && completedSetIndex < updatedSets.length) {
      final currentSet = updatedSets[completedSetIndex];
      updatedSets[completedSetIndex] = currentSet.copyWith(
        isCompleted: isCompleted ?? !currentSet.isCompleted,
      );
    }

    final updatedItem = currentItem.copyWith(
      targetSets: targetSets,
      targetReps: targetReps,
      targetWeight: targetWeight,
      sets: updatedSets,
    );

    final updatedExercises = List<WorkoutExerciseItem>.from(day.exercises);
    updatedExercises[exerciseIndex] = updatedItem;

    final updatedDay = day.copyWith(exercises: updatedExercises);
    final updatedDays = List<RoutineDay>.from(routine.days);
    updatedDays[dayIndex] = updatedDay;

    _cachedRoutines![routineIndex] = routine.copyWith(days: updatedDays);
  }

  /// Updates weight, reps, or completion for a specific set in an exercise
  Future<void> updateSpecificSet({
    required String routineId,
    required String dayName,
    required String exerciseItemId,
    required int setIndex,
    double? weight,
    int? reps,
    bool? isCompleted,
  }) async {
    final routines = await getRoutines();
    final routineIndex = routines.indexWhere((r) => r.id == routineId);
    if (routineIndex < 0) return;

    final routine = routines[routineIndex];
    final dayIndex = routine.days.indexWhere(
      (d) => d.dayName.toLowerCase() == dayName.toLowerCase(),
    );
    if (dayIndex < 0) return;

    final day = routine.days[dayIndex];
    final exerciseIndex = day.exercises.indexWhere((e) => e.id == exerciseItemId);
    if (exerciseIndex < 0) return;

    final currentItem = day.exercises[exerciseIndex];
    if (setIndex < 0 || setIndex >= currentItem.sets.length) return;

    final currentSet = currentItem.sets[setIndex];
    final updatedSet = currentSet.copyWith(
      weight: weight ?? currentSet.weight,
      reps: reps ?? currentSet.reps,
      isCompleted: isCompleted ?? currentSet.isCompleted,
    );

    final updatedSets = List<ExerciseSet>.from(currentItem.sets)..[setIndex] = updatedSet;
    final updatedItem = currentItem.copyWith(sets: updatedSets);

    final updatedExercises = List<WorkoutExerciseItem>.from(day.exercises)
      ..[exerciseIndex] = updatedItem;

    final updatedDay = day.copyWith(exercises: updatedExercises);
    final updatedDays = List<RoutineDay>.from(routine.days)..[dayIndex] = updatedDay;

    _cachedRoutines![routineIndex] = routine.copyWith(days: updatedDays);
  }

  /// Adds a new set to an exercise in a routine day
  Future<void> addSetToExercise({
    required String routineId,
    required String dayName,
    required String exerciseItemId,
    double? weight,
    int? reps,
  }) async {
    final routines = await getRoutines();
    final routineIndex = routines.indexWhere((r) => r.id == routineId);
    if (routineIndex < 0) return;

    final routine = routines[routineIndex];
    final dayIndex = routine.days.indexWhere(
      (d) => d.dayName.toLowerCase() == dayName.toLowerCase(),
    );
    if (dayIndex < 0) return;

    final day = routine.days[dayIndex];
    final exerciseIndex = day.exercises.indexWhere((e) => e.id == exerciseItemId);
    if (exerciseIndex < 0) return;

    final currentItem = day.exercises[exerciseIndex];
    final updatedSets = List<ExerciseSet>.from(currentItem.sets);
    final lastSet = updatedSets.isNotEmpty ? updatedSets.last : null;

    final newSetWeight = weight ?? lastSet?.weight ?? currentItem.targetWeight;
    final newSetReps = reps ?? lastSet?.reps ?? currentItem.targetReps;

    updatedSets.add(ExerciseSet(
      setNumber: updatedSets.length + 1,
      weight: newSetWeight,
      reps: newSetReps,
      isCompleted: false,
    ));

    final updatedItem = currentItem.copyWith(
      targetSets: updatedSets.length,
      sets: updatedSets,
    );

    final updatedExercises = List<WorkoutExerciseItem>.from(day.exercises)
      ..[exerciseIndex] = updatedItem;

    final updatedDay = day.copyWith(exercises: updatedExercises);
    final updatedDays = List<RoutineDay>.from(routine.days)..[dayIndex] = updatedDay;

    _cachedRoutines![routineIndex] = routine.copyWith(days: updatedDays);
  }

  /// Removes a specific set from an exercise in a routine day
  Future<void> removeSetFromExercise({
    required String routineId,
    required String dayName,
    required String exerciseItemId,
    required int setIndex,
  }) async {
    final routines = await getRoutines();
    final routineIndex = routines.indexWhere((r) => r.id == routineId);
    if (routineIndex < 0) return;

    final routine = routines[routineIndex];
    final dayIndex = routine.days.indexWhere(
      (d) => d.dayName.toLowerCase() == dayName.toLowerCase(),
    );
    if (dayIndex < 0) return;

    final day = routine.days[dayIndex];
    final exerciseIndex = day.exercises.indexWhere((e) => e.id == exerciseItemId);
    if (exerciseIndex < 0) return;

    final currentItem = day.exercises[exerciseIndex];
    if (setIndex < 0 || setIndex >= currentItem.sets.length) return;

    final updatedSets = List<ExerciseSet>.from(currentItem.sets)..removeAt(setIndex);

    // Renumber remaining sets
    for (int i = 0; i < updatedSets.length; i++) {
      updatedSets[i] = updatedSets[i].copyWith(setNumber: i + 1);
    }

    final updatedItem = currentItem.copyWith(
      targetSets: updatedSets.length,
      sets: updatedSets,
    );

    final updatedExercises = List<WorkoutExerciseItem>.from(day.exercises)
      ..[exerciseIndex] = updatedItem;

    final updatedDay = day.copyWith(exercises: updatedExercises);
    final updatedDays = List<RoutineDay>.from(routine.days)..[dayIndex] = updatedDay;

    _cachedRoutines![routineIndex] = routine.copyWith(days: updatedDays);
  }

  // ── Static Exercise Catalog (70+ Widely Used Exercises) ───────────────────

  List<Exercise> _buildStaticExerciseCatalog() {
    return const [
      // ── CHEST ──
      Exercise(
        id: 'ex_barbell_bench_press',
        name: 'Barbell Bench Press',
        targetMuscle: 'Chest',
        secondaryMuscles: ['Triceps', 'Shoulders'],
        category: 'Upper Body',
        equipment: 'Barbell',
        defaultSets: 4,
        defaultReps: 8,
        defaultWeight: 60.0,
        instructions: 'Lie flat on the bench, grip the barbell slightly wider than shoulder width, lower slowly to mid-chest, and press up until arms are extended.',
      ),
      Exercise(
        id: 'ex_incline_dumbbell_press',
        name: 'Incline Dumbbell Press',
        targetMuscle: 'Chest',
        secondaryMuscles: ['Shoulders', 'Triceps'],
        category: 'Upper Body',
        equipment: 'Dumbbell',
        defaultSets: 3,
        defaultReps: 10,
        defaultWeight: 22.0,
        instructions: 'Set bench to 30-45 degrees. Press dumbbells upward directly over your upper chest, squeezing at the top.',
      ),
      Exercise(
        id: 'ex_flat_dumbbell_press',
        name: 'Flat Dumbbell Press',
        targetMuscle: 'Chest',
        secondaryMuscles: ['Triceps', 'Shoulders'],
        category: 'Upper Body',
        equipment: 'Dumbbell',
        defaultSets: 3,
        defaultReps: 10,
        defaultWeight: 24.0,
        instructions: 'Lie on a flat bench holding dumbbells at chest level. Press them up smoothly until arms are straight without clanking them together.',
      ),
      Exercise(
        id: 'ex_incline_barbell_bench_press',
        name: 'Incline Barbell Bench Press',
        targetMuscle: 'Chest',
        secondaryMuscles: ['Shoulders', 'Triceps'],
        category: 'Upper Body',
        equipment: 'Barbell',
        defaultSets: 4,
        defaultReps: 8,
        defaultWeight: 50.0,
        instructions: 'Lie on a 30-degree incline bench, lower the bar smoothly to your upper clavicle line, and press powerfully upward.',
      ),
      Exercise(
        id: 'ex_pec_deck_fly',
        name: 'Pec Deck / Butterfly Fly',
        targetMuscle: 'Chest',
        secondaryMuscles: ['Shoulders'],
        category: 'Upper Body',
        equipment: 'Machine',
        defaultSets: 3,
        defaultReps: 12,
        defaultWeight: 40.0,
        instructions: 'Sit upright with back flat against the pad. Bring padded arms together in a hugging motion, squeezing the inner pecs.',
      ),
      Exercise(
        id: 'ex_cable_chest_fly',
        name: 'Cable Chest Fly',
        targetMuscle: 'Chest',
        secondaryMuscles: ['Shoulders'],
        category: 'Upper Body',
        equipment: 'Cable',
        defaultSets: 3,
        defaultReps: 12,
        defaultWeight: 15.0,
        instructions: 'Set pulleys at chest height. Step forward slightly, bring handles together in an arc with a slight bend in your elbows.',
      ),
      Exercise(
        id: 'ex_machine_chest_press',
        name: 'Machine Chest Press',
        targetMuscle: 'Chest',
        secondaryMuscles: ['Triceps', 'Shoulders'],
        category: 'Upper Body',
        equipment: 'Machine',
        defaultSets: 3,
        defaultReps: 10,
        defaultWeight: 45.0,
        instructions: 'Adjust seat so handles align with mid-chest. Press outward until arms are extended, pausing briefly at the peak.',
      ),
      Exercise(
        id: 'ex_chest_dip',
        name: 'Chest Dip',
        targetMuscle: 'Chest',
        secondaryMuscles: ['Triceps', 'Shoulders'],
        category: 'Upper Body',
        equipment: 'Bodyweight',
        defaultSets: 3,
        defaultReps: 10,
        defaultWeight: 0.0,
        instructions: 'Grip parallel bars, lean forward at a 30-degree angle, lower until upper arms are parallel to the floor, and press up.',
      ),
      Exercise(
        id: 'ex_push_up',
        name: 'Push-Up',
        targetMuscle: 'Chest',
        secondaryMuscles: ['Triceps', 'Abs'],
        category: 'Upper Body',
        equipment: 'Bodyweight',
        defaultSets: 3,
        defaultReps: 15,
        defaultWeight: 0.0,
        instructions: 'Maintain a strict plank posture. Lower your chest until it nearly touches the floor, then press back up explosively.',
      ),
      Exercise(
        id: 'ex_decline_barbell_bench_press',
        name: 'Decline Barbell Bench Press',
        targetMuscle: 'Chest',
        secondaryMuscles: ['Triceps'],
        category: 'Upper Body',
        equipment: 'Barbell',
        defaultSets: 3,
        defaultReps: 10,
        defaultWeight: 55.0,
        instructions: 'Secure legs in the decline bench. Lower bar gently to the lower chest and press directly upwards.',
      ),
      Exercise(
        id: 'ex_dumbbell_pullover',
        name: 'Dumbbell Pullover',
        targetMuscle: 'Chest',
        secondaryMuscles: ['Back', 'Triceps'],
        category: 'Upper Body',
        equipment: 'Dumbbell',
        defaultSets: 3,
        defaultReps: 12,
        defaultWeight: 18.0,
        instructions: 'Lie across a bench holding one dumbbell with both hands. Lower behind your head feeling the chest and lat stretch, then pull back up.',
      ),
      Exercise(
        id: 'ex_low_to_high_cable_fly',
        name: 'Low-to-High Cable Fly',
        targetMuscle: 'Chest',
        secondaryMuscles: ['Shoulders'],
        category: 'Upper Body',
        equipment: 'Cable',
        defaultSets: 3,
        defaultReps: 12,
        defaultWeight: 10.0,
        instructions: 'Set pulleys to lowest level. Pull handles upward and together in an arc, focusing on the clavicular upper chest.',
      ),
      Exercise(
        id: 'ex_high_to_low_cable_fly',
        name: 'High-to-Low Cable Fly',
        targetMuscle: 'Chest',
        secondaryMuscles: ['Triceps'],
        category: 'Upper Body',
        equipment: 'Cable',
        defaultSets: 3,
        defaultReps: 12,
        defaultWeight: 15.0,
        instructions: 'Set pulleys above shoulder height. Bring handles downward and inward towards your hips to emphasize lower chest.',
      ),
      Exercise(
        id: 'ex_dumbbell_squeeze_press',
        name: 'Dumbbell Squeeze Press',
        targetMuscle: 'Chest',
        secondaryMuscles: ['Triceps'],
        category: 'Upper Body',
        equipment: 'Dumbbell',
        defaultSets: 3,
        defaultReps: 10,
        defaultWeight: 20.0,
        instructions: 'Press two dumbbells firmly together through the entire pressing range of motion, creating constant inner pec tension.',
      ),
      // ── BACK ──
      Exercise(
        id: 'ex_lat_pulldown',
        name: 'Lat Pulldown',
        targetMuscle: 'Back',
        secondaryMuscles: ['Biceps', 'Shoulders'],
        category: 'Upper Body',
        equipment: 'Cable',
        defaultSets: 4,
        defaultReps: 10,
        defaultWeight: 50.0,
        instructions: 'Sit with thighs secured. Pull bar down smoothly to upper chest while keeping torso slightly leaned back.',
      ),
      Exercise(
        id: 'ex_seated_cable_row',
        name: 'Seated Cable Row',
        targetMuscle: 'Back',
        secondaryMuscles: ['Biceps', 'Shoulders'],
        category: 'Upper Body',
        equipment: 'Cable',
        defaultSets: 3,
        defaultReps: 10,
        defaultWeight: 45.0,
        instructions: 'Keep torso upright with slight natural arch in lower back. Pull handle towards navel, squeezing shoulder blades together.',
      ),
      Exercise(
        id: 'ex_pull_up',
        name: 'Pull-Up',
        targetMuscle: 'Back',
        secondaryMuscles: ['Biceps', 'Shoulders'],
        category: 'Upper Body',
        equipment: 'Bodyweight',
        defaultSets: 3,
        defaultReps: 8,
        defaultWeight: 0.0,
        instructions: 'Overhand grip on bar slightly wider than shoulders. Pull up until chin clears the bar, lowering with controlled tempo.',
      ),
      Exercise(
        id: 'ex_bent_over_barbell_row',
        name: 'Bent-Over Barbell Row',
        targetMuscle: 'Back',
        secondaryMuscles: ['Biceps', 'Legs'],
        category: 'Upper Body',
        equipment: 'Barbell',
        defaultSets: 4,
        defaultReps: 8,
        defaultWeight: 50.0,
        instructions: 'Hinge hips at 45 degrees with flat spine. Pull barbell to lower ribcage, driving elbows toward the ceiling.',
      ),
      Exercise(
        id: 'ex_one_arm_dumbbell_row',
        name: 'One-Arm Dumbbell Row',
        targetMuscle: 'Back',
        secondaryMuscles: ['Biceps', 'Shoulders'],
        category: 'Upper Body',
        equipment: 'Dumbbell',
        defaultSets: 3,
        defaultReps: 10,
        defaultWeight: 22.0,
        instructions: 'Place one knee and hand on bench. Pull dumbbell upward toward your hip crease, keeping elbow tucked close.',
      ),
      Exercise(
        id: 'ex_t_bar_row',
        name: 'T-Bar Row',
        targetMuscle: 'Back',
        secondaryMuscles: ['Biceps', 'Shoulders'],
        category: 'Upper Body',
        equipment: 'Barbell',
        defaultSets: 3,
        defaultReps: 10,
        defaultWeight: 40.0,
        instructions: 'Straddle the bar with hinged hips. Pull handle up to chest with elbows flaring slightly, squeezing mid-back.',
      ),
      Exercise(
        id: 'ex_chin_up',
        name: 'Chin-Up',
        targetMuscle: 'Back',
        secondaryMuscles: ['Biceps'],
        category: 'Upper Body',
        equipment: 'Bodyweight',
        defaultSets: 3,
        defaultReps: 8,
        defaultWeight: 0.0,
        instructions: 'Underhand shoulder-width grip. Pull upward until chin clears the bar with strong bicep and lat involvement.',
      ),
      Exercise(
        id: 'ex_straight_arm_cable_pulldown',
        name: 'Straight-Arm Cable Pulldown',
        targetMuscle: 'Back',
        secondaryMuscles: ['Triceps'],
        category: 'Upper Body',
        equipment: 'Cable',
        defaultSets: 3,
        defaultReps: 12,
        defaultWeight: 20.0,
        instructions: 'Stand tall facing high pulley. With arms nearly straight, pull bar down in an arc to thighs, flexing lats intensely.',
      ),
      Exercise(
        id: 'ex_machine_row',
        name: 'Machine Row',
        targetMuscle: 'Back',
        secondaryMuscles: ['Biceps'],
        category: 'Upper Body',
        equipment: 'Machine',
        defaultSets: 3,
        defaultReps: 10,
        defaultWeight: 40.0,
        instructions: 'Chest firmly against the pad. Pull handles back smoothly and hold the squeeze for 1 second at full contraction.',
      ),
      Exercise(
        id: 'ex_chest_supported_db_row',
        name: 'Chest-Supported Dumbbell Row',
        targetMuscle: 'Back',
        secondaryMuscles: ['Biceps', 'Shoulders'],
        category: 'Upper Body',
        equipment: 'Dumbbell',
        defaultSets: 3,
        defaultReps: 10,
        defaultWeight: 18.0,
        instructions: 'Lie prone on a 30-degree incline bench. Row dumbbells upward without swinging or lower-back strain.',
      ),
      Exercise(
        id: 'ex_conventional_deadlift',
        name: 'Conventional Deadlift',
        targetMuscle: 'Back',
        secondaryMuscles: ['Legs', 'Abs'],
        category: 'Lower Body',
        equipment: 'Barbell',
        defaultSets: 4,
        defaultReps: 5,
        defaultWeight: 90.0,
        instructions: 'Feet hip-width, grip outside knees. Drive feet into floor, extending hips and knees simultaneously to stand tall.',
      ),
      Exercise(
        id: 'ex_barbell_shrug',
        name: 'Barbell Shrug',
        targetMuscle: 'Back',
        secondaryMuscles: ['Shoulders'],
        category: 'Upper Body',
        equipment: 'Barbell',
        defaultSets: 3,
        defaultReps: 12,
        defaultWeight: 60.0,
        instructions: 'Hold barbell with overhand grip. Elevate shoulders straight up towards ears, pause at the peak, and lower under control.',
      ),
      Exercise(
        id: 'ex_dumbbell_shrug',
        name: 'Dumbbell Shrug',
        targetMuscle: 'Back',
        secondaryMuscles: ['Shoulders'],
        category: 'Upper Body',
        equipment: 'Dumbbell',
        defaultSets: 3,
        defaultReps: 12,
        defaultWeight: 24.0,
        instructions: 'Hold heavy dumbbells at your sides. Shrug straight up, holding peak contraction without rolling shoulders.',
      ),
      Exercise(
        id: 'ex_back_extension',
        name: 'Back Extension',
        targetMuscle: 'Back',
        secondaryMuscles: ['Legs'],
        category: 'Upper Body',
        equipment: 'Bodyweight',
        defaultSets: 3,
        defaultReps: 12,
        defaultWeight: 0.0,
        instructions: 'Lock ankles in 45-degree hyperextension bench. Lower upper body forward, then engage glutes and lower back to return to neutral.',
      ),
      // ── SHOULDERS ──
      Exercise(
        id: 'ex_barbell_overhead_press',
        name: 'Barbell Overhead Press',
        targetMuscle: 'Shoulders',
        secondaryMuscles: ['Triceps', 'Abs'],
        category: 'Upper Body',
        equipment: 'Barbell',
        defaultSets: 4,
        defaultReps: 8,
        defaultWeight: 40.0,
        instructions: 'Stand with feet shoulder-width. Press barbell overhead in a straight vertical bar path, locking out with head through arms.',
      ),
      Exercise(
        id: 'ex_seated_dumbbell_shoulder_press',
        name: 'Seated Dumbbell Shoulder Press',
        targetMuscle: 'Shoulders',
        secondaryMuscles: ['Triceps'],
        category: 'Upper Body',
        equipment: 'Dumbbell',
        defaultSets: 3,
        defaultReps: 10,
        defaultWeight: 18.0,
        instructions: 'Sit upright with back support. Press dumbbells upward until arms are straight overhead, lowering smoothly to ear level.',
      ),
      Exercise(
        id: 'ex_dumbbell_lateral_raise',
        name: 'Dumbbell Lateral Raise',
        targetMuscle: 'Shoulders',
        secondaryMuscles: ['Traps'],
        category: 'Upper Body',
        equipment: 'Dumbbell',
        defaultSets: 4,
        defaultReps: 12,
        defaultWeight: 8.0,
        instructions: 'Raise dumbbells out to your sides until elbows are level with shoulders. Pour slightly forward like emptying glasses.',
      ),
      Exercise(
        id: 'ex_cable_lateral_raise',
        name: 'Cable Lateral Raise',
        targetMuscle: 'Shoulders',
        secondaryMuscles: ['Traps'],
        category: 'Upper Body',
        equipment: 'Cable',
        defaultSets: 3,
        defaultReps: 12,
        defaultWeight: 5.0,
        instructions: 'Set low pulley. Stand side-on, raise arm outward in the scapular plane with continuous smooth tension.',
      ),
      Exercise(
        id: 'ex_cable_face_pull',
        name: 'Cable Face Pull',
        targetMuscle: 'Shoulders',
        secondaryMuscles: ['Back', 'Traps'],
        category: 'Upper Body',
        equipment: 'Cable',
        defaultSets: 3,
        defaultReps: 15,
        defaultWeight: 15.0,
        instructions: 'Set rope attachment to eye level. Pull rope towards bridge of nose, flaring elbows out and rotating hands back.',
      ),
      Exercise(
        id: 'ex_reverse_pec_deck',
        name: 'Reverse Pec Deck',
        targetMuscle: 'Shoulders',
        secondaryMuscles: ['Back'],
        category: 'Upper Body',
        equipment: 'Machine',
        defaultSets: 3,
        defaultReps: 12,
        defaultWeight: 30.0,
        instructions: 'Sit facing the machine pad. Grip handles, keep elbows slightly bent, and fly outward to isolate posterior delts.',
      ),
      Exercise(
        id: 'ex_arnold_press',
        name: 'Arnold Press',
        targetMuscle: 'Shoulders',
        secondaryMuscles: ['Triceps'],
        category: 'Upper Body',
        equipment: 'Dumbbell',
        defaultSets: 3,
        defaultReps: 10,
        defaultWeight: 16.0,
        instructions: 'Start with dumbbells at chin height, palms facing you. Rotate palms outward as you press overhead in one fluid motion.',
      ),
      Exercise(
        id: 'ex_machine_shoulder_press',
        name: 'Machine Shoulder Press',
        targetMuscle: 'Shoulders',
        secondaryMuscles: ['Triceps'],
        category: 'Upper Body',
        equipment: 'Machine',
        defaultSets: 3,
        defaultReps: 10,
        defaultWeight: 35.0,
        instructions: 'Adjust seat height so handles sit at chin level. Press upward overhead with stable shoulder blade posture.',
      ),
      Exercise(
        id: 'ex_dumbbell_front_raise',
        name: 'Dumbbell Front Raise',
        targetMuscle: 'Shoulders',
        secondaryMuscles: ['Chest'],
        category: 'Upper Body',
        equipment: 'Dumbbell',
        defaultSets: 3,
        defaultReps: 12,
        defaultWeight: 8.0,
        instructions: 'Stand tall, raise dumbbells in front of you to eye level with controlled speed without rocking your torso.',
      ),
      Exercise(
        id: 'ex_bent_over_db_reverse_fly',
        name: 'Bent-Over Dumbbell Reverse Fly',
        targetMuscle: 'Shoulders',
        secondaryMuscles: ['Back'],
        category: 'Upper Body',
        equipment: 'Dumbbell',
        defaultSets: 3,
        defaultReps: 12,
        defaultWeight: 8.0,
        instructions: 'Hinge at hips with flat back. Raise dumbbells outward like wings, squeezing rear delts at peak contraction.',
      ),
      Exercise(
        id: 'ex_upright_row',
        name: 'Upright Row',
        targetMuscle: 'Shoulders',
        secondaryMuscles: ['Biceps', 'Traps'],
        category: 'Upper Body',
        equipment: 'Barbell',
        defaultSets: 3,
        defaultReps: 10,
        defaultWeight: 25.0,
        instructions: 'Grip barbell shoulder-width apart. Pull upward along your torso, leading with high elbows up to chest level.',
      ),
      Exercise(
        id: 'ex_smith_machine_shoulder_press',
        name: 'Smith Machine Shoulder Press',
        targetMuscle: 'Shoulders',
        secondaryMuscles: ['Triceps'],
        category: 'Upper Body',
        equipment: 'Machine',
        defaultSets: 3,
        defaultReps: 10,
        defaultWeight: 35.0,
        instructions: 'Position bench inside Smith machine. Lower guided bar smoothly in front of face to chin height, then press up.',
      ),
      // ── BICEPS ──
      Exercise(
        id: 'ex_barbell_curl',
        name: 'Barbell Curl',
        targetMuscle: 'Biceps',
        secondaryMuscles: ['Forearms'],
        category: 'Upper Body',
        equipment: 'Barbell',
        defaultSets: 3,
        defaultReps: 10,
        defaultWeight: 25.0,
        instructions: 'Stand tall with shoulder-width underhand grip. Curl barbell upward keeping upper arms pinned firmly against ribs.',
      ),
      Exercise(
        id: 'ex_dumbbell_curl',
        name: 'Dumbbell Curl',
        targetMuscle: 'Biceps',
        secondaryMuscles: ['Forearms'],
        category: 'Upper Body',
        equipment: 'Dumbbell',
        defaultSets: 3,
        defaultReps: 10,
        defaultWeight: 12.0,
        instructions: 'Hold dumbbells at sides with palms neutral, curl upward supinating wrists so palms face shoulders at top.',
      ),
      Exercise(
        id: 'ex_hammer_curl',
        name: 'Hammer Curl',
        targetMuscle: 'Biceps',
        secondaryMuscles: ['Forearms'],
        category: 'Upper Body',
        equipment: 'Dumbbell',
        defaultSets: 3,
        defaultReps: 10,
        defaultWeight: 12.0,
        instructions: 'Keep palms facing each other throughout the curl movement. Builds brachialis and forearm thickness.',
      ),
      Exercise(
        id: 'ex_preacher_curl',
        name: 'Preacher Curl',
        targetMuscle: 'Biceps',
        secondaryMuscles: ['Forearms'],
        category: 'Upper Body',
        equipment: 'Barbell',
        defaultSets: 3,
        defaultReps: 10,
        defaultWeight: 20.0,
        instructions: 'Rest upper arms firmly on preacher bench pad. Curl bar upward without lifting elbows off the surface.',
      ),
      Exercise(
        id: 'ex_incline_dumbbell_curl',
        name: 'Incline Dumbbell Curl',
        targetMuscle: 'Biceps',
        secondaryMuscles: ['Forearms'],
        category: 'Upper Body',
        equipment: 'Dumbbell',
        defaultSets: 3,
        defaultReps: 10,
        defaultWeight: 10.0,
        instructions: 'Sit on a 45-degree incline bench, letting arms hang behind torso. Curl dumbbells to emphasize the long head stretch.',
      ),
      Exercise(
        id: 'ex_cable_curl',
        name: 'Cable Curl',
        targetMuscle: 'Biceps',
        secondaryMuscles: ['Forearms'],
        category: 'Upper Body',
        equipment: 'Cable',
        defaultSets: 3,
        defaultReps: 12,
        defaultWeight: 15.0,
        instructions: 'Attach straight or EZ bar to low pulley. Curl upward enjoying constant tension throughout the arc.',
      ),
      Exercise(
        id: 'ex_concentration_curl',
        name: 'Concentration Curl',
        targetMuscle: 'Biceps',
        secondaryMuscles: ['Forearms'],
        category: 'Upper Body',
        equipment: 'Dumbbell',
        defaultSets: 3,
        defaultReps: 12,
        defaultWeight: 10.0,
        instructions: 'Sit on bench with elbow braced inside thigh. Curl dumbbell upward to chest with zero body momentum.',
      ),
      Exercise(
        id: 'ex_ez_bar_curl',
        name: 'EZ-Bar Curl',
        targetMuscle: 'Biceps',
        secondaryMuscles: ['Forearms'],
        category: 'Upper Body',
        equipment: 'Barbell',
        defaultSets: 3,
        defaultReps: 10,
        defaultWeight: 25.0,
        instructions: 'Grip the angled bends of the EZ curl bar to reduce wrist strain while curling with maximum loading.',
      ),
      Exercise(
        id: 'ex_rope_hammer_curl',
        name: 'Rope Hammer Curl',
        targetMuscle: 'Biceps',
        secondaryMuscles: ['Forearms'],
        category: 'Upper Body',
        equipment: 'Cable',
        defaultSets: 3,
        defaultReps: 12,
        defaultWeight: 15.0,
        instructions: 'Attach rope to low pulley, curl upward with palms facing inwards, pulling rope ends apart at top.',
      ),
      Exercise(
        id: 'ex_spider_curl',
        name: 'Spider Curl',
        targetMuscle: 'Biceps',
        secondaryMuscles: ['Forearms'],
        category: 'Upper Body',
        equipment: 'Barbell',
        defaultSets: 3,
        defaultReps: 10,
        defaultWeight: 18.0,
        instructions: 'Lie chest-down on steep incline bench with arms hanging vertically. Curl upward for strict bicep isolation.',
      ),
      Exercise(
        id: 'ex_reverse_barbell_curl',
        name: 'Reverse Barbell Curl',
        targetMuscle: 'Biceps',
        secondaryMuscles: ['Forearms'],
        category: 'Upper Body',
        equipment: 'Barbell',
        defaultSets: 3,
        defaultReps: 12,
        defaultWeight: 18.0,
        instructions: 'Use overhand (pronated) grip on barbell. Curl bar upward targeting the brachioradialis forearm muscle.',
      ),
      Exercise(
        id: 'ex_dumbbell_wrist_curl',
        name: 'Dumbbell Wrist Curl',
        targetMuscle: 'Biceps',
        secondaryMuscles: ['Forearms'],
        category: 'Upper Body',
        equipment: 'Dumbbell',
        defaultSets: 3,
        defaultReps: 15,
        defaultWeight: 8.0,
        instructions: 'Rest forearms on bench with wrists hanging over edge. Curl wrists upward slowly, building forearm grip strength.',
      ),
      // ── TRICEPS ──
      Exercise(
        id: 'ex_rope_cable_pushdown',
        name: 'Rope Cable Pushdown',
        targetMuscle: 'Triceps',
        secondaryMuscles: ['Forearms'],
        category: 'Upper Body',
        equipment: 'Cable',
        defaultSets: 3,
        defaultReps: 12,
        defaultWeight: 17.5,
        instructions: 'Attach rope to high pulley. Keep elbows locked at your sides, push down and flare rope ends apart at the bottom.',
      ),
      Exercise(
        id: 'ex_straight_bar_pushdown',
        name: 'Straight-Bar Cable Pushdown',
        targetMuscle: 'Triceps',
        secondaryMuscles: [],
        category: 'Upper Body',
        equipment: 'Cable',
        defaultSets: 3,
        defaultReps: 12,
        defaultWeight: 20.0,
        instructions: 'Grip straight bar overhand, press down until elbows fully lock out with controlled return.',
      ),
      Exercise(
        id: 'ex_ez_bar_skull_crusher',
        name: 'EZ-Bar Skull Crusher',
        targetMuscle: 'Triceps',
        secondaryMuscles: ['Chest'],
        category: 'Upper Body',
        equipment: 'Barbell',
        defaultSets: 3,
        defaultReps: 10,
        defaultWeight: 22.5,
        instructions: 'Lie on flat bench with EZ bar overhead. Bend only at the elbows, lowering bar toward your forehead or crown, then press up.',
      ),
      Exercise(
        id: 'ex_overhead_dumbbell_triceps_extension',
        name: 'Overhead Dumbbell Triceps Extension',
        targetMuscle: 'Triceps',
        secondaryMuscles: ['Shoulders'],
        category: 'Upper Body',
        equipment: 'Dumbbell',
        defaultSets: 3,
        defaultReps: 10,
        defaultWeight: 16.0,
        instructions: 'Hold one dumbbell with both hands overhead. Lower it behind your neck keeping elbows pointing forward, then extend arms.',
      ),
      Exercise(
        id: 'ex_close_grip_bench_press',
        name: 'Close-Grip Bench Press',
        targetMuscle: 'Triceps',
        secondaryMuscles: ['Chest', 'Shoulders'],
        category: 'Upper Body',
        equipment: 'Barbell',
        defaultSets: 3,
        defaultReps: 8,
        defaultWeight: 50.0,
        instructions: 'Hands shoulder-width on the bar. Keep elbows tucked close to your ribs as you lower and press upward.',
      ),
      Exercise(
        id: 'ex_overhead_cable_triceps_extension',
        name: 'Overhead Cable Triceps Extension',
        targetMuscle: 'Triceps',
        secondaryMuscles: [],
        category: 'Upper Body',
        equipment: 'Cable',
        defaultSets: 3,
        defaultReps: 12,
        defaultWeight: 15.0,
        instructions: 'Face away from high or mid cable pulley. Extend arms overhead forward, keeping upper arms parallel to ears.',
      ),
      Exercise(
        id: 'ex_triceps_dip',
        name: 'Triceps Dip',
        targetMuscle: 'Triceps',
        secondaryMuscles: ['Chest', 'Shoulders'],
        category: 'Upper Body',
        equipment: 'Bodyweight',
        defaultSets: 3,
        defaultReps: 10,
        defaultWeight: 0.0,
        instructions: 'Stay upright on dip bars with elbows pointing straight back behind you, focusing load strictly on triceps.',
      ),
      Exercise(
        id: 'ex_machine_triceps_extension',
        name: 'Machine Triceps Extension',
        targetMuscle: 'Triceps',
        secondaryMuscles: [],
        category: 'Upper Body',
        equipment: 'Machine',
        defaultSets: 3,
        defaultReps: 12,
        defaultWeight: 35.0,
        instructions: 'Sit with back supported, elbows aligned with machine axis. Push handles downward to full arm lockout.',
      ),
      Exercise(
        id: 'ex_dumbbell_kickback',
        name: 'Dumbbell Kickback',
        targetMuscle: 'Triceps',
        secondaryMuscles: [],
        category: 'Upper Body',
        equipment: 'Dumbbell',
        defaultSets: 3,
        defaultReps: 12,
        defaultWeight: 8.0,
        instructions: 'Torso hinged forward parallel to ground. Pin upper arm high, extend forearm back until arm is straight, squeeze hard.',
      ),
      Exercise(
        id: 'ex_diamond_push_up',
        name: 'Diamond Push-Up',
        targetMuscle: 'Triceps',
        secondaryMuscles: ['Chest'],
        category: 'Upper Body',
        equipment: 'Bodyweight',
        defaultSets: 3,
        defaultReps: 12,
        defaultWeight: 0.0,
        instructions: 'Position hands directly below chest with thumbs and index fingers touching to form a diamond shape.',
      ),
      // ── LEGS ──
      Exercise(
        id: 'ex_barbell_back_squat',
        name: 'Barbell Back Squat',
        targetMuscle: 'Legs',
        secondaryMuscles: ['Abs'],
        category: 'Lower Body',
        equipment: 'Barbell',
        defaultSets: 4,
        defaultReps: 8,
        defaultWeight: 80.0,
        instructions: 'Rest barbell on upper traps. Descend with hips back and knees tracking toes until thighs break parallel, then drive up.',
      ),
      Exercise(
        id: 'ex_leg_press',
        name: 'Leg Press',
        targetMuscle: 'Legs',
        secondaryMuscles: [],
        category: 'Lower Body',
        equipment: 'Machine',
        defaultSets: 4,
        defaultReps: 10,
        defaultWeight: 140.0,
        instructions: 'Feet shoulder-width on platform. Lower sled until knees bend 90 degrees, press through whole foot without locking knees violently.',
      ),
      Exercise(
        id: 'ex_romanian_deadlift',
        name: 'Romanian Deadlift',
        targetMuscle: 'Legs',
        secondaryMuscles: ['Back'],
        category: 'Lower Body',
        equipment: 'Barbell',
        defaultSets: 4,
        defaultReps: 8,
        defaultWeight: 70.0,
        instructions: 'Slight knee bend. Push hips back as barbell glides down shins until deep hamstring stretch is felt, then drive hips forward.',
      ),
      Exercise(
        id: 'ex_leg_extension',
        name: 'Leg Extension',
        targetMuscle: 'Legs',
        secondaryMuscles: [],
        category: 'Lower Body',
        equipment: 'Machine',
        defaultSets: 3,
        defaultReps: 12,
        defaultWeight: 45.0,
        instructions: 'Back against pad, shin pad just above ankles. Extend knees upward to lockout, holding peak quad contraction for 1 second.',
      ),
      Exercise(
        id: 'ex_lying_leg_curl',
        name: 'Lying Leg Curl',
        targetMuscle: 'Legs',
        secondaryMuscles: [],
        category: 'Lower Body',
        equipment: 'Machine',
        defaultSets: 3,
        defaultReps: 12,
        defaultWeight: 35.0,
        instructions: 'Lie face down with pad behind Achilles tendons. Curl heels up towards glutes, keeping hips pressed flat to pad.',
      ),
      Exercise(
        id: 'ex_seated_leg_curl',
        name: 'Seated Leg Curl',
        targetMuscle: 'Legs',
        secondaryMuscles: [],
        category: 'Lower Body',
        equipment: 'Machine',
        defaultSets: 3,
        defaultReps: 12,
        defaultWeight: 40.0,
        instructions: 'Adjust thigh lap pad tightly. Curl legs down and backwards under your seat, engaging hamstrings throughout.',
      ),
      Exercise(
        id: 'ex_bulgarian_split_squat',
        name: 'Bulgarian Split Squat',
        targetMuscle: 'Legs',
        secondaryMuscles: [],
        category: 'Lower Body',
        equipment: 'Dumbbell',
        defaultSets: 3,
        defaultReps: 10,
        defaultWeight: 14.0,
        instructions: 'Rear foot elevated on bench behind you. Lower until front thigh is parallel to ground, driving through front heel to rise.',
      ),
      Exercise(
        id: 'ex_barbell_front_squat',
        name: 'Barbell Front Squat',
        targetMuscle: 'Legs',
        secondaryMuscles: ['Abs'],
        category: 'Lower Body',
        equipment: 'Barbell',
        defaultSets: 3,
        defaultReps: 8,
        defaultWeight: 55.0,
        instructions: 'Bar racked across front delts with high elbows. Squat deep with upright torso, placing immense focus on quads.',
      ),
      Exercise(
        id: 'ex_dumbbell_goblet_squat',
        name: 'Dumbbell Goblet Squat',
        targetMuscle: 'Legs',
        secondaryMuscles: ['Abs'],
        category: 'Lower Body',
        equipment: 'Dumbbell',
        defaultSets: 3,
        defaultReps: 12,
        defaultWeight: 20.0,
        instructions: 'Hold dumbbell vertically against chest. Squat between knees keeping chest up and spine long.',
      ),
      Exercise(
        id: 'ex_standing_calf_raise',
        name: 'Standing Calf Raise',
        targetMuscle: 'Legs',
        secondaryMuscles: [],
        category: 'Lower Body',
        equipment: 'Machine',
        defaultSets: 4,
        defaultReps: 15,
        defaultWeight: 50.0,
        instructions: 'Balls of feet on step with heels hanging off. Lower into deep calf stretch, then rise onto tiptoes squeezing gastrocnemius.',
      ),
      Exercise(
        id: 'ex_seated_calf_raise',
        name: 'Seated Calf Raise',
        targetMuscle: 'Legs',
        secondaryMuscles: [],
        category: 'Lower Body',
        equipment: 'Machine',
        defaultSets: 3,
        defaultReps: 15,
        defaultWeight: 35.0,
        instructions: 'Sit with knees bent 90 degrees under thigh pads. Elevate toes high to build the soleus calf muscle.',
      ),
      Exercise(
        id: 'ex_barbell_hip_thrust',
        name: 'Barbell Hip Thrust',
        targetMuscle: 'Legs',
        secondaryMuscles: [],
        category: 'Lower Body',
        equipment: 'Barbell',
        defaultSets: 4,
        defaultReps: 10,
        defaultWeight: 80.0,
        instructions: 'Upper back against bench, barbell across hips with pad. Drive hips toward ceiling, locking out glutes at full extension.',
      ),
      Exercise(
        id: 'ex_walking_lunge',
        name: 'Walking Lunge',
        targetMuscle: 'Legs',
        secondaryMuscles: [],
        category: 'Lower Body',
        equipment: 'Dumbbell',
        defaultSets: 3,
        defaultReps: 12,
        defaultWeight: 14.0,
        instructions: 'Step forward into a deep lunge, back knee kissing the ground, driving through front heel to step directly into next rep.',
      ),
      Exercise(
        id: 'ex_hack_squat',
        name: 'Hack Squat',
        targetMuscle: 'Legs',
        secondaryMuscles: [],
        category: 'Lower Body',
        equipment: 'Machine',
        defaultSets: 3,
        defaultReps: 10,
        defaultWeight: 80.0,
        instructions: 'Shoulders and back braced against machine carriage. Squat down to 90 degrees, pushing through feet with strict quad isolation.',
      ),
      Exercise(
        id: 'ex_dumbbell_romanian_deadlift',
        name: 'Dumbbell Romanian Deadlift',
        targetMuscle: 'Legs',
        secondaryMuscles: ['Back'],
        category: 'Lower Body',
        equipment: 'Dumbbell',
        defaultSets: 3,
        defaultReps: 10,
        defaultWeight: 22.0,
        instructions: 'Hold dumbbells in front of thighs, hinge back at hips with soft knees, feel deep hamstring stretch and return.',
      ),
      Exercise(
        id: 'ex_hip_abduction_machine',
        name: 'Hip Abduction Machine',
        targetMuscle: 'Legs',
        secondaryMuscles: [],
        category: 'Lower Body',
        equipment: 'Machine',
        defaultSets: 3,
        defaultReps: 15,
        defaultWeight: 45.0,
        instructions: 'Sit with pads against outer thighs. Push legs outwards apart, holding peak contraction to train gluteus medius.',
      ),
      Exercise(
        id: 'ex_hip_adduction_machine',
        name: 'Hip Adduction Machine',
        targetMuscle: 'Legs',
        secondaryMuscles: [],
        category: 'Lower Body',
        equipment: 'Machine',
        defaultSets: 3,
        defaultReps: 15,
        defaultWeight: 40.0,
        instructions: 'Pads positioned on inside of knees. Squeeze thighs inwards together smoothly to strengthen the adductors.',
      ),
      // ── ABS ──
      Exercise(
        id: 'ex_plank',
        name: 'Plank',
        targetMuscle: 'Abs',
        secondaryMuscles: ['Shoulders'],
        category: 'Core',
        equipment: 'Bodyweight',
        defaultSets: 3,
        defaultReps: 45,
        defaultWeight: 0.0,
        instructions: 'Rest on forearms and toes with body in a rigid straight line. Brace core hard, pulling belly button toward spine.',
      ),
      Exercise(
        id: 'ex_hanging_knee_raise',
        name: 'Hanging Knee Raise',
        targetMuscle: 'Abs',
        secondaryMuscles: ['Forearms'],
        category: 'Core',
        equipment: 'Bodyweight',
        defaultSets: 3,
        defaultReps: 12,
        defaultWeight: 0.0,
        instructions: 'Hang from pull-up bar. Flex abs to curl knees up to chest without swinging, lowering under control.',
      ),
      Exercise(
        id: 'ex_cable_crunch',
        name: 'Cable Crunch',
        targetMuscle: 'Abs',
        secondaryMuscles: [],
        category: 'Core',
        equipment: 'Cable',
        defaultSets: 3,
        defaultReps: 15,
        defaultWeight: 25.0,
        instructions: 'Kneel below high pulley holding rope at temples. Curl spine downward bringing elbows to thighs.',
      ),
      Exercise(
        id: 'ex_hanging_leg_raise',
        name: 'Hanging Leg Raise',
        targetMuscle: 'Abs',
        secondaryMuscles: ['Forearms'],
        category: 'Core',
        equipment: 'Bodyweight',
        defaultSets: 3,
        defaultReps: 10,
        defaultWeight: 0.0,
        instructions: 'Hang from bar with straight legs. Contract lower abdominals to raise feet to 90 degrees or higher.',
      ),
      Exercise(
        id: 'ex_ab_wheel_rollout',
        name: 'Ab-Wheel Rollout',
        targetMuscle: 'Abs',
        secondaryMuscles: ['Shoulders'],
        category: 'Core',
        equipment: 'Bodyweight',
        defaultSets: 3,
        defaultReps: 10,
        defaultWeight: 0.0,
        instructions: 'Kneel holding wheel handles. Roll forward maintaining slight posterior pelvic tilt, then pull back using abs.',
      ),
      Exercise(
        id: 'ex_bicycle_crunch',
        name: 'Bicycle Crunch',
        targetMuscle: 'Abs',
        secondaryMuscles: [],
        category: 'Core',
        equipment: 'Bodyweight',
        defaultSets: 3,
        defaultReps: 20,
        defaultWeight: 0.0,
        instructions: 'Lie flat on back. Alternate rotating opposite elbow to opposite knee while extending the other leg.',
      ),
      Exercise(
        id: 'ex_russian_twist',
        name: 'Russian Twist',
        targetMuscle: 'Abs',
        secondaryMuscles: [],
        category: 'Core',
        equipment: 'Bodyweight',
        defaultSets: 3,
        defaultReps: 20,
        defaultWeight: 0.0,
        instructions: 'Sit with knees bent and feet elevated. Rotate torso from left to right, engaging oblique abdominal walls.',
      ),
      Exercise(
        id: 'ex_decline_sit_up',
        name: 'Decline Sit-Up',
        targetMuscle: 'Abs',
        secondaryMuscles: [],
        category: 'Core',
        equipment: 'Bodyweight',
        defaultSets: 3,
        defaultReps: 15,
        defaultWeight: 0.0,
        instructions: 'Hook feet on decline bench. Curl upper torso upward curling abdominal wall toward knees.',
      ),
      Exercise(
        id: 'ex_machine_abdominal_crunch',
        name: 'Machine Abdominal Crunch',
        targetMuscle: 'Abs',
        secondaryMuscles: [],
        category: 'Core',
        equipment: 'Machine',
        defaultSets: 3,
        defaultReps: 12,
        defaultWeight: 35.0,
        instructions: 'Sit in machine with upper pads on chest. Flex abdominals to curl forward against resistance.',
      ),
      Exercise(
        id: 'ex_captains_chair_knee_raise',
        name: 'Captain’s Chair Knee Raise',
        targetMuscle: 'Abs',
        secondaryMuscles: [],
        category: 'Core',
        equipment: 'Bodyweight',
        defaultSets: 3,
        defaultReps: 12,
        defaultWeight: 0.0,
        instructions: 'Rest forearms on parallel arm pads with back flat against cushion. Lift knees up towards chest smoothly.',
      ),
      Exercise(
        id: 'ex_lying_leg_raise',
        name: 'Lying Leg Raise',
        targetMuscle: 'Abs',
        secondaryMuscles: [],
        category: 'Core',
        equipment: 'Bodyweight',
        defaultSets: 3,
        defaultReps: 15,
        defaultWeight: 0.0,
        instructions: 'Lie flat on back with hands under glutes. Raise legs together to 90 degrees without letting lower back arch.',
      ),
      Exercise(
        id: 'ex_mountain_climber',
        name: 'Mountain Climber',
        targetMuscle: 'Abs',
        secondaryMuscles: ['Shoulders'],
        category: 'Core',
        equipment: 'Bodyweight',
        defaultSets: 3,
        defaultReps: 20,
        defaultWeight: 0.0,
        instructions: 'Hold push-up position. Drive knees alternatively towards chest at a rhythmic, controlled pace.',
      ),
    ];
  }

  // ── Default Preset Routines ──────────────────────────────────────────────

}
