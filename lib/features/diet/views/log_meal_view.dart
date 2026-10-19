import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:velto/app/routes/app_pages.dart';
import 'package:velto/core/constants/app_colors.dart';
import 'package:velto/core/constants/app_sizes.dart';
import 'package:velto/core/widgets/app_widgets.dart';
import 'package:velto/features/diet/controllers/log_meal_controller.dart';
import 'package:velto/features/diet/models/saved_meal.dart';

class LogMealView extends StatelessWidget {
  const LogMealView({super.key});

  void _openAddNewMeal() {
    Get.toNamed(Routes.addMeal);
  }

  void _editMeal(SavedMeal meal) {
    Get.toNamed(Routes.addMeal, arguments: meal);
  }

  void _confirmDelete(BuildContext context, LogMealController controller, SavedMeal meal) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Delete Saved Meal?',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
        ),
        content: Text('Are you sure you want to delete "${meal.name}" from your saved meals?'),
        actions: [
          AppButton.text(
            text: 'Cancel',
            size: AppButtonSize.sm,
            onPressed: () => Navigator.pop(ctx),
          ),
          AppButton.danger(
            text: 'Delete',
            size: AppButtonSize.sm,
            onPressed: () {
              Navigator.pop(ctx);
              controller.deleteMeal(meal.id);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = AppStyle(isDark);
    final controller = Get.put(LogMealController());

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: AppAppBar(
        title: 'Log Meal',
        showBackButton: true,
        onBackPressed: () => Get.back(),
        isDark: isDark,
        actions: [
          IconButton(
            tooltip: 'Add new meal',
            icon: Icon(LucideIcons.plus, color: s.brand),
            onPressed: _openAddNewMeal,
          ),
          const SizedBox(width: AppSizes.xs),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSizes.lg, AppSizes.sm, AppSizes.lg, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 'Add New Meal' Primary Hero Action Card
                  GestureDetector(
                    onTap: _openAddNewMeal,
                    child: Container(
                      padding: const EdgeInsets.all(AppSizes.md),
                      decoration: BoxDecoration(
                        color: isDark ? s.surface : null,
                        gradient: isDark
                            ? null
                            : LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  AppColors.primary.withValues(alpha: 0.85),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                        border: isDark ? Border.all(color: s.brand.withValues(alpha: 0.35)) : null,
                        boxShadow: isDark
                            ? null
                            : [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isDark ? s.brandSoft : Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              LucideIcons.sparkles,
                              color: isDark ? s.brand : Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: AppSizes.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Add New Meal',
                                  style: GoogleFonts.manrope(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? s.primary : Colors.white,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Combine ingredients and track live macros',
                                  style: GoogleFonts.manrope(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? s.secondary : Colors.white.withValues(alpha: 0.85),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isDark ? s.brand : Colors.white,
                              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(LucideIcons.plus, size: 14, color: isDark ? const Color(0xFF042017) : AppColors.primary),
                                const SizedBox(width: 4),
                                Text(
                                  'Create',
                                  style: GoogleFonts.manrope(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? const Color(0xFF042017) : AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSizes.md),

                  // Search Bar
                  AppSearchBar(
                    hintText: 'Search saved meals or ingredients...',
                    isDark: isDark,
                    onChanged: controller.onSearchChanged,
                  ),

                  const SizedBox(height: AppSizes.md),

                  // Category Filter Chips
                  SizedBox(
                    height: 38,
                    child: Obx(() {
                      final selected = controller.selectedCategory.value;
                      return ListView(
                        scrollDirection: Axis.horizontal,
                        children: controller.categories.map((cat) {
                          final isSelected = selected == cat;
                          return Padding(
                            padding: const EdgeInsets.only(right: AppSizes.xs),
                            child: GestureDetector(
                              onTap: () => controller.onCategorySelected(cat),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? s.brand
                                      : (isDark ? AppColors.surfaceDark2 : AppColors.surfaceLight),
                                  borderRadius: BorderRadius.circular(AppSizes.radiusRound),
                                  border: Border.all(
                                    color: isSelected ? s.brand : s.border,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    cat,
                                    style: GoogleFonts.manrope(
                                      fontSize: 12,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                      color: isSelected
                                          ? (isDark ? const Color(0xFF042017) : Colors.white)
                                          : s.secondary,
                                    ),
                                 ),
                              ),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    }),
                  ),

                  const SizedBox(height: AppSizes.md),

                  // Section Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Saved Meals',
                        style: GoogleFonts.manrope(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: s.primary,
                        ),
                      ),
                      Obx(
                        () => Text(
                          '${controller.savedMeals.length} found',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: s.tertiary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.sm),
                ],
              ),
            ),
          ),

          // Saved Meals List / Empty State
          Obx(() {
            final isLoading = controller.isLoading.value;
            final meals = controller.savedMeals.toList();

            if (isLoading) {
              return const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (meals.isEmpty) {
              return SliverFillRemaining(
                hasScrollBody: false,
                child: AppEmptyState(
                  isDark: isDark,
                  icon: LucideIcons.utensils,
                  title: 'No saved meals found',
                  subtitle: controller.searchQuery.value.isNotEmpty
                      ? 'No meal matches "${controller.searchQuery.value}"'
                      : 'Create a custom meal by adding ingredients and defining quantities.',
                  actionLabel: '+ Add new meal',
                  onAction: _openAddNewMeal,
                ),
              );
            }

            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(AppSizes.lg, 0, AppSizes.lg, AppSizes.xxl),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final meal = meals[index];
                    return _SavedMealCard(
                      meal: meal,
                      isDark: isDark,
                      s: s,
                      onEdit: () => _editMeal(meal),
                      onLog: () => controller.logMeal(meal),
                      onDelete: () => _confirmDelete(context, controller, meal),
                    );
                  },
                  childCount: meals.length,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _SavedMealCard extends StatelessWidget {
  final SavedMeal meal;
  final bool isDark;
  final AppStyle s;
  final VoidCallback onEdit;
  final VoidCallback onLog;
  final VoidCallback onDelete;

  const _SavedMealCard({
    required this.meal,
    required this.isDark,
    required this.s,
    required this.onEdit,
    required this.onLog,
    required this.onDelete,
  });

  IconData _getCategoryIcon() {
    switch (meal.category.toLowerCase()) {
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

  Color _getCategoryColor() {
    switch (meal.category.toLowerCase()) {
      case 'breakfast':
        return AppColors.amber;
      case 'lunch':
        return isDark ? AppColors.primaryDark : AppColors.primary;
      case 'dinner':
        return isDark ? const Color(0xFF94A3B8) : AppColors.secondary;
      case 'snack':
      default:
        return isDark ? const Color(0xFFF97316) : AppColors.tertiary;
    }
  }

  Color _getCategoryBg() {
    switch (meal.category.toLowerCase()) {
      case 'breakfast':
        return isDark ? AppColors.amberSoftDark : AppColors.amberSoft;
      case 'lunch':
        return isDark ? AppColors.primarySoftDark : AppColors.primarySoft;
      case 'dinner':
        return isDark ? AppColors.secondarySoftDark : AppColors.secondarySoft;
      case 'snack':
      default:
        return isDark ? AppColors.tertiarySoftDark : AppColors.tertiarySoft;
    }
  }

  String _formatGrams(double val) {
    if (val == val.roundToDouble()) {
      return '${val.toInt()}g';
    }
    return '${val.toStringAsFixed(1)}g';
  }

  Widget _macroPill(String label, String value, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(width: 3.5),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white.withValues(alpha: 0.85) : AppColors.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ingredientsList = meal.items.map((i) {
      return i.ingredient.name.split('(').first.split('/').first.trim();
    }).toList();

    final subtitle = ingredientsList.isNotEmpty
        ? '${meal.category} · ${ingredientsList.join(', ')}'
        : meal.category;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.sm),
      child: Dismissible(
        key: Key(meal.id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onDelete(),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: AppColors.rose,
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          ),
          child: const Icon(LucideIcons.trash_2, color: Colors.white, size: 20),
        ),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onEdit,
          child: AppCard(
            isDark: isDark,
            padding: const EdgeInsets.all(AppSizes.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top Row: Category Icon + Title/Ingredients + Calories ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: _getCategoryBg(),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getCategoryIcon(),
                        size: 20,
                        color: _getCategoryColor(),
                      ),
                    ),
                    const SizedBox(width: AppSizes.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            meal.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.manrope(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: s.primary,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: s.tertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${meal.totalCalories}',
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: s.primary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          'kcal',
                          style: GoogleFonts.manrope(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: s.tertiary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // ── Subtle Divider ──
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    color: isDark
                        ? AppColors.borderDark.withValues(alpha: 0.4)
                        : AppColors.borderLight.withValues(alpha: 0.7),
                  ),
                ),

                // ── Bottom Row: Macro Micro-Pills & Clean Actions ──
                Row(
                  children: [
                    _macroPill(
                      'P',
                      _formatGrams(meal.totalProtein),
                      AppColors.macroProtein,
                      isDark ? AppColors.macroProteinSoftDark : AppColors.macroProteinSoft,
                    ),
                    const SizedBox(width: 5),
                    _macroPill(
                      'C',
                      _formatGrams(meal.totalCarbs),
                      AppColors.macroCarbs,
                      isDark ? AppColors.macroCarbsSoftDark : AppColors.macroCarsbSoft,
                    ),
                    const SizedBox(width: 5),
                    _macroPill(
                      'F',
                      _formatGrams(meal.totalFat),
                      AppColors.macroFats,
                      isDark ? AppColors.macroFatsSoftDark : AppColors.macroFatsSoft,
                    ),
                    const Spacer(),
                    PopupMenuButton<String>(
                      tooltip: 'Meal options',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      color: isDark ? AppColors.surfaceDark2 : Colors.white,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                        side: BorderSide(color: s.border),
                      ),
                      onSelected: (value) {
                        if (value == 'edit') onEdit();
                        if (value == 'delete') onDelete();
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          height: 38,
                          child: Row(
                            children: [
                              Icon(LucideIcons.pencil, size: 14, color: s.primary),
                              const SizedBox(width: 8),
                              Text(
                                'Edit meal',
                                style: GoogleFonts.manrope(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: s.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          height: 38,
                          child: Row(
                            children: [
                              const Icon(LucideIcons.trash_2, size: 14, color: AppColors.rose),
                              const SizedBox(width: 8),
                              Text(
                                'Delete',
                                style: GoogleFonts.manrope(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.rose,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDark2 : AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                          border: Border.all(color: s.border),
                        ),
                        child: Icon(
                          LucideIcons.ellipsis_vertical,
                          size: 14,
                          color: s.secondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AppButton.primary(
                      text: 'Log',
                      icon: LucideIcons.plus,
                      size: AppButtonSize.xs,
                      onPressed: onLog,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
