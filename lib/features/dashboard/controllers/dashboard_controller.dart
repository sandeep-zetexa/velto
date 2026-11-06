import 'package:get/get.dart';
import 'package:velto/core/services/local_storage_service.dart';
import 'package:velto/features/diet/models/daily_diet_log.dart';
import 'package:velto/features/diet/models/meal_model.dart';
import 'package:velto/features/diet/services/diet_service.dart';
import 'package:velto/features/workout/models/daily_workout_log.dart';
import 'package:velto/features/workout/models/workout_routine.dart';
import 'package:velto/features/workout/services/workout_service.dart';

/// A single row in the dashboard "Recent activity" list.
class DashboardActivity {
  final String title;
  final String subtitle;
  final DashboardActivityType type;
  final DateTime sortDate;

  const DashboardActivity({
    required this.title,
    required this.subtitle,
    required this.type,
    required this.sortDate,
  });
}

enum DashboardActivityType { workout, meal, nutrition }

/// Aggregates today's diet + workout state for the home dashboard.
class DashboardController extends GetxController {
  final DietService _dietService = DietService();
  final WorkoutService _workoutService = WorkoutService();

  final RxBool isLoading = true.obs;

  // Nutrition (today)
  final Rx<DailyDietLog> todayDiet = DailyDietLog(
    date: LocalStorageService.formatDateKey(DateTime.now()),
  ).obs;

  // Workout (today)
  final Rx<WorkoutRoutine?> activeRoutine = Rx<WorkoutRoutine?>(null);
  final Rx<DailyWorkoutLog?> todayWorkout = Rx<DailyWorkoutLog?>(null);

  // Weekly consistency
  final RxInt weekWorkoutsDone = 0.obs;
  final RxInt weekWorkoutsPlanned = 0.obs;
  final RxInt weekDaysLoggedMeals = 0.obs;

  // Recent activity feed
  final RxList<DashboardActivity> recentActivity = <DashboardActivity>[].obs;

  String get todayKey => LocalStorageService.formatDateKey(DateTime.now());

  int get caloriesLogged => todayDiet.value.totalCalories;
  int get calorieGoal => todayDiet.value.dailyCalorieGoal;
  int get caloriesRemaining => todayDiet.value.remainingCalories;
  double get calorieProgress => todayDiet.value.calorieProgress;

  int get proteinLogged => todayDiet.value.totalProtein;
  int get proteinGoal => todayDiet.value.proteinGoal;
  double get proteinProgress =>
      proteinGoal > 0 ? (proteinLogged / proteinGoal).clamp(0.0, 1.0) : 0.0;

  int get carbsLogged => todayDiet.value.totalCarbs;
  int get carbsGoal => todayDiet.value.carbsGoal;
  int get fatsLogged => todayDiet.value.totalFats;
  int get fatsGoal => todayDiet.value.fatsGoal;

  int get mealsLogged => todayDiet.value.meals.length;

  bool get hasActiveRoutine => activeRoutine.value != null;

  bool get isRestDayToday {
    final log = todayWorkout.value;
    if (log != null) return log.isRestDay;
    final routine = activeRoutine.value;
    if (routine == null || routine.days.isEmpty) return false;
    final idx = DateTime.now().weekday - 1;
    return routine.days[idx.clamp(0, routine.days.length - 1)].isRestDay;
  }

  String get todayWorkoutFocus {
    final log = todayWorkout.value;
    if (log != null) return log.musclesDisplay;
    final routine = activeRoutine.value;
    if (routine == null || routine.days.isEmpty) return 'No plan yet';
    final idx = DateTime.now().weekday - 1;
    return routine.days[idx.clamp(0, routine.days.length - 1)].musclesDisplay;
  }

  /// Muscle words for today's session, from the logged exercises and the day plan.
  List<String> get todayMuscleLabels {
    final raw = <String>[];
    final log = todayWorkout.value;
    if (log != null) {
      raw.addAll(log.muscles);
      for (final item in log.exercises) {
        raw.add(item.exercise.targetMuscle);
      }
      return raw;
    }
    final routine = activeRoutine.value;
    if (routine == null || routine.days.isEmpty) return raw;
    final idx = DateTime.now().weekday - 1;
    final day = routine.days[idx.clamp(0, routine.days.length - 1)];
    raw.addAll(day.muscles);
    for (final item in day.exercises) {
      raw.add(item.exercise.targetMuscle);
    }
    return raw;
  }

  String get todayRoutineName =>
      todayWorkout.value?.routineName ??
      activeRoutine.value?.name ??
      'Workout';

  int get todaySetsDone => todayWorkout.value?.completedSets ?? 0;
  int get todaySetsTotal => todayWorkout.value?.totalSets ?? 0;
  double get todayWorkoutProgress {
    if (todaySetsTotal <= 0) return 0.0;
    return (todaySetsDone / todaySetsTotal).clamp(0.0, 1.0);
  }

  bool get todayWorkoutStarted => todaySetsDone > 0;
  bool get todayWorkoutComplete => todayWorkout.value?.isCompleted ?? false;

  double get weekConsistency {
    if (weekWorkoutsPlanned.value <= 0) return 0.0;
    return (weekWorkoutsDone.value / weekWorkoutsPlanned.value).clamp(0.0, 1.0);
  }

  String get greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String get motivationalLine {
    if (!hasActiveRoutine && mealsLogged == 0) {
      return 'Start by creating a workout plan or logging your first meal.';
    }
    if (isRestDayToday) {
      return 'Rest day — recover well and stay on top of nutrition.';
    }
    if (todayWorkoutComplete) {
      return 'Workout done. Nice work — keep nutrition dialed in.';
    }
    if (todayWorkoutStarted) {
      return 'You\'re mid-session. Finish strong.';
    }
    if (calorieProgress >= 0.85 && calorieProgress <= 1.0) {
      return 'Calories looking solid. Keep it consistent.';
    }
    if (mealsLogged == 0) {
      return 'Log your meals to stay on track today.';
    }
    return 'Small steps compound. Stick with the plan.';
  }

  @override
  void onInit() {
    super.onInit();
    reload();
  }

  Future<void> reload() async {
    isLoading.value = true;
    try {
      await Future.wait([
        _loadTodayDiet(),
        _loadTodayWorkout(),
      ]);
      await _loadWeeklyStats();
      await _buildRecentActivity();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadTodayDiet() async {
    todayDiet.value = await _dietService.getDailyLog(todayKey);
  }

  Future<void> _loadTodayWorkout() async {
    activeRoutine.value = await _workoutService.getActiveRoutine();
    final existing = await _workoutService.getDailyLog(todayKey);
    if (existing != null) {
      todayWorkout.value = existing;
      return;
    }

    final routine = activeRoutine.value;
    if (routine != null && routine.days.isNotEmpty) {
      final idx = DateTime.now().weekday - 1;
      final day = routine.days[idx.clamp(0, routine.days.length - 1)];
      todayWorkout.value = DailyWorkoutLog.fromRoutineDay(
        date: todayKey,
        routineId: routine.id,
        routineName: routine.name,
        day: day,
      );
    } else {
      todayWorkout.value = null;
    }
  }

  Future<void> _loadWeeklyStats() async {
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));

    final weekKeys = List.generate(
      7,
      (i) => LocalStorageService.formatDateKey(monday.add(Duration(days: i))),
    );

    final routine = activeRoutine.value;
    weekWorkoutsPlanned.value = routine?.totalWorkoutsInWeek ?? 0;

    final workoutLogs = await _workoutService.getAllDailyLogs();
    var workoutsDone = 0;
    for (final key in weekKeys) {
      final log = workoutLogs[key];
      if (log == null || log.isRestDay) continue;
      if (log.completedSets > 0) workoutsDone++;
    }
    weekWorkoutsDone.value = workoutsDone;

    final dietLogs = await _dietService.getAllDailyLogs();
    var mealDays = 0;
    for (final key in weekKeys) {
      final log = dietLogs[key];
      if (log != null && log.meals.isNotEmpty) mealDays++;
    }
    weekDaysLoggedMeals.value = mealDays;
  }

  Future<void> _buildRecentActivity() async {
    final items = <DashboardActivity>[];
    final now = DateTime.now();

    // Today's meals (most recent first)
    final meals = List<MealModel>.from(todayDiet.value.meals);
    for (final meal in meals.take(3)) {
      items.add(DashboardActivity(
        title: meal.title,
        subtitle: '${meal.category} · ${meal.calories} kcal · ${meal.time}',
        type: DashboardActivityType.meal,
        sortDate: now,
      ));
    }

    // Today's workout progress
    final workout = todayWorkout.value;
    if (workout != null && !workout.isRestDay && workout.completedSets > 0) {
      items.add(DashboardActivity(
        title: workout.isCompleted
            ? 'Completed ${workout.musclesDisplay}'
            : 'Training · ${workout.musclesDisplay}',
        subtitle:
            '${workout.completedSets}/${workout.totalSets} sets · ${workout.routineName}',
        type: DashboardActivityType.workout,
        sortDate: now,
      ));
    }

    // Look back over the past week for completed workouts / meal days
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final workoutLogs = await _workoutService.getAllDailyLogs();
    final dietLogs = await _dietService.getAllDailyLogs();

    for (int i = 0; i < 7; i++) {
      final day = monday.add(Duration(days: i));
      if (day.isAfter(now)) continue;
      final key = LocalStorageService.formatDateKey(day);
      final isToday = key == todayKey;

      final wLog = workoutLogs[key];
      if (!isToday &&
          wLog != null &&
          !wLog.isRestDay &&
          wLog.completedSets > 0) {
        items.add(DashboardActivity(
          title: wLog.isCompleted
              ? 'Finished ${wLog.musclesDisplay}'
              : 'Partial · ${wLog.musclesDisplay}',
          subtitle: '${_relativeDayLabel(day)} · ${wLog.completedSets} sets',
          type: DashboardActivityType.workout,
          sortDate: day,
        ));
      }

      final dLog = dietLogs[key];
      if (!isToday && dLog != null && dLog.meals.isNotEmpty) {
        final onTrack = dLog.totalCalories <= dLog.dailyCalorieGoal;
        items.add(DashboardActivity(
          title: onTrack ? 'Nutrition goal met' : 'Meals logged',
          subtitle:
              '${_relativeDayLabel(day)} · ${dLog.totalCalories} / ${dLog.dailyCalorieGoal} kcal',
          type: DashboardActivityType.nutrition,
          sortDate: day,
        ));
      }
    }

    items.sort((a, b) => b.sortDate.compareTo(a.sortDate));
    recentActivity.assignAll(items.take(5));
  }

  String _relativeDayLabel(DateTime day) {
    final today = DateTime.now();
    final a = DateTime(today.year, today.month, today.day);
    final b = DateTime(day.year, day.month, day.day);
    final diff = a.difference(b).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[day.weekday - 1];
  }
}
