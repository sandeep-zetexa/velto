import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:velto/features/diet/controllers/add_meal_controller.dart';
import 'package:velto/features/diet/controllers/diet_controller.dart';
import 'package:velto/features/diet/models/meal_model.dart';
import 'package:velto/features/diet/models/saved_meal.dart';
import 'package:velto/features/diet/services/diet_service.dart';
import 'package:velto/features/diet/views/add_meal_view.dart';
import 'package:velto/features/diet/views/diet_view.dart';
import 'package:velto/features/diet/views/log_meal_view.dart';

void main() {
  group('Diet Feature Tests', () {
    final service = DietService();

    test('DietService loads static ingredients catalog with wide variety', () async {
      final ingredients = await service.getIngredients();
      expect(ingredients.length >= 70, true);

      final milk = ingredients.firstWhere((i) => i.id == 'ing_toned_milk');
      expect(milk.name, contains('Toned Milk'));
      expect(milk.nutritionPer.amount, 100.0);
      expect(milk.nutritionPer.unit, 'ml');
      expect(milk.macros.calories, 58.0);

      // Fitness staples
      expect(ingredients.any((i) => i.id == 'ing_chicken_breast'), true);
      expect(ingredients.any((i) => i.id == 'ing_whey_protein'), true);
      expect(ingredients.any((i) => i.id == 'ing_creatine'), true);
      expect(ingredients.any((i) => i.id == 'ing_egg_white'), true);
      expect(ingredients.any((i) => i.id == 'ing_soya_chunks'), true);

      // Everyday common foods
      expect(ingredients.any((i) => i.id == 'ing_roti'), true);
      expect(ingredients.any((i) => i.id == 'ing_white_rice'), true);
      expect(ingredients.any((i) => i.id == 'ing_moong_dal'), true);
      expect(ingredients.any((i) => i.id == 'ing_chickpeas'), true);
      expect(ingredients.any((i) => i.id == 'ing_spinach'), true);
      expect(ingredients.any((i) => i.id == 'ing_boiled_potato'), true);
      expect(ingredients.any((i) => i.id == 'ing_banana'), true);
    });

    test('Quantity adjustment recalculates macros dynamically (200ml Toned Milk)', () async {
      final ingredients = await service.getIngredients();
      final tonedMilk = ingredients.firstWhere((i) => i.id == 'ing_toned_milk');

      // 100ml base -> 58 kcal, 3.1g P, 4.7g C, 3.0g F
      // User adjusts to 200ml
      final item = MealIngredientItem(
        ingredient: tonedMilk,
        quantity: 200.0,
        unit: 'ml',
      );

      expect(item.ratio, 2.0);
      expect(item.calories, 116);
      expect(item.protein, 6.2);
      expect(item.carbs, 9.4);
      expect(item.fat, 6.0);
    });

    test('SavedMeal calculates total calories and macros across multiple ingredients', () async {
      final ingredients = await service.getIngredients();
      final tonedMilk = ingredients.firstWhere((i) => i.id == 'ing_toned_milk');
      final teaLeaves = ingredients.firstWhere((i) => i.id == 'ing_tea_leaves');
      final sugar = ingredients.firstWhere((i) => i.id == 'ing_sugar');

      final teaMeal = SavedMeal(
        id: 'test_tea',
        name: 'Masala Tea',
        category: 'Snack',
        items: [
          MealIngredientItem(ingredient: tonedMilk, quantity: 200.0, unit: 'ml'),
          MealIngredientItem(ingredient: teaLeaves, quantity: 2.0, unit: 'g'),
          MealIngredientItem(ingredient: sugar, quantity: 5.0, unit: 'g'),
        ],
      );

      // 200ml toned milk (116 kcal) + 2g tea leaves (2 kcal) + 5g sugar (20 kcal) = 138 kcal
      expect(teaMeal.totalCalories, 138);
      expect(teaMeal.totalProtein > 6.0, true);
      expect(teaMeal.totalCarbs > 14.0, true);
      expect(teaMeal.totalFat >= 6.0, true);

      // Verify conversion to MealModel for diet logger
      final mealModel = teaMeal.toMealModel(time: '8:30 AM');
      expect(mealModel.title, 'Masala Tea');
      expect(mealModel.calories, 138);
      expect(mealModel.category, 'Snack');
      expect(mealModel.time, '8:30 AM');
    });

    test('DietService saves custom meal and retrieves it', () async {
      final ingredients = await service.getIngredients();
      final oats = ingredients.firstWhere((i) => i.id == 'ing_rolled_oats');

      final customMeal = SavedMeal(
        id: 'custom_oats_test',
        name: 'Custom Oats Breakfast',
        category: 'Breakfast',
        items: [
          MealIngredientItem(ingredient: oats, quantity: 60.0, unit: 'g'),
        ],
      );

      await service.saveMeal(customMeal);

      final saved = await service.getSavedMeals();
      expect(saved.any((m) => m.name == 'Custom Oats Breakfast'), true);

      // Test update
      final updatedMeal = customMeal.copyWith(name: 'Updated Oats Bowl');
      await service.updateMeal(updatedMeal);
      final afterUpdate = await service.getSavedMeals();
      expect(afterUpdate.any((m) => m.name == 'Updated Oats Bowl'), true);

      // Test delete
      final deleted = await service.deleteMeal('custom_oats_test');
      expect(deleted, true);
      final afterDelete = await service.getSavedMeals();
      expect(afterDelete.any((m) => m.id == 'custom_oats_test'), false);
    });

    testWidgets('LogMealView renders redesigned saved meal cards with macro pills and actions', (tester) async {
      await tester.pumpWidget(
        const GetMaterialApp(
          home: LogMealView(),
        ),
      );

      // Wait for mock data to load
      await tester.pumpAndSettle();

      // Verify category chips
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Breakfast'), findsOneWidget);

      // Verify saved meals card shows meal names
      expect(find.text('Masala Tea'), findsOneWidget);

      // Verify hero calories
      expect(find.text('138'), findsOneWidget);
      expect(find.text('kcal'), findsWidgets);

      // Verify macro micro-pills exist (P, C, F)
      expect(find.text('P'), findsWidgets);
      expect(find.text('C'), findsWidgets);
      expect(find.text('F'), findsWidgets);

      // Verify Log action button exists
      expect(find.text('Log'), findsWidgets);
    });

    testWidgets('AddMealView renders bottom action buttons without overflow in edit mode', (tester) async {
      Get.reset();
      final sampleMeal = SavedMeal(
        id: 'edit_test',
        name: 'Oats with Milk',
        category: 'Breakfast',
        items: [],
      );

      final controller = Get.put(AddMealController());
      controller.editingMeal = sampleMeal;

      await tester.pumpWidget(
        const GetMaterialApp(
          home: AddMealView(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Check that "Save Changes" and "Save & Log" are rendered and found
      expect(find.text('Save Changes'), findsOneWidget);
      expect(find.text('Save & Log'), findsOneWidget);

      // Verify no RenderFlex overflow exceptions occurred
      expect(tester.takeException(), isNull);
    });

    testWidgets('AddMealView renders primary ingredients hero and quick-add popular staples', (tester) async {
      Get.reset();
      Get.put(AddMealController());

      await tester.pumpWidget(
        const GetMaterialApp(
          home: AddMealView(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Verify prominent ingredients CTA
      expect(find.text('Add Ingredients to Start'), findsOneWidget);
      expect(find.text('Browse & Add Ingredients'), findsOneWidget);

      // Verify quick-add popular staples exist
      expect(find.text('Quick Add Popular Staples'), findsOneWidget);
      expect(find.text('Rolled Oats'), findsOneWidget);
      expect(find.text('Chicken Breast'), findsOneWidget);
      expect(find.text('Whole Eggs'), findsOneWidget);
    });

    testWidgets('DietView renders logged meal cards with protein, carbs, and fats macro counts', (tester) async {
      Get.reset();
      final dietController = Get.put(DietController());
      dietController.addMeal(
        const MealModel(
          id: 'test_meal_1',
          category: 'Breakfast',
          time: '8:30 AM',
          title: 'Oatmeal & Whey Protein',
          calories: 340,
          protein: 32,
          carbs: 45,
          fats: 6,
        ),
      );

      await tester.pumpWidget(
        const GetMaterialApp(
          home: DietView(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify meal title & calories
      expect(find.text('Oatmeal & Whey Protein'), findsOneWidget);
      expect(find.text('340'), findsWidgets);

      // Verify macro counts P, C, F
      expect(find.text('32g'), findsOneWidget);
      expect(find.text('45g'), findsOneWidget);
      expect(find.text('6g'), findsOneWidget);

      // Verify macro badge labels exist
      expect(find.text('P'), findsWidgets);
      expect(find.text('C'), findsWidgets);
      expect(find.text('F'), findsWidgets);
    });
  });
}

