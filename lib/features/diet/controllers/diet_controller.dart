import 'package:get/get.dart';
import 'package:velto/core/services/local_storage_service.dart';
import 'package:velto/features/diet/models/daily_diet_log.dart';
import 'package:velto/features/diet/models/meal_model.dart';
import 'package:velto/features/diet/services/diet_service.dart';

class DietController extends GetxController {
  final DietService _dietService = DietService();

  final RxInt dailyCalorieGoal = 2200.obs;
  final RxInt proteinGoal = 150.obs;
  final RxInt carbsGoal = 220.obs;
  final RxInt fatsGoal = 70.obs;

  final RxList<MealModel> meals = <MealModel>[].obs;
  final Rx<DateTime> selectedDate = Rx<DateTime>(DateTime.now());
  final RxInt selectedDayIndex = 0.obs;
  final RxBool isLoading = false.obs;

  int get todayDayIndex {
    final weekday = DateTime.now().weekday; // 1 = Mon, 7 = Sun
    return (weekday - 1).clamp(0, 6);
  }

  String get selectedDateKey => LocalStorageService.formatDateKey(selectedDate.value);

  int get totalCalories => meals.fold(0, (sum, item) => sum + item.calories);
  int get remainingCalories => (dailyCalorieGoal.value - totalCalories).clamp(0, 9999);

  int get totalProtein => meals.fold(0, (sum, item) => sum + item.protein);
  int get totalCarbs => meals.fold(0, (sum, item) => sum + item.carbs);
  int get totalFats => meals.fold(0, (sum, item) => sum + item.fats);

  double get calorieProgress =>
      dailyCalorieGoal.value > 0 ? (totalCalories / dailyCalorieGoal.value).clamp(0.0, 1.0) : 0.0;

  @override
  void onInit() {
    super.onInit();
    selectedDayIndex.value = todayDayIndex;
    selectedDate.value = DateTime.now();
    loadDailyLogForSelectedDate();
  }

  Future<void> selectDay(int index) async {
    if (index >= 0 && index < 7) {
      selectedDayIndex.value = index;
      final now = DateTime.now();
      final currentWeekday = now.weekday; // 1 = Mon, 7 = Sun
      final monday = now.subtract(Duration(days: currentWeekday - 1));
      final dateForIndex = monday.add(Duration(days: index));
      selectedDate.value = dateForIndex;
      await loadDailyLogForSelectedDate();
    }
  }

  Future<void> loadDailyLogForSelectedDate() async {
    isLoading.value = true;
    try {
      final log = await _dietService.getDailyLog(selectedDateKey);
      meals.assignAll(log.meals);
      dailyCalorieGoal.value = log.dailyCalorieGoal;
      proteinGoal.value = log.proteinGoal;
      carbsGoal.value = log.carbsGoal;
      fatsGoal.value = log.fatsGoal;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addMeal(MealModel meal) async {
    meals.insert(0, meal);
    await _persistCurrentLog();
  }

  Future<void> removeMeal(String id) async {
    meals.removeWhere((item) => item.id == id);
    await _persistCurrentLog();
  }

  Future<void> _persistCurrentLog() async {
    final log = DailyDietLog(
      date: selectedDateKey,
      meals: List<MealModel>.from(meals),
      dailyCalorieGoal: dailyCalorieGoal.value,
      proteinGoal: proteinGoal.value,
      carbsGoal: carbsGoal.value,
      fatsGoal: fatsGoal.value,
    );
    await _dietService.saveDailyLog(log);
  }
}
