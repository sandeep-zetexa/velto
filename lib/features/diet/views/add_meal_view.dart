import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:velto/core/constants/app_colors.dart';
import 'package:velto/core/constants/app_sizes.dart';
import 'package:velto/core/widgets/app_widgets.dart';
import 'package:velto/features/diet/controllers/add_meal_controller.dart';
import 'package:velto/features/diet/widgets/ingredient_picker_sheet.dart';
import 'package:velto/features/diet/widgets/meal_macro_summary_card.dart';

class AddMealView extends StatelessWidget {
  const AddMealView({super.key});

  IconData _categoryIcon(String cat) {
    switch (cat.toLowerCase()) {
      case 'breakfast':
        return LucideIcons.sun;
      case 'lunch':
        return LucideIcons.utensils;
      case 'dinner':
        return LucideIcons.moon;
      case 'snack':
      default:
        return LucideIcons.cookie;
    }
  }

  Widget _quickAddChip(
    BuildContext context,
    AddMealController controller,
    String name,
    AppStyle s,
    bool isDark,
  ) {
    return InkWell(
      onTap: () => IngredientPickerSheet.show(
        context,
        controller,
        initialQuery: name,
      ),
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6.5),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark2 : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(color: s.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.plus, size: 12, color: s.brand),
            const SizedBox(width: 4),
            Text(
              name,
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: s.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = AppStyle(isDark);
    final controller = Get.put(AddMealController());

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: AppAppBar(
        title: controller.isEditing ? 'Edit Meal' : 'Add Meal',
        showBackButton: true,
        onBackPressed: () => Get.back(),
        isDark: isDark,
        actions: [
          AppButton.text(
            text: controller.isEditing ? 'Update' : 'Save',
            onPressed: controller.saveAndClose,
            size: AppButtonSize.md,
          ),
          const SizedBox(width: AppSizes.sm),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Compact Meal Name & Category Header
                  AppCard(
                    isDark: isDark,
                    padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: controller.nameController,
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: s.primary,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Meal Name (e.g. Protein Oatmeal Bowl)',
                            hintStyle: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: s.tertiary,
                            ),
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            border: InputBorder.none,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Obx(() {
                          final selected = controller.selectedCategory.value;
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: controller.categories.map((cat) {
                                final isSelected = selected == cat;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: GestureDetector(
                                    onTap: () => controller.selectedCategory.value = cat,
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 150),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? s.brand
                                            : (isDark ? AppColors.surfaceDark2 : AppColors.secondarySoft.withValues(alpha: 0.6)),
                                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                                        border: Border.all(
                                          color: isSelected ? s.brand : s.border,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            _categoryIcon(cat),
                                            size: 13,
                                            color: isSelected ? Colors.white : s.secondary,
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            cat,
                                            style: GoogleFonts.manrope(
                                              fontSize: 11,
                                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                              color: isSelected ? Colors.white : s.secondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSizes.lg),

                  // 2. Ingredients Section Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Ingredients',
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: s.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Obx(
                            () => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: controller.items.isEmpty
                                    ? (isDark ? AppColors.surfaceDark2 : AppColors.secondarySoft)
                                    : s.brandSoft,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${controller.items.length}',
                                style: GoogleFonts.manrope(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: controller.items.isEmpty ? s.tertiary : s.brand,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Obx(() {
                        if (controller.items.isNotEmpty) {
                          return AppButton.primary(
                            text: 'Add Item',
                            icon: LucideIcons.plus,
                            size: AppButtonSize.xs,
                            onPressed: () => IngredientPickerSheet.show(context, controller),
                          );
                        }
                        return const SizedBox.shrink();
                      }),
                    ],
                  ),

                  const SizedBox(height: AppSizes.sm),

                  // 3. Ingredients Content: Hero Add State OR List of Items
                  Obx(() {
                    final items = controller.items.toList();
                    if (items.isEmpty) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Primary Hero Add Box
                          GestureDetector(
                            onTap: () => IngredientPickerSheet.show(context, controller),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSizes.xl,
                                horizontal: AppSizes.lg,
                              ),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.surfaceDark2 : AppColors.surfaceLight,
                                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                                border: Border.all(
                                  color: s.brand.withValues(alpha: 0.45),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: s.brand.withValues(alpha: isDark ? 0.05 : 0.08),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: s.brandSoft,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      LucideIcons.plus,
                                      size: 26,
                                      color: s.brand,
                                    ),
                                  ),
                                  const SizedBox(height: AppSizes.sm),
                                  Text(
                                    'Add Ingredients to Start',
                                    style: GoogleFonts.manrope(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: s.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tap here to browse 100+ foods like oats, chicken, eggs & milk.\nMacros calculate live as you choose quantities.',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.manrope(
                                      fontSize: 12,
                                      color: s.secondary,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: AppSizes.md),
                                  AppButton.primary(
                                    text: 'Browse & Add Ingredients',
                                    icon: LucideIcons.search,
                                    size: AppButtonSize.sm,
                                    onPressed: () => IngredientPickerSheet.show(context, controller),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: AppSizes.lg),

                          // Popular Staples Quick Add
                          Text(
                            'Quick Add Popular Staples',
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: s.tertiary,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: AppSizes.xs),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _quickAddChip(context, controller, 'Rolled Oats', s, isDark),
                              _quickAddChip(context, controller, 'Toned Milk', s, isDark),
                              _quickAddChip(context, controller, 'Whole Eggs', s, isDark),
                              _quickAddChip(context, controller, 'Chicken Breast', s, isDark),
                              _quickAddChip(context, controller, 'Basmati Rice', s, isDark),
                              _quickAddChip(context, controller, 'Banana', s, isDark),
                              _quickAddChip(context, controller, 'Whey Protein', s, isDark),
                              _quickAddChip(context, controller, 'Fresh Paneer', s, isDark),
                              _quickAddChip(context, controller, 'Peanut Butter', s, isDark),
                            ],
                          ),
                        ],
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: items.length,
                          separatorBuilder: (_, index) => const SizedBox(height: AppSizes.sm),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            final isLiquid = item.unit.toLowerCase() == 'ml';
                            final stepAmount = isLiquid ? 25.0 : 10.0;

                            return Container(
                              padding: const EdgeInsets.all(AppSizes.md),
                              decoration: BoxDecoration(
                                color: s.surface,
                                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                                border: Border.all(color: s.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.ingredient.name,
                                              style: GoogleFonts.manrope(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: s.primary,
                                              ),
                                            ),
                                            if (item.ingredient.brand != null) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                item.ingredient.brand!,
                                                style: GoogleFonts.manrope(
                                                  fontSize: 11,
                                                  color: s.secondary,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      // Delete button
                                      AppButton.icon(
                                        icon: LucideIcons.trash_2,
                                        size: AppButtonSize.xs,
                                        variant: AppButtonVariant.danger,
                                        customBgColor: isDark ? AppColors.roseSoftDark : AppColors.roseSoft,
                                        customTextColor: AppColors.rose,
                                        onPressed: () => controller.removeIngredient(index),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: AppSizes.sm),

                                  // Quantity Stepper Row & Calories
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Stepper
                                      Container(
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? AppColors.surfaceDark2
                                              : AppColors.secondarySoft,
                                          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                                          border: Border.all(color: s.border),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            GestureDetector(
                                              onTap: () {
                                                controller.updateQuantity(
                                                  index,
                                                  item.quantity - stepAmount,
                                                );
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.all(6),
                                                child: Icon(
                                                  LucideIcons.minus,
                                                  size: 14,
                                                  color: s.primary,
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 10),
                                              child: Text(
                                                '${item.quantity.toStringAsFixed(item.quantity % 1 == 0 ? 0 : 1)} ${item.unit}',
                                                style: GoogleFonts.manrope(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w800,
                                                  color: s.primary,
                                                ),
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () {
                                                controller.updateQuantity(
                                                  index,
                                                  item.quantity + stepAmount,
                                                );
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.all(6),
                                                child: Icon(
                                                  LucideIcons.plus,
                                                  size: 14,
                                                  color: s.primary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Calories for this ingredient
                                      Text(
                                        '${item.calories} kcal',
                                        style: GoogleFonts.manrope(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: s.primary,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: AppSizes.sm),

                                  // Mini Macro Badges for this item
                                  Row(
                                    children: [
                                      _macroBadge('P: ${item.protein}g', AppColors.macroProtein),
                                      const SizedBox(width: 6),
                                      _macroBadge('C: ${item.carbs}g', AppColors.macroCarbs),
                                      const SizedBox(width: 6),
                                      _macroBadge('F: ${item.fat}g', AppColors.macroFats),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: AppSizes.sm),

                        // Add Another Ingredient button
                        AppButton.soft(
                          text: 'Add another ingredient',
                          icon: LucideIcons.plus,
                          size: AppButtonSize.sm,
                          fullWidth: true,
                          onPressed: () => IngredientPickerSheet.show(context, controller),
                        ),

                        const SizedBox(height: AppSizes.xl),

                        // Live Macros Summary Card (only shown when ingredients are present)
                        MealMacroSummaryCard(
                          totalCalories: controller.totalCalories,
                          totalProtein: controller.totalProtein,
                          totalCarbs: controller.totalCarbs,
                          totalFat: controller.totalFat,
                          servings: controller.servings.value,
                          isDark: isDark,
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: EdgeInsets.fromLTRB(
              AppSizes.lg,
              AppSizes.md,
              AppSizes.lg,
              MediaQuery.of(context).padding.bottom + AppSizes.md,
            ),
            decoration: BoxDecoration(
              color: s.surface,
              border: Border(top: BorderSide(color: s.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: AppButton.outline(
                    text: controller.isEditing ? 'Save Changes' : 'Save Meal',
                    size: AppButtonSize.md,
                    fullWidth: true,
                    onPressed: controller.saveAndClose,
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: AppButton.primary(
                    text: 'Save & Log',
                    icon: LucideIcons.check,
                    size: AppButtonSize.md,
                    fullWidth: true,
                    onPressed: controller.saveAndLogMeal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _macroBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: GoogleFonts.manrope(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
