import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:velto/core/services/local_storage_service.dart';
import 'package:velto/features/diet/controllers/diet_controller.dart';
import 'package:velto/features/diet/models/meal_model.dart';
import 'package:velto/features/diet/models/saved_meal.dart';
import 'package:velto/features/diet/services/diet_service.dart';
import 'package:velto/features/workout/controllers/workout_controller.dart';
import 'package:velto/features/workout/models/exercise.dart';
import 'package:velto/features/workout/models/routine_day.dart';
import 'package:velto/features/workout/models/workout_routine.dart';
import 'package:velto/features/workout/services/workout_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Minimal Storage & Date-Keyed Plan Switching Tests', () {
    late WorkoutService workoutService;
    late DietService dietService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      Get.reset();
      workoutService = WorkoutService();
      dietService = DietService();
      await workoutService.fetchExercisesApi();
      await dietService.fetchIngredientsApi();
    });

    test('Exercises contain SVG vector data with placeholder fallback', () async {
      final exercises = await workoutService.fetchExercisesApi();
      expect(exercises.isNotEmpty, true);
      for (final ex in exercises) {
        expect(ex.svg, isNotNull);
        expect(ex.svg!.contains('<svg'), true);
        expect(ex.svg!.contains('</svg>'), true);
      }
    });

    test('Routines use minimal storage format (storing list of exerciseId references)', () async {
      final exercises = await workoutService.getExercises();
      final benchPress = exercises.firstWhere((e) => e.name == 'Barbell Bench Press');
      final squat = exercises.firstWhere((e) => e.name == 'Barbell Back Squat');

      final day1Item = WorkoutExerciseItem.create(
        exercise: benchPress,
        targetSets: 4,
        targetReps: 8,
        targetWeight: 80.0,
      );
      final day2Item = WorkoutExerciseItem.create(
        exercise: squat,
        targetSets: 5,
        targetReps: 5,
        targetWeight: 100.0,
      );

      final customRoutine = WorkoutRoutine(
        id: 'minimal_custom_split_1',
        name: 'Heavy Minimal Split',
        isCustom: true,
        days: [
          RoutineDay(
            dayName: 'Monday',
            dayShort: 'Mon',
            muscles: ['Chest'],
            exercises: [day1Item],
          ),
          RoutineDay(
            dayName: 'Tuesday',
            dayShort: 'Tue',
            muscles: ['Legs'],
            exercises: [day2Item],
          ),
        ],
      );

      // Verify minimal JSON serialization only contains exerciseId and configuration
      final minimalJson = customRoutine.toMinimalJson();
      expect(minimalJson['id'], 'minimal_custom_split_1');
      expect(minimalJson['name'], 'Heavy Minimal Split');
      expect(minimalJson['days'] is List, true);

      final daysList = minimalJson['days'] as List;
      final mondayJson = daysList[0] as Map<String, dynamic>;
      final exercisesList = mondayJson['exercises'] as List;
      final firstExJson = exercisesList[0] as Map<String, dynamic>;

      // Minimal JSON must reference exerciseId without embedding full duplicate exercise catalog
      expect(firstExJson['exerciseId'], benchPress.id);
      expect(firstExJson.containsKey('exercise'), false); // No bloated duplicate object
      expect(firstExJson['targetWeight'], 80.0);
      expect(firstExJson['targetSets'], 4);

      // Verify inflation using exercise catalog map reconstructs full WorkoutRoutine
      final inflated = WorkoutRoutine.fromMinimalJson(minimalJson, workoutService.exerciseMap);
      expect(inflated.name, 'Heavy Minimal Split');
      expect(inflated.days[0].exercises.first.exercise.name, 'Barbell Bench Press');
      expect(inflated.days[1].exercises.first.exercise.name, 'Barbell Back Squat');
      expect(inflated.days[0].exercises.first.targetWeight, 80.0);
    });

    test('Diet saved meals use minimal storage format (storing list of ingredientId references)', () async {
      final ingredients = await dietService.getIngredients();
      final oats = ingredients.firstWhere((i) => i.id == 'ing_rolled_oats');
      final whey = ingredients.firstWhere((i) => i.id == 'ing_whey_protein');

      final customSavedMeal = SavedMeal(
        id: 'saved_meal_power_shake',
        name: 'Power Shake',
        category: 'Breakfast',
        items: [
          MealIngredientItem(ingredient: oats, quantity: 60, unit: 'g'),
          MealIngredientItem(ingredient: whey, quantity: 35, unit: 'g'),
        ],
      );

      final minimalJson = customSavedMeal.toMinimalJson();
      expect(minimalJson['id'], 'saved_meal_power_shake');
      expect(minimalJson['items'] is List, true);

      final ingList = minimalJson['items'] as List;
      final firstIng = ingList[0] as Map<String, dynamic>;
      expect(firstIng['ingredientId'], 'ing_rolled_oats');
      expect(firstIng['quantity'], 60.0);
      expect(firstIng.containsKey('ingredient'), false); // Minimal storage

      final inflated = SavedMeal.fromMinimalJson(minimalJson, dietService.ingredientMap);
      expect(inflated.name, 'Power Shake');
      expect(inflated.items[0].ingredient.name, contains('Rolled Oats'));
      expect(inflated.items[1].ingredient.name, contains('Whey Protein'));
      expect(inflated.totalProtein > 30, true);
    });

    test('Plans and meals start completely empty when storage is cleared', () async {
      expect(await workoutService.getRoutines(), isEmpty);
      expect(await workoutService.getActiveRoutine(), isNull);
      expect(await dietService.getSavedMeals(), isEmpty);
    });

    test('Workout plan switching preserves yesterday\'s completed plan and ticks, while today shows the new plan', () async {
      final exercises = await workoutService.getExercises();
      final benchPress = exercises.firstWhere((e) => e.name == 'Barbell Bench Press');
      final squat = exercises.firstWhere((e) => e.name == 'Barbell Back Squat');

      final ppl = WorkoutRoutine(
        id: 'user_routine_ppl',
        name: 'Push Pull Legs (PPL)',
        days: [
          RoutineDay(
            dayName: 'Monday',
            dayShort: 'Mon',
            muscles: ['Chest'],
            exercises: [
              WorkoutExerciseItem.create(exercise: benchPress, targetSets: 3, targetReps: 10, targetWeight: 60.0),
            ],
          ),
        ],
      );

      final broSplit = WorkoutRoutine(
        id: 'user_routine_bro',
        name: 'Bro Split (Muscle Groups)',
        days: [
          RoutineDay(
            dayName: 'Monday',
            dayShort: 'Mon',
            muscles: ['Chest'],
            exercises: [
              WorkoutExerciseItem.create(exercise: benchPress, targetSets: 4, targetReps: 8, targetWeight: 65.0),
            ],
          ),
          RoutineDay(
            dayName: 'Tuesday',
            dayShort: 'Tue',
            muscles: ['Legs'],
            exercises: [
              WorkoutExerciseItem.create(exercise: squat, targetSets: 4, targetReps: 8, targetWeight: 80.0),
            ],
          ),
        ],
      );

      await workoutService.saveRoutine(ppl, setActive: true);
      await workoutService.saveRoutine(broSplit);

      final controller = Get.put(WorkoutController());
      await controller.loadRoutines();

      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayKey = LocalStorageService.formatDateKey(yesterday);
      final today = DateTime.now();
      final todayKey = LocalStorageService.formatDateKey(today);

      // Select yesterday
      controller.selectedDate.value = yesterday;
      await controller.loadDailyLogForDate(yesterday);

      expect(controller.selectedDay, isNotNull);
      final yesterdayEx = controller.selectedDay!.exercises.first;

      // Complete Set 0 yesterday
      await controller.toggleSetCompletion(yesterdayEx, 0);
      expect(controller.selectedDay!.exercises.first.sets[0].isCompleted, true);

      // Verify yesterday's log is saved to storage under yesterday's date
      final savedYesterdayLog = await workoutService.getDailyLog(yesterdayKey);
      expect(savedYesterdayLog, isNotNull);
      expect(savedYesterdayLog!.routineId, ppl.id);
      expect(savedYesterdayLog.exercises.first.sets[0].isCompleted, true);

      // NOW TODAY: user switches routine to Bro Split
      controller.selectedDate.value = today;
      await controller.switchActiveRoutine(broSplit.id);
      await controller.loadDailyLogForDate(today);

      // Verify today displays the new active routine (Bro Split)
      expect(controller.effectiveRoutineName, contains('Bro Split'));
      expect(controller.activeRoutine.value!.id, broSplit.id);
      final todaySavedLog = await workoutService.getDailyLog(todayKey);
      expect(todaySavedLog, isNotNull);
      expect(todaySavedLog!.routineId, broSplit.id);

      // Now navigate back to yesterday: yesterday MUST STILL show PPL and yesterday's completed tick!
      controller.selectedDate.value = yesterday;
      await controller.loadDailyLogForDate(yesterday);

      expect(controller.effectiveRoutineName, contains('Push Pull Legs'));
      expect(controller.selectedDay!.exercises.first.sets[0].isCompleted, true);

      // Verify today still has Bro Split
      controller.selectedDate.value = today;
      await controller.loadDailyLogForDate(today);
      expect(controller.effectiveRoutineName, contains('Bro Split'));
    });

    test('Diet logs are date-keyed: meals logged yesterday remain in yesterday, today has today\'s meals', () async {
      final dietController = Get.put(DietController());
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final today = DateTime.now();

      // Log meal for yesterday
      dietController.selectedDate.value = yesterday;
      await dietController.loadDailyLogForSelectedDate();
      await dietController.addMeal(
        const MealModel(
          id: 'yesterday_lunch',
          category: 'Lunch',
          time: '1:00 PM',
          title: 'Yesterday Chicken Rice',
          calories: 550,
          protein: 42,
          carbs: 65,
          fats: 10,
        ),
      );

      expect(dietController.meals.any((m) => m.id == 'yesterday_lunch'), true);
      expect(dietController.totalCalories, 550);

      // Now switch to today: should have empty/default meals for today
      dietController.selectedDate.value = today;
      await dietController.loadDailyLogForSelectedDate();
      expect(dietController.meals.any((m) => m.id == 'yesterday_lunch'), false);

      // Add meal today
      await dietController.addMeal(
        const MealModel(
          id: 'today_breakfast',
          category: 'Breakfast',
          time: '8:00 AM',
          title: 'Today Eggs and Toast',
          calories: 320,
          protein: 24,
          carbs: 28,
          fats: 12,
        ),
      );

      expect(dietController.meals.any((m) => m.id == 'today_breakfast'), true);
      expect(dietController.totalCalories, 320);

      // Switch back to yesterday: yesterday still has yesterday's meal and yesterday's calories
      dietController.selectedDate.value = yesterday;
      await dietController.loadDailyLogForSelectedDate();
      expect(dietController.meals.any((m) => m.id == 'yesterday_lunch'), true);
      expect(dietController.meals.any((m) => m.id == 'today_breakfast'), false);
      expect(dietController.totalCalories, 550);
    });
  });
}
