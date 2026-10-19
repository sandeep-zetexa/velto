import 'package:velto/features/diet/models/ingredient.dart';
import 'package:velto/features/diet/models/meal_model.dart';

/// Represents a configured ingredient inside a saved or custom meal with its specific quantity.
class MealIngredientItem {
  final Ingredient ingredient;
  final double quantity;
  final String unit;

  const MealIngredientItem({
    required this.ingredient,
    required this.quantity,
    required this.unit,
  });

  /// Ratio of selected quantity compared to ingredient's base nutritionPer amount.
  double get ratio {
    final baseAmount = ingredient.nutritionPer.amount;
    if (baseAmount <= 0) return 1.0;
    return quantity / baseAmount;
  }

  /// Calculated calories for this quantity.
  int get calories => (ingredient.macros.calories * ratio).round();

  /// Calculated protein (in grams) for this quantity.
  double get protein => double.parse((ingredient.macros.protein * ratio).toStringAsFixed(1));

  /// Calculated carbs (in grams) for this quantity.
  double get carbs => double.parse((ingredient.macros.carbs * ratio).toStringAsFixed(1));

  /// Calculated fat (in grams) for this quantity.
  double get fat => double.parse((ingredient.macros.fat * ratio).toStringAsFixed(1));

  /// Calculated fiber (in grams) for this quantity.
  double get fiber => double.parse((ingredient.macros.fiber * ratio).toStringAsFixed(1));

  MealIngredientItem copyWith({
    Ingredient? ingredient,
    double? quantity,
    String? unit,
  }) {
    return MealIngredientItem(
      ingredient: ingredient ?? this.ingredient,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
    );
  }

  factory MealIngredientItem.fromJson(Map<String, dynamic> json) {
    return MealIngredientItem(
      ingredient: Ingredient.fromJson(json['ingredient']),
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'] ?? json['ingredient']['nutritionPer']['unit'] ?? 'g',
    );
  }

  Map<String, dynamic> toJson() => {
    'ingredient': ingredient.toJson(),
    'quantity': quantity,
    'unit': unit,
  };
}

/// Represents a user-saved meal or recipe composed of multiple ingredients.
class SavedMeal {
  final String id;
  final String name;
  final String category; // 'Breakfast', 'Lunch', 'Dinner', 'Snack'
  final int servings;
  final List<MealIngredientItem> items;

  const SavedMeal({
    required this.id,
    required this.name,
    required this.category,
    this.servings = 1,
    required this.items,
  });

  int get totalCalories => items.fold(0, (sum, item) => sum + item.calories);

  double get totalProtein => double.parse(
        items.fold(0.0, (sum, item) => sum + item.protein).toStringAsFixed(1),
      );

  double get totalCarbs => double.parse(
        items.fold(0.0, (sum, item) => sum + item.carbs).toStringAsFixed(1),
      );

  double get totalFat => double.parse(
        items.fold(0.0, (sum, item) => sum + item.fat).toStringAsFixed(1),
      );

  double get totalFiber => double.parse(
        items.fold(0.0, (sum, item) => sum + item.fiber).toStringAsFixed(1),
      );

  /// Converts this saved meal into a [MealModel] that can be logged into the daily diet tracker.
  MealModel toMealModel({String? time}) {
    final now = DateTime.now();
    final hour = now.hour;
    final minute = now.minute.toString().padLeft(2, '0');
    final ampm = hour >= 12 ? 'PM' : 'AM';
    final formattedHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final fallbackTime = '$formattedHour:$minute $ampm';

    return MealModel(
      id: '${id}_${DateTime.now().millisecondsSinceEpoch}',
      category: category,
      time: time ?? fallbackTime,
      title: name,
      calories: totalCalories,
      protein: totalProtein.round(),
      carbs: totalCarbs.round(),
      fats: totalFat.round(),
    );
  }

  factory SavedMeal.fromJson(Map<String, dynamic> json) {
    return SavedMeal(
      id: json['id'],
      name: json['name'],
      category: json['category'] ?? 'Snack',
      servings: json['servings'] ?? 1,
      items: (json['items'] as List<dynamic>)
          .map((item) => MealIngredientItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'servings': servings,
    'items': items.map((e) => e.toJson()).toList(),
  };

  SavedMeal copyWith({
    String? id,
    String? name,
    String? category,
    int? servings,
    List<MealIngredientItem>? items,
  }) {
    return SavedMeal(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      servings: servings ?? this.servings,
      items: items ?? this.items,
    );
  }
}
