import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:velto/core/constants/app_colors.dart';
import 'package:velto/core/constants/app_sizes.dart';
import 'package:velto/core/widgets/app_widgets.dart';

class MealMacroSummaryCard extends StatelessWidget {
  final int totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final int servings;
  final bool isDark;

  const MealMacroSummaryCard({
    super.key,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.servings,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final s = AppStyle(isDark);

    // Calculate calorie contribution from macros (4 kcal/g protein, 4 kcal/g carb, 9 kcal/g fat)
    final proteinKcal = totalProtein * 4;
    final carbsKcal = totalCarbs * 4;
    final fatKcal = totalFat * 9;
    final totalMacroKcal = proteinKcal + carbsKcal + fatKcal;

    final proteinFlex = totalMacroKcal > 0 ? (proteinKcal / totalMacroKcal * 100).round() : 33;
    final carbsFlex = totalMacroKcal > 0 ? (carbsKcal / totalMacroKcal * 100).round() : 33;
    final fatFlex = totalMacroKcal > 0 ? (fatKcal / totalMacroKcal * 100).round() : 34;

    return AppCard(
      isDark: isDark,
      padding: const EdgeInsets.all(AppSizes.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Title & Total Calories
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(LucideIcons.flame, size: 16, color: s.brand),
                      const SizedBox(width: 6),
                      Text(
                        'Total Nutrition',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: s.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '$totalCalories',
                        style: GoogleFonts.manrope(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: s.primary,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'kcal',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: s.secondary,
                        ),
                      ),
                      if (servings > 1) ...[
                        const SizedBox(width: 8),
                        Text(
                          '(${(totalCalories / servings).round()} kcal / serving)',
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            color: s.tertiary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: s.brandSoft,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: Text(
                  '$servings ${servings == 1 ? "serving" : "servings"}',
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: s.brand,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSizes.md),

          // Proportional Macro Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 6,
              child: totalMacroKcal > 0
                  ? Row(
                      children: [
                        if (proteinFlex > 0)
                          Expanded(
                            flex: proteinFlex,
                            child: Container(color: AppColors.macroProtein),
                          ),
                        if (carbsFlex > 0)
                          Expanded(
                            flex: carbsFlex,
                            child: Container(color: AppColors.macroCarbs),
                          ),
                        if (fatFlex > 0)
                          Expanded(
                            flex: fatFlex,
                            child: Container(color: AppColors.macroFats),
                          ),
                      ],
                    )
                  : Container(color: s.border),
            ),
          ),

          const SizedBox(height: AppSizes.md),

          // 3 Columns: Protein, Carbs, Fats
          Row(
            children: [
              Expanded(
                child: _MacroPill(
                  label: 'Protein',
                  amount: '${totalProtein}g',
                  color: AppColors.macroProtein,
                  softBg: isDark ? AppColors.macroProteinSoftDark : AppColors.macroProteinSoft,
                  s: s,
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: _MacroPill(
                  label: 'Carbs',
                  amount: '${totalCarbs}g',
                  color: AppColors.macroCarbs,
                  softBg: isDark ? AppColors.macroCarbsSoftDark : AppColors.macroCarsbSoft,
                  s: s,
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: _MacroPill(
                  label: 'Fats',
                  amount: '${totalFat}g',
                  color: AppColors.macroFats,
                  softBg: isDark ? AppColors.macroFatsSoftDark : AppColors.macroFatsSoft,
                  s: s,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroPill extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;
  final Color softBg;
  final AppStyle s;

  const _MacroPill({
    required this.label,
    required this.amount,
    required this.color,
    required this.softBg,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: softBg,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.manrope(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            amount,
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: s.primary,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}
