import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:velto/features/workout/models/exercise.dart';
import 'package:velto/features/workout/models/routine_day.dart';
import 'package:velto/features/workout/models/workout_routine.dart';
import 'package:velto/features/workout/services/workout_service.dart';

class WorkoutController extends GetxController {
  final WorkoutService _workoutService = WorkoutService();

  final Rx<WorkoutRoutine?> activeRoutine = Rx<WorkoutRoutine?>(null);
  final RxList<WorkoutRoutine> allRoutines = <WorkoutRoutine>[].obs;
  final RxInt selectedDayIndex = 0.obs;
  final RxBool isLoading = false.obs;

  /// Day index based on current system day (Monday = 0, Tuesday = 1, ... Sunday = 6)
  int get todayDayIndex {
    final weekday = DateTime.now().weekday; // 1 = Mon, 7 = Sun
    return (weekday - 1).clamp(0, 6);
  }

  RoutineDay? get selectedDay {
    final routine = activeRoutine.value;
    if (routine == null || routine.days.isEmpty) return null;
    if (selectedDayIndex.value < 0 || selectedDayIndex.value >= routine.days.length) {
      return routine.days.first;
    }
    return routine.days[selectedDayIndex.value];
  }

  @override
  void onInit() {
    super.onInit();
    selectedDayIndex.value = todayDayIndex;
    loadRoutines();
  }

  Future<void> loadRoutines() async {
    isLoading.value = true;
    try {
      final routines = await _workoutService.getRoutines();
      allRoutines.assignAll(routines);
      activeRoutine.value = await _workoutService.getActiveRoutine();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> switchActiveRoutine(String routineId) async {
    await _workoutService.setActiveRoutine(routineId);
    await loadRoutines();
    Get.snackbar(
      'Routine Switched',
      'Active plan is now "${activeRoutine.value?.name ?? ""}"',
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    );
  }

  Future<bool> deleteRoutine(String routineId) async {
    if (allRoutines.length <= 1) {
      Get.snackbar(
        'Cannot Delete Schedule',
        'You must have at least one active workout schedule.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      );
      return false;
    }

    final deleted = await _workoutService.deleteRoutine(routineId);
    if (deleted) {
      await loadRoutines();
      if (!Get.testMode) {
        Get.snackbar(
          'Schedule Deleted',
          'Workout schedule has been removed.',
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        );
      }
      return true;
    }
    return false;
  }

  void selectDay(int index) {
    if (index >= 0 && index < 7) {
      selectedDayIndex.value = index;
      _hasUserToggledExpansion = false;
      expandedExerciseIds.clear();
    }
  }

  // ── Collapsible / Expandable State ─────────────────────────────────────────

  final RxSet<String> expandedExerciseIds = <String>{}.obs;
  bool _hasUserToggledExpansion = false;

  bool isExerciseExpanded(String id, int index) {
    if (expandedExerciseIds.contains(id)) return true;
    // By default, keep the first exercise open so user sees workout details,
    // while remaining exercises are cleanly collapsed.
    if (!_hasUserToggledExpansion && index == 0) return true;
    return false;
  }

  void toggleExerciseExpanded(String id, int index) {
    if (!_hasUserToggledExpansion) {
      _hasUserToggledExpansion = true;
      if (index == 0) {
        expandedExerciseIds.clear();
        return;
      } else {
        final day = selectedDay;
        if (day != null && day.exercises.isNotEmpty) {
          expandedExerciseIds.add(day.exercises.first.id);
        }
      }
    }

    if (expandedExerciseIds.contains(id)) {
      expandedExerciseIds.remove(id);
    } else {
      expandedExerciseIds.add(id);
    }
  }

  bool areAllExpanded(RoutineDay day) {
    if (day.exercises.isEmpty) return false;
    for (int i = 0; i < day.exercises.length; i++) {
      if (!isExerciseExpanded(day.exercises[i].id, i)) return false;
    }
    return true;
  }

  void expandAll(RoutineDay day) {
    _hasUserToggledExpansion = true;
    expandedExerciseIds.assignAll(day.exercises.map((e) => e.id));
  }

  void collapseAll() {
    _hasUserToggledExpansion = true;
    expandedExerciseIds.clear();
  }

  // ── Exercise Quick Increments & Logging ──────────────────────────────────

  Future<void> increaseWeight(WorkoutExerciseItem item, [double delta = 2.5]) async {
    final newWeight = item.targetWeight + delta;
    await _updateItem(item.id, weight: newWeight);
  }

  Future<void> decreaseWeight(WorkoutExerciseItem item, [double delta = 2.5]) async {
    final newWeight = (item.targetWeight - delta).clamp(0.0, 500.0);
    await _updateItem(item.id, weight: newWeight);
  }

  Future<void> increaseReps(WorkoutExerciseItem item, [int delta = 1]) async {
    final newReps = item.targetReps + delta;
    await _updateItem(item.id, reps: newReps);
  }

  Future<void> decreaseReps(WorkoutExerciseItem item, [int delta = 1]) async {
    final newReps = (item.targetReps - delta).clamp(1, 100);
    await _updateItem(item.id, reps: newReps);
  }

  Future<void> increaseSets(WorkoutExerciseItem item) async {
    final newSets = item.targetSets + 1;
    await _updateItem(item.id, sets: newSets);
  }

  Future<void> decreaseSets(WorkoutExerciseItem item) async {
    if (item.targetSets <= 1) return;
    final newSets = item.targetSets - 1;
    await _updateItem(item.id, sets: newSets);
  }

  // ── Individual Set-Level Updates ─────────────────────────────────────────

  Future<void> updateSetWeight(WorkoutExerciseItem item, int setIndex, double delta) async {
    if (setIndex >= 0 && setIndex < item.sets.length) {
      final currentWeight = item.sets[setIndex].weight;
      final newWeight = (currentWeight + delta).clamp(0.0, 500.0);
      await _updateSpecificSet(item.id, setIndex, weight: newWeight);
    }
  }

  Future<void> updateSetReps(WorkoutExerciseItem item, int setIndex, int delta) async {
    if (setIndex >= 0 && setIndex < item.sets.length) {
      final currentReps = item.sets[setIndex].reps;
      final newReps = (currentReps + delta).clamp(1, 100);
      await _updateSpecificSet(item.id, setIndex, reps: newReps);
    }
  }

  Future<void> addSet(WorkoutExerciseItem item) async {
    final routine = activeRoutine.value;
    final day = selectedDay;
    if (routine == null || day == null) return;

    final lastSet = item.sets.isNotEmpty ? item.sets.last : null;
    final weight = lastSet?.weight ?? item.targetWeight;
    final reps = lastSet?.reps ?? item.targetReps;

    await _workoutService.addSetToExercise(
      routineId: routine.id,
      dayName: day.dayName,
      exerciseItemId: item.id,
      weight: weight,
      reps: reps,
    );
    await _refreshActiveRoutine();
  }

  Future<void> removeSet(WorkoutExerciseItem item, int setIndex) async {
    if (item.sets.length <= 1) return;
    final routine = activeRoutine.value;
    final day = selectedDay;
    if (routine == null || day == null) return;

    await _workoutService.removeSetFromExercise(
      routineId: routine.id,
      dayName: day.dayName,
      exerciseItemId: item.id,
      setIndex: setIndex,
    );
    await _refreshActiveRoutine();
  }

  Future<void> _updateSpecificSet(
    String exerciseItemId,
    int setIndex, {
    double? weight,
    int? reps,
    bool? isCompleted,
  }) async {
    final routine = activeRoutine.value;
    final day = selectedDay;
    if (routine == null || day == null) return;

    await _workoutService.updateSpecificSet(
      routineId: routine.id,
      dayName: day.dayName,
      exerciseItemId: exerciseItemId,
      setIndex: setIndex,
      weight: weight,
      reps: reps,
      isCompleted: isCompleted,
    );
    await _refreshActiveRoutine();
  }

  Future<void> toggleSetCompletion(WorkoutExerciseItem item, int setIndex) async {
    final routine = activeRoutine.value;
    final day = selectedDay;
    if (routine == null || day == null) return;

    await _workoutService.updateExerciseInRoutineDay(
      routineId: routine.id,
      dayName: day.dayName,
      exerciseItemId: item.id,
      completedSetIndex: setIndex,
    );
    await _refreshActiveRoutine();
  }

  Future<void> addExerciseToCurrentDay(
    Exercise exercise, {
    int sets = 3,
    int reps = 10,
    double weight = 20.0,
  }) async {
    final routine = activeRoutine.value;
    final day = selectedDay;
    if (routine == null || day == null) return;

    final newItem = WorkoutExerciseItem.create(
      exercise: exercise,
      targetSets: sets,
      targetReps: reps,
      targetWeight: weight,
    );

    final updatedExercises = List<WorkoutExerciseItem>.from(day.exercises)..add(newItem);
    final updatedDay = day.copyWith(
      exercises: updatedExercises,
      isRestDay: false,
    );

    final updatedDays = List<RoutineDay>.from(routine.days);
    updatedDays[selectedDayIndex.value] = updatedDay;

    final updatedRoutine = routine.copyWith(days: updatedDays);
    _hasUserToggledExpansion = true;
    expandedExerciseIds.add(newItem.id);
    await _workoutService.saveRoutine(updatedRoutine, setActive: true);
    await _refreshActiveRoutine();
  }

  Future<void> removeExerciseFromCurrentDay(String exerciseItemId) async {
    final routine = activeRoutine.value;
    final day = selectedDay;
    if (routine == null || day == null) return;

    final updatedExercises = List<WorkoutExerciseItem>.from(day.exercises)
      ..removeWhere((e) => e.id == exerciseItemId);

    final updatedDay = day.copyWith(exercises: updatedExercises);
    final updatedDays = List<RoutineDay>.from(routine.days);
    updatedDays[selectedDayIndex.value] = updatedDay;

    final updatedRoutine = routine.copyWith(days: updatedDays);
    await _workoutService.saveRoutine(updatedRoutine, setActive: true);
    await _refreshActiveRoutine();
  }

  Future<void> _updateItem(
    String exerciseItemId, {
    int? sets,
    int? reps,
    double? weight,
  }) async {
    final routine = activeRoutine.value;
    final day = selectedDay;
    if (routine == null || day == null) return;

    await _workoutService.updateExerciseInRoutineDay(
      routineId: routine.id,
      dayName: day.dayName,
      exerciseItemId: exerciseItemId,
      sets: sets,
      reps: reps,
      weight: weight,
    );
    await _refreshActiveRoutine();
  }

  Future<void> _refreshActiveRoutine() async {
    final updated = await _workoutService.getActiveRoutine();
    activeRoutine.value = updated;
  }
}
