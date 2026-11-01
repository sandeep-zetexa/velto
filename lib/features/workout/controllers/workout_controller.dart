import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:velto/core/services/local_storage_service.dart';
import 'package:velto/features/workout/models/daily_workout_log.dart';
import 'package:velto/features/workout/models/exercise.dart';
import 'package:velto/features/workout/models/routine_day.dart';
import 'package:velto/features/workout/models/workout_routine.dart';
import 'package:velto/features/workout/services/workout_service.dart';

class WorkoutController extends GetxController {
  final WorkoutService _workoutService = WorkoutService();

  final Rx<WorkoutRoutine?> activeRoutine = Rx<WorkoutRoutine?>(null);
  final RxList<WorkoutRoutine> allRoutines = <WorkoutRoutine>[].obs;
  final RxInt selectedDayIndex = 0.obs;
  final Rx<DateTime> selectedDate = Rx<DateTime>(DateTime.now());
  final Rx<DailyWorkoutLog?> currentDailyLog = Rx<DailyWorkoutLog?>(null);
  final RxBool isLoading = false.obs;

  /// Day index based on current system day (Monday = 0, Tuesday = 1, ... Sunday = 6)
  int get todayDayIndex {
    final weekday = DateTime.now().weekday; // 1 = Mon, 7 = Sun
    return (weekday - 1).clamp(0, 6);
  }

  String get selectedDateKey => LocalStorageService.formatDateKey(selectedDate.value);

  /// Shows the plan performed on this specific date (or the active plan for today)
  String get effectiveRoutineName {
    if (currentDailyLog.value != null && currentDailyLog.value!.routineName.isNotEmpty) {
      return currentDailyLog.value!.routineName;
    }
    return activeRoutine.value?.name ?? 'Workout Routine';
  }

  /// Adapted day model containing exercises and ticks for the currently selected date.
  RoutineDay? get selectedDay {
    final routine = activeRoutine.value;
    if (routine == null || routine.days.isEmpty) return null;
    final routineDay = (selectedDayIndex.value >= 0 && selectedDayIndex.value < routine.days.length)
        ? routine.days[selectedDayIndex.value]
        : routine.days.first;

    if (currentDailyLog.value != null &&
        currentDailyLog.value!.dayName.toLowerCase() == routineDay.dayName.toLowerCase()) {
      final log = currentDailyLog.value!;
      return RoutineDay(
        dayName: log.dayName,
        dayShort: log.dayName.length >= 3 ? log.dayName.substring(0, 3) : log.dayName,
        muscles: log.muscles,
        isRestDay: log.isRestDay,
        exercises: log.exercises,
      );
    }
    return routineDay;
  }

  @override
  void onInit() {
    super.onInit();
    selectedDayIndex.value = todayDayIndex;
    selectedDate.value = DateTime.now();
    loadRoutines();
  }

  Future<void> loadRoutines() async {
    isLoading.value = true;
    try {
      final routines = await _workoutService.getRoutines();
      allRoutines.assignAll(routines);
      activeRoutine.value = await _workoutService.getActiveRoutine();
      await loadDailyLogForDate(selectedDate.value);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadDailyLogForDate(DateTime date) async {
    final dateKey = LocalStorageService.formatDateKey(date);
    final log = await _workoutService.getDailyLog(dateKey);
    if (log != null) {
      currentDailyLog.value = log;
    } else {
      // If no log yet recorded on this date, initialize from active routine
      final routine = activeRoutine.value;
      if (routine != null && routine.days.isNotEmpty) {
        final day = routine.days[selectedDayIndex.value.clamp(0, routine.days.length - 1)];
        currentDailyLog.value = DailyWorkoutLog.fromRoutineDay(
          date: dateKey,
          routineId: routine.id,
          routineName: routine.name,
          day: day,
        );
      } else {
        currentDailyLog.value = null;
      }
    }
  }

  Future<void> switchActiveRoutine(String routineId) async {
    await _workoutService.setActiveRoutine(routineId);
    await loadRoutines();

    // If viewing today, re-initialize today's log to the newly chosen active routine
    final isToday = selectedDayIndex.value == todayDayIndex;
    if (isToday) {
      final routine = activeRoutine.value;
      if (routine != null && routine.days.isNotEmpty) {
        final day = routine.days[selectedDayIndex.value.clamp(0, routine.days.length - 1)];
        final newLog = DailyWorkoutLog.fromRoutineDay(
          date: selectedDateKey,
          routineId: routine.id,
          routineName: routine.name,
          day: day,
        );
        currentDailyLog.value = newLog;
        await _workoutService.saveDailyLog(newLog);
      }
    }

    if (!Get.testMode && Get.context != null) {
      Get.snackbar(
        'Routine Switched',
        'Active plan is now "${activeRoutine.value?.name ?? ""}"',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      );
    }
  }

  Future<bool> deleteRoutine(String routineId) async {
    final deleted = await _workoutService.deleteRoutine(routineId);
    if (deleted) {
      await loadRoutines();
      if (!Get.testMode && Get.context != null) {
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

  Future<void> selectDay(int index) async {
    if (index >= 0 && index < 7) {
      selectedDayIndex.value = index;
      _hasUserToggledExpansion = false;
      expandedExerciseIds.clear();

      final now = DateTime.now();
      final currentWeekday = now.weekday; // 1 = Mon ... 7 = Sun
      final monday = now.subtract(Duration(days: currentWeekday - 1));
      final dateForIndex = monday.add(Duration(days: index));
      selectedDate.value = dateForIndex;

      // Immediately synchronize currentDailyLog so synchronous assertions match
      final routine = activeRoutine.value;
      if (routine != null && routine.days.length > index) {
        final day = routine.days[index];
        currentDailyLog.value = DailyWorkoutLog.fromRoutineDay(
          date: LocalStorageService.formatDateKey(dateForIndex),
          routineId: routine.id,
          routineName: routine.name,
          day: day,
        );
      }

      await loadDailyLogForDate(dateForIndex);
    }
  }

  // ── Collapsible / Expandable State ─────────────────────────────────────────

  final RxSet<String> expandedExerciseIds = <String>{}.obs;
  bool _hasUserToggledExpansion = false;

  bool isExerciseExpanded(String id, int index) {
    if (expandedExerciseIds.contains(id)) return true;
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

  // ── Individual Set-Level Updates & Done/Not-Done Ticks ────────────────────

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
    if (day == null) return;

    final lastSet = item.sets.isNotEmpty ? item.sets.last : null;
    final weight = lastSet?.weight ?? item.targetWeight;
    final reps = lastSet?.reps ?? item.targetReps;

    final newSet = ExerciseSet(
      setNumber: item.sets.length + 1,
      weight: weight,
      reps: reps,
      isCompleted: false,
    );

    final updatedExercises = day.exercises.map((e) {
      if (e.id == item.id) {
        return e.copyWith(
          targetSets: e.targetSets + 1,
          sets: [...e.sets, newSet],
        );
      }
      return e;
    }).toList();

    await _saveCurrentDayExercises(updatedExercises);

    if (routine != null) {
      await _workoutService.addSetToExercise(
        routineId: routine.id,
        dayName: day.dayName,
        exerciseItemId: item.id,
        weight: weight,
        reps: reps,
      );
      await _refreshActiveRoutine();
    }
  }

  Future<void> removeSet(WorkoutExerciseItem item, int setIndex) async {
    if (item.sets.length <= 1) return;
    final routine = activeRoutine.value;
    final day = selectedDay;
    if (day == null) return;

    final updatedExercises = day.exercises.map((e) {
      if (e.id == item.id) {
        final sets = List<ExerciseSet>.from(e.sets);
        sets.removeAt(setIndex);
        final reindexed = List.generate(
          sets.length,
          (i) => sets[i].copyWith(setNumber: i + 1),
        );
        return e.copyWith(
          targetSets: reindexed.length,
          sets: reindexed,
        );
      }
      return e;
    }).toList();

    await _saveCurrentDayExercises(updatedExercises);

    if (routine != null) {
      await _workoutService.removeSetFromExercise(
        routineId: routine.id,
        dayName: day.dayName,
        exerciseItemId: item.id,
        setIndex: setIndex,
      );
      await _refreshActiveRoutine();
    }
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
    if (day == null) return;

    final updatedExercises = day.exercises.map((e) {
      if (e.id == exerciseItemId && setIndex >= 0 && setIndex < e.sets.length) {
        final sets = List<ExerciseSet>.from(e.sets);
        final cur = sets[setIndex];
        sets[setIndex] = cur.copyWith(
          weight: weight ?? cur.weight,
          reps: reps ?? cur.reps,
          isCompleted: isCompleted ?? cur.isCompleted,
        );
        return e.copyWith(sets: sets);
      }
      return e;
    }).toList();

    await _saveCurrentDayExercises(updatedExercises);

    if (routine != null) {
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
  }

  Future<void> toggleSetCompletion(WorkoutExerciseItem item, int setIndex) async {
    final day = selectedDay;
    if (day == null || setIndex < 0 || setIndex >= item.sets.length) return;
    final currentStatus = item.sets[setIndex].isCompleted;
    await _updateSpecificSet(
      item.id,
      setIndex,
      isCompleted: !currentStatus,
    );
  }

  Future<void> addExerciseToCurrentDay(
    Exercise exercise, {
    int sets = 3,
    int reps = 10,
    double weight = 20.0,
  }) async {
    final routine = activeRoutine.value;
    final day = selectedDay;
    if (day == null) return;

    final newItem = WorkoutExerciseItem.create(
      exercise: exercise,
      targetSets: sets,
      targetReps: reps,
      targetWeight: weight,
    );

    final updatedExercises = List<WorkoutExerciseItem>.from(day.exercises)..add(newItem);
    await _saveCurrentDayExercises(updatedExercises);

    _hasUserToggledExpansion = true;
    expandedExerciseIds.add(newItem.id);

    if (routine != null) {
      final updatedDay = day.copyWith(exercises: updatedExercises, isRestDay: false);
      final updatedDays = List<RoutineDay>.from(routine.days);
      final dayIdx = routine.days.indexWhere(
        (d) => d.dayName.toLowerCase() == day.dayName.toLowerCase(),
      );
      if (dayIdx >= 0) {
        updatedDays[dayIdx] = updatedDay;
      } else if (selectedDayIndex.value < updatedDays.length) {
        updatedDays[selectedDayIndex.value] = updatedDay;
      } else {
        updatedDays.add(updatedDay);
      }
      final updatedRoutine = routine.copyWith(days: updatedDays);
      await _workoutService.saveRoutine(updatedRoutine, setActive: true);
      await _refreshActiveRoutine();
    }
  }

  Future<void> removeExerciseFromCurrentDay(String exerciseItemId) async {
    final routine = activeRoutine.value;
    final day = selectedDay;
    if (day == null) return;

    final updatedExercises = List<WorkoutExerciseItem>.from(day.exercises)
      ..removeWhere((e) => e.id == exerciseItemId);
    await _saveCurrentDayExercises(updatedExercises);

    if (routine != null) {
      final updatedDay = day.copyWith(exercises: updatedExercises);
      final updatedDays = List<RoutineDay>.from(routine.days);
      final dayIdx = routine.days.indexWhere(
        (d) => d.dayName.toLowerCase() == day.dayName.toLowerCase(),
      );
      if (dayIdx >= 0) {
        updatedDays[dayIdx] = updatedDay;
      } else if (selectedDayIndex.value < updatedDays.length) {
        updatedDays[selectedDayIndex.value] = updatedDay;
      } else {
        updatedDays.add(updatedDay);
      }
      final updatedRoutine = routine.copyWith(days: updatedDays);
      await _workoutService.saveRoutine(updatedRoutine, setActive: true);
      await _refreshActiveRoutine();
    }
  }

  Future<void> _updateItem(
    String exerciseItemId, {
    int? sets,
    int? reps,
    double? weight,
  }) async {
    final routine = activeRoutine.value;
    final day = selectedDay;
    if (day == null) return;

    final updatedExercises = day.exercises.map((e) {
      if (e.id == exerciseItemId) {
        final targetSets = sets ?? e.targetSets;
        final targetReps = reps ?? e.targetReps;
        final targetWeight = weight ?? e.targetWeight;

        var setList = List<ExerciseSet>.from(e.sets);
        if (sets != null) {
          if (targetSets > setList.length) {
            for (int i = setList.length; i < targetSets; i++) {
              setList.add(ExerciseSet(
                setNumber: i + 1,
                reps: targetReps,
                weight: targetWeight,
              ));
            }
          } else if (targetSets < setList.length) {
            setList = setList.sublist(0, targetSets);
          }
        }
        return e.copyWith(
          targetSets: targetSets,
          targetReps: targetReps,
          targetWeight: targetWeight,
          sets: setList,
        );
      }
      return e;
    }).toList();

    await _saveCurrentDayExercises(updatedExercises);

    if (routine != null) {
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
  }

  Future<void> _saveCurrentDayExercises(List<WorkoutExerciseItem> exercises) async {
    final routine = activeRoutine.value;
    final day = selectedDay;
    if (day == null) return;

    final updatedLog = DailyWorkoutLog(
      date: selectedDateKey,
      routineId: routine?.id ?? '',
      routineName: routine?.name ?? 'Workout Routine',
      dayName: day.dayName,
      muscles: day.muscles,
      isRestDay: false,
      exercises: exercises,
    );

    currentDailyLog.value = updatedLog;
    await _workoutService.saveDailyLog(updatedLog);
  }

  Future<void> _refreshActiveRoutine() async {
    final updated = await _workoutService.getActiveRoutine();
    activeRoutine.value = updated;
  }
}
