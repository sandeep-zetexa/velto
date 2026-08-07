class Ingredient {
  final String id;
  final String name;
  final String? brand;
  final String category;
  final NutritionPer nutritionPer;
  final Macros macros;
  final Micros micros;

  const Ingredient({
    required this.id,
    required this.name,
    this.brand,
    required this.category,
    required this.nutritionPer,
    required this.macros,
    required this.micros,
  });

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      id: json['id'],
      name: json['name'],
      brand: json['brand'],
      category: json['category'],
      nutritionPer: NutritionPer.fromJson(json['nutritionPer']),
      macros: Macros.fromJson(json['macros']),
      micros: Micros.fromJson(json['micros']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'brand': brand,
    'category': category,
    'nutritionPer': nutritionPer.toJson(),
    'macros': macros.toJson(),
    'micros': micros.toJson(),
  };

  Ingredient copyWith({
    String? id,
    String? name,
    String? brand,
    String? category,
    NutritionPer? nutritionPer,
    Macros? macros,
    Micros? micros,
  }) {
    return Ingredient(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      category: category ?? this.category,
      nutritionPer: nutritionPer ?? this.nutritionPer,
      macros: macros ?? this.macros,
      micros: micros ?? this.micros,
    );
  }
}

class NutritionPer {
  final double amount;
  final String unit;

  const NutritionPer({
    required this.amount,
    required this.unit,
  });

  factory NutritionPer.fromJson(Map<String, dynamic> json) {
    return NutritionPer(
      amount: (json['amount'] as num).toDouble(),
      unit: json['unit'],
    );
  }

  Map<String, dynamic> toJson() => {
    'amount': amount,
    'unit': unit,
  };

  NutritionPer copyWith({
    double? amount,
    String? unit,
  }) {
    return NutritionPer(
      amount: amount ?? this.amount,
      unit: unit ?? this.unit,
    );
  }
}

class Macros {
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double sugar;

  const Macros({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.sugar,
  });

  factory Macros.fromJson(Map<String, dynamic> json) {
    return Macros(
      calories: (json['calories'] as num).toDouble(),
      protein: (json['protein'] as num).toDouble(),
      carbs: (json['carbs'] as num).toDouble(),
      fat: (json['fat'] as num).toDouble(),
      fiber: (json['fiber'] as num).toDouble(),
      sugar: (json['sugar'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
    'fiber': fiber,
    'sugar': sugar,
  };

  Macros copyWith({
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    double? fiber,
    double? sugar,
  }) {
    return Macros(
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      fiber: fiber ?? this.fiber,
      sugar: sugar ?? this.sugar,
    );
  }
}

class Micros {
  final double sodium;
  final double potassium;

  const Micros({
    required this.sodium,
    required this.potassium,
  });

  factory Micros.fromJson(Map<String, dynamic> json) {
    return Micros(
      sodium: (json['sodium'] as num).toDouble(),
      potassium: (json['potassium'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'sodium': sodium,
    'potassium': potassium,
  };

  Micros copyWith({
    double? sodium,
    double? potassium,
  }) {
    return Micros(
      sodium: sodium ?? this.sodium,
      potassium: potassium ?? this.potassium,
    );
  }
}