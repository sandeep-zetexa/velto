import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:velto/core/constants/app_colors.dart';
import 'package:velto/features/diet/controllers/diet_controller.dart';
import 'package:velto/features/diet/models/saved_meal.dart';
import 'package:velto/features/diet/services/diet_service.dart';

class LogMealController extends GetxController {
  final DietService _dietService = DietService();

  final RxList<SavedMeal> savedMeals = <SavedMeal>[].obs;
  final RxBool isLoading = true.obs;
  final RxString searchQuery = ''.obs;
  final RxString selectedCategory = 'All'.obs;

  final List<String> categories = const [
    'All',
    'Breakfast',
    'Lunch',
    'Dinner',
    'Snack',
  ];

  @override
  void onInit() {
    super.onInit();
    loadSavedMeals();
  }

  Future<void> loadSavedMeals() async {
    isLoading.value = true;
    try {
      final list = await _dietService.getSavedMeals(
        query: searchQuery.value,
        category: selectedCategory.value,
      );
      savedMeals.assignAll(list);
    } finally {
      isLoading.value = false;
    }
  }

  void onSearchChanged(String query) {
    searchQuery.value = query;
    loadSavedMeals();
  }

  void onCategorySelected(String category) {
    selectedCategory.value = category;
    loadSavedMeals();
  }

  /// Logs the selected saved meal into today's meals log.
  void logMeal(SavedMeal savedMeal, {String? customCategory, String? customTime}) {
    final dietController = Get.isRegistered<DietController>()
        ? Get.find<DietController>()
        : Get.put(DietController());

    final mealModel = savedMeal.toMealModel(time: customTime);

    // If a custom category was specified, override category
    final finalMeal = customCategory != null
        ? mealModel.copyWith(category: customCategory)
        : mealModel;

    dietController.addMeal(finalMeal);

    Get.snackbar(
      'Meal Logged',
      'Added "${savedMeal.name}" (${savedMeal.totalCalories} kcal) to today\'s meals',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Get.isDarkMode ? AppColors.surfaceDark2 : AppColors.primary,
      colorText: Get.isDarkMode ? AppColors.textPrimaryDark : Colors.white,
      borderColor: Get.isDarkMode ? AppColors.borderDark : null,
      borderWidth: Get.isDarkMode ? 1 : null,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 2),
      icon: Icon(Icons.check_circle_rounded, color: Get.isDarkMode ? AppColors.primaryDark : Colors.white),
    );
  }

  /// Delete a saved meal.
  Future<void> deleteMeal(String mealId) async {
    final success = await _dietService.deleteMeal(mealId);
    if (success) {
      savedMeals.removeWhere((m) => m.id == mealId);
      Get.snackbar(
        'Meal Removed',
        'Meal removed from saved collection',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      );
    }
  }
}
