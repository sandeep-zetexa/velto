import 'package:velto/features/workout/models/exercise.dart';
import 'package:velto/features/workout/models/routine_day.dart';
import 'package:velto/features/workout/models/workout_routine.dart';

class WorkoutService {
  static final WorkoutService _instance = WorkoutService._internal();
  factory WorkoutService() => _instance;
  WorkoutService._internal();

  List<WorkoutRoutine>? _cachedRoutines;
  List<Exercise>? _cachedExercises;

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
    'Cardio',
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

  // ── Exercise Catalog Retrieval ───────────────────────────────────────────
  Future<List<Exercise>> getExercises({
    String? muscle,
    String? query,
    String? equipment,
  }) async {
    _cachedExercises ??= _buildStaticExerciseCatalog();

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

  // ── Routine Management ───────────────────────────────────────────────────

  Future<List<WorkoutRoutine>> getRoutines() async {
    if (_cachedRoutines == null || _cachedRoutines!.isEmpty) {
      _cachedRoutines = _buildDefaultPresetRoutines();
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
  }

  Future<void> saveRoutine(WorkoutRoutine routine, {bool setActive = false}) async {
    final routines = await getRoutines();
    final index = routines.indexWhere((r) => r.id == routine.id);

    if (index >= 0) {
      _cachedRoutines![index] = routine.copyWith(isActive: setActive ? true : routine.isActive);
    } else {
      _cachedRoutines!.add(routine.copyWith(isActive: setActive));
    }

    if (setActive) {
      await setActiveRoutine(routine.id);
    }
  }

  Future<bool> deleteRoutine(String routineId) async {
    final routines = await getRoutines();
    final index = routines.indexWhere((r) => r.id == routineId);
    if (index < 0) return false;

    final wasActive = routines[index].isActive;
    _cachedRoutines!.removeAt(index);

    if (wasActive && _cachedRoutines!.isNotEmpty) {
      _cachedRoutines![0] = _cachedRoutines![0].copyWith(isActive: true);
    }
    return true;
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
        id: 'ex_bench_press',
        name: 'Barbell Bench Press',
        targetMuscle: 'Chest',
        secondaryMuscles: ['Triceps', 'Front Delts'],
        category: 'Upper Body',
        equipment: 'Barbell',
        defaultSets: 4,
        defaultReps: 8,
        defaultWeight: 60.0,
      ),
      Exercise(
        id: 'ex_incline_db_press',
        name: 'Incline Dumbbell Press',
        targetMuscle: 'Chest',
        secondaryMuscles: ['Front Delts', 'Triceps'],
        category: 'Upper Body',
        equipment: 'Dumbbell',
        defaultSets: 3,
        defaultReps: 10,
        defaultWeight: 22.0,
      ),
      Exercise(
        id: 'ex_cable_flyes',
        name: 'Cable Chest Flyes',
        targetMuscle: 'Chest',
        secondaryMuscles: ['Front Delts'],
        category: 'Upper Body',
        equipment: 'Cable',
        defaultSets: 3,
        defaultReps: 12,
        defaultWeight: 12.5,
      ),
      Exercise(
        id: 'ex_chest_dips',
        name: 'Chest Dips',
        targetMuscle: 'Chest',
        secondaryMuscles: ['Triceps', 'Front Delts'],
        category: 'Upper Body',
        equipment: 'Bodyweight',
        defaultSets: 3,
        defaultReps: 10,
        defaultWeight: 0.0,
      ),
      Exercise(
        id: 'ex_push_ups',
        name: 'Push-Ups',
        targetMuscle: 'Chest',
        secondaryMuscles: ['Triceps', 'Core'],
        category: 'Upper Body',
        equipment: 'Bodyweight',
        defaultSets: 3,
        defaultReps: 15,
        defaultWeight: 0.0,
      ),
      Exercise(
        id: 'ex_machine_chest_press',
        name: 'Machine Chest Press',
        targetMuscle: 'Chest',
        secondaryMuscles: ['Triceps'],
        category: 'Upper Body',
        equipment: 'Machine',
        defaultSets: 3,
        defaultReps: 12,
        defaultWeight: 50.0,
      ),
      Exercise(
        id: 'ex_pec_deck_fly',
        name: 'Pec Deck Fly',
        targetMuscle: 'Chest',
        secondaryMuscles: ['Front Delts'],
        category: 'Upper Body',
        equipment: 'Machine',
        defaultSets: 3,
        defaultReps: 12,
        defaultWeight: 45.0,
      ),
      Exercise(
        id: 'ex_decline_bench_press',
        name: 'Decline Barbell Press',
        targetMuscle: 'Chest',
        secondaryMuscles: ['Triceps'],
        category: 'Upper Body',
        equipment: 'Barbell',
        defaultSets: 3,
        defaultReps: 10,
        defaultWeight: 60.0,
      ),

      // ── BACK ──
      Exercise(
        id: 'ex_deadlift',
        name: 'Barbell Deadlift',
        targetMuscle: 'Back',
        secondaryMuscles: ['Hamstrings', 'Glutes', 'Traps'],
        category: 'Compound',
        equipment: 'Barbell',
        defaultSets: 4,
        defaultReps: 5,
        defaultWeight: 100.0,
      ),
      Exercise(
        id: 'ex_pull_ups',
        name: 'Pull-Ups',
        targetMuscle: 'Back',
        secondaryMuscles: ['Biceps', 'Rear Delts'],
        category: 'Upper Body',
        equipment: 'Bodyweight',
        defaultSets: 3,
        defaultReps: 8,
        defaultWeight: 0.0,
      ),
      Exercise(
        id: 'ex_lat_pulldown',
        name: 'Lat Pulldown',
        targetMuscle: 'Back',
        secondaryMuscles: ['Biceps'],
        category: 'Upper Body',
        equipment: 'Cable',
        defaultSets: 3,
        defaultReps: 10,
        defaultWeight: 55.0,
      ),
      Exercise(
        id: 'ex_barbell_row',
        name: 'Bent-Over Barbell Row',
        targetMuscle: 'Back',
        secondaryMuscles: ['Biceps', 'Rear Delts'],
        category: 'Upper Body',
        equipment: 'Barbell',
        defaultSets: 3,
        defaultReps: 8,
        defaultWeight: 50.0,
      ),
      Exercise(
        id: 'ex_seated_cable_row',
        name: 'Seated Cable Row',
        targetMuscle: 'Back',
        secondaryMuscles: ['Biceps', 'Rhomboids'],
        category: 'Upper Body',
        equipment: 'Cable',
        defaultSets: 3,
        defaultReps: 10,
        defaultWeight: 50.0,
      ),
      Exercise(
        id: 'ex_one_arm_db_row',
        name: 'One-Arm Dumbbell Row',
        targetMuscle: 'Back',
        secondaryMuscles: ['Biceps', 'Lats'],
        category: 'Upper Body',
        equipment: 'Dumbbell',
        defaultSets: 3,
        defaultReps: 10,
        defaultWeight: 24.0,
      ),
      Exercise(
        id: 'ex_t_bar_row',
        name: 'T-Bar Row',
        targetMuscle: 'Back',
        secondaryMuscles: ['Biceps', 'Traps'],
        category: 'Upper Body',
        equipment: 'Machine',
        defaultSets: 3,
        defaultReps: 10,
        defaultWeight: 40.0,
      ),
      Exercise(
        id: 'ex_face_pulls',
        name: 'Face Pulls',
        targetMuscle: 'Back',
        secondaryMuscles: ['Rear Delts', 'Rotator Cuff'],
        category: 'Upper Body',
        equipment: 'Cable',
        defaultSets: 3,
        defaultReps: 15,
        defaultWeight: 17.5,
      ),

      // ── SHOULDERS ──
      Exercise(
        id: 'ex_overhead_press',
        name: 'Overhead Barbell Press',
        targetMuscle: 'Shoulders',
        secondaryMuscles: ['Triceps', 'Upper Chest'],
        category: 'Upper Body',
        equipment: 'Barbell',
        defaultSets: 4,
        defaultReps: 8,
        defaultWeight: 40.0,
      ),
      Exercise(
        id: 'ex_db_shoulder_press',
        name: 'Seated Dumbbell Shoulder Press',
        targetMuscle: 'Shoulders',
        secondaryMuscles: ['Triceps'],
        category: 'Upper Body',
        equipment: 'Dumbbell',
        defaultSets: 3,
        defaultReps: 10,
        defaultWeight: 20.0,
      ),
      Exercise(
        id: 'ex_db_lateral_raise',
        name: 'Dumbbell Lateral Raises',
        targetMuscle: 'Shoulders',
        secondaryMuscles: ['Traps'],
        category: 'Upper Body',
        equipment: 'Dumbbell',
        defaultSets: 4,
        defaultReps: 12,
        defaultWeight: 10.0,
      ),
      Exercise(
        id: 'ex_cable_lateral_raise',
        name: 'Cable Lateral Raises',
        targetMuscle: 'Shoulders',
        secondaryMuscles: ['Traps'],
        category: 'Upper Body',
        equipment: 'Cable',
        defaultSets: 3,
        defaultReps: 15,
        defaultWeight: 7.5,
      ),
      Exercise(
        id: 'ex_arnold_press',
        name: 'Arnold Dumbbell Press',
        targetMuscle: 'Shoulders',
        secondaryMuscles: ['Triceps'],
        category: 'Upper Body',
        equipment: 'Dumbbell',
        defaultSets: 3,
        defaultReps: 10,
        defaultWeight: 16.0,
      ),
      Exercise(
        id: 'ex_rear_delt_fly',
        name: 'Reverse Pec Deck / Rear Delt Fly',
        targetMuscle: 'Shoulders',
        secondaryMuscles: ['Upper Back'],
        category: 'Upper Body',
        equipment: 'Machine',
        defaultSets: 3,
        defaultReps: 15,
        defaultWeight: 35.0,
      ),
      Exercise(
        id: 'ex_shrugs',
        name: 'Barbell / Dumbbell Shrugs',
        targetMuscle: 'Shoulders',
        secondaryMuscles: ['Traps'],
        category: 'Upper Body',
        equipment: 'Barbell',
        defaultSets: 3,
        defaultReps: 12,
        defaultWeight: 60.0,
      ),

      // ── BICEPS ──
      Exercise(
        id: 'ex_barbell_curl',
        name: 'Barbell Bicep Curl',
        targetMuscle: 'Biceps',
        secondaryMuscles: ['Forearms'],
        category: 'Upper Body',
        equipment: 'Barbell',
        defaultSets: 3,
        defaultReps: 10,
        defaultWeight: 25.0,
      ),
      Exercise(
        id: 'ex_incline_db_curl',
        name: 'Incline Dumbbell Curl',
        targetMuscle: 'Biceps',
        secondaryMuscles: ['Brachialis'],
        category: 'Upper Body',
        equipment: 'Dumbbell',
        defaultSets: 3,
        defaultReps: 10,
        defaultWeight: 12.0,
      ),
      Exercise(
        id: 'ex_hammer_curl',
        name: 'Dumbbell Hammer Curls',
        targetMuscle: 'Biceps',
        secondaryMuscles: ['Brachialis', 'Forearms'],
        category: 'Upper Body',
        equipment: 'Dumbbell',
        defaultSets: 3,
        defaultReps: 12,
        defaultWeight: 14.0,
      ),
      Exercise(
        id: 'ex_preacher_curl',
        name: 'EZ-Bar Preacher Curl',
        targetMuscle: 'Biceps',
        secondaryMuscles: ['Brachialis'],
        category: 'Upper Body',
        equipment: 'Barbell',
        defaultSets: 3,
        defaultReps: 10,
        defaultWeight: 22.5,
      ),
      Exercise(
        id: 'ex_cable_rope_curl',
        name: 'Cable Rope Bicep Curl',
        targetMuscle: 'Biceps',
        secondaryMuscles: ['Forearms'],
        category: 'Upper Body',
        equipment: 'Cable',
        defaultSets: 3,
        defaultReps: 12,
        defaultWeight: 20.0,
      ),

      // ── TRICEPS ──
      Exercise(
        id: 'ex_tricep_pushdown',
        name: 'Cable Tricep Pushdown (Rope/V-Bar)',
        targetMuscle: 'Triceps',
        secondaryMuscles: [],
        category: 'Upper Body',
        equipment: 'Cable',
        defaultSets: 3,
        defaultReps: 12,
        defaultWeight: 25.0,
      ),
      Exercise(
        id: 'ex_skull_crushers',
        name: 'Lying Skull Crushers',
        targetMuscle: 'Triceps',
        secondaryMuscles: [],
        category: 'Upper Body',
        equipment: 'Barbell',
        defaultSets: 3,
        defaultReps: 10,
        defaultWeight: 25.0,
      ),
      Exercise(
        id: 'ex_overhead_cable_tricep',
        name: 'Overhead Cable Tricep Extension',
        targetMuscle: 'Triceps',
        secondaryMuscles: [],
        category: 'Upper Body',
        equipment: 'Cable',
        defaultSets: 3,
        defaultReps: 12,
        defaultWeight: 20.0,
      ),
      Exercise(
        id: 'ex_close_grip_bench',
        name: 'Close-Grip Bench Press',
        targetMuscle: 'Triceps',
        secondaryMuscles: ['Chest'],
        category: 'Upper Body',
        equipment: 'Barbell',
        defaultSets: 3,
        defaultReps: 10,
        defaultWeight: 50.0,
      ),
      Exercise(
        id: 'ex_bench_dips',
        name: 'Bench Dips',
        targetMuscle: 'Triceps',
        secondaryMuscles: ['Chest'],
        category: 'Upper Body',
        equipment: 'Bodyweight',
        defaultSets: 3,
        defaultReps: 12,
        defaultWeight: 0.0,
      ),

      // ── LEGS (Quads, Hamstrings, Glutes, Calves) ──
      Exercise(
        id: 'ex_squat',
        name: 'Barbell Back Squat',
        targetMuscle: 'Legs',
        secondaryMuscles: ['Quads', 'Glutes', 'Core'],
        category: 'Lower Body',
        equipment: 'Barbell',
        defaultSets: 4,
        defaultReps: 8,
        defaultWeight: 80.0,
      ),
      Exercise(
        id: 'ex_leg_press',
        name: 'Leg Press',
        targetMuscle: 'Legs',
        secondaryMuscles: ['Quads', 'Glutes'],
        category: 'Lower Body',
        equipment: 'Machine',
        defaultSets: 3,
        defaultReps: 12,
        defaultWeight: 140.0,
      ),
      Exercise(
        id: 'ex_rdl',
        name: 'Romanian Deadlift (RDL)',
        targetMuscle: 'Legs',
        secondaryMuscles: ['Hamstrings', 'Glutes', 'Lower Back'],
        category: 'Lower Body',
        equipment: 'Barbell',
        defaultSets: 3,
        defaultReps: 10,
        defaultWeight: 60.0,
      ),
      Exercise(
        id: 'ex_leg_extension',
        name: 'Leg Extensions',
        targetMuscle: 'Legs',
        secondaryMuscles: ['Quads'],
        category: 'Lower Body',
        equipment: 'Machine',
        defaultSets: 3,
        defaultReps: 12,
        defaultWeight: 45.0,
      ),
      Exercise(
        id: 'ex_leg_curl',
        name: 'Lying / Seated Leg Curls',
        targetMuscle: 'Legs',
        secondaryMuscles: ['Hamstrings'],
        category: 'Lower Body',
        equipment: 'Machine',
        defaultSets: 3,
        defaultReps: 12,
        defaultWeight: 40.0,
      ),
      Exercise(
        id: 'ex_bulgarian_split_squat',
        name: 'Bulgarian Split Squats',
        targetMuscle: 'Legs',
        secondaryMuscles: ['Quads', 'Glutes'],
        category: 'Lower Body',
        equipment: 'Dumbbell',
        defaultSets: 3,
        defaultReps: 10,
        defaultWeight: 14.0,
      ),
      Exercise(
        id: 'ex_hip_thrust',
        name: 'Barbell Hip Thrust',
        targetMuscle: 'Legs',
        secondaryMuscles: ['Glutes', 'Hamstrings'],
        category: 'Lower Body',
        equipment: 'Barbell',
        defaultSets: 3,
        defaultReps: 10,
        defaultWeight: 70.0,
      ),
      Exercise(
        id: 'ex_walking_lunges',
        name: 'Walking Dumbbell Lunges',
        targetMuscle: 'Legs',
        secondaryMuscles: ['Quads', 'Glutes'],
        category: 'Lower Body',
        equipment: 'Dumbbell',
        defaultSets: 3,
        defaultReps: 12,
        defaultWeight: 12.0,
      ),
      Exercise(
        id: 'ex_calf_raise',
        name: 'Standing Calf Raises',
        targetMuscle: 'Legs',
        secondaryMuscles: ['Calves'],
        category: 'Lower Body',
        equipment: 'Machine',
        defaultSets: 4,
        defaultReps: 15,
        defaultWeight: 50.0,
      ),

      // ── ABS & CORE ──
      Exercise(
        id: 'ex_hanging_leg_raise',
        name: 'Hanging Leg / Knee Raises',
        targetMuscle: 'Abs',
        secondaryMuscles: ['Hip Flexors'],
        category: 'Core',
        equipment: 'Bodyweight',
        defaultSets: 3,
        defaultReps: 12,
        defaultWeight: 0.0,
      ),
      Exercise(
        id: 'ex_cable_crunch',
        name: 'Cable Kneeling Crunches',
        targetMuscle: 'Abs',
        secondaryMuscles: [],
        category: 'Core',
        equipment: 'Cable',
        defaultSets: 3,
        defaultReps: 15,
        defaultWeight: 35.0,
      ),
      Exercise(
        id: 'ex_plank',
        name: 'Plank Hold (60s)',
        targetMuscle: 'Abs',
        secondaryMuscles: ['Shoulders', 'Lower Back'],
        category: 'Core',
        equipment: 'Bodyweight',
        defaultSets: 3,
        defaultReps: 60,
        defaultWeight: 0.0,
      ),
      Exercise(
        id: 'ex_ab_wheel',
        name: 'Ab Wheel Rollouts',
        targetMuscle: 'Abs',
        secondaryMuscles: ['Lats'],
        category: 'Core',
        equipment: 'Bodyweight',
        defaultSets: 3,
        defaultReps: 10,
        defaultWeight: 0.0,
      ),
      Exercise(
        id: 'ex_russian_twist',
        name: 'Russian Twists',
        targetMuscle: 'Abs',
        secondaryMuscles: ['Obliques'],
        category: 'Core',
        equipment: 'Dumbbell',
        defaultSets: 3,
        defaultReps: 20,
        defaultWeight: 8.0,
      ),

      // ── CARDIO ──
      Exercise(
        id: 'ex_incline_treadmill',
        name: 'Incline Treadmill Walk',
        targetMuscle: 'Cardio',
        secondaryMuscles: ['Calves', 'Heart'],
        category: 'Cardio',
        equipment: 'Machine',
        defaultSets: 1,
        defaultReps: 20,
        defaultWeight: 0.0,
      ),
      Exercise(
        id: 'ex_stairmaster',
        name: 'Stairmaster Intervals',
        targetMuscle: 'Cardio',
        secondaryMuscles: ['Quads', 'Glutes'],
        category: 'Cardio',
        equipment: 'Machine',
        defaultSets: 1,
        defaultReps: 15,
        defaultWeight: 0.0,
      ),
      Exercise(
        id: 'ex_jump_rope',
        name: 'Jump Rope Conditioning',
        targetMuscle: 'Cardio',
        secondaryMuscles: ['Calves'],
        category: 'Cardio',
        equipment: 'Bodyweight',
        defaultSets: 3,
        defaultReps: 100,
        defaultWeight: 0.0,
      ),
    ];
  }

  // ── Default Preset Routines ──────────────────────────────────────────────

  List<WorkoutRoutine> _buildDefaultPresetRoutines() {
    final catalog = _buildStaticExerciseCatalog();

    Exercise ex(String id) =>
        catalog.firstWhere((e) => e.id == id, orElse: () => catalog.first);

    // 1. Push Pull Legs (PPL) - Active by default
    final pplRoutine = WorkoutRoutine(
      id: 'routine_ppl',
      name: 'Push Pull Legs (PPL)',
      description: 'The golden standard 6-day split for muscle hypertrophy & strength',
      isActive: true,
      isCustom: false,
      days: [
        RoutineDay(
          dayName: 'Monday',
          dayShort: 'Mon',
          muscles: ['Chest', 'Shoulders', 'Triceps'],
          isRestDay: false,
          exercises: [
            WorkoutExerciseItem.create(exercise: ex('ex_bench_press'), targetSets: 4, targetReps: 8, targetWeight: 60.0),
            WorkoutExerciseItem.create(exercise: ex('ex_incline_db_press'), targetSets: 3, targetReps: 10, targetWeight: 22.0),
            WorkoutExerciseItem.create(exercise: ex('ex_overhead_press'), targetSets: 3, targetReps: 8, targetWeight: 40.0),
            WorkoutExerciseItem.create(exercise: ex('ex_db_lateral_raise'), targetSets: 4, targetReps: 12, targetWeight: 10.0),
            WorkoutExerciseItem.create(exercise: ex('ex_tricep_pushdown'), targetSets: 3, targetReps: 12, targetWeight: 25.0),
          ],
        ),
        RoutineDay(
          dayName: 'Tuesday',
          dayShort: 'Tue',
          muscles: ['Back', 'Biceps'],
          isRestDay: false,
          exercises: [
            WorkoutExerciseItem.create(exercise: ex('ex_deadlift'), targetSets: 4, targetReps: 5, targetWeight: 100.0),
            WorkoutExerciseItem.create(exercise: ex('ex_lat_pulldown'), targetSets: 3, targetReps: 10, targetWeight: 55.0),
            WorkoutExerciseItem.create(exercise: ex('ex_seated_cable_row'), targetSets: 3, targetReps: 10, targetWeight: 50.0),
            WorkoutExerciseItem.create(exercise: ex('ex_face_pulls'), targetSets: 3, targetReps: 15, targetWeight: 17.5),
            WorkoutExerciseItem.create(exercise: ex('ex_barbell_curl'), targetSets: 3, targetReps: 10, targetWeight: 25.0),
            WorkoutExerciseItem.create(exercise: ex('ex_hammer_curl'), targetSets: 3, targetReps: 12, targetWeight: 14.0),
          ],
        ),
        RoutineDay(
          dayName: 'Wednesday',
          dayShort: 'Wed',
          muscles: ['Legs', 'Abs'],
          isRestDay: false,
          exercises: [
            WorkoutExerciseItem.create(exercise: ex('ex_squat'), targetSets: 4, targetReps: 8, targetWeight: 80.0),
            WorkoutExerciseItem.create(exercise: ex('ex_leg_press'), targetSets: 3, targetReps: 12, targetWeight: 140.0),
            WorkoutExerciseItem.create(exercise: ex('ex_rdl'), targetSets: 3, targetReps: 10, targetWeight: 60.0),
            WorkoutExerciseItem.create(exercise: ex('ex_leg_extension'), targetSets: 3, targetReps: 12, targetWeight: 45.0),
            WorkoutExerciseItem.create(exercise: ex('ex_calf_raise'), targetSets: 4, targetReps: 15, targetWeight: 50.0),
            WorkoutExerciseItem.create(exercise: ex('ex_hanging_leg_raise'), targetSets: 3, targetReps: 12, targetWeight: 0.0),
          ],
        ),
        RoutineDay(
          dayName: 'Thursday',
          dayShort: 'Thu',
          muscles: ['Chest', 'Triceps'],
          isRestDay: false,
          exercises: [
            WorkoutExerciseItem.create(exercise: ex('ex_incline_db_press'), targetSets: 3, targetReps: 10, targetWeight: 24.0),
            WorkoutExerciseItem.create(exercise: ex('ex_cable_flyes'), targetSets: 3, targetReps: 12, targetWeight: 12.5),
            WorkoutExerciseItem.create(exercise: ex('ex_cable_lateral_raise'), targetSets: 3, targetReps: 15, targetWeight: 7.5),
            WorkoutExerciseItem.create(exercise: ex('ex_skull_crushers'), targetSets: 3, targetReps: 10, targetWeight: 25.0),
            WorkoutExerciseItem.create(exercise: ex('ex_overhead_cable_tricep'), targetSets: 3, targetReps: 12, targetWeight: 20.0),
          ],
        ),
        RoutineDay(
          dayName: 'Friday',
          dayShort: 'Fri',
          muscles: ['Back', 'Biceps'],
          isRestDay: false,
          exercises: [
            WorkoutExerciseItem.create(exercise: ex('ex_pull_ups'), targetSets: 3, targetReps: 8, targetWeight: 0.0),
            WorkoutExerciseItem.create(exercise: ex('ex_barbell_row'), targetSets: 3, targetReps: 8, targetWeight: 50.0),
            WorkoutExerciseItem.create(exercise: ex('ex_one_arm_db_row'), targetSets: 3, targetReps: 10, targetWeight: 24.0),
            WorkoutExerciseItem.create(exercise: ex('ex_incline_db_curl'), targetSets: 3, targetReps: 10, targetWeight: 12.0),
            WorkoutExerciseItem.create(exercise: ex('ex_cable_rope_curl'), targetSets: 3, targetReps: 12, targetWeight: 20.0),
          ],
        ),
        RoutineDay(
          dayName: 'Saturday',
          dayShort: 'Sat',
          muscles: ['Legs', 'Abs'],
          isRestDay: false,
          exercises: [
            WorkoutExerciseItem.create(exercise: ex('ex_leg_press'), targetSets: 3, targetReps: 10, targetWeight: 150.0),
            WorkoutExerciseItem.create(exercise: ex('ex_bulgarian_split_squat'), targetSets: 3, targetReps: 10, targetWeight: 14.0),
            WorkoutExerciseItem.create(exercise: ex('ex_leg_curl'), targetSets: 3, targetReps: 12, targetWeight: 40.0),
            WorkoutExerciseItem.create(exercise: ex('ex_hip_thrust'), targetSets: 3, targetReps: 10, targetWeight: 70.0),
            WorkoutExerciseItem.create(exercise: ex('ex_cable_crunch'), targetSets: 3, targetReps: 15, targetWeight: 35.0),
          ],
        ),
        const RoutineDay(
          dayName: 'Sunday',
          dayShort: 'Sun',
          muscles: ['Rest & Recovery'],
          isRestDay: true,
          exercises: [],
        ),
      ],
    );

    // 2. Bro Split (Classic 5-Day Bodybuilding Split)
    final broSplit = WorkoutRoutine(
      id: 'routine_bro_split',
      name: 'Bro Split (Muscle Groups)',
      description: 'Dedicated single muscle group per day for focused volume & pump',
      isActive: false,
      isCustom: false,
      days: [
        RoutineDay(
          dayName: 'Monday',
          dayShort: 'Mon',
          muscles: ['Chest'],
          isRestDay: false,
          exercises: [
            WorkoutExerciseItem.create(exercise: ex('ex_bench_press'), targetSets: 4, targetReps: 8, targetWeight: 65.0),
            WorkoutExerciseItem.create(exercise: ex('ex_incline_db_press'), targetSets: 3, targetReps: 10, targetWeight: 22.0),
            WorkoutExerciseItem.create(exercise: ex('ex_pec_deck_fly'), targetSets: 3, targetReps: 12, targetWeight: 45.0),
            WorkoutExerciseItem.create(exercise: ex('ex_cable_flyes'), targetSets: 3, targetReps: 15, targetWeight: 12.5),
            WorkoutExerciseItem.create(exercise: ex('ex_push_ups'), targetSets: 3, targetReps: 15, targetWeight: 0.0),
          ],
        ),
        RoutineDay(
          dayName: 'Tuesday',
          dayShort: 'Tue',
          muscles: ['Back'],
          isRestDay: false,
          exercises: [
            WorkoutExerciseItem.create(exercise: ex('ex_deadlift'), targetSets: 4, targetReps: 6, targetWeight: 100.0),
            WorkoutExerciseItem.create(exercise: ex('ex_pull_ups'), targetSets: 3, targetReps: 8, targetWeight: 0.0),
            WorkoutExerciseItem.create(exercise: ex('ex_barbell_row'), targetSets: 3, targetReps: 8, targetWeight: 50.0),
            WorkoutExerciseItem.create(exercise: ex('ex_lat_pulldown'), targetSets: 3, targetReps: 10, targetWeight: 55.0),
            WorkoutExerciseItem.create(exercise: ex('ex_seated_cable_row'), targetSets: 3, targetReps: 12, targetWeight: 45.0),
          ],
        ),
        RoutineDay(
          dayName: 'Wednesday',
          dayShort: 'Wed',
          muscles: ['Shoulders'],
          isRestDay: false,
          exercises: [
            WorkoutExerciseItem.create(exercise: ex('ex_overhead_press'), targetSets: 4, targetReps: 8, targetWeight: 40.0),
            WorkoutExerciseItem.create(exercise: ex('ex_db_lateral_raise'), targetSets: 4, targetReps: 12, targetWeight: 10.0),
            WorkoutExerciseItem.create(exercise: ex('ex_arnold_press'), targetSets: 3, targetReps: 10, targetWeight: 16.0),
            WorkoutExerciseItem.create(exercise: ex('ex_rear_delt_fly'), targetSets: 3, targetReps: 15, targetWeight: 35.0),
            WorkoutExerciseItem.create(exercise: ex('ex_shrugs'), targetSets: 3, targetReps: 12, targetWeight: 60.0),
          ],
        ),
        RoutineDay(
          dayName: 'Thursday',
          dayShort: 'Thu',
          muscles: ['Biceps', 'Triceps'],
          isRestDay: false,
          exercises: [
            WorkoutExerciseItem.create(exercise: ex('ex_barbell_curl'), targetSets: 3, targetReps: 10, targetWeight: 25.0),
            WorkoutExerciseItem.create(exercise: ex('ex_tricep_pushdown'), targetSets: 3, targetReps: 12, targetWeight: 25.0),
            WorkoutExerciseItem.create(exercise: ex('ex_hammer_curl'), targetSets: 3, targetReps: 12, targetWeight: 14.0),
            WorkoutExerciseItem.create(exercise: ex('ex_skull_crushers'), targetSets: 3, targetReps: 10, targetWeight: 25.0),
            WorkoutExerciseItem.create(exercise: ex('ex_preacher_curl'), targetSets: 3, targetReps: 10, targetWeight: 20.0),
            WorkoutExerciseItem.create(exercise: ex('ex_bench_dips'), targetSets: 3, targetReps: 12, targetWeight: 0.0),
          ],
        ),
        RoutineDay(
          dayName: 'Friday',
          dayShort: 'Fri',
          muscles: ['Legs'],
          isRestDay: false,
          exercises: [
            WorkoutExerciseItem.create(exercise: ex('ex_squat'), targetSets: 4, targetReps: 8, targetWeight: 80.0),
            WorkoutExerciseItem.create(exercise: ex('ex_leg_press'), targetSets: 3, targetReps: 12, targetWeight: 140.0),
            WorkoutExerciseItem.create(exercise: ex('ex_rdl'), targetSets: 3, targetReps: 10, targetWeight: 60.0),
            WorkoutExerciseItem.create(exercise: ex('ex_leg_extension'), targetSets: 3, targetReps: 12, targetWeight: 45.0),
            WorkoutExerciseItem.create(exercise: ex('ex_calf_raise'), targetSets: 4, targetReps: 15, targetWeight: 50.0),
          ],
        ),
        RoutineDay(
          dayName: 'Saturday',
          dayShort: 'Sat',
          muscles: ['Abs', 'Cardio'],
          isRestDay: false,
          exercises: [
            WorkoutExerciseItem.create(exercise: ex('ex_hanging_leg_raise'), targetSets: 3, targetReps: 12, targetWeight: 0.0),
            WorkoutExerciseItem.create(exercise: ex('ex_cable_crunch'), targetSets: 3, targetReps: 15, targetWeight: 35.0),
            WorkoutExerciseItem.create(exercise: ex('ex_plank'), targetSets: 3, targetReps: 60, targetWeight: 0.0),
            WorkoutExerciseItem.create(exercise: ex('ex_incline_treadmill'), targetSets: 1, targetReps: 20, targetWeight: 0.0),
          ],
        ),
        const RoutineDay(
          dayName: 'Sunday',
          dayShort: 'Sun',
          muscles: ['Rest & Recovery'],
          isRestDay: true,
          exercises: [],
        ),
      ],
    );

    // 3. Upper / Lower 4-Day Split
    final upperLower = WorkoutRoutine(
      id: 'routine_upper_lower',
      name: 'Upper / Lower (4-Day)',
      description: 'Balanced frequency & recovery ideal for busy lifters & athletes',
      isActive: false,
      isCustom: false,
      days: [
        RoutineDay(
          dayName: 'Monday',
          dayShort: 'Mon',
          muscles: ['Upper Body'],
          isRestDay: false,
          exercises: [
            WorkoutExerciseItem.create(exercise: ex('ex_bench_press'), targetSets: 4, targetReps: 6, targetWeight: 70.0),
            WorkoutExerciseItem.create(exercise: ex('ex_barbell_row'), targetSets: 3, targetReps: 8, targetWeight: 55.0),
            WorkoutExerciseItem.create(exercise: ex('ex_overhead_press'), targetSets: 3, targetReps: 8, targetWeight: 40.0),
            WorkoutExerciseItem.create(exercise: ex('ex_lat_pulldown'), targetSets: 3, targetReps: 10, targetWeight: 55.0),
            WorkoutExerciseItem.create(exercise: ex('ex_tricep_pushdown'), targetSets: 3, targetReps: 12, targetWeight: 25.0),
          ],
        ),
        RoutineDay(
          dayName: 'Tuesday',
          dayShort: 'Tue',
          muscles: ['Lower Body'],
          isRestDay: false,
          exercises: [
            WorkoutExerciseItem.create(exercise: ex('ex_squat'), targetSets: 4, targetReps: 6, targetWeight: 85.0),
            WorkoutExerciseItem.create(exercise: ex('ex_rdl'), targetSets: 3, targetReps: 8, targetWeight: 65.0),
            WorkoutExerciseItem.create(exercise: ex('ex_leg_press'), targetSets: 3, targetReps: 10, targetWeight: 140.0),
            WorkoutExerciseItem.create(exercise: ex('ex_calf_raise'), targetSets: 4, targetReps: 12, targetWeight: 50.0),
            WorkoutExerciseItem.create(exercise: ex('ex_hanging_leg_raise'), targetSets: 3, targetReps: 12, targetWeight: 0.0),
          ],
        ),
        const RoutineDay(
          dayName: 'Wednesday',
          dayShort: 'Wed',
          muscles: ['Rest & Recovery'],
          isRestDay: true,
          exercises: [],
        ),
        RoutineDay(
          dayName: 'Thursday',
          dayShort: 'Thu',
          muscles: ['Upper Body'],
          isRestDay: false,
          exercises: [
            WorkoutExerciseItem.create(exercise: ex('ex_incline_db_press'), targetSets: 3, targetReps: 10, targetWeight: 24.0),
            WorkoutExerciseItem.create(exercise: ex('ex_pull_ups'), targetSets: 3, targetReps: 8, targetWeight: 0.0),
            WorkoutExerciseItem.create(exercise: ex('ex_db_lateral_raise'), targetSets: 4, targetReps: 12, targetWeight: 10.0),
            WorkoutExerciseItem.create(exercise: ex('ex_seated_cable_row'), targetSets: 3, targetReps: 10, targetWeight: 50.0),
            WorkoutExerciseItem.create(exercise: ex('ex_barbell_curl'), targetSets: 3, targetReps: 10, targetWeight: 25.0),
          ],
        ),
        RoutineDay(
          dayName: 'Friday',
          dayShort: 'Fri',
          muscles: ['Lower Body'],
          isRestDay: false,
          exercises: [
            WorkoutExerciseItem.create(exercise: ex('ex_deadlift'), targetSets: 3, targetReps: 5, targetWeight: 110.0),
            WorkoutExerciseItem.create(exercise: ex('ex_bulgarian_split_squat'), targetSets: 3, targetReps: 10, targetWeight: 14.0),
            WorkoutExerciseItem.create(exercise: ex('ex_leg_extension'), targetSets: 3, targetReps: 12, targetWeight: 45.0),
            WorkoutExerciseItem.create(exercise: ex('ex_leg_curl'), targetSets: 3, targetReps: 12, targetWeight: 40.0),
            WorkoutExerciseItem.create(exercise: ex('ex_cable_crunch'), targetSets: 3, targetReps: 15, targetWeight: 35.0),
          ],
        ),
        const RoutineDay(
          dayName: 'Saturday',
          dayShort: 'Sat',
          muscles: ['Rest & Recovery'],
          isRestDay: true,
          exercises: [],
        ),
        const RoutineDay(
          dayName: 'Sunday',
          dayShort: 'Sun',
          muscles: ['Rest & Recovery'],
          isRestDay: true,
          exercises: [],
        ),
      ],
    );

    return [pplRoutine, broSplit, upperLower];
  }
}
