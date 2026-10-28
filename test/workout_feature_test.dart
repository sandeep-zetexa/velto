import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:velto/features/workout/controllers/add_routine_controller.dart';
import 'package:velto/features/workout/controllers/workout_controller.dart';
import 'package:velto/features/workout/models/exercise.dart';
import 'package:velto/features/workout/models/routine_day.dart';
import 'package:velto/features/workout/models/workout_routine.dart';
import 'package:velto/features/workout/services/workout_service.dart';
import 'package:velto/features/workout/views/add_routine_view.dart';
import 'package:velto/features/workout/views/workout_view.dart';
import 'package:velto/features/workout/widgets/routine_selector_sheet.dart';

Future<void> seedTestRoutines(WorkoutService service) async {
  final exercises = await service.getExercises();
  final bench = exercises.firstWhere((e) => e.name == 'Barbell Bench Press');
  final incline = exercises.firstWhere((e) => e.name.contains('Incline Dumbbell Press'));
  final squat = exercises.firstWhere((e) => e.name == 'Barbell Back Squat');
  final deadlift = exercises.firstWhere((e) => e.name.contains('Deadlift'));

  final ppl = WorkoutRoutine(
    id: 'routine_ppl',
    name: 'Push Pull Legs (PPL)',
    days: [
      RoutineDay(
        dayName: 'Monday',
        dayShort: 'Mon',
        muscles: ['Chest'],
        exercises: [
          WorkoutExerciseItem.create(exercise: bench, targetSets: 4, targetReps: 8, targetWeight: 60.0),
          WorkoutExerciseItem.create(exercise: incline, targetSets: 3, targetReps: 10, targetWeight: 22.0),
        ],
      ),
      RoutineDay(
        dayName: 'Tuesday',
        dayShort: 'Tue',
        muscles: ['Back'],
        exercises: [
          WorkoutExerciseItem.create(exercise: deadlift, targetSets: 4, targetReps: 5, targetWeight: 100.0),
        ],
      ),
      RoutineDay(
        dayName: 'Wednesday',
        dayShort: 'Wed',
        muscles: ['Legs'],
        exercises: [
          WorkoutExerciseItem.create(exercise: squat, targetSets: 4, targetReps: 8, targetWeight: 80.0),
        ],
      ),
      const RoutineDay(dayName: 'Thursday', dayShort: 'Thu', muscles: ['Rest'], isRestDay: true, exercises: []),
      const RoutineDay(dayName: 'Friday', dayShort: 'Fri', muscles: ['Rest'], isRestDay: true, exercises: []),
      const RoutineDay(dayName: 'Saturday', dayShort: 'Sat', muscles: ['Rest'], isRestDay: true, exercises: []),
      const RoutineDay(dayName: 'Sunday', dayShort: 'Sun', muscles: ['Rest'], isRestDay: true, exercises: []),
    ],
  );

  final broSplit = WorkoutRoutine(
    id: 'routine_bro_split',
    name: 'Bro Split (Muscle Groups)',
    days: [
      RoutineDay(
        dayName: 'Monday',
        dayShort: 'Mon',
        muscles: ['Chest'],
        exercises: [
          WorkoutExerciseItem.create(exercise: bench, targetSets: 4, targetReps: 8, targetWeight: 65.0),
        ],
      ),
      const RoutineDay(dayName: 'Tuesday', dayShort: 'Tue', muscles: ['Back'], isRestDay: false, exercises: []),
      const RoutineDay(dayName: 'Wednesday', dayShort: 'Wed', muscles: ['Legs'], isRestDay: false, exercises: []),
      const RoutineDay(dayName: 'Thursday', dayShort: 'Thu', muscles: ['Shoulders'], isRestDay: false, exercises: []),
      const RoutineDay(dayName: 'Friday', dayShort: 'Fri', muscles: ['Arms'], isRestDay: false, exercises: []),
      const RoutineDay(dayName: 'Saturday', dayShort: 'Sat', muscles: ['Abs'], isRestDay: false, exercises: []),
      const RoutineDay(dayName: 'Sunday', dayShort: 'Sun', muscles: ['Rest'], isRestDay: true, exercises: []),
    ],
  );

  final upperLower = WorkoutRoutine(
    id: 'routine_upper_lower',
    name: 'Upper Lower Split',
    days: [
      RoutineDay(
        dayName: 'Monday',
        dayShort: 'Mon',
        muscles: ['Upper Body'],
        exercises: [
          WorkoutExerciseItem.create(exercise: bench, targetSets: 4, targetReps: 8, targetWeight: 60.0),
        ],
      ),
      const RoutineDay(dayName: 'Tuesday', dayShort: 'Tue', muscles: ['Lower Body'], isRestDay: false, exercises: []),
      const RoutineDay(dayName: 'Wednesday', dayShort: 'Wed', muscles: ['Rest'], isRestDay: true, exercises: []),
      const RoutineDay(dayName: 'Thursday', dayShort: 'Thu', muscles: ['Upper Body'], isRestDay: false, exercises: []),
      const RoutineDay(dayName: 'Friday', dayShort: 'Fri', muscles: ['Lower Body'], isRestDay: false, exercises: []),
      const RoutineDay(dayName: 'Saturday', dayShort: 'Sat', muscles: ['Rest'], isRestDay: true, exercises: []),
      const RoutineDay(dayName: 'Sunday', dayShort: 'Sun', muscles: ['Rest'], isRestDay: true, exercises: []),
    ],
  );

  await service.saveRoutine(ppl, setActive: true);
  await service.saveRoutine(broSplit);
  await service.saveRoutine(upperLower);
}

void main() {
  group('Workout Feature Tests', () {
    final service = WorkoutService();

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await seedTestRoutines(service);
    });

    test('WorkoutService loads extensive exercise catalog', () async {
      final exercises = await service.getExercises();
      expect(exercises.length >= 40, true);

      // Verify staples across major muscle groups
      expect(exercises.any((e) => e.name == 'Barbell Bench Press'), true);
      expect(exercises.any((e) => e.name == 'Barbell Back Squat'), true);
      expect(exercises.any((e) => e.name.contains('Deadlift')), true);
      expect(exercises.any((e) => e.name.contains('Pull-Up')), true);
      expect(exercises.any((e) => e.name.contains('Overhead Press')), true);
      expect(exercises.any((e) => e.name.contains('Barbell Curl')), true);
      expect(exercises.any((e) => e.name.contains('Pushdown')), true);
      expect(exercises.any((e) => e.name.contains('Hanging')), true);
    });

    test('WorkoutService filters exercises by muscle group (e.g. Legs)', () async {
      final legExercises = await service.getExercises(muscle: 'Legs');
      expect(legExercises.isNotEmpty, true);
      expect(legExercises.every((e) =>
          e.targetMuscle == 'Legs' ||
          e.secondaryMuscles.contains('Quads') ||
          e.secondaryMuscles.contains('Hamstrings') ||
          e.secondaryMuscles.contains('Glutes') ||
          e.secondaryMuscles.contains('Calves')), true);
    });

    test('WorkoutService manages routines and active routine selection', () async {
      final routines = await service.getRoutines();
      expect(routines.length >= 3, true);

      final active = await service.getActiveRoutine();
      expect(active, isNotNull);
      expect(active!.name, contains('Push Pull Legs'));

      // Switch active routine to Bro Split
      final broSplit = routines.firstWhere((r) => r.name.contains('Bro Split'));
      await service.setActiveRoutine(broSplit.id);

      final newActive = await service.getActiveRoutine();
      expect(newActive!.id, broSplit.id);
      expect(newActive.name, contains('Bro Split'));

      // Reset back to PPL
      final ppl = routines.firstWhere((r) => r.name.contains('Push Pull Legs'));
      await service.setActiveRoutine(ppl.id);
    });

    test('WorkoutController manages active routine, day selection, and increments', () async {
      Get.reset();
      final controller = Get.put(WorkoutController());
      await controller.loadRoutines();

      expect(controller.activeRoutine.value, isNotNull);
      expect(controller.allRoutines.length >= 3, true);

      // Select Monday
      await controller.selectDay(0);
      expect(controller.selectedDayIndex.value, 0);

      final day = controller.selectedDay;
      expect(day, isNotNull);
      expect(day!.dayName, 'Monday');

      if (day.exercises.isNotEmpty) {
        final firstEx = day.exercises.first;
        final initialWeight = firstEx.targetWeight;
        final initialReps = firstEx.targetReps;

        // Increase weight
        await controller.increaseWeight(firstEx, 2.5);
        final afterWeight = controller.selectedDay!.exercises.first.targetWeight;
        expect(afterWeight, initialWeight + 2.5);

        // Increase reps
        await controller.increaseReps(firstEx, 1);
        final afterReps = controller.selectedDay!.exercises.first.targetReps;
        expect(afterReps, initialReps + 1);

        // Toggle set completion
        expect(firstEx.sets.first.isCompleted, false);
        await controller.toggleSetCompletion(firstEx, 0);
        expect(controller.selectedDay!.exercises.first.sets.first.isCompleted, true);
      }
    });

    test('Every set can have independent reps and weight', () async {
      Get.reset();
      final controller = Get.put(WorkoutController());
      await controller.loadRoutines();
      await controller.selectDay(0);

      // Ensure first exercise has at least 3 sets
      while (controller.selectedDay!.exercises.first.sets.length < 3) {
        await controller.addSet(controller.selectedDay!.exercises.first);
      }

      final ex = controller.selectedDay!.exercises.first;
      // Adjust Set 0, Set 1, Set 2 with distinct weight and reps
      await controller.updateSetWeight(ex, 0, 5.0);
      await controller.updateSetWeight(ex, 1, 10.0);
      await controller.updateSetReps(ex, 1, -2);
      await controller.updateSetWeight(ex, 2, 15.0);
      await controller.updateSetReps(ex, 2, -4);

      final updatedSets = controller.selectedDay!.exercises.first.sets;
      expect(updatedSets[0].weight != updatedSets[1].weight, true);
      expect(updatedSets[1].weight != updatedSets[2].weight, true);
      expect(updatedSets[0].reps != updatedSets[1].reps, true);
      expect(updatedSets[1].reps != updatedSets[2].reps, true);
    });

    test('AddRoutineController creates custom routine with selected muscles & exercises', () async {
      Get.reset();
      final controller = Get.put(AddRoutineController());
      controller.nameController.text = 'Arnold Split Custom';

      // Configure Day 0 (Monday)
      controller.selectDay(0);
      controller.toggleMuscle('Chest');
      controller.toggleMuscle('Back');

      final exercises = await service.getExercises();
      final benchPress = exercises.firstWhere((e) => e.name == 'Barbell Bench Press');
      controller.addExerciseToCurrentDay(benchPress, targetSets: 4, targetReps: 8, targetWeight: 75.0);

      expect(controller.currentDay.exercises.length, 1);
      expect(controller.currentDay.exercises.first.exercise.name, 'Barbell Bench Press');
      expect(controller.currentDay.exercises.first.targetWeight, 75.0);
    });

    testWidgets('WorkoutView renders active routine, days, exercises, and interactive steppers', (tester) async {
      Get.reset();
      final controller = Get.put(WorkoutController());
      await controller.loadRoutines();

      // Ensure Monday (Push day with exercises) is selected
      controller.selectDay(0);

      await tester.pumpWidget(
        const GetMaterialApp(
          home: WorkoutView(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify active routine name rendered
      expect(find.text(controller.activeRoutine.value!.name), findsWidgets);

      // Verify schedule header & day tabs
      expect(find.text('Weekly Schedule'), findsOneWidget);
      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Tue'), findsOneWidget);
      expect(find.text('Wed'), findsOneWidget);

      // Verify stepper labels exist (WEIGHT, REPS, SETS)
      expect(find.text('WEIGHT'), findsWidgets);
      expect(find.text('REPS'), findsWidgets);
      expect(find.text('SETS'), findsWidgets);

      // Verify interactive set rows exist (Set 1, Set 2)
      expect(find.text('Set 1'), findsWidgets);

      // Verify Add Exercise button exists
      await tester.scrollUntilVisible(find.text('Add Exercise to Today'), 500);
      expect(find.text('Add Exercise to Today'), findsOneWidget);
    });

    testWidgets('WorkoutView supports collapsible exercises and Expand/Collapse All', (tester) async {
      Get.reset();
      final controller = Get.put(WorkoutController());
      await controller.loadRoutines();
      await controller.selectDay(0);

      await tester.pumpWidget(
        const GetMaterialApp(
          home: WorkoutView(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify EXERCISES header and toggle button exist
      expect(find.textContaining('EXERCISES'), findsOneWidget);

      // Initially exercise 0 is expanded, rest collapsed -> button shows 'Expand All'
      expect(find.text('Expand All'), findsOneWidget);
      expect(controller.isExerciseExpanded(controller.selectedDay!.exercises.first.id, 0), true);

      // 1. Tap Expand All -> all exercises expand, button switches to 'Collapse All'
      await tester.tap(find.text('Expand All'));
      await tester.pumpAndSettle();
      expect(find.text('Collapse All'), findsOneWidget);
      expect(controller.areAllExpanded(controller.selectedDay!), true);

      // 2. Tap Collapse All -> all exercises collapse, button switches to 'Expand All'
      await tester.tap(find.text('Collapse All'));
      await tester.pumpAndSettle();
      expect(find.text('Expand All'), findsOneWidget);
      expect(controller.isExerciseExpanded(controller.selectedDay!.exercises.first.id, 0), false);

      // 3. Tap individual exercise header -> toggles that exercise open
      final firstExerciseName = controller.selectedDay!.exercises.first.exercise.name;
      await tester.tap(find.text(firstExerciseName));
      await tester.pumpAndSettle();
      expect(controller.isExerciseExpanded(controller.selectedDay!.exercises.first.id, 0), true);

      // 4. Tap individual exercise header again -> toggles that exercise closed
      await tester.tap(find.text(firstExerciseName));
      await tester.pumpAndSettle();
      expect(controller.isExerciseExpanded(controller.selectedDay!.exercises.first.id, 0), false);
    });

    testWidgets('AddRoutineView renders 7-day schedule and muscle selection without overflow', (tester) async {
      Get.reset();
      Get.put(AddRoutineController());

      await tester.pumpWidget(
        const GetMaterialApp(
          home: AddRoutineView(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify title & schedule
      expect(find.text('Create Routine'), findsOneWidget);
      expect(find.text('Schedule by Day'), findsOneWidget);
      expect(find.text('Mon'), findsOneWidget);

      // Verify Rest Day and muscle chips are present
      expect(find.text('Rest Day'), findsWidgets);
      expect(find.text('Chest'), findsWidgets);
      expect(find.text('Back'), findsWidgets);
      expect(find.text('Legs'), findsWidgets);

      // Verify no default exercises are pre-added for newly created routine
      final controller = Get.find<AddRoutineController>();
      expect(controller.currentDay.exercises.isEmpty, true);

      // Tap Chest chip -> exercises filtered for Chest
      await tester.tap(find.text('Chest').first);
      await tester.pumpAndSettle();
      expect(controller.currentDay.muscles.contains('Chest'), true);

      // 1-tap Add an exercise
      expect(find.text('Add'), findsWidgets);
      await tester.ensureVisible(find.text('Add').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add').first);
      await tester.pumpAndSettle();

      // Exercise should now be added to current day
      expect(controller.currentDay.exercises.length, 1);
      expect(find.text('Added to Mon'), findsOneWidget);
      expect(find.text('Added'), findsWidgets);

      // Verify action buttons
      expect(find.text('Save Routine'), findsOneWidget);
      expect(find.text('Save & Set Active'), findsOneWidget);

      // Verify no RenderFlex overflow
      expect(tester.takeException(), isNull);
    });

    testWidgets('AddRoutineView toggles Rest Day chip cleanly', (tester) async {
      Get.reset();
      final controller = Get.put(AddRoutineController());

      await tester.pumpWidget(
        const GetMaterialApp(
          home: AddRoutineView(),
        ),
      );
      await tester.pumpAndSettle();

      // Initially Monday is not rest day
      expect(controller.currentDay.isRestDay, false);

      // Tap Rest Day chip
      await tester.tap(find.text('Rest Day'));
      await tester.pumpAndSettle();

      expect(controller.currentDay.isRestDay, true);
      expect(find.text('Rest & Recovery'), findsWidgets);

      // Tap Rest Day chip again to un-toggle
      await tester.tap(find.text('Rest Day'));
      await tester.pumpAndSettle();
      expect(controller.currentDay.isRestDay, false);
    });

    testWidgets('RoutineSelectorSheet renders redesigned routines with 7-day strip and switches routine', (tester) async {
      Get.reset();
      Get.testMode = true;
      final controller = Get.put(WorkoutController());
      await controller.loadRoutines();

      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => RoutineSelectorSheet.show(context, controller),
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Verify sheet title & routines
      expect(find.text('Workout Routines'), findsOneWidget);
      expect(find.text('ACTIVE'), findsOneWidget);
      expect(find.text('Create New Workout Routine'), findsOneWidget);

      // Verify preset routine names are present
      expect(find.text('Push Pull Legs (PPL)'), findsOneWidget);
      expect(find.text('Bro Split (Muscle Groups)'), findsOneWidget);

      // Verify Delete buttons are present
      expect(find.text('Delete'), findsWidgets);

      // Tap Delete on one of the routines
      final initialCount = controller.allRoutines.length;
      await tester.tap(find.text('Delete').first);
      await tester.pumpAndSettle();

      // Confirmation dialog appears
      expect(find.text('Delete Workout Schedule?'), findsOneWidget);
      expect(find.text('Delete Schedule'), findsOneWidget);

      // Confirm deletion
      await tester.tap(find.text('Delete Schedule'));
      await tester.pumpAndSettle();

      expect(controller.allRoutines.length, initialCount - 1);

      // Verify no RenderFlex overflow
      expect(tester.takeException(), isNull);
    });

    testWidgets('AddRoutineView renders delete options when editing a schedule', (tester) async {
      Get.reset();
      Get.testMode = true;
      final service = WorkoutService();
      final routines = await service.getRoutines();
      final target = routines.first;

      final controller = AddRoutineController();
      controller.editingRoutine = target;
      Get.put(controller);

      await tester.pumpWidget(
        const GetMaterialApp(
          home: AddRoutineView(),
        ),
      );
      await tester.pumpAndSettle();

      // Check title reflects edit mode
      expect(find.text('Edit Routine'), findsOneWidget);

      // Verify delete option is available
      expect(find.byIcon(LucideIcons.trash_2), findsWidgets);
      expect(find.text('Delete this workout schedule'), findsOneWidget);
    });

    testWidgets('WorkoutView renders enhanced day selector with day name, date, and Jump to Today', (tester) async {
      Get.reset();
      Get.testMode = true;
      final controller = Get.put(WorkoutController());
      await controller.loadRoutines();

      // Ensure today is not Sunday for the test so we have a workout day
      controller.selectDay(0); // Monday (Push day)

      await tester.pumpWidget(
        const GetMaterialApp(
          home: WorkoutView(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify days are rendered
      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Tue'), findsOneWidget);
      expect(find.text('Wed'), findsOneWidget);

      // Verify muscle focus is visible in the day strip (e.g. Chest / Push / Rest)
      expect(find.text('Chest'), findsWidgets);

      // Verify day stats badges are rendered in active day card
      expect(find.textContaining('Exercises'), findsWidgets);
      expect(find.textContaining('Sets Target'), findsWidgets);

      // If viewing another day other than today, Jump to Today button appears
      final otherIndex = (controller.todayDayIndex + 2) % 7;
      controller.selectDay(otherIndex);
      await tester.pumpAndSettle();

      expect(find.text('Jump to Today'), findsOneWidget);

      // Tap Jump to Today -> returns to today
      await tester.tap(find.text('Jump to Today'));
      await tester.pumpAndSettle();
      expect(controller.selectedDayIndex.value, controller.todayDayIndex);

      expect(tester.takeException(), isNull);
    });
  });
}
