import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:velto/core/constants/app_colors.dart';
import 'package:velto/features/diet/controllers/diet_controller.dart';
import 'package:velto/features/diet/controllers/log_meal_controller.dart';
import 'package:velto/features/diet/models/ingredient.dart';
import 'package:velto/features/diet/models/saved_meal.dart';
import 'package:velto/features/diet/services/diet_service.dart';

class AddMealController extends GetxController {
  final DietService _dietService = DietService();

  final TextEditingController nameController = TextEditingController();
  final RxString selectedCategory = 'Breakfast'.obs;
  final RxInt servings = 1.obs;

  // Selected ingredients in the custom meal
  final RxList<MealIngredientItem> items = <MealIngredientItem>[].obs;

  // Catalog state for ingredient picker
  final RxList<Ingredient> catalogIngredients = <Ingredient>[].obs;
  final RxBool isCatalogLoading = false.obs;
  final RxString catalogQuery = ''.obs;
  final RxString catalogCategory = 'All'.obs;

  final List<String> categories = const [
    'Breakfast',
    'Lunch',
    'Dinner',
    'Snack',
  ];

  final List<String> catalogCategories = const [
    'All',
    'Protein',
    'Grains',
    'Dairy',
    'Vegetables',
    'Fruits',
    'Legumes',
    'Nuts & Seeds',
    'Oils & Fats',
    'Beverages',
    'Supplements',
    'Condiments',
  ];

  SavedMeal? editingMeal;
  bool get isEditing => editingMeal != null;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is SavedMeal) {
      editingMeal = args;
      nameController.text = args.name;
      selectedCategory.value = args.category;
      servings.value = args.servings;
      items.assignAll(args.items);
    }
    loadCatalog();
  }

  @override
  void onClose() {
    nameController.dispose();
    super.onClose();
  }

  // ── Macro Calculations ───────────────────────────────────────────────────

  int get totalCalories => items.fold(0, (sum, i) => sum + i.calories);

  double get totalProtein => double.parse(
        items.fold(0.0, (sum, i) => sum + i.protein).toStringAsFixed(1),
      );

  double get totalCarbs => double.parse(
        items.fold(0.0, (sum, i) => sum + i.carbs).toStringAsFixed(1),
      );

  double get totalFat => double.parse(
        items.fold(0.0, (sum, i) => sum + i.fat).toStringAsFixed(1),
      );

  double get totalFiber => double.parse(
        items.fold(0.0, (sum, i) => sum + i.fiber).toStringAsFixed(1),
      );

  // ── Catalog Loading ──────────────────────────────────────────────────────

  Future<void> loadCatalog() async {
    isCatalogLoading.value = true;
    try {
      final list = await _dietService.getIngredients(
        query: catalogQuery.value,
        category: catalogCategory.value,
      );
      catalogIngredients.assignAll(list);
    } finally {
      isCatalogLoading.value = false;
    }
  }

  void onCatalogSearchChanged(String query) {
    catalogQuery.value = query;
    loadCatalog();
  }

  void onCatalogCategoryChanged(String category) {
    catalogCategory.value = category;
    loadCatalog();
  }

  // ── Ingredient Management ────────────────────────────────────────────────

  void addIngredient(Ingredient ingredient, double quantity, String unit) {
    final existingIndex = items.indexWhere((i) => i.ingredient.id == ingredient.id);
    if (existingIndex >= 0) {
      // Update existing ingredient quantity
      final existing = items[existingIndex];
      items[existingIndex] = existing.copyWith(
        quantity: existing.quantity + quantity,
      );
    } else {
      items.add(MealIngredientItem(
        ingredient: ingredient,
        quantity: quantity,
        unit: unit,
      ));
    }
  }

  void updateQuantity(int index, double newQuantity) {
    if (index >= 0 && index < items.length) {
      if (newQuantity <= 0) {
        removeIngredient(index);
      } else {
        items[index] = items[index].copyWith(quantity: newQuantity);
      }
    }
  }

  void removeIngredient(int index) {
    if (index >= 0 && index < items.length) {
      items.removeAt(index);
    }
  }

  // ── Save & Log Actions ───────────────────────────────────────────────────

  bool _validateInput() {
    if (nameController.text.trim().isEmpty) {
      Get.snackbar(
        'Meal Name Required',
        'Please enter a name for your meal (e.g., Morning Tea, Protein Oatmeal)',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        backgroundColor: AppColors.rose,
        colorText: Colors.white,
      );
      return false;
    }

    if (items.isEmpty) {
      Get.snackbar(
        'Ingredients Needed',
        'Please add at least one ingredient to calculate macros',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        backgroundColor: AppColors.rose,
        colorText: Colors.white,
      );
      return false;
    }

    return true;
  }

  Future<SavedMeal?> saveMeal() async {
    if (!_validateInput()) return null;

    final meal = SavedMeal(
      id: editingMeal?.id ?? 'meal_${DateTime.now().millisecondsSinceEpoch}',
      name: nameController.text.trim(),
      category: selectedCategory.value,
      servings: servings.value,
      items: List.from(items),
    );

    final saved = isEditing
        ? await _dietService.updateMeal(meal)
        : await _dietService.saveMeal(meal);

    // Refresh LogMealController if active
    if (Get.isRegistered<LogMealController>()) {
      Get.find<LogMealController>().loadSavedMeals();
    }

    return saved;
  }

  Future<void> saveAndClose() async {
    final saved = await saveMeal();
    if (saved != null) {
      Get.back(result: saved);
      Get.snackbar(
        isEditing ? 'Meal Updated' : 'Meal Saved',
        isEditing
            ? '"${saved.name}" has been updated'
            : '"${saved.name}" has been added to your saved meals',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.isDarkMode ? AppColors.surfaceDark2 : AppColors.primary,
        colorText: Get.isDarkMode ? AppColors.textPrimaryDark : Colors.white,
        borderColor: Get.isDarkMode ? AppColors.borderDark : null,
        borderWidth: Get.isDarkMode ? 1 : null,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        duration: const Duration(seconds: 2),
      );
    }
  }

  Future<void> saveAndLogMeal() async {
    final saved = await saveMeal();
    if (saved != null) {
      final dietController = Get.isRegistered<DietController>()
          ? Get.find<DietController>()
          : Get.put(DietController());

      dietController.addMeal(saved.toMealModel());

      Get.back(result: saved);
      Get.snackbar(
        'Meal Logged',
        'Saved "${saved.name}" and logged ${saved.totalCalories} kcal to today\'s meals',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.isDarkMode ? AppColors.surfaceDark2 : AppColors.primary,
        colorText: Get.isDarkMode ? AppColors.textPrimaryDark : Colors.white,
        borderColor: Get.isDarkMode ? AppColors.borderDark : null,
        borderWidth: Get.isDarkMode ? 1 : null,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        duration: const Duration(seconds: 2),
      );
    }
  }
}
