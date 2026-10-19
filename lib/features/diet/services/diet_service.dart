import 'dart:convert';
import 'package:velto/features/diet/models/ingredient.dart';
import 'package:velto/features/diet/models/saved_meal.dart';

class DietService {
  DietService._internal();
  static final DietService _instance = DietService._internal();
  factory DietService() => _instance;

  // In-memory cache loaded initially from static JSON, allowing new additions during session.
  List<Ingredient>? _cachedIngredients;
  List<SavedMeal>? _cachedSavedMeals;

  /// Fetch ingredients catalog from static JSON data with optional search and category filters.
  Future<List<Ingredient>> getIngredients({String? query, String? category}) async {
    // Simulate slight network latency
    await Future.delayed(const Duration(milliseconds: 200));

    if (_cachedIngredients == null) {
      final decoded = jsonDecode(_staticIngredientsJson) as List<dynamic>;
      _cachedIngredients = decoded
          .map((item) => Ingredient.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    var list = _cachedIngredients!;

    if (category != null && category.isNotEmpty && category != 'All') {
      list = list
          .where((item) => item.category.toLowerCase() == category.toLowerCase())
          .toList();
    }

    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      list = list.where((item) {
        final matchesName = item.name.toLowerCase().contains(q);
        final matchesBrand = item.brand?.toLowerCase().contains(q) ?? false;
        final matchesCategory = item.category.toLowerCase().contains(q);
        return matchesName || matchesBrand || matchesCategory;
      }).toList();
    }

    return List.from(list);
  }

  /// Fetch saved meals list from static JSON data with optional search and category filters.
  Future<List<SavedMeal>> getSavedMeals({String? query, String? category}) async {
    // Simulate slight network latency
    await Future.delayed(const Duration(milliseconds: 200));

    if (_cachedSavedMeals == null) {
      final decoded = jsonDecode(_staticSavedMealsJson) as List<dynamic>;
      _cachedSavedMeals = decoded
          .map((item) => SavedMeal.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    var list = _cachedSavedMeals!;

    if (category != null && category.isNotEmpty && category != 'All') {
      list = list
          .where((item) => item.category.toLowerCase() == category.toLowerCase())
          .toList();
    }

    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      list = list.where((item) {
        final matchesName = item.name.toLowerCase().contains(q);
        final matchesCategory = item.category.toLowerCase().contains(q);
        final matchesIngredient = item.items.any(
          (i) => i.ingredient.name.toLowerCase().contains(q),
        );
        return matchesName || matchesCategory || matchesIngredient;
      }).toList();
    }

    return List.from(list);
  }

  /// Save a newly created custom meal.
  Future<SavedMeal> saveMeal(SavedMeal meal) async {
    await Future.delayed(const Duration(milliseconds: 250));

    if (_cachedSavedMeals == null) {
      await getSavedMeals();
    }

    // Insert at beginning of list
    _cachedSavedMeals!.insert(0, meal);
    return meal;
  }

  /// Update an existing saved meal.
  Future<SavedMeal> updateMeal(SavedMeal updatedMeal) async {
    await Future.delayed(const Duration(milliseconds: 200));

    if (_cachedSavedMeals == null) {
      await getSavedMeals();
    }

    final index = _cachedSavedMeals!.indexWhere((m) => m.id == updatedMeal.id);
    if (index >= 0) {
      _cachedSavedMeals![index] = updatedMeal;
    } else {
      _cachedSavedMeals!.insert(0, updatedMeal);
    }
    return updatedMeal;
  }

  /// Delete a saved meal by id.
  Future<bool> deleteMeal(String mealId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    if (_cachedSavedMeals == null) return false;
    final prevLength = _cachedSavedMeals!.length;
    _cachedSavedMeals!.removeWhere((m) => m.id == mealId);
    return _cachedSavedMeals!.length < prevLength;
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Static Mock JSON Data
  // ───────────────────────────────────────────────────────────────────────────

  static const String _staticIngredientsJson = '''
[
  {
    "id": "ing_chicken_breast",
    "name": "Raw Chicken Breast",
    "brand": null,
    "category": "Protein",
    "nutritionPer": {"amount": 100.0, "unit": "g"},
    "macros": {
      "calories": 165.0,
      "protein": 31.0,
      "carbs": 0.0,
      "fat": 3.6,
      "fiber": 0.0,
      "sugar": 0.0
    },
    "micros": {"sodium": 74.0, "potassium": 256.0}
  },
  {
    "id": "ing_grilled_chicken_breast",
    "name": "Grilled Chicken Breast",
    "brand": null,
    "category": "Protein",
    "nutritionPer": {"amount": 100.0, "unit": "g"},
    "macros": {
      "calories": 151.0,
      "protein": 30.5,
      "carbs": 0.0,
      "fat": 3.2,
      "fiber": 0.0,
      "sugar": 0.0
    },
    "micros": {"sodium": 85.0, "potassium": 280.0}
  },
  {
    "id": "ing_chicken_thigh",
    "name": "Chicken Thigh (Skinless, Boneless)",
    "brand": null,
    "category": "Protein",
    "nutritionPer": {"amount": 100.0, "unit": "g"},
    "macros": {
      "calories": 177.0,
      "protein": 24.0,
      "carbs": 0.0,
      "fat": 8.5,
      "fiber": 0.0,
      "sugar": 0.0
    },
    "micros": {"sodium": 82.0, "potassium": 260.0}
  },
  {
    "id": "ing_whole_egg",
    "name": "Whole Egg (Large)",
    "brand": null,
    "category": "Protein",
    "nutritionPer": {"amount": 50.0, "unit": "g"},
    "macros": {
      "calories": 74.0,
      "protein": 6.3,
      "carbs": 0.4,
      "fat": 5.0,
      "fiber": 0.0,
      "sugar": 0.2
    },
    "micros": {"sodium": 71.0, "potassium": 69.0}
  },
  {
    "id": "ing_egg_white",
    "name": "Egg White (Large)",
    "brand": null,
    "category": "Protein",
    "nutritionPer": {"amount": 33.0, "unit": "g"},
    "macros": {
      "calories": 17.0,
      "protein": 3.6,
      "carbs": 0.2,
      "fat": 0.1,
      "fiber": 0.0,
      "sugar": 0.2
    },
    "micros": {"sodium": 55.0, "potassium": 54.0}
  },
  {
    "id": "ing_boiled_egg",
    "name": "Hard Boiled Egg",
    "brand": null,
    "category": "Protein",
    "nutritionPer": {"amount": 50.0, "unit": "g"},
    "macros": {
      "calories": 77.0,
      "protein": 6.3,
      "carbs": 0.6,
      "fat": 5.3,
      "fiber": 0.0,
      "sugar": 0.6
    },
    "micros": {"sodium": 62.0, "potassium": 63.0}
  },
  {
    "id": "ing_canned_tuna",
    "name": "Canned Tuna in Water",
    "brand": "John West",
    "category": "Protein",
    "nutritionPer": {"amount": 100.0, "unit": "g"},
    "macros": {
      "calories": 116.0,
      "protein": 26.0,
      "carbs": 0.0,
      "fat": 0.8,
      "fiber": 0.0,
      "sugar": 0.0
    },
    "micros": {"sodium": 250.0, "potassium": 220.0}
  },
  {
    "id": "ing_salmon",
    "name": "Atlantic Salmon Fillet",
    "brand": null,
    "category": "Protein",
    "nutritionPer": {"amount": 100.0, "unit": "g"},
    "macros": {
      "calories": 206.0,
      "protein": 22.0,
      "carbs": 0.0,
      "fat": 12.5,
      "fiber": 0.0,
      "sugar": 0.0
    },
    "micros": {"sodium": 59.0, "potassium": 384.0}
  },
  {
    "id": "ing_ground_beef",
    "name": "Lean Minced Meat / Ground Beef (90/10)",
    "brand": null,
    "category": "Protein",
    "nutritionPer": {"amount": 100.0, "unit": "g"},
    "macros": {
      "calories": 176.0,
      "protein": 20.0,
      "carbs": 0.0,
      "fat": 10.0,
      "fiber": 0.0,
      "sugar": 0.0
    },
    "micros": {"sodium": 66.0, "potassium": 318.0}
  },
  {
    "id": "ing_shrimp",
    "name": "Peeled Shrimps / Prawns",
    "brand": null,
    "category": "Protein",
    "nutritionPer": {"amount": 100.0, "unit": "g"},
    "macros": {
      "calories": 99.0,
      "protein": 24.0,
      "carbs": 0.2,
      "fat": 0.3,
      "fiber": 0.0,
      "sugar": 0.0
    },
    "micros": {"sodium": 111.0, "potassium": 259.0}
  },
  {
    "id": "ing_turkey_breast",
    "name": "Smoked Turkey Breast Slices",
    "brand": null,
    "category": "Protein",
    "nutritionPer": {"amount": 50.0, "unit": "g"},
    "macros": {
      "calories": 52.0,
      "protein": 11.0,
      "carbs": 1.0,
      "fat": 0.8,
      "fiber": 0.0,
      "sugar": 0.5
    },
    "micros": {"sodium": 450.0, "potassium": 150.0}
  },
  {
    "id": "ing_paneer",
    "name": "Fresh Paneer (Cottage Cheese)",
    "brand": "Amul Malai Paneer",
    "category": "Protein",
    "nutritionPer": {"amount": 100.0, "unit": "g"},
    "macros": {
      "calories": 265.0,
      "protein": 18.3,
      "carbs": 3.6,
      "fat": 20.8,
      "fiber": 0.0,
      "sugar": 2.0
    },
    "micros": {"sodium": 22.0, "potassium": 75.0}
  },
  {
    "id": "ing_low_fat_paneer",
    "name": "Low-Fat Paneer",
    "brand": "Amul Lite",
    "category": "Protein",
    "nutritionPer": {"amount": 100.0, "unit": "g"},
    "macros": {
      "calories": 160.0,
      "protein": 25.0,
      "carbs": 4.0,
      "fat": 5.0,
      "fiber": 0.0,
      "sugar": 3.0
    },
    "micros": {"sodium": 30.0, "potassium": 90.0}
  },
  {
    "id": "ing_tofu",
    "name": "Firm Tofu",
    "brand": null,
    "category": "Protein",
    "nutritionPer": {"amount": 100.0, "unit": "g"},
    "macros": {
      "calories": 83.0,
      "protein": 10.0,
      "carbs": 2.0,
      "fat": 4.8,
      "fiber": 1.0,
      "sugar": 0.5
    },
    "micros": {"sodium": 10.0, "potassium": 120.0}
  },
  {
    "id": "ing_soya_chunks",
    "name": "Soya Chunks / Soya Vadi",
    "brand": "Nutrela",
    "category": "Protein",
    "nutritionPer": {"amount": 50.0, "unit": "g"},
    "macros": {
      "calories": 173.0,
      "protein": 26.0,
      "carbs": 16.5,
      "fat": 0.3,
      "fiber": 6.5,
      "sugar": 0.0
    },
    "micros": {"sodium": 5.0, "potassium": 320.0}
  },
  {
    "id": "ing_rolled_oats",
    "name": "Rolled Oats",
    "brand": "Quaker",
    "category": "Grains",
    "nutritionPer": {"amount": 50.0, "unit": "g"},
    "macros": {
      "calories": 194.0,
      "protein": 6.8,
      "carbs": 33.2,
      "fat": 3.6,
      "fiber": 5.1,
      "sugar": 0.8
    },
    "micros": {"sodium": 2.0, "potassium": 180.0}
  },
  {
    "id": "ing_instant_oats",
    "name": "Instant Quick Oats",
    "brand": "Kellogg's",
    "category": "Grains",
    "nutritionPer": {"amount": 40.0, "unit": "g"},
    "macros": {
      "calories": 150.0,
      "protein": 5.0,
      "carbs": 27.0,
      "fat": 2.5,
      "fiber": 4.0,
      "sugar": 1.0
    },
    "micros": {"sodium": 3.0, "potassium": 140.0}
  },
  {
    "id": "ing_white_rice",
    "name": "Cooked Basmati White Rice",
    "brand": "India Gate",
    "category": "Grains",
    "nutritionPer": {"amount": 100.0, "unit": "g"},
    "macros": {
      "calories": 130.0,
      "protein": 2.7,
      "carbs": 28.2,
      "fat": 0.3,
      "fiber": 0.4,
      "sugar": 0.1
    },
    "micros": {"sodium": 1.0, "potassium": 35.0}
  },
  {
    "id": "ing_brown_rice",
    "name": "Cooked Brown Rice",
    "brand": "Daawat",
    "category": "Grains",
    "nutritionPer": {"amount": 100.0, "unit": "g"},
    "macros": {
      "calories": 112.0,
      "protein": 2.6,
      "carbs": 23.5,
      "fat": 0.9,
      "fiber": 1.8,
      "sugar": 0.2
    },
    "micros": {"sodium": 1.0, "potassium": 43.0}
  },
  {
    "id": "ing_roti",
    "name": "Whole Wheat Roti / Chapati (1 Roti)",
    "brand": null,
    "category": "Grains",
    "nutritionPer": {"amount": 35.0, "unit": "g"},
    "macros": {
      "calories": 90.0,
      "protein": 3.2,
      "carbs": 17.5,
      "fat": 1.2,
      "fiber": 2.8,
      "sugar": 0.2
    },
    "micros": {"sodium": 4.0, "potassium": 95.0}
  },
  {
    "id": "ing_brown_bread",
    "name": "Brown Bread (1 Slice)",
    "brand": "Harvest Gold",
    "category": "Grains",
    "nutritionPer": {"amount": 40.0, "unit": "g"},
    "macros": {
      "calories": 95.0,
      "protein": 3.8,
      "carbs": 17.5,
      "fat": 1.2,
      "fiber": 2.4,
      "sugar": 1.8
    },
    "micros": {"sodium": 140.0, "potassium": 80.0}
  },
  {
    "id": "ing_white_bread",
    "name": "White Bread (1 Slice)",
    "brand": "Britannia",
    "category": "Grains",
    "nutritionPer": {"amount": 30.0, "unit": "g"},
    "macros": {
      "calories": 80.0,
      "protein": 2.6,
      "carbs": 15.0,
      "fat": 1.0,
      "fiber": 0.8,
      "sugar": 1.5
    },
    "micros": {"sodium": 150.0, "potassium": 40.0}
  },
  {
    "id": "ing_sourdough_bread",
    "name": "Artisan Sourdough Bread (1 Slice)",
    "brand": null,
    "category": "Grains",
    "nutritionPer": {"amount": 50.0, "unit": "g"},
    "macros": {
      "calories": 120.0,
      "protein": 4.5,
      "carbs": 23.0,
      "fat": 1.0,
      "fiber": 1.5,
      "sugar": 0.5
    },
    "micros": {"sodium": 210.0, "potassium": 60.0}
  },
  {
    "id": "ing_sweet_potato",
    "name": "Boiled Sweet Potato",
    "brand": null,
    "category": "Grains",
    "nutritionPer": {"amount": 100.0, "unit": "g"},
    "macros": {
      "calories": 86.0,
      "protein": 1.6,
      "carbs": 20.1,
      "fat": 0.1,
      "fiber": 3.0,
      "sugar": 4.2
    },
    "micros": {"sodium": 55.0, "potassium": 337.0}
  },
  {
    "id": "ing_boiled_potato",
    "name": "Boiled Potato",
    "brand": null,
    "category": "Grains",
    "nutritionPer": {"amount": 100.0, "unit": "g"},
    "macros": {
      "calories": 87.0,
      "protein": 1.9,
      "carbs": 20.1,
      "fat": 0.1,
      "fiber": 1.8,
      "sugar": 0.9
    },
    "micros": {"sodium": 4.0, "potassium": 379.0}
  },
  {
    "id": "ing_quinoa",
    "name": "Cooked Quinoa",
    "brand": "True Elements",
    "category": "Grains",
    "nutritionPer": {"amount": 100.0, "unit": "g"},
    "macros": {
      "calories": 120.0,
      "protein": 4.4,
      "carbs": 21.3,
      "fat": 1.9,
      "fiber": 2.8,
      "sugar": 0.9
    },
    "micros": {"sodium": 7.0, "potassium": 172.0}
  },
  {
    "id": "ing_wheat_pasta",
    "name": "Cooked Whole Wheat Pasta",
    "brand": "Barilla",
    "category": "Grains",
    "nutritionPer": {"amount": 100.0, "unit": "g"},
    "macros": {
      "calories": 124.0,
      "protein": 5.3,
      "carbs": 26.5,
      "fat": 0.5,
      "fiber": 3.9,
      "sugar": 0.8
    },
    "micros": {"sodium": 4.0, "potassium": 85.0}
  },
  {
    "id": "ing_rice_cakes",
    "name": "Crispy Rice Cakes (Plain / Salted)",
    "brand": null,
    "category": "Grains",
    "nutritionPer": {"amount": 18.0, "unit": "g"},
    "macros": {
      "calories": 70.0,
      "protein": 1.5,
      "carbs": 15.0,
      "fat": 0.5,
      "fiber": 0.8,
      "sugar": 0.1
    },
    "micros": {"sodium": 25.0, "potassium": 45.0}
  },
  {
    "id": "ing_muesli",
    "name": "Fruit & Nut Muesli",
    "brand": "Kellogg's",
    "category": "Grains",
    "nutritionPer": {"amount": 40.0, "unit": "g"},
    "macros": {
      "calories": 155.0,
      "protein": 3.5,
      "carbs": 28.0,
      "fat": 3.2,
      "fiber": 3.5,
      "sugar": 7.5
    },
    "micros": {"sodium": 60.0, "potassium": 160.0}
  },
  {
    "id": "ing_moong_dal",
    "name": "Yellow Moong Dal (Cooked)",
    "brand": null,
    "category": "Legumes",
    "nutritionPer": {"amount": 100.0, "unit": "g"},
    "macros": {
      "calories": 105.0,
      "protein": 7.0,
      "carbs": 18.0,
      "fat": 0.4,
      "fiber": 4.0,
      "sugar": 1.0
    },
    "micros": {"sodium": 5.0, "potassium": 190.0}
  },
  {
    "id": "ing_masoor_dal",
    "name": "Red Lentils / Masoor Dal (Cooked)",
    "brand": null,
    "category": "Legumes",
    "nutritionPer": {"amount": 100.0, "unit": "g"},
    "macros": {
      "calories": 116.0,
      "protein": 9.0,
      "carbs": 20.1,
      "fat": 0.4,
      "fiber": 7.9,
      "sugar": 1.8
    },
    "micros": {"sodium": 2.0, "potassium": 369.0}
  },
  {
    "id": "ing_toor_dal",
    "name": "Toor Dal / Arhar Dal (Cooked)",
    "brand": null,
    "category": "Legumes",
    "nutritionPer": {"amount": 100.0, "unit": "g"},
    "macros": {
      "calories": 110.0,
      "protein": 7.2,
      "carbs": 19.5,
      "fat": 0.6,
      "fiber": 5.0,
      "sugar": 1.2
    },
    "micros": {"sodium": 4.0, "potassium": 240.0}
  },
  {
    "id": "ing_chickpeas",
    "name": "Boiled Chickpeas / Chana",
    "brand": null,
    "category": "Legumes",
    "nutritionPer": {"amount": 100.0, "unit": "g"},
    "macros": {
      "calories": 164.0,
      "protein": 8.9,
      "carbs": 27.4,
      "fat": 2.6,
      "fiber": 7.6,
      "sugar": 4.8
    },
    "micros": {"sodium": 7.0, "potassium": 291.0}
  },
  {
    "id": "ing_kidney_beans",
    "name": "Boiled Kidney Beans / Rajma",
    "brand": null,
    "category": "Legumes",
    "nutritionPer": {"amount": 100.0, "unit": "g"},
    "macros": {
      "calories": 127.0,
      "protein": 8.7,
      "carbs": 22.8,
      "fat": 0.5,
      "fiber": 6.4,
      "sugar": 0.3
    },
    "micros": {"sodium": 2.0, "potassium": 405.0}
  },
  {
    "id": "ing_black_beans",
    "name": "Boiled Black Beans",
    "brand": null,
    "category": "Legumes",
    "nutritionPer": {"amount": 100.0, "unit": "g"},
    "macros": {
      "calories": 132.0,
      "protein": 8.9,
      "carbs": 23.7,
      "fat": 0.5,
      "fiber": 8.7,
      "sugar": 0.3
    },
    "micros": {"sodium": 1.0, "potassium": 355.0}
  },
  {
    "id": "ing_green_peas",
    "name": "Boiled Green Peas / Matar",
    "brand": null,
    "category": "Legumes",
    "nutritionPer": {"amount": 100.0, "unit": "g"},
    "macros": {
      "calories": 81.0,
      "protein": 5.4,
      "carbs": 14.5,
      "fat": 0.4,
      "fiber": 5.1,
      "sugar": 5.7
    },
    "micros": {"sodium": 5.0, "potassium": 244.0}
  },
  {
    "id": "ing_sprouted_moong",
    "name": "Sprouted Moong Beans",
    "brand": null,
    "category": "Legumes",
    "nutritionPer": {"amount": 100.0, "unit": "g"},
    "macros": {
      "calories": 30.0,
      "protein": 3.0,
      "carbs": 5.9,
      "fat": 0.2,
      "fiber": 1.8,
      "sugar": 4.1
    },
    "micros": {"sodium": 6.0, "potassium": 149.0}
  },
  {
    "id": "ing_edamame",
    "name": "Steamed Edamame",
    "brand": null,
    "category": "Legumes",
    "nutritionPer": {"amount": 100.0, "unit": "g"},
    "macros": {
      "calories": 122.0,
      "protein": 11.9,
      "carbs": 8.9,
      "fat": 5.2,
      "fiber": 5.2,
      "sugar": 2.2
    },
    "micros": {"sodium": 6.0, "potassium": 436.0}
  },
  {
    "id": "ing_toned_milk",
    "name": "Toned Milk (3% Fat)",
    "brand": "Amul Taaza",
    "category": "Dairy",
    "nutritionPer": {"amount": 100.0, "unit": "ml"},
    "macros": {
      "calories": 58.0,
      "protein": 3.1,
      "carbs": 4.7,
      "fat": 3.0,
      "fiber": 0.0,
      "sugar": 4.7
    },
    "micros": {"sodium": 50.0, "potassium": 140.0}
  },
  {
    "id": "ing_whole_milk",
    "name": "Whole Milk (6% Fat)",
    "brand": "Amul Gold",
    "category": "Dairy",
    "nutritionPer": {"amount": 100.0, "unit": "ml"},
    "macros": {
      "calories": 88.0,
      "protein": 3.4,
      "carbs": 5.0,
      "fat": 6.0,
      "fiber": 0.0,
      "sugar": 5.0
    },
    "micros": {"sodium": 48.0, "potassium": 135.0}
  },
  {
    "id": "ing_skimmed_milk",
    "name": "Skimmed Milk (0.5% Fat)",
    "brand": "Amul Slim 'n' Trim",
    "category": "Dairy",
    "nutritionPer": {"amount": 100.0, "unit": "ml"},
    "macros": {
      "calories": 35.0,
      "protein": 3.2,
      "carbs": 4.8,
      "fat": 0.2,
      "fiber": 0.0,
      "sugar": 4.8
    },
    "micros": {"sodium": 52.0, "potassium": 150.0}
  },
  {
    "id": "ing_greek_yogurt",
    "name": "Greek Yogurt (Plain, 0% Fat)",
    "brand": "Epigamia",
    "category": "Dairy",
    "nutritionPer": {"amount": 100.0, "unit": "g"},
    "macros": {
      "calories": 60.0,
      "protein": 8.5,
      "carbs": 4.5,
      "fat": 0.2,
      "fiber": 0.0,
      "sugar": 4.0
    },
    "micros": {"sodium": 36.0, "potassium": 141.0}
  },
  {
    "id": "ing_curd",
    "name": "Plain Curd / Dahi",
    "brand": "Amul Masti Dahi",
    "category": "Dairy",
    "nutritionPer": {"amount": 100.0, "unit": "g"},
    "macros": {
      "calories": 65.0,
      "protein": 3.5,
      "carbs": 4.7,
      "fat": 3.8,
      "fiber": 0.0,
      "sugar": 4.7
    },
    "micros": {"sodium": 45.0, "potassium": 150.0}
  },
  {
    "id": "ing_almond_milk",
    "name": "Unsweetened Almond Milk",
    "brand": "Raw Pressery",
    "category": "Dairy",
    "nutritionPer": {"amount": 100.0, "unit": "ml"},
    "macros": {
      "calories": 15.0,
      "protein": 0.5,
      "carbs": 0.3,
      "fat": 1.2,
      "fiber": 0.4,
      "sugar": 0.0
    },
    "micros": {"sodium": 65.0, "potassium": 60.0}
  },
  {
    "id": "ing_soy_milk",
    "name": "Unsweetened Soy Milk",
    "brand": "Sofit",
    "category": "Dairy",
    "nutritionPer": {"amount": 100.0, "unit": "ml"},
    "macros": {
      "calories": 38.0,
      "protein": 3.2,
      "carbs": 1.8,
      "fat": 1.8,
      "fiber": 0.8,
      "sugar": 0.4
    },
    "micros": {"sodium": 40.0, "potassium": 120.0}
  },
  {
    "id": "ing_oat_milk",
    "name": "Barista Oat Milk",
    "brand": "Oatly",
    "category": "Dairy",
    "nutritionPer": {"amount": 100.0, "unit": "ml"},
    "macros": {
      "calories": 46.0,
      "protein": 1.0,
      "carbs": 6.7,
      "fat": 1.5,
      "fiber": 0.8,
      "sugar": 4.1
    },
    "micros": {"sodium": 42.0, "potassium": 130.0}
  },
  {
    "id": "ing_cheddar_cheese",
    "name": "Cheddar Cheese (1 Slice)",
    "brand": "Amul",
    "category": "Dairy",
    "nutritionPer": {"amount": 25.0, "unit": "g"},
    "macros": {
      "calories": 100.0,
      "protein": 6.5,
      "carbs": 0.5,
      "fat": 8.2,
      "fiber": 0.0,
      "sugar": 0.1
    },
    "micros": {"sodium": 180.0, "potassium": 25.0}
  },
  {
    "id": "ing_mozzarella",
    "name": "Part-Skim Mozzarella",
    "brand": null,
    "category": "Dairy",
    "nutritionPer": {"amount": 30.0, "unit": "g"},
    "macros": {
      "calories": 85.0,
      "protein": 6.8,
      "carbs": 0.8,
      "fat": 6.3,
      "fiber": 0.0,
      "sugar": 0.3
    },
    "micros": {"sodium": 175.0, "potassium": 30.0}
  },
  {
    "id": "ing_broccoli",
    "name": "Steamed Fresh Broccoli",
    "brand": null,
    "category": "Vegetables",
    "nutritionPer": {"amount": 100.0, "unit": "g"},
    "macros": {
      "calories": 35.0,
      "protein": 2.4,
      "carbs": 7.2,
      "fat": 0.4,
      "fiber": 2.6,
      "sugar": 1.4
    },
    "micros": {"sodium": 33.0, "potassium": 316.0}
  },
  {
    "id": "ing_spinach",
    "name": "Fresh Baby Spinach / Palak",
    "brand": null,
    "category": "Vegetables",
    "nutritionPer": {"amount": 100.0, "unit": "g"},
    "macros": {
      "calories": 23.0,
      "protein": 2.9,
      "carbs": 3.6,
      "fat": 0.4,
      "fiber": 2.2,
      "sugar": 0.4
    },
    "micros": {"sodium": 79.0, "potassium": 558.0}
  },
  {
    "id": "ing_onion",
    "name": "Red Onion (Chopped)",
    "brand": null,
    "category": "Vegetables",
    "nutritionPer": {"amount": 100.0, "unit": "g"},
    "macros": {
      "calories": 40.0,
      "protein": 1.1,
      "carbs": 9.3,
      "fat": 0.1,
      "fiber": 1.7,
      "sugar": 4.2
    },
    "micros": {"sodium": 4.0, "potassium": 146.0}
  },
  {
    "id": "ing_tomatoes",
    "name": "Ripe Red Tomatoes",
    "brand": null,
    "category": "Vegetables",
    "nutritionPer": {"amount": 100.0, "unit": "g"},
    "macros": {
      "calories": 18.0,
      "protein": 0.9,
      "carbs": 3.9,
      "fat": 0.2,
      "fiber": 1.2,
      "sugar": 2.6
    },
    "micros": {"sodium": 5.0, "potassium": 237.0}
  },
  {
    "id": "ing_cucumber",
    "name": "Fresh Cucumber / Kheera",
    "brand": null,
    "category": "Vegetables",
    "nutritionPer": {"amount": 100.0, "unit": "g"},
    "macros": {
      "calories": 15.0,
      "protein": 0.7,
      "carbs": 3.6,
      "fat": 0.1,
      "fiber": 0.5,
      "sugar": 1.7
    },
    "micros": {"sodium": 2.0, "potassium": 147.0}
  },
  {
    "id": "ing_capsicum",
    "name": "Green Bell Pepper / Capsicum",
    "brand": null,
    "category": "Vegetables",
    "nutritionPer": {"amount": 100.0, "unit": "g"},
    "macros": {
      "calories": 20.0,
      "protein": 0.9,
      "carbs": 4.6,
      "fat": 0.2,
      "fiber": 1.7,
      "sugar": 2.4
    },
    "micros": {"sodium": 3.0, "potassium": 175.0}
  },
  {
    "id": "ing_carrots",
    "name": "Fresh Carrots",
    "brand": null,
    "category": "Vegetables",
    "nutritionPer": {"amount": 100.0, "unit": "g"},
    "macros": {
      "calories": 41.0,
      "protein": 0.9,
      "carbs": 9.6,
      "fat": 0.2,
      "fiber": 2.8,
      "sugar": 4.7
    },
    "micros": {"sodium": 69.0, "potassium": 320.0}
  },
  {
    "id": "ing_cauliflower",
    "name": "Cauliflower Florets / Gobi",
    "brand": null,
    "category": "Vegetables",
    "nutritionPer": {"amount": 100.0, "unit": "g"},
    "macros": {
      "calories": 25.0,
      "protein": 1.9,
      "carbs": 5.0,
      "fat": 0.3,
      "fiber": 2.0,
      "sugar": 1.9
    },
    "micros": {"sodium": 30.0, "potassium": 299.0}
  },
  {
    "id": "ing_mushrooms",
    "name": "Fresh Button Mushrooms",
    "brand": null,
    "category": "Vegetables",
    "nutritionPer": {"amount": 100.0, "unit": "g"},
    "macros": {
      "calories": 22.0,
      "protein": 3.1,
      "carbs": 3.3,
      "fat": 0.3,
      "fiber": 1.0,
      "sugar": 2.0
    },
    "micros": {"sodium": 5.0, "potassium": 318.0}
  },
  {
    "id": "ing_zucchini",
    "name": "Zucchini (Sliced)",
    "brand": null,
    "category": "Vegetables",
    "nutritionPer": {"amount": 100.0, "unit": "g"},
    "macros": {
      "calories": 17.0,
      "protein": 1.2,
      "carbs": 3.1,
      "fat": 0.3,
      "fiber": 1.0,
      "sugar": 2.5
    },
    "micros": {"sodium": 8.0, "potassium": 261.0}
  },
  {
    "id": "ing_green_beans",
    "name": "Fresh Green French Beans",
    "brand": null,
    "category": "Vegetables",
    "nutritionPer": {"amount": 100.0, "unit": "g"},
    "macros": {
      "calories": 31.0,
      "protein": 1.8,
      "carbs": 7.0,
      "fat": 0.2,
      "fiber": 2.7,
      "sugar": 3.3
    },
    "micros": {"sodium": 6.0, "potassium": 211.0}
  },
  {
    "id": "ing_lettuce",
    "name": "Crisp Romaine Lettuce",
    "brand": null,
    "category": "Vegetables",
    "nutritionPer": {"amount": 100.0, "unit": "g"},
    "macros": {
      "calories": 17.0,
      "protein": 1.2,
      "carbs": 3.3,
      "fat": 0.3,
      "fiber": 2.1,
      "sugar": 1.2
    },
    "micros": {"sodium": 8.0, "potassium": 247.0}
  },
  {
    "id": "ing_sweet_corn",
    "name": "Boiled Sweet Corn",
    "brand": null,
    "category": "Vegetables",
    "nutritionPer": {"amount": 100.0, "unit": "g"},
    "macros": {
      "calories": 86.0,
      "protein": 3.2,
      "carbs": 19.0,
      "fat": 1.2,
      "fiber": 2.7,
      "sugar": 6.3
    },
    "micros": {"sodium": 15.0, "potassium": 270.0}
  },
  {
    "id": "ing_banana",
    "name": "Fresh Banana",
    "brand": null,
    "category": "Fruits",
    "nutritionPer": {"amount": 100.0, "unit": "g"},
    "macros": {
      "calories": 89.0,
      "protein": 1.1,
      "carbs": 22.8,
      "fat": 0.3,
      "fiber": 2.6,
      "sugar": 12.2
    },
    "micros": {"sodium": 1.0, "potassium": 358.0}
  },
  {
    "id": "ing_apple",
    "name": "Crisp Red Apple",
    "brand": null,
    "category": "Fruits",
    "nutritionPer": {"amount": 150.0, "unit": "g"},
    "macros": {
      "calories": 78.0,
      "protein": 0.4,
      "carbs": 20.8,
      "fat": 0.3,
      "fiber": 3.6,
      "sugar": 15.5
    },
    "micros": {"sodium": 1.5, "potassium": 160.0}
  },
  {
    "id": "ing_blueberries",
    "name": "Fresh Blueberries",
    "brand": null,
    "category": "Fruits",
    "nutritionPer": {"amount": 100.0, "unit": "g"},
    "macros": {
      "calories": 57.0,
      "protein": 0.7,
      "carbs": 14.5,
      "fat": 0.3,
      "fiber": 2.4,
      "sugar": 9.9
    },
    "micros": {"sodium": 1.0, "potassium": 77.0}
  },
  {
    "id": "ing_strawberries",
    "name": "Fresh Strawberries",
    "brand": null,
    "category": "Fruits",
    "nutritionPer": {"amount": 100.0, "unit": "g"},
    "macros": {
      "calories": 32.0,
      "protein": 0.7,
      "carbs": 7.7,
      "fat": 0.3,
      "fiber": 2.0,
      "sugar": 4.9
    },
    "micros": {"sodium": 1.0, "potassium": 153.0}
  },
  {
    "id": "ing_orange",
    "name": "Juicy Fresh Orange",
    "brand": null,
    "category": "Fruits",
    "nutritionPer": {"amount": 130.0, "unit": "g"},
    "macros": {
      "calories": 62.0,
      "protein": 1.2,
      "carbs": 15.4,
      "fat": 0.2,
      "fiber": 3.1,
      "sugar": 12.2
    },
    "micros": {"sodium": 0.0, "potassium": 237.0}
  },
  {
    "id": "ing_watermelon",
    "name": "Fresh Sweet Watermelon",
    "brand": null,
    "category": "Fruits",
    "nutritionPer": {"amount": 150.0, "unit": "g"},
    "macros": {
      "calories": 45.0,
      "protein": 0.9,
      "carbs": 11.4,
      "fat": 0.2,
      "fiber": 0.6,
      "sugar": 9.4
    },
    "micros": {"sodium": 2.0, "potassium": 170.0}
  },
  {
    "id": "ing_papaya",
    "name": "Ripe Papaya",
    "brand": null,
    "category": "Fruits",
    "nutritionPer": {"amount": 100.0, "unit": "g"},
    "macros": {
      "calories": 43.0,
      "protein": 0.5,
      "carbs": 10.8,
      "fat": 0.3,
      "fiber": 1.7,
      "sugar": 7.8
    },
    "micros": {"sodium": 8.0, "potassium": 182.0}
  },
  {
    "id": "ing_mango",
    "name": "Fresh Mango Slices",
    "brand": null,
    "category": "Fruits",
    "nutritionPer": {"amount": 100.0, "unit": "g"},
    "macros": {
      "calories": 60.0,
      "protein": 0.8,
      "carbs": 15.0,
      "fat": 0.4,
      "fiber": 1.6,
      "sugar": 13.7
    },
    "micros": {"sodium": 1.0, "potassium": 168.0}
  },
  {
    "id": "ing_grapes",
    "name": "Seedless Table Grapes",
    "brand": null,
    "category": "Fruits",
    "nutritionPer": {"amount": 100.0, "unit": "g"},
    "macros": {
      "calories": 69.0,
      "protein": 0.7,
      "carbs": 18.1,
      "fat": 0.2,
      "fiber": 0.9,
      "sugar": 15.5
    },
    "micros": {"sodium": 2.0, "potassium": 191.0}
  },
  {
    "id": "ing_pineapple",
    "name": "Fresh Pineapple Chunks",
    "brand": null,
    "category": "Fruits",
    "nutritionPer": {"amount": 100.0, "unit": "g"},
    "macros": {
      "calories": 50.0,
      "protein": 0.5,
      "carbs": 13.1,
      "fat": 0.1,
      "fiber": 1.4,
      "sugar": 9.9
    },
    "micros": {"sodium": 1.0, "potassium": 109.0}
  },
  {
    "id": "ing_pomegranate",
    "name": "Pomegranate Arils (Seeds)",
    "brand": null,
    "category": "Fruits",
    "nutritionPer": {"amount": 100.0, "unit": "g"},
    "macros": {
      "calories": 83.0,
      "protein": 1.7,
      "carbs": 18.7,
      "fat": 1.2,
      "fiber": 4.0,
      "sugar": 13.7
    },
    "micros": {"sodium": 3.0, "potassium": 236.0}
  },
  {
    "id": "ing_avocado",
    "name": "Hass Avocado",
    "brand": null,
    "category": "Fruits",
    "nutritionPer": {"amount": 50.0, "unit": "g"},
    "macros": {
      "calories": 80.0,
      "protein": 1.0,
      "carbs": 4.3,
      "fat": 7.3,
      "fiber": 3.4,
      "sugar": 0.3
    },
    "micros": {"sodium": 4.0, "potassium": 243.0}
  },
  {
    "id": "ing_dates",
    "name": "Medjool Dates (2 Dates)",
    "brand": null,
    "category": "Fruits",
    "nutritionPer": {"amount": 48.0, "unit": "g"},
    "macros": {
      "calories": 133.0,
      "protein": 0.9,
      "carbs": 36.0,
      "fat": 0.1,
      "fiber": 3.2,
      "sugar": 32.0
    },
    "micros": {"sodium": 1.0, "potassium": 335.0}
  },
  {
    "id": "ing_almonds",
    "name": "Raw California Almonds",
    "brand": null,
    "category": "Nuts & Seeds",
    "nutritionPer": {"amount": 30.0, "unit": "g"},
    "macros": {
      "calories": 173.0,
      "protein": 6.3,
      "carbs": 6.1,
      "fat": 15.0,
      "fiber": 3.5,
      "sugar": 1.2
    },
    "micros": {"sodium": 1.0, "potassium": 210.0}
  },
  {
    "id": "ing_walnuts",
    "name": "Raw Walnuts (Akhrot)",
    "brand": null,
    "category": "Nuts & Seeds",
    "nutritionPer": {"amount": 30.0, "unit": "g"},
    "macros": {
      "calories": 196.0,
      "protein": 4.6,
      "carbs": 4.1,
      "fat": 19.6,
      "fiber": 2.0,
      "sugar": 0.8
    },
    "micros": {"sodium": 1.0, "potassium": 132.0}
  },
  {
    "id": "ing_cashews",
    "name": "Whole Cashews (Kaju)",
    "brand": null,
    "category": "Nuts & Seeds",
    "nutritionPer": {"amount": 30.0, "unit": "g"},
    "macros": {
      "calories": 166.0,
      "protein": 5.5,
      "carbs": 9.1,
      "fat": 13.1,
      "fiber": 1.0,
      "sugar": 1.8
    },
    "micros": {"sodium": 4.0, "potassium": 198.0}
  },
  {
    "id": "ing_chia_seeds",
    "name": "Organic Chia Seeds",
    "brand": "True Elements",
    "category": "Nuts & Seeds",
    "nutritionPer": {"amount": 15.0, "unit": "g"},
    "macros": {
      "calories": 73.0,
      "protein": 2.5,
      "carbs": 6.3,
      "fat": 4.6,
      "fiber": 5.1,
      "sugar": 0.0
    },
    "micros": {"sodium": 2.0, "potassium": 61.0}
  },
  {
    "id": "ing_flax_seeds",
    "name": "Ground Flax Seeds",
    "brand": null,
    "category": "Nuts & Seeds",
    "nutritionPer": {"amount": 15.0, "unit": "g"},
    "macros": {
      "calories": 80.0,
      "protein": 2.7,
      "carbs": 4.3,
      "fat": 6.3,
      "fiber": 4.1,
      "sugar": 0.2
    },
    "micros": {"sodium": 4.0, "potassium": 122.0}
  },
  {
    "id": "ing_pumpkin_seeds",
    "name": "Raw Pumpkin Seeds",
    "brand": null,
    "category": "Nuts & Seeds",
    "nutritionPer": {"amount": 20.0, "unit": "g"},
    "macros": {
      "calories": 114.0,
      "protein": 6.0,
      "carbs": 2.8,
      "fat": 9.8,
      "fiber": 1.3,
      "sugar": 0.3
    },
    "micros": {"sodium": 4.0, "potassium": 160.0}
  },
  {
    "id": "ing_peanut_butter",
    "name": "Natural Peanut Butter (Crunchy)",
    "brand": "Pintola",
    "category": "Nuts & Seeds",
    "nutritionPer": {"amount": 32.0, "unit": "g"},
    "macros": {
      "calories": 190.0,
      "protein": 8.0,
      "carbs": 7.0,
      "fat": 16.0,
      "fiber": 2.0,
      "sugar": 2.0
    },
    "micros": {"sodium": 5.0, "potassium": 210.0}
  },
  {
    "id": "ing_almond_butter",
    "name": "All-Natural Almond Butter",
    "brand": "The Whole Truth",
    "category": "Nuts & Seeds",
    "nutritionPer": {"amount": 32.0, "unit": "g"},
    "macros": {
      "calories": 196.0,
      "protein": 7.0,
      "carbs": 6.0,
      "fat": 18.0,
      "fiber": 3.3,
      "sugar": 1.4
    },
    "micros": {"sodium": 2.0, "potassium": 240.0}
  },
  {
    "id": "ing_olive_oil",
    "name": "Extra Virgin Olive Oil",
    "brand": "Borges",
    "category": "Oils & Fats",
    "nutritionPer": {"amount": 10.0, "unit": "ml"},
    "macros": {
      "calories": 88.0,
      "protein": 0.0,
      "carbs": 0.0,
      "fat": 10.0,
      "fiber": 0.0,
      "sugar": 0.0
    },
    "micros": {"sodium": 0.0, "potassium": 0.0}
  },
  {
    "id": "ing_ghee",
    "name": "Pure Desi Cow Ghee",
    "brand": "Amul",
    "category": "Oils & Fats",
    "nutritionPer": {"amount": 10.0, "unit": "g"},
    "macros": {
      "calories": 90.0,
      "protein": 0.0,
      "carbs": 0.0,
      "fat": 10.0,
      "fiber": 0.0,
      "sugar": 0.0
    },
    "micros": {"sodium": 0.0, "potassium": 0.0}
  },
  {
    "id": "ing_coconut_oil",
    "name": "Virgin Cold-Pressed Coconut Oil",
    "brand": "Maxcare",
    "category": "Oils & Fats",
    "nutritionPer": {"amount": 10.0, "unit": "ml"},
    "macros": {
      "calories": 86.0,
      "protein": 0.0,
      "carbs": 0.0,
      "fat": 10.0,
      "fiber": 0.0,
      "sugar": 0.0
    },
    "micros": {"sodium": 0.0, "potassium": 0.0}
  },
  {
    "id": "ing_butter",
    "name": "Table Butter (Salted)",
    "brand": "Amul",
    "category": "Oils & Fats",
    "nutritionPer": {"amount": 10.0, "unit": "g"},
    "macros": {
      "calories": 72.0,
      "protein": 0.1,
      "carbs": 0.0,
      "fat": 8.1,
      "fiber": 0.0,
      "sugar": 0.0
    },
    "micros": {"sodium": 82.0, "potassium": 3.0}
  },
  {
    "id": "ing_black_coffee",
    "name": "Black Coffee / Americano (No Sugar)",
    "brand": "Nescafé",
    "category": "Beverages",
    "nutritionPer": {"amount": 200.0, "unit": "ml"},
    "macros": {
      "calories": 4.0,
      "protein": 0.3,
      "carbs": 0.7,
      "fat": 0.0,
      "fiber": 0.0,
      "sugar": 0.0
    },
    "micros": {"sodium": 5.0, "potassium": 116.0}
  },
  {
    "id": "ing_green_tea",
    "name": "Brewed Green Tea (Pure)",
    "brand": "Tetley",
    "category": "Beverages",
    "nutritionPer": {"amount": 200.0, "unit": "ml"},
    "macros": {
      "calories": 2.0,
      "protein": 0.2,
      "carbs": 0.4,
      "fat": 0.0,
      "fiber": 0.0,
      "sugar": 0.0
    },
    "micros": {"sodium": 2.0, "potassium": 40.0}
  },
  {
    "id": "ing_tea_leaves",
    "name": "Tea Leaves / Chai Patti",
    "brand": "Tata Tea",
    "category": "Beverages",
    "nutritionPer": {"amount": 2.0, "unit": "g"},
    "macros": {
      "calories": 2.0,
      "protein": 0.1,
      "carbs": 0.4,
      "fat": 0.0,
      "fiber": 0.0,
      "sugar": 0.0
    },
    "micros": {"sodium": 1.0, "potassium": 15.0}
  },
  {
    "id": "ing_coconut_water",
    "name": "Fresh Tender Coconut Water",
    "brand": null,
    "category": "Beverages",
    "nutritionPer": {"amount": 200.0, "unit": "ml"},
    "macros": {
      "calories": 38.0,
      "protein": 1.4,
      "carbs": 8.9,
      "fat": 0.4,
      "fiber": 2.2,
      "sugar": 5.2
    },
    "micros": {"sodium": 50.0, "potassium": 500.0}
  },
  {
    "id": "ing_diet_coke",
    "name": "Diet Soda / Zero-Calorie Cola",
    "brand": "Coca-Cola Zero",
    "category": "Beverages",
    "nutritionPer": {"amount": 250.0, "unit": "ml"},
    "macros": {
      "calories": 0.0,
      "protein": 0.0,
      "carbs": 0.0,
      "fat": 0.0,
      "fiber": 0.0,
      "sugar": 0.0
    },
    "micros": {"sodium": 30.0, "potassium": 0.0}
  },
  {
    "id": "ing_lemon_juice",
    "name": "Fresh Squeezed Lemon Juice",
    "brand": null,
    "category": "Beverages",
    "nutritionPer": {"amount": 30.0, "unit": "ml"},
    "macros": {
      "calories": 8.0,
      "protein": 0.1,
      "carbs": 2.6,
      "fat": 0.1,
      "fiber": 0.1,
      "sugar": 0.8
    },
    "micros": {"sodium": 1.0, "potassium": 38.0}
  },
  {
    "id": "ing_whey_protein",
    "name": "Whey Protein Isolate",
    "brand": "Optimum Nutrition Gold Standard",
    "category": "Supplements",
    "nutritionPer": {"amount": 30.0, "unit": "g"},
    "macros": {
      "calories": 120.0,
      "protein": 24.0,
      "carbs": 2.0,
      "fat": 1.0,
      "fiber": 0.5,
      "sugar": 1.0
    },
    "micros": {"sodium": 130.0, "potassium": 160.0}
  },
  {
    "id": "ing_whey_concentrate",
    "name": "Whey Protein Concentrate (80%)",
    "brand": "MuscleBlaze Biozyme",
    "category": "Supplements",
    "nutritionPer": {"amount": 33.0, "unit": "g"},
    "macros": {
      "calories": 130.0,
      "protein": 25.0,
      "carbs": 3.2,
      "fat": 1.8,
      "fiber": 0.0,
      "sugar": 1.5
    },
    "micros": {"sodium": 140.0, "potassium": 180.0}
  },
  {
    "id": "ing_casein_protein",
    "name": "Micellar Casein Protein",
    "brand": "Dymatize Elite Casein",
    "category": "Supplements",
    "nutritionPer": {"amount": 33.0, "unit": "g"},
    "macros": {
      "calories": 120.0,
      "protein": 24.0,
      "carbs": 3.0,
      "fat": 1.0,
      "fiber": 0.5,
      "sugar": 1.0
    },
    "micros": {"sodium": 240.0, "potassium": 160.0}
  },
  {
    "id": "ing_plant_protein",
    "name": "Plant / Pea & Rice Protein Powder",
    "brand": "Cosmix No-Nonsense",
    "category": "Supplements",
    "nutritionPer": {"amount": 33.0, "unit": "g"},
    "macros": {
      "calories": 130.0,
      "protein": 24.0,
      "carbs": 3.5,
      "fat": 2.0,
      "fiber": 2.0,
      "sugar": 0.0
    },
    "micros": {"sodium": 280.0, "potassium": 110.0}
  },
  {
    "id": "ing_creatine",
    "name": "Creatine Monohydrate (Creapure)",
    "brand": "MuscleBlaze",
    "category": "Supplements",
    "nutritionPer": {"amount": 5.0, "unit": "g"},
    "macros": {
      "calories": 0.0,
      "protein": 0.0,
      "carbs": 0.0,
      "fat": 0.0,
      "fiber": 0.0,
      "sugar": 0.0
    },
    "micros": {"sodium": 0.0, "potassium": 0.0}
  },
  {
    "id": "ing_sugar",
    "name": "White Sugar",
    "brand": "Madhur",
    "category": "Condiments",
    "nutritionPer": {"amount": 5.0, "unit": "g"},
    "macros": {
      "calories": 20.0,
      "protein": 0.0,
      "carbs": 5.0,
      "fat": 0.0,
      "fiber": 0.0,
      "sugar": 5.0
    },
    "micros": {"sodium": 0.0, "potassium": 0.0}
  },
  {
    "id": "ing_honey",
    "name": "Raw Natural Honey",
    "brand": "Dabur",
    "category": "Condiments",
    "nutritionPer": {"amount": 15.0, "unit": "g"},
    "macros": {
      "calories": 45.0,
      "protein": 0.1,
      "carbs": 12.3,
      "fat": 0.0,
      "fiber": 0.1,
      "sugar": 12.2
    },
    "micros": {"sodium": 1.0, "potassium": 8.0}
  },
  {
    "id": "ing_jaggery",
    "name": "Organic Jaggery / Gur",
    "brand": "Organic India",
    "category": "Condiments",
    "nutritionPer": {"amount": 15.0, "unit": "g"},
    "macros": {
      "calories": 57.0,
      "protein": 0.1,
      "carbs": 14.2,
      "fat": 0.0,
      "fiber": 0.0,
      "sugar": 13.0
    },
    "micros": {"sodium": 5.0, "potassium": 65.0}
  },
  {
    "id": "ing_stevia",
    "name": "Stevia (Zero-Calorie Sweetener)",
    "brand": "SugarFree Green",
    "category": "Condiments",
    "nutritionPer": {"amount": 1.0, "unit": "g"},
    "macros": {
      "calories": 0.0,
      "protein": 0.0,
      "carbs": 0.0,
      "fat": 0.0,
      "fiber": 0.0,
      "sugar": 0.0
    },
    "micros": {"sodium": 0.0, "potassium": 0.0}
  },
  {
    "id": "ing_hummus",
    "name": "Classic Mediterranean Hummus",
    "brand": "Wingreens",
    "category": "Condiments",
    "nutritionPer": {"amount": 30.0, "unit": "g"},
    "macros": {
      "calories": 70.0,
      "protein": 2.4,
      "carbs": 4.3,
      "fat": 5.1,
      "fiber": 1.8,
      "sugar": 0.3
    },
    "micros": {"sodium": 115.0, "potassium": 68.0}
  },
  {
    "id": "ing_ketchup",
    "name": "Tomato Ketchup",
    "brand": "Heinz",
    "category": "Condiments",
    "nutritionPer": {"amount": 15.0, "unit": "g"},
    "macros": {
      "calories": 17.0,
      "protein": 0.2,
      "carbs": 4.1,
      "fat": 0.0,
      "fiber": 0.1,
      "sugar": 3.7
    },
    "micros": {"sodium": 160.0, "potassium": 45.0}
  },
  {
    "id": "ing_sriracha",
    "name": "Sriracha Hot Chili Sauce",
    "brand": "Huy Fong",
    "category": "Condiments",
    "nutritionPer": {"amount": 10.0, "unit": "g"},
    "macros": {
      "calories": 10.0,
      "protein": 0.2,
      "carbs": 2.0,
      "fat": 0.2,
      "fiber": 0.4,
      "sugar": 1.5
    },
    "micros": {"sodium": 190.0, "potassium": 35.0}
  },
  {
    "id": "ing_soy_sauce",
    "name": "Soy Sauce (Low Sodium)",
    "brand": "Kikkoman",
    "category": "Condiments",
    "nutritionPer": {"amount": 15.0, "unit": "ml"},
    "macros": {
      "calories": 10.0,
      "protein": 1.5,
      "carbs": 0.8,
      "fat": 0.0,
      "fiber": 0.0,
      "sugar": 0.2
    },
    "micros": {"sodium": 575.0, "potassium": 35.0}
  },
  {
    "id": "ing_mustard",
    "name": "Dijon / Wholegrain Mustard",
    "brand": "Maille",
    "category": "Condiments",
    "nutritionPer": {"amount": 10.0, "unit": "g"},
    "macros": {
      "calories": 12.0,
      "protein": 0.7,
      "carbs": 0.6,
      "fat": 0.8,
      "fiber": 0.4,
      "sugar": 0.2
    },
    "micros": {"sodium": 110.0, "potassium": 15.0}
  }
]
''';

  static const String _staticSavedMealsJson = '''
[
  {
    "id": "meal_tea_01",
    "name": "Masala Tea",
    "category": "Snack",
    "servings": 1,
    "items": [
      {
        "ingredient": {
          "id": "ing_toned_milk",
          "name": "Toned Milk (3% Fat)",
          "brand": "Amul Taaza",
          "category": "Dairy",
          "nutritionPer": {"amount": 100.0, "unit": "ml"},
          "macros": {
            "calories": 58.0,
            "protein": 3.1,
            "carbs": 4.7,
            "fat": 3.0,
            "fiber": 0.0,
            "sugar": 4.7
          },
          "micros": {"sodium": 50.0, "potassium": 140.0}
        },
        "quantity": 200.0,
        "unit": "ml"
      },
      {
        "ingredient": {
          "id": "ing_tea_leaves",
          "name": "Tea Leaves / Chai Patti",
          "brand": "Tata Tea",
          "category": "Beverages",
          "nutritionPer": {"amount": 2.0, "unit": "g"},
          "macros": {
            "calories": 2.0,
            "protein": 0.1,
            "carbs": 0.4,
            "fat": 0.0,
            "fiber": 0.0,
            "sugar": 0.0
          },
          "micros": {"sodium": 1.0, "potassium": 15.0}
        },
        "quantity": 2.0,
        "unit": "g"
      },
      {
        "ingredient": {
          "id": "ing_sugar",
          "name": "White Sugar",
          "brand": "Madhur",
          "category": "Condiments",
          "nutritionPer": {"amount": 5.0, "unit": "g"},
          "macros": {
            "calories": 20.0,
            "protein": 0.0,
            "carbs": 5.0,
            "fat": 0.0,
            "fiber": 0.0,
            "sugar": 5.0
          },
          "micros": {"sodium": 0.0, "potassium": 0.0}
        },
        "quantity": 5.0,
        "unit": "g"
      }
    ]
  },
  {
    "id": "meal_oats_02",
    "name": "Power Protein Oats Bowl",
    "category": "Breakfast",
    "servings": 1,
    "items": [
      {
        "ingredient": {
          "id": "ing_rolled_oats",
          "name": "Rolled Oats",
          "brand": "Quaker",
          "category": "Grains",
          "nutritionPer": {"amount": 50.0, "unit": "g"},
          "macros": {
            "calories": 194.0,
            "protein": 6.8,
            "carbs": 33.2,
            "fat": 3.6,
            "fiber": 5.1,
            "sugar": 0.8
          },
          "micros": {"sodium": 2.0, "potassium": 180.0}
        },
        "quantity": 50.0,
        "unit": "g"
      },
      {
        "ingredient": {
          "id": "ing_whey_protein",
          "name": "Whey Protein Isolate",
          "brand": "Optimum Nutrition",
          "category": "Supplements",
          "nutritionPer": {"amount": 30.0, "unit": "g"},
          "macros": {
            "calories": 120.0,
            "protein": 24.0,
            "carbs": 2.0,
            "fat": 1.0,
            "fiber": 0.5,
            "sugar": 1.0
          },
          "micros": {"sodium": 130.0, "potassium": 160.0}
        },
        "quantity": 30.0,
        "unit": "g"
      },
      {
        "ingredient": {
          "id": "ing_banana",
          "name": "Fresh Banana",
          "brand": null,
          "category": "Fruits",
          "nutritionPer": {"amount": 100.0, "unit": "g"},
          "macros": {
            "calories": 89.0,
            "protein": 1.1,
            "carbs": 22.8,
            "fat": 0.3,
            "fiber": 2.6,
            "sugar": 12.2
          },
          "micros": {"sodium": 1.0, "potassium": 358.0}
        },
        "quantity": 100.0,
        "unit": "g"
      },
      {
        "ingredient": {
          "id": "ing_peanut_butter",
          "name": "Natural Peanut Butter",
          "brand": "Pintola",
          "category": "Nuts & Seeds",
          "nutritionPer": {"amount": 32.0, "unit": "g"},
          "macros": {
            "calories": 190.0,
            "protein": 8.0,
            "carbs": 7.0,
            "fat": 16.0,
            "fiber": 2.0,
            "sugar": 2.0
          },
          "micros": {"sodium": 5.0, "potassium": 210.0}
        },
        "quantity": 16.0,
        "unit": "g"
      }
    ]
  },
  {
    "id": "meal_chicken_rice_03",
    "name": "Grilled Chicken with Rice",
    "category": "Lunch",
    "servings": 1,
    "items": [
      {
        "ingredient": {
          "id": "ing_chicken_breast",
          "name": "Raw Chicken Breast",
          "brand": null,
          "category": "Protein",
          "nutritionPer": {"amount": 100.0, "unit": "g"},
          "macros": {
            "calories": 165.0,
            "protein": 31.0,
            "carbs": 0.0,
            "fat": 3.6,
            "fiber": 0.0,
            "sugar": 0.0
          },
          "micros": {"sodium": 74.0, "potassium": 256.0}
        },
        "quantity": 150.0,
        "unit": "g"
      },
      {
        "ingredient": {
          "id": "ing_white_rice",
          "name": "Cooked White Rice (Basmati)",
          "brand": "India Gate",
          "category": "Grains",
          "nutritionPer": {"amount": 100.0, "unit": "g"},
          "macros": {
            "calories": 130.0,
            "protein": 2.7,
            "carbs": 28.2,
            "fat": 0.3,
            "fiber": 0.4,
            "sugar": 0.1
          },
          "micros": {"sodium": 1.0, "potassium": 35.0}
        },
        "quantity": 150.0,
        "unit": "g"
      },
      {
        "ingredient": {
          "id": "ing_olive_oil",
          "name": "Extra Virgin Olive Oil",
          "brand": "Borges",
          "category": "Oils & Fats",
          "nutritionPer": {"amount": 10.0, "unit": "ml"},
          "macros": {
            "calories": 88.0,
            "protein": 0.0,
            "carbs": 0.0,
            "fat": 10.0,
            "fiber": 0.0,
            "sugar": 0.0
          },
          "micros": {"sodium": 0.0, "potassium": 0.0}
        },
        "quantity": 5.0,
        "unit": "ml"
      }
    ]
  },
  {
    "id": "meal_eggs_toast_04",
    "name": "Eggs & Brown Bread Toast",
    "category": "Breakfast",
    "servings": 1,
    "items": [
      {
        "ingredient": {
          "id": "ing_whole_egg",
          "name": "Whole Egg (Large)",
          "brand": null,
          "category": "Protein",
          "nutritionPer": {"amount": 50.0, "unit": "g"},
          "macros": {
            "calories": 74.0,
            "protein": 6.3,
            "carbs": 0.4,
            "fat": 5.0,
            "fiber": 0.0,
            "sugar": 0.2
          },
          "micros": {"sodium": 71.0, "potassium": 69.0}
        },
        "quantity": 100.0,
        "unit": "g"
      },
      {
        "ingredient": {
          "id": "ing_brown_bread",
          "name": "Brown Bread (1 Slice)",
          "brand": "Harvest Gold",
          "category": "Grains",
          "nutritionPer": {"amount": 40.0, "unit": "g"},
          "macros": {
            "calories": 95.0,
            "protein": 3.8,
            "carbs": 17.5,
            "fat": 1.2,
            "fiber": 2.4,
            "sugar": 1.8
          },
          "micros": {"sodium": 140.0, "potassium": 80.0}
        },
        "quantity": 80.0,
        "unit": "g"
      }
    ]
  }
]
''';
}
