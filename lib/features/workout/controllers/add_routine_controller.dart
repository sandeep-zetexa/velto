import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:velto/features/workout/controllers/workout_controller.dart';
import 'package:velto/features/workout/models/exercise.dart';
import 'package:velto/features/workout/models/routine_day.dart';
import 'package:velto/features/workout/models/workout_routine.dart';
import 'package:velto/features/workout/services/workout_service.dart';

class AddRoutineController extends GetxController {
  final WorkoutService _workoutService = WorkoutService();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  final RxInt selectedDayIndex = 0.obs;
  final RxList<RoutineDay> days = <RoutineDay>[].obs;

  WorkoutRoutine? editingRoutine;
  bool get isEditing => editingRoutine != null;

  final List<String> availableMuscles = const [
    'Chest',
    'Back',
    'Shoulders',
    'Biceps',
    'Triceps',
    'Legs',
    'Abs',
    'Cardio',
  ];

  RoutineDay get currentDay => days[selectedDayIndex.value];

  final RxList<Exercise> allExercises = <Exercise>[].obs;
  final RxString exerciseSearchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _loadExercises();
    final args = Get.arguments;
    if (args is WorkoutRoutine) {
      editingRoutine = args;
      nameController.text = args.name;
      descriptionController.text = args.description;
      days.assignAll(args.days.map((d) => d.copyWith()).toList());
    } else {
      // Start with clean, unconfigured days - user selects muscles and exercises
      days.assignAll(
        List.generate(7, (i) {
          final name = WorkoutService.routineDayNames[i];
          final short = WorkoutService.routineDayShorts[i];
          return RoutineDay(
            dayName: name,
            dayShort: short,
            muscles: const [],
            isRestDay: false,
            exercises: const [],
          );
        }),
      );
    }
  }

  Future<void> _loadExercises() async {
    final list = await _workoutService.getExercises();
    allExercises.assignAll(list);
  }

  @override
  void onClose() {
    nameController.dispose();
    descriptionController.dispose();
    super.onClose();
  }

  void selectDay(int index) {
    if (index >= 0 && index < days.length) {
      selectedDayIndex.value = index;
    }
  }

  void toggleRestDay(bool isRest) {
    final cur = currentDay;
    days[selectedDayIndex.value] = cur.copyWith(
      isRestDay: isRest,
      muscles: isRest ? const ['Rest'] : const [],
    );
  }

  void toggleMuscle(String muscle) {
    final cur = currentDay;
    final currentMuscles = List<String>.from(cur.muscles)
      ..removeWhere((m) => m.toLowerCase().contains('rest'));

    if (currentMuscles.contains(muscle)) {
      currentMuscles.remove(muscle);
    } else {
      currentMuscles.add(muscle);
    }

    days[selectedDayIndex.value] = cur.copyWith(
      muscles: currentMuscles,
      isRestDay: false,
    );
  }

  bool isExerciseAdded(Exercise exercise) {
    return currentDay.exercises.any(
      (item) => item.exercise.id == exercise.id || item.exercise.name == exercise.name,
    );
  }

  void toggleExercise(Exercise exercise) {
    final cur = currentDay;
    final index = cur.exercises.indexWhere(
      (item) => item.exercise.id == exercise.id || item.exercise.name == exercise.name,
    );

    if (index != -1) {
      removeExercise(index);
    } else {
      addExerciseToCurrentDay(exercise);
    }
  }

  List<Exercise> get filteredExercisesForCurrentDay {
    final cur = currentDay;
    final query = exerciseSearchQuery.value.trim().toLowerCase();

    List<Exercise> list;
    if (cur.muscles.isEmpty) {
      list = allExercises;
    } else {
      final selectedLower = cur.muscles.map((m) => m.toLowerCase()).toSet();
      list = allExercises.where((e) {
        final target = e.targetMuscle.toLowerCase();
        final isLegsMatch = selectedLower.contains('legs') &&
            (target == 'legs' ||
                target == 'quads' ||
                target == 'hamstrings' ||
                target == 'glutes' ||
                target == 'calves');
        final isTargetMatch = selectedLower.contains(target);
        final isSecondaryMatch = e.secondaryMuscles.any((sm) => selectedLower.contains(sm.toLowerCase()));

        return isLegsMatch || isTargetMatch || isSecondaryMatch;
      }).toList();
    }

    if (query.isNotEmpty) {
      list = list.where((e) {
        return e.name.toLowerCase().contains(query) ||
            e.targetMuscle.toLowerCase().contains(query) ||
            e.equipment.toLowerCase().contains(query);
      }).toList();
    }

    return list;
  }

  void addExerciseToCurrentDay(
    Exercise exercise, {
    int? targetSets,
    int? targetReps,
    double? targetWeight,
  }) {
    final cur = currentDay;
    final newItem = WorkoutExerciseItem.create(
      exercise: exercise,
      targetSets: targetSets,
      targetReps: targetReps,
      targetWeight: targetWeight,
    );

    final updatedExercises = List<WorkoutExerciseItem>.from(cur.exercises)..add(newItem);

    // Auto-add exercise muscle to current day if not present
    final updatedMuscles = List<String>.from(cur.muscles)
      ..removeWhere((m) => m.toLowerCase().contains('rest'));
    if (!updatedMuscles.contains(exercise.targetMuscle)) {
      updatedMuscles.add(exercise.targetMuscle);
    }

    days[selectedDayIndex.value] = cur.copyWith(
      exercises: updatedExercises,
      muscles: updatedMuscles,
      isRestDay: false,
    );
  }

  void removeExercise(int index) {
    final cur = currentDay;
    if (index >= 0 && index < cur.exercises.length) {
      final updated = List<WorkoutExerciseItem>.from(cur.exercises)..removeAt(index);
      days[selectedDayIndex.value] = cur.copyWith(exercises: updated);
    }
  }

  void updateExerciseSets(int index, int sets) {
    final cur = currentDay;
    if (index >= 0 && index < cur.exercises.length && sets >= 1) {
      final item = cur.exercises[index];
      final updated = cur.exercises[index].copyWith(
        targetSets: sets,
        sets: List.generate(
          sets,
          (i) => ExerciseSet(
            setNumber: i + 1,
            reps: item.targetReps,
            weight: item.targetWeight,
          ),
        ),
      );
      final list = List<WorkoutExerciseItem>.from(cur.exercises)..[index] = updated;
      days[selectedDayIndex.value] = cur.copyWith(exercises: list);
    }
  }

  void updateExerciseReps(int index, int reps) {
    final cur = currentDay;
    if (index >= 0 && index < cur.exercises.length && reps >= 1) {
      final item = cur.exercises[index];
      final updated = item.copyWith(
        targetReps: reps,
        sets: item.sets.map((s) => s.copyWith(reps: reps)).toList(),
      );
      final list = List<WorkoutExerciseItem>.from(cur.exercises)..[index] = updated;
      days[selectedDayIndex.value] = cur.copyWith(exercises: list);
    }
  }

  void updateExerciseWeight(int index, double weight) {
    final cur = currentDay;
    if (index >= 0 && index < cur.exercises.length && weight >= 0) {
      final item = cur.exercises[index];
      final updated = item.copyWith(
        targetWeight: weight,
        sets: item.sets.map((s) => s.copyWith(weight: weight)).toList(),
      );
      final list = List<WorkoutExerciseItem>.from(cur.exercises)..[index] = updated;
      days[selectedDayIndex.value] = cur.copyWith(exercises: list);
    }
  }

  void updateSpecificSetWeight(int exIndex, int setIndex, double weight) {
    final cur = currentDay;
    if (exIndex >= 0 && exIndex < cur.exercises.length) {
      final item = cur.exercises[exIndex];
      if (setIndex >= 0 && setIndex < item.sets.length) {
        final updatedSet = item.sets[setIndex].copyWith(weight: weight);
        final setsList = List<ExerciseSet>.from(item.sets)..[setIndex] = updatedSet;
        final updatedEx = item.copyWith(sets: setsList);
        final list = List<WorkoutExerciseItem>.from(cur.exercises)..[exIndex] = updatedEx;
        days[selectedDayIndex.value] = cur.copyWith(exercises: list);
      }
    }
  }

  void updateSpecificSetReps(int exIndex, int setIndex, int reps) {
    final cur = currentDay;
    if (exIndex >= 0 && exIndex < cur.exercises.length) {
      final item = cur.exercises[exIndex];
      if (setIndex >= 0 && setIndex < item.sets.length && reps >= 1) {
        final updatedSet = item.sets[setIndex].copyWith(reps: reps);
        final setsList = List<ExerciseSet>.from(item.sets)..[setIndex] = updatedSet;
        final updatedEx = item.copyWith(sets: setsList);
        final list = List<WorkoutExerciseItem>.from(cur.exercises)..[exIndex] = updatedEx;
        days[selectedDayIndex.value] = cur.copyWith(exercises: list);
      }
    }
  }

  void addSetToExercise(int exIndex) {
    final cur = currentDay;
    if (exIndex >= 0 && exIndex < cur.exercises.length) {
      final item = cur.exercises[exIndex];
      final lastSet = item.sets.isNotEmpty ? item.sets.last : null;
      final newSets = List<ExerciseSet>.from(item.sets)
        ..add(ExerciseSet(
          setNumber: item.sets.length + 1,
          weight: lastSet?.weight ?? item.targetWeight,
          reps: lastSet?.reps ?? item.targetReps,
          isCompleted: false,
        ));
      final updatedEx = item.copyWith(
        targetSets: newSets.length,
        sets: newSets,
      );
      final list = List<WorkoutExerciseItem>.from(cur.exercises)..[exIndex] = updatedEx;
      days[selectedDayIndex.value] = cur.copyWith(exercises: list);
    }
  }

  void removeSetFromExercise(int exIndex, int setIndex) {
    final cur = currentDay;
    if (exIndex >= 0 && exIndex < cur.exercises.length) {
      final item = cur.exercises[exIndex];
      if (item.sets.length > 1 && setIndex >= 0 && setIndex < item.sets.length) {
        final newSets = List<ExerciseSet>.from(item.sets)..removeAt(setIndex);
        for (int i = 0; i < newSets.length; i++) {
          newSets[i] = newSets[i].copyWith(setNumber: i + 1);
        }
        final updatedEx = item.copyWith(
          targetSets: newSets.length,
          sets: newSets,
        );
        final list = List<WorkoutExerciseItem>.from(cur.exercises)..[exIndex] = updatedEx;
        days[selectedDayIndex.value] = cur.copyWith(exercises: list);
      }
    }
  }

  Future<void> saveRoutine({bool setActive = false}) async {
    final name = nameController.text.trim();
    if (name.isEmpty) {
      Get.snackbar(
        'Routine Name Required',
        'Please enter a name for your routine (e.g. "Upper / Lower Split")',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    final id = editingRoutine?.id ?? 'routine_${DateTime.now().millisecondsSinceEpoch}';
    final routine = WorkoutRoutine(
      id: id,
      name: name,
      description: descriptionController.text.trim().isEmpty
          ? '${days.where((d) => !d.isRestDay).length}-day custom training routine'
          : descriptionController.text.trim(),
      days: days.toList(),
      isActive: setActive ? true : (editingRoutine?.isActive ?? false),
      isCustom: true,
      createdAt: editingRoutine?.createdAt ?? DateTime.now(),
    );

    await _workoutService.saveRoutine(routine, setActive: setActive);

    // Refresh workout view controller if registered
    if (Get.isRegistered<WorkoutController>()) {
      await Get.find<WorkoutController>().loadRoutines();
    }

    Get.back();
    Get.snackbar(
      isEditing ? 'Routine Updated' : 'Routine Created',
      '"$name" has been saved successfully.',
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    );
  }

  Future<bool> deleteRoutine() async {
    if (editingRoutine == null) return false;

    final all = await _workoutService.getRoutines();
    if (all.length <= 1) {
      Get.snackbar(
        'Cannot Delete Schedule',
        'You must have at least one active workout schedule.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      );
      return false;
    }

    final deleted = await _workoutService.deleteRoutine(editingRoutine!.id);
    if (deleted) {
      if (Get.isRegistered<WorkoutController>()) {
        await Get.find<WorkoutController>().loadRoutines();
      }
      Get.back();
      if (!Get.testMode) {
        Get.snackbar(
          'Schedule Deleted',
          '"${editingRoutine!.name}" has been removed.',
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        );
      }
      return true;
    }
    return false;
  }
}
