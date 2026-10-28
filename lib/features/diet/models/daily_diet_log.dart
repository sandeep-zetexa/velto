import 'package:velto/features/diet/models/meal_model.dart';

/// Represents a persistent daily nutrition tracking log for a specific calendar date ("yyyy-MM-dd").
/// Preserves meals logged, eaten status, and macro totals for each date independently,
/// ensuring yesterday's tracked diet remains untouched when logging or changing plans today.
class DailyDietLog {
  final String date; // "yyyy-MM-dd"
  final List<MealModel> meals;
  final int dailyCalorieGoal;
  final int proteinGoal;
  final int carbsGoal;
  final int fatsGoal;

  const DailyDietLog({
    required this.date,
    this.meals = const [],
    this.dailyCalorieGoal = 2200,
    this.proteinGoal = 150,
    this.carbsGoal = 220,
    this.fatsGoal = 70,
  });

  int get totalCalories => meals.fold(0, (sum, m) => sum + m.calories);
  int get totalProtein => meals.fold(0, (sum, m) => sum + m.protein);
  int get totalCarbs => meals.fold(0, (sum, m) => sum + m.carbs);
  int get totalFats => meals.fold(0, (sum, m) => sum + m.fats);

  int get remainingCalories => (dailyCalorieGoal - totalCalories).clamp(0, 9999);
  double get calorieProgress => (totalCalories / dailyCalorieGoal).clamp(0.0, 1.0);

  DailyDietLog copyWith({
    String? date,
    List<MealModel>? meals,
    int? dailyCalorieGoal,
    int? proteinGoal,
    int? carbsGoal,
    int? fatsGoal,
  }) {
    return DailyDietLog(
      date: date ?? this.date,
      meals: meals ?? this.meals,
      dailyCalorieGoal: dailyCalorieGoal ?? this.dailyCalorieGoal,
      proteinGoal: proteinGoal ?? this.proteinGoal,
      carbsGoal: carbsGoal ?? this.carbsGoal,
      fatsGoal: fatsGoal ?? this.fatsGoal,
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date,
        'meals': meals.map((m) => m.toJson()).toList(),
        'dailyCalorieGoal': dailyCalorieGoal,
        'proteinGoal': proteinGoal,
        'carbsGoal': carbsGoal,
        'fatsGoal': fatsGoal,
      };

  factory DailyDietLog.fromJson(Map<String, dynamic> json) => DailyDietLog(
        date: json['date'] as String,
        meals: (json['meals'] as List<dynamic>?)
                ?.map((m) => MealModel.fromJson(Map<String, dynamic>.from(m as Map)))
                .toList() ??
            const [],
        dailyCalorieGoal: json['dailyCalorieGoal'] as int? ?? 2200,
        proteinGoal: json['proteinGoal'] as int? ?? 150,
        carbsGoal: json['carbsGoal'] as int? ?? 220,
        fatsGoal: json['fatsGoal'] as int? ?? 70,
      );
}
