import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:velto/core/constants/app_colors.dart';
import 'package:velto/core/constants/app_sizes.dart';
import 'package:velto/core/widgets/app_widgets.dart';
import 'package:velto/features/diet/controllers/add_meal_controller.dart';
import 'package:velto/features/diet/models/ingredient.dart';

class IngredientPickerSheet extends StatefulWidget {
  final AddMealController controller;
  final String? initialQuery;

  const IngredientPickerSheet({
    super.key,
    required this.controller,
    this.initialQuery,
  });

  static Future<void> show(
    BuildContext context,
    AddMealController controller, {
    String? initialQuery,
  }) {
    if (initialQuery != null && initialQuery.isNotEmpty) {
      controller.onCatalogSearchChanged(initialQuery);
    } else {
      controller.onCatalogSearchChanged('');
    }
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => IngredientPickerSheet(
        controller: controller,
        initialQuery: initialQuery,
      ),
    );
  }

  @override
  State<IngredientPickerSheet> createState() => _IngredientPickerSheetState();
}

class _IngredientPickerSheetState extends State<IngredientPickerSheet> {
  Ingredient? _selectedIngredient;
  double _quantity = 100.0;
  late final TextEditingController _qtyController;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _qtyController = TextEditingController(text: '100');
    _searchController = TextEditingController(text: widget.initialQuery ?? '');
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onIngredientTapped(Ingredient ing) {
    setState(() {
      _selectedIngredient = ing;
      _quantity = ing.nutritionPer.amount > 0 ? ing.nutritionPer.amount : 100.0;
      _qtyController.text = _quantity.toStringAsFixed(_quantity % 1 == 0 ? 0 : 1);
    });
  }

  void _onQuantityChanged(double newQty) {
    if (newQty < 1) newQty = 1;
    setState(() {
      _quantity = newQty;
      _qtyController.text = _quantity.toStringAsFixed(_quantity % 1 == 0 ? 0 : 1);
    });
  }

  IconData _iconForCategory(String category) {
    switch (category) {
      case 'Protein':
        return LucideIcons.beef;
      case 'Grains':
        return LucideIcons.wheat;
      case 'Dairy':
        return LucideIcons.milk;
      case 'Vegetables':
        return LucideIcons.carrot;
      case 'Fruits':
        return LucideIcons.apple;
      case 'Legumes':
        return LucideIcons.bean;
      case 'Nuts & Seeds':
        return LucideIcons.nut;
      case 'Oils & Fats':
        return LucideIcons.droplets;
      case 'Beverages':
        return LucideIcons.coffee;
      case 'Supplements':
        return LucideIcons.dumbbell;
      case 'Condiments':
        return LucideIcons.utensils;
      default:
        return LucideIcons.apple;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = AppStyle(isDark);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXl)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: AppSizes.sm),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: s.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg, vertical: AppSizes.xs),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedIngredient == null ? 'Select Ingredient' : 'Configure Quantity',
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: s.primary,
                    letterSpacing: -0.3,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    if (_selectedIngredient != null) {
                      setState(() => _selectedIngredient = null);
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  icon: Icon(
                    _selectedIngredient != null ? LucideIcons.arrow_left : LucideIcons.x,
                    color: s.secondary,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          Expanded(
            child: _selectedIngredient == null
                ? _buildIngredientCatalog(s, isDark)
                : _buildQuantityConfig(s, isDark),
          ),
        ],
      ),
    );
  }

  // ── Step 1: Ingredient Catalog List ──────────────────────────────────────

  Widget _buildIngredientCatalog(AppStyle s, bool isDark) {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSizes.lg, AppSizes.md, AppSizes.lg, AppSizes.sm),
          child: AppSearchBar(
            controller: _searchController,
            hintText: 'Search milk, oats, eggs, chicken...',
            isDark: isDark,
            onChanged: widget.controller.onCatalogSearchChanged,
          ),
        ),

        // Categories chip list
        SizedBox(
          height: 38,
          child: Obx(() {
            final selected = widget.controller.catalogCategory.value;
            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
              scrollDirection: Axis.horizontal,
              children: widget.controller.catalogCategories.map((cat) {
                final isSelected = selected == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: AppSizes.xs),
                  child: GestureDetector(
                    onTap: () => widget.controller.onCatalogCategoryChanged(cat),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? s.brand
                            : (isDark ? AppColors.surfaceDark2 : AppColors.secondarySoft),
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
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? (isDark ? const Color(0xFF042017) : Colors.white) : s.primary,
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

        const SizedBox(height: AppSizes.sm),

        // Ingredients list
        Expanded(
          child: Obx(() {
            final isLoading = widget.controller.isCatalogLoading.value;
            final list = widget.controller.catalogIngredients.toList();

            if (isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (list.isEmpty) {
              return Center(
                child: Text(
                  'No ingredients found',
                  style: GoogleFonts.manrope(color: s.secondary),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg, vertical: AppSizes.sm),
              itemCount: list.length,
              separatorBuilder: (_, index) => const SizedBox(height: AppSizes.sm),
              itemBuilder: (context, index) {
                final ing = list[index];
                return GestureDetector(
                  onTap: () => _onIngredientTapped(ing),
                  child: Container(
                    padding: const EdgeInsets.all(AppSizes.md),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark2 : AppColors.bgLight,
                      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                      border: Border.all(color: s.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: s.brandSoft,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(_iconForCategory(ing.category), size: 20, color: s.brand),
                        ),
                        const SizedBox(width: AppSizes.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ing.name,
                                style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: s.primary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${ing.brand != null ? "${ing.brand} · " : ""}${ing.nutritionPer.amount.toInt()} ${ing.nutritionPer.unit} · ${ing.macros.calories.round()} kcal',
                                style: GoogleFonts.manrope(
                                  fontSize: 11,
                                  color: s.secondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  _miniBadge('P: ${ing.macros.protein}g', AppColors.macroProtein),
                                  const SizedBox(width: 4),
                                  _miniBadge('C: ${ing.macros.carbs}g', AppColors.macroCarbs),
                                  const SizedBox(width: 4),
                                  _miniBadge('F: ${ing.macros.fat}g', AppColors.macroFats),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Icon(LucideIcons.circle_plus, size: 20, color: s.brand),
                      ],
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }

  // ── Step 2: Interactive Quantity & Live Macros Configuration ──────────────

  Widget _buildQuantityConfig(AppStyle s, bool isDark) {
    final ing = _selectedIngredient!;
    final baseAmount = ing.nutritionPer.amount > 0 ? ing.nutritionPer.amount : 100.0;
    final ratio = _quantity / baseAmount;
    final calcCalories = (ing.macros.calories * ratio).round();
    final calcProtein = (ing.macros.protein * ratio).toStringAsFixed(1);
    final calcCarbs = (ing.macros.carbs * ratio).toStringAsFixed(1);
    final calcFat = (ing.macros.fat * ratio).toStringAsFixed(1);

    // Quick suggestions depending on unit
    final isLiquid = ing.nutritionPer.unit.toLowerCase() == 'ml';
    final quickOptions = isLiquid
        ? [100.0, 150.0, 200.0, 250.0, 300.0]
        : [25.0, 50.0, 100.0, 150.0, 200.0];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ingredient Header Card
          Container(
            padding: const EdgeInsets.all(AppSizes.md),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark2 : AppColors.bgLight,
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              border: Border.all(color: s.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: s.brandSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(LucideIcons.utensils, size: 22, color: s.brand),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ing.name,
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: s.primary,
                        ),
                      ),
                      if (ing.brand != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          ing.brand!,
                          style: GoogleFonts.manrope(fontSize: 12, color: s.secondary),
                        ),
                      ],
                      const SizedBox(height: 2),
                      Text(
                        'Base: ${baseAmount.toInt()} ${ing.nutritionPer.unit} = ${ing.macros.calories.round()} kcal',
                        style: GoogleFonts.manrope(fontSize: 11, color: s.tertiary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSizes.lg),

          // Live Macro Preview Card
          Container(
            padding: const EdgeInsets.all(AppSizes.md),
            decoration: BoxDecoration(
              color: s.brandSoft,
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              border: Border.all(
                color: s.brand.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Live Macros for ${_quantity.toStringAsFixed(_quantity % 1 == 0 ? 0 : 1)} ${ing.nutritionPer.unit}',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: s.brand,
                      ),
                    ),
                    Text(
                      '$calcCalories kcal',
                      style: GoogleFonts.manrope(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: s.brand,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.sm),
                Row(
                  children: [
                    Expanded(
                      child: _macroStatBox('Protein', '${calcProtein}g', AppColors.macroProtein, isDark),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Expanded(
                      child: _macroStatBox('Carbs', '${calcCarbs}g', AppColors.macroCarbs, isDark),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Expanded(
                      child: _macroStatBox('Fats', '${calcFat}g', AppColors.macroFats, isDark),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSizes.xl),

          // Quantity Selector Label & Stepper
          Text(
            'Quantity (${ing.nutritionPer.unit})',
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: s.primary,
            ),
          ),
          const SizedBox(height: AppSizes.sm),

          // Stepper & Text Field Row
          Row(
            children: [
              _stepperButton(LucideIcons.minus, () {
                _onQuantityChanged(_quantity - (isLiquid ? 25 : 10));
              }, s),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark2 : AppColors.bgLight,
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    border: Border.all(color: s.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 90,
                        child: TextField(
                          controller: _qtyController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.manrope(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: s.primary,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (val) {
                            final parsed = double.tryParse(val);
                            if (parsed != null && parsed > 0) {
                              setState(() => _quantity = parsed);
                            }
                          },
                        ),
                      ),
                      Text(
                        ing.nutritionPer.unit,
                        style: GoogleFonts.manrope(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: s.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.md),
              _stepperButton(LucideIcons.plus, () {
                _onQuantityChanged(_quantity + (isLiquid ? 25 : 10));
              }, s),
            ],
          ),

          const SizedBox(height: AppSizes.md),

          // Quick Preset Chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: quickOptions.map((qty) {
              final isSelected = (_quantity - qty).abs() < 0.1;
              return GestureDetector(
                onTap: () => _onQuantityChanged(qty),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? s.brand
                        : (isDark ? AppColors.surfaceDark2 : AppColors.secondarySoft),
                    borderRadius: BorderRadius.circular(AppSizes.radiusRound),
                    border: Border.all(
                      color: isSelected ? s.brand : s.border,
                    ),
                  ),
                  child: Text(
                    '${qty.toInt()} ${ing.nutritionPer.unit}',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected ? (isDark ? const Color(0xFF042017) : Colors.white) : s.primary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: AppSizes.xxl),

          // Add to Meal Button
          AppButton.primary(
            text: 'Add ${_quantity.toStringAsFixed(_quantity % 1 == 0 ? 0 : 1)} ${ing.nutritionPer.unit} to Meal',
            icon: LucideIcons.plus,
            size: AppButtonSize.lg,
            fullWidth: true,
            onPressed: () {
              widget.controller.addIngredient(ing, _quantity, ing.nutritionPer.unit);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _stepperButton(IconData icon, VoidCallback onTap, AppStyle s) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: s.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(color: s.border),
        ),
        child: Icon(icon, size: 20, color: s.primary),
      ),
    );
  }

  Widget _miniBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: GoogleFonts.manrope(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _macroStatBox(String label, String value, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.manrope(fontSize: 10, color: color, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }
}
