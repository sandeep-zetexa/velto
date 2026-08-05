import 'package:get/get.dart';
import 'package:velto/features/diet/models/meal_model.dart';

class DietController extends GetxController {
  final RxInt dailyCalorieGoal = 2200.obs;
  final RxInt proteinGoal = 150.obs;
  final RxInt carbsGoal = 220.obs;
  final RxInt fatsGoal = 70.obs;

  final RxList<MealModel> meals = <MealModel>[].obs;

  int get totalCalories => meals.fold(0, (sum, item) => sum + item.calories);
  int get remainingCalories => (dailyCalorieGoal.value - totalCalories).clamp(0, 9999);
  
  int get totalProtein => meals.fold(0, (sum, item) => sum + item.protein);
  int get totalCarbs => meals.fold(0, (sum, item) => sum + item.carbs);
  int get totalFats => meals.fold(0, (sum, item) => sum + item.fats);

  double get calorieProgress => (totalCalories / dailyCalorieGoal.value).clamp(0.0, 1.0);

  void addMeal(MealModel meal) {
    meals.insert(0, meal);
  }

  void removeMeal(String id) {
    meals.removeWhere((item) => item.id == id);
  }
}
