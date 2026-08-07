class Recipe {
  final String id;
  final String name;
  final int servings;
  final List<RecipeIngredient> ingredients;

  const Recipe({
    required this.id,
    required this.name,
    required this.servings,
    required this.ingredients,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'],
      name: json['name'],
      servings: json['servings'],
      ingredients: (json['ingredients'] as List)
          .map((e) => RecipeIngredient.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'servings': servings,
    'ingredients': ingredients.map((e) => e.toJson()).toList(),
  };
}

class RecipeIngredient {
  final String ingredientId;
  final double amount;
  final String unit;

  const RecipeIngredient({
    required this.ingredientId,
    required this.amount,
    required this.unit,
  });

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    return RecipeIngredient(
      ingredientId: json['ingredientId'],
      amount: (json['amount'] as num).toDouble(),
      unit: json['unit'],
    );
  }

  Map<String, dynamic> toJson() => {
    'ingredientId': ingredientId,
    'amount': amount,
    'unit': unit,
  };
}