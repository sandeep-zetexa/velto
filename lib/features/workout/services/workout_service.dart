import 'package:velto/core/services/local_storage_service.dart';
import 'package:velto/features/workout/models/daily_workout_log.dart';
import 'package:velto/features/workout/models/exercise.dart';
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
    final raw = _buildStaticExerciseCatalog();
    final exercises = raw.map((e) {
      if (e.svg == null || e.svg!.isEmpty) {
        return e.copyWith(svg: Exercise.defaultPlaceholderSvg);
      }
      return e;
    }).toList();
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 18h18"/><path d="M6 18V8"/><path d="M18 18V8"/><path d="M4 8h16"/><rect x="2" y="6" width="2" height="4" rx="1"/><rect x="20" y="6" width="2" height="4" rx="1"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 19h18"/><path d="M5 19l8-10h6"/><path d="M12 6h8"/><circle cx="12" cy="6" r="1.5"/><circle cx="20" cy="6" r="1.5"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m6.5 6.5 11 11"/><path d="m21 21-1-1"/><path d="m3 3 1 1"/><path d="m18 22 4-4"/><path d="m2 6 4-4"/><path d="m3 10 7-7"/><path d="m14 21 7-7"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 19h18"/><path d="M5 19l8-10h6"/><path d="M12 6h8"/><circle cx="12" cy="6" r="1.5"/><circle cx="20" cy="6" r="1.5"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 4v16"/><path d="M19 4v16"/><path d="M5 12h4"/><path d="M19 12h-4"/><rect x="10" y="9" width="4" height="6" rx="1"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="4" cy="5" r="2"/><circle cx="20" cy="5" r="2"/><path d="M6 5c3 4 5 7 6 7s3-3 6-7"/><circle cx="12" cy="12" r="2"/><path d="M12 14v6"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="4" y="4" width="6" height="16" rx="2"/><path d="M10 9h6l4 3v5"/><circle cx="16" cy="9" r="1.5"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 8h6v12"/><path d="M14 8h6v12"/><path d="M12 7v6"/><path d="m10 11 2 2 2-2"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 20h18"/><path d="m4 16 11-4 4 2"/><path d="M15 12v8"/><circle cx="19" cy="10" r="2"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 18h18"/><path d="M6 18V8"/><path d="M18 18V8"/><path d="M4 8h16"/><rect x="2" y="6" width="2" height="4" rx="1"/><rect x="20" y="6" width="2" height="4" rx="1"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m6.5 6.5 11 11"/><path d="m21 21-1-1"/><path d="m3 3 1 1"/><path d="m18 22 4-4"/><path d="m2 6 4-4"/><path d="m3 10 7-7"/><path d="m14 21 7-7"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="4" cy="5" r="2"/><circle cx="20" cy="5" r="2"/><path d="M6 5c3 4 5 7 6 7s3-3 6-7"/><circle cx="12" cy="12" r="2"/><path d="M12 14v6"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="4" cy="5" r="2"/><circle cx="20" cy="5" r="2"/><path d="M6 5c3 4 5 7 6 7s3-3 6-7"/><circle cx="12" cy="12" r="2"/><path d="M12 14v6"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m6.5 6.5 11 11"/><path d="m21 21-1-1"/><path d="m3 3 1 1"/><path d="m18 22 4-4"/><path d="m2 6 4-4"/><path d="m3 10 7-7"/><path d="m14 21 7-7"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 5h18"/><path d="M12 5v7"/><path d="m9 9 3 3 3-3"/><rect x="9" y="16" width="6" height="5" rx="1"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 19h16"/><circle cx="19" cy="12" r="2"/><path d="M17 12H8"/><path d="M10 8l-4 4 4 4"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 5h18"/><path d="M5 5v5"/><path d="M19 5v5"/><path d="M12 19V9"/><path d="m9 12 3-3 3 3"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 14h16"/><rect x="2" y="12" width="2" height="4" rx="1"/><rect x="20" y="12" width="2" height="4" rx="1"/><path d="M12 18v-8"/><path d="m9 13 3-3 3 3"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m6.5 6.5 11 11"/><path d="m21 21-1-1"/><path d="m3 3 1 1"/><path d="m18 22 4-4"/><path d="m2 6 4-4"/><path d="m3 10 7-7"/><path d="m14 21 7-7"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 14h16"/><rect x="2" y="12" width="2" height="4" rx="1"/><rect x="20" y="12" width="2" height="4" rx="1"/><path d="M12 18v-8"/><path d="m9 13 3-3 3 3"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 5h18"/><path d="M5 5v5"/><path d="M19 5v5"/><path d="M12 19V9"/><path d="m9 12 3-3 3 3"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 5h18"/><path d="M12 5v7"/><path d="m9 9 3 3 3-3"/><rect x="9" y="16" width="6" height="5" rx="1"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 4v16h16"/><rect x="7" y="10" width="4" height="6" rx="1"/><path d="M14 13h4"/><circle cx="19" cy="13" r="1.5"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m6.5 6.5 11 11"/><path d="m21 21-1-1"/><path d="m3 3 1 1"/><path d="m18 22 4-4"/><path d="m2 6 4-4"/><path d="m3 10 7-7"/><path d="m14 21 7-7"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 18h18"/><circle cx="6" cy="18" r="3"/><circle cx="18" cy="18" r="3"/><path d="M12 14V6"/><path d="m9 9 3-3 3 3"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 17l4-5 4-1 4 1 4 5"/><circle cx="12" cy="6" r="2.5"/><path d="M3 20h18"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 17l4-5 4-1 4 1 4 5"/><circle cx="12" cy="6" r="2.5"/><path d="M3 20h18"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 19h16"/><path d="M6 19l6-8 7 3"/><circle cx="19" cy="14" r="2"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 8h16"/><rect x="2" y="6" width="2" height="4" rx="1"/><rect x="20" y="6" width="2" height="4" rx="1"/><path d="M12 16V9"/><path d="m9 12 3-3 3 3"/><path d="M9 20h6"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 8h16"/><rect x="2" y="6" width="2" height="4" rx="1"/><rect x="20" y="6" width="2" height="4" rx="1"/><path d="M12 16V9"/><path d="m9 12 3-3 3 3"/><path d="M9 20h6"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 15c2-6 6-8 8-8s6 2 8 8"/><circle cx="4" cy="16" r="1.5"/><circle cx="20" cy="16" r="1.5"/><path d="M12 12v8"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 15c2-6 6-8 8-8s6 2 8 8"/><circle cx="4" cy="16" r="1.5"/><circle cx="20" cy="16" r="1.5"/><path d="M12 12v8"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="4" cy="12" r="2"/><path d="M6 12h7"/><path d="m13 12 5-4"/><path d="m13 12 5 4"/><circle cx="19" cy="7" r="1.5"/><circle cx="19" cy="17" r="1.5"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 4v16"/><path d="M4 12c3-4 6-5 8-5s5 1 8 5"/><circle cx="4" cy="12" r="1.5"/><circle cx="20" cy="12" r="1.5"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 8h16"/><rect x="2" y="6" width="2" height="4" rx="1"/><rect x="20" y="6" width="2" height="4" rx="1"/><path d="M12 16V9"/><path d="m9 12 3-3 3 3"/><path d="M9 20h6"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="4" y="4" width="6" height="16" rx="2"/><path d="M10 9h6l4 3v5"/><circle cx="16" cy="9" r="1.5"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M6 20v-8c0-2 2-4 4-4h7"/><circle cx="18" cy="8" r="2"/><path d="M6 20h4"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 4v16"/><path d="M4 12c3-4 6-5 8-5s5 1 8 5"/><circle cx="4" cy="12" r="1.5"/><circle cx="20" cy="12" r="1.5"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 10h16"/><rect x="2" y="8" width="2" height="4" rx="1"/><rect x="20" y="8" width="2" height="4" rx="1"/><path d="M12 20v-9"/><path d="m9 14 3-3 3 3"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 8h16"/><rect x="2" y="6" width="2" height="4" rx="1"/><rect x="20" y="6" width="2" height="4" rx="1"/><path d="M12 16V9"/><path d="m9 12 3-3 3 3"/><path d="M9 20h6"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M6 19l4-8 5 4"/><circle cx="16" cy="14" r="2.5"/><path d="M4 21h8"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M6 19l4-8 5 4"/><circle cx="16" cy="14" r="2.5"/><path d="M4 21h8"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M7 19l4-8 5 3"/><path d="M17 10v7"/><rect x="15.5" y="8" width="3" height="2" rx="0.5"/><rect x="15.5" y="17" width="3" height="2" rx="0.5"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 19h16"/><path d="M6 19l6-9h6"/><circle cx="18" cy="10" r="2"/><path d="M12 14l4-4"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M6 19l4-8 5 4"/><circle cx="16" cy="14" r="2.5"/><path d="M4 21h8"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="6" cy="19" r="2"/><path d="M8 19l7-6"/><circle cx="16" cy="12" r="2"/><path d="M18 10l-4 4"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M6 19l4-8 5 4"/><circle cx="16" cy="14" r="2.5"/><path d="M4 21h8"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M6 19l4-8 5 4"/><circle cx="16" cy="14" r="2.5"/><path d="M4 21h8"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M7 19l4-8 5 3"/><path d="M17 10v7"/><rect x="15.5" y="8" width="3" height="2" rx="0.5"/><rect x="15.5" y="17" width="3" height="2" rx="0.5"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M6 19l4-8 5 4"/><circle cx="16" cy="14" r="2.5"/><path d="M4 21h8"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M6 19l4-8 5 4"/><circle cx="16" cy="14" r="2.5"/><path d="M4 21h8"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 16h8l4-4"/><circle cx="17" cy="11" r="2"/><path d="M4 20h16"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="4" r="2"/><path d="M12 6v6"/><path d="m12 12-4 6"/><path d="m12 12 4 6"/><circle cx="8" cy="18" r="1.5"/><circle cx="16" cy="18" r="1.5"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="4" r="2"/><path d="M12 6v8"/><path d="M6 14h12"/><path d="m10 17 2 2 2-2"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 17h18"/><path d="M8 17v-6l4-3"/><path d="M10 8h6"/><circle cx="10" cy="8" r="1.5"/><circle cx="16" cy="8" r="1.5"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 21V9"/><path d="M8 9h8"/><circle cx="8" cy="9" r="1.5"/><circle cx="16" cy="9" r="1.5"/><path d="m9 6 3-3 3 3"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 18h18"/><path d="M6 18V8"/><path d="M18 18V8"/><path d="M4 8h16"/><rect x="2" y="6" width="2" height="4" rx="1"/><rect x="20" y="6" width="2" height="4" rx="1"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 21V9"/><path d="M8 9h8"/><circle cx="8" cy="9" r="1.5"/><circle cx="16" cy="9" r="1.5"/><path d="m9 6 3-3 3 3"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 8h6v12"/><path d="M14 8h6v12"/><path d="M12 7v6"/><path d="m10 11 2 2 2-2"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="4" y="4" width="6" height="16" rx="2"/><path d="M10 9h6l4 3v5"/><circle cx="16" cy="9" r="1.5"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m6.5 6.5 11 11"/><path d="m21 21-1-1"/><path d="m3 3 1 1"/><path d="m18 22 4-4"/><path d="m2 6 4-4"/><path d="m3 10 7-7"/><path d="m14 21 7-7"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 20h18"/><path d="m4 16 11-4 4 2"/><path d="M15 12v8"/><circle cx="19" cy="10" r="2"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 7h18"/><rect x="2" y="5" width="2" height="4" rx="1"/><rect x="20" y="5" width="2" height="4" rx="1"/><path d="M6 20l4-7 4 3 4-8"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 20h16"/><path d="M5 19l10-10"/><rect x="13" y="6" width="6" height="4" rx="1" transform="rotate(-45 16 8)"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 18h18"/><circle cx="6" cy="18" r="3"/><circle cx="18" cy="18" r="3"/><path d="M12 14V6"/><path d="m9 9 3-3 3 3"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M6 8v8h8"/><path d="m14 16 4 3"/><circle cx="19" cy="19" r="2"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 15h12l3 3"/><path d="m16 15 2-5"/><circle cx="19" cy="10" r="2"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 15h12l3 3"/><path d="m16 15 2-5"/><circle cx="19" cy="10" r="2"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 21h18"/><path d="M16 21v-5l-4-3-4 4v4"/><circle cx="12" cy="7" r="2"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 7h18"/><rect x="2" y="5" width="2" height="4" rx="1"/><rect x="20" y="5" width="2" height="4" rx="1"/><path d="M6 20l4-7 4 3 4-8"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 7h18"/><rect x="2" y="5" width="2" height="4" rx="1"/><rect x="20" y="5" width="2" height="4" rx="1"/><path d="M6 20l4-7 4 3 4-8"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 20h16"/><path d="m7 19 6-8 4 3-2 5"/><path d="M13 5v4"/><path d="m11 7 2-2 2 2"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 20h16"/><path d="m7 19 6-8 4 3-2 5"/><path d="M13 5v4"/><path d="m11 7 2-2 2 2"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="13" width="5" height="7" rx="1"/><path d="M8 15h6l4 5"/><circle cx="12" cy="13" r="2"/><path d="M12 9v3"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 21h18"/><path d="M16 21v-5l-4-3-4 4v4"/><circle cx="12" cy="7" r="2"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 20h16"/><path d="M5 19l10-10"/><rect x="13" y="6" width="6" height="4" rx="1" transform="rotate(-45 16 8)"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 18h18"/><circle cx="6" cy="18" r="3"/><circle cx="18" cy="18" r="3"/><path d="M12 14V6"/><path d="m9 9 3-3 3 3"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 19h16"/><circle cx="12" cy="9" r="3"/><path d="m9 15-3 4"/><path d="m15 15 3 4"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 19h16"/><circle cx="12" cy="9" r="3"/><path d="m9 15-3 4"/><path d="m15 15 3 4"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 20h18"/><path d="m4 16 12-3 4 1"/><path d="M16 13v7"/><path d="M4 16v4"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 4h16"/><path d="M12 4v8l5 2"/><circle cx="12" cy="8" r="1.5"/><path d="M12 12h5"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="4" r="2"/><path d="M12 6v4"/><path d="M12 10c-3 1-5 4-5 8h6"/><path d="M3 21h18"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 4h16"/><path d="M12 4v8l5 2"/><circle cx="12" cy="8" r="1.5"/><path d="M12 12h5"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="6"/><circle cx="12" cy="12" r="2"/><path d="M4 12h2"/><path d="M18 12h2"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 20h18"/><path d="M5 20c2-5 6-7 10-4l3 4"/><circle cx="7" cy="12" r="2"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 19l5-6 6 6"/><path d="M7 10c2-2 6-2 8 0"/><path d="m14 8 2 2-2 2"/><circle cx="10" cy="8" r="2"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 20h18"/><path d="M5 20c2-5 6-7 10-4l3 4"/><circle cx="7" cy="12" r="2"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="4" r="2"/><path d="M12 6v4"/><path d="M12 10c-3 1-5 4-5 8h6"/><path d="M3 21h18"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 4h16"/><path d="M12 4v8l5 2"/><circle cx="12" cy="8" r="1.5"/><path d="M12 12h5"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 4h16"/><path d="M12 4v8l5 2"/><circle cx="12" cy="8" r="1.5"/><path d="M12 12h5"/></svg>',
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
        svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 20h18"/><path d="m4 16 11-4 4 2"/><path d="M15 12v8"/><circle cx="19" cy="10" r="2"/></svg>',
      ),
    ];
  }

  // ── Default Preset Routines ──────────────────────────────────────────────

}
