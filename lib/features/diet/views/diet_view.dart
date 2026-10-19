import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:velto/app/routes/app_pages.dart';
import 'package:velto/core/constants/app_colors.dart';
import 'package:velto/core/constants/app_sizes.dart';
import 'package:velto/core/widgets/app_widgets.dart';
import 'package:velto/features/diet/controllers/diet_controller.dart';
import 'package:velto/features/diet/models/meal_model.dart';

class DietView extends StatelessWidget {
  const DietView({super.key});

  void _openLogMeal() {
    Get.toNamed(Routes.logMeal);
  }

  void _confirmDeleteLoggedMeal(BuildContext context, DietController controller, MealModel meal) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Remove Meal?',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
        ),
        content: Text('Remove "${meal.title}" from today\'s tracked meals?'),
        actions: [
          AppButton.text(
            text: 'Cancel',
            size: AppButtonSize.sm,
            onPressed: () => Navigator.pop(ctx),
          ),
          AppButton.danger(
            text: 'Remove',
            size: AppButtonSize.sm,
            onPressed: () {
              Navigator.pop(ctx);
              controller.removeMeal(meal.id);
              Get.snackbar(
                'Meal Removed',
                'Removed "${meal.title}" from today\'s log',
                snackPosition: SnackPosition.BOTTOM,
                margin: const EdgeInsets.all(16),
                duration: const Duration(seconds: 2),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _macroBadge(String label, String value, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(5),
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
          const SizedBox(width: 3),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = AppStyle(isDark);
    final controller = Get.put(DietController());

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          AppSliverAppBar(
            title: 'Diet',
            subtitle: 'Nutrition',
            isDark: isDark,
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppSizes.lg, AppSizes.sm, AppSizes.lg, 120),
            sliver: Obx(
              () => SliverList(
                delegate: SliverChildListDelegate([
                  // ── Unified Nutrition & Macros Tracking Card ────────
                  AppCard(
                    isDark: isDark,
                    padding: const EdgeInsets.all(AppSizes.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Tier: Calories with Arc Progress
                        Row(
                          children: [
                            SizedBox(
                              width: 78,
                              height: 78,
                              child: CustomPaint(
                                painter: _ArcPainter(
                                  progress: controller.calorieProgress,
                                  color: s.brand,
                                  trackColor: s.border,
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '${controller.totalCalories}',
                                        style: GoogleFonts.manrope(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: s.primary,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      Text(
                                        'kcal',
                                        style: GoogleFonts.manrope(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600,
                                          color: s.secondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSizes.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Today\'s Calories',
                                        style: GoogleFonts.manrope(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: s.secondary,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                        decoration: BoxDecoration(
                                          color: controller.totalCalories <= controller.dailyCalorieGoal.value
                                              ? s.brandSoft
                                              : (isDark ? AppColors.roseSoftDark : AppColors.roseSoft),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              controller.totalCalories <= controller.dailyCalorieGoal.value
                                                  ? LucideIcons.circle_check
                                                  : LucideIcons.triangle_alert,
                                              size: 11,
                                              color: controller.totalCalories <= controller.dailyCalorieGoal.value
                                                  ? s.brand
                                                  : AppColors.rose,
                                            ),
                                            const SizedBox(width: 3.5),
                                            Text(
                                              controller.totalCalories <= controller.dailyCalorieGoal.value
                                                  ? 'On track'
                                                  : 'Goal exceeded',
                                              style: GoogleFonts.manrope(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: controller.totalCalories <= controller.dailyCalorieGoal.value
                                                    ? s.brand
                                                    : AppColors.rose,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${controller.remainingCalories} remaining',
                                    style: GoogleFonts.manrope(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: s.primary,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'of ${controller.dailyCalorieGoal.value} kcal goal',
                                    style: GoogleFonts.manrope(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: s.tertiary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Faint divider separating Calories & Macros
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Divider(
                            height: 1,
                            thickness: 1,
                            color: isDark
                                ? AppColors.borderDark.withValues(alpha: 0.5)
                                : AppColors.borderLight.withValues(alpha: 0.7),
                          ),
                        ),

                        // Bottom Tier: 3 Associated Macro Wells
                        Row(
                          children: [
                            Expanded(
                              child: _MacroItem(
                                name: 'Protein',
                                current: controller.totalProtein,
                                goal: controller.proteinGoal.value,
                                unit: 'g',
                                color: AppColors.macroProtein,
                                iconBg: isDark ? AppColors.macroProteinSoftDark : AppColors.macroProteinSoft,
                                icon: LucideIcons.beef,
                                s: s,
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(width: AppSizes.xs),
                            Expanded(
                              child: _MacroItem(
                                name: 'Carbs',
                                current: controller.totalCarbs,
                                goal: controller.carbsGoal.value,
                                unit: 'g',
                                color: AppColors.macroCarbs,
                                iconBg: isDark ? AppColors.macroCarbsSoftDark : AppColors.macroCarsbSoft,
                                icon: LucideIcons.wheat,
                                s: s,
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(width: AppSizes.xs),
                            Expanded(
                              child: _MacroItem(
                                name: 'Fats',
                                current: controller.totalFats,
                                goal: controller.fatsGoal.value,
                                unit: 'g',
                                color: AppColors.macroFats,
                                iconBg: isDark ? AppColors.macroFatsSoftDark : AppColors.macroFatsSoft,
                                icon: LucideIcons.droplet,
                                s: s,
                                isDark: isDark,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.xl),

                  // Meals Header & Log Meal Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppSectionHeader(title: 'Meals', isDark: isDark),
                      AppButton.soft(
                        text: 'Log meal',
                        icon: LucideIcons.plus,
                        size: AppButtonSize.xs,
                        onPressed: _openLogMeal,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.md),

                  // Meals List / Empty State
                  if (controller.meals.isEmpty)
                    AppEmptyState(
                      isDark: isDark,
                      icon: LucideIcons.utensils_crossed,
                      title: 'Nothing logged yet',
                      subtitle: 'Tap "Log meal" to track your\nfirst meal of the day.',
                      actionLabel: '+ Log meal',
                      onAction: _openLogMeal,
                    )
                  else
                    ...controller.meals.map(
                      (m) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSizes.sm),
                        child: Dismissible(
                          key: Key(m.id),
                          direction: DismissDirection.endToStart,
                          onDismissed: (_) {
                            controller.removeMeal(m.id);
                            Get.snackbar(
                              'Meal Removed',
                              'Removed "${m.title}" from today\'s log',
                              snackPosition: SnackPosition.BOTTOM,
                              margin: const EdgeInsets.all(16),
                              duration: const Duration(seconds: 2),
                            );
                          },
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: AppColors.rose,
                              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                            ),
                            child: const Icon(LucideIcons.trash_2, color: Colors.white, size: 20),
                          ),
                          child: AppCard(
                            isDark: isDark,
                            padding: const EdgeInsets.all(AppSizes.md),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: m.getIconBg(isDark),
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                  child: Icon(
                                    m.icon,
                                    size: 20,
                                    color: m.getIconColor(isDark),
                                  ),
                                ),
                                const SizedBox(width: AppSizes.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            m.category,
                                            style: GoogleFonts.manrope(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: s.primary,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '· ${m.time}',
                                            style: GoogleFonts.manrope(
                                              fontSize: 11,
                                              color: s.secondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        m.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.manrope(
                                          fontSize: 11,
                                          color: s.secondary,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 4,
                                        runSpacing: 4,
                                        children: [
                                          _macroBadge(
                                            'P',
                                            '${m.protein}g',
                                            AppColors.macroProtein,
                                            isDark ? AppColors.macroProteinSoftDark : AppColors.macroProteinSoft,
                                          ),
                                          _macroBadge(
                                            'C',
                                            '${m.carbs}g',
                                            AppColors.macroCarbs,
                                            isDark ? AppColors.macroCarbsSoftDark : AppColors.macroCarbsSoft,
                                          ),
                                          _macroBadge(
                                            'F',
                                            '${m.fats}g',
                                            AppColors.macroFats,
                                            isDark ? AppColors.macroFatsSoftDark : AppColors.macroFatsSoft,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${m.calories}',
                                      style: GoogleFonts.manrope(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: s.primary,
                                      ),
                                    ),
                                    Text(
                                      'kcal',
                                      style: GoogleFonts.manrope(
                                        fontSize: 10,
                                        color: s.secondary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: AppSizes.sm),
                                AppButton.icon(
                                  icon: LucideIcons.trash_2,
                                  size: AppButtonSize.xs,
                                  variant: AppButtonVariant.danger,
                                  customBgColor: isDark ? AppColors.roseSoftDark : AppColors.roseSoft,
                                  customTextColor: AppColors.rose,
                                  onPressed: () => _confirmDeleteLoggedMeal(context, controller, m),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroItem extends StatelessWidget {
  final String name, unit;
  final int current, goal;
  final Color color;
  final Color iconBg;
  final IconData icon;
  final AppStyle s;
  final bool isDark;

  const _MacroItem({
    required this.name,
    required this.current,
    required this.goal,
    required this.unit,
    required this.color,
    required this.iconBg,
    required this.icon,
    required this.s,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final progress = goal > 0 ? (current / goal).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark2 : AppColors.secondarySoft.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Icon(icon, size: 11, color: color),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: s.secondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$current',
                style: GoogleFonts.manrope(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: s.primary,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                unit,
                style: GoogleFonts.manrope(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: s.secondary,
                ),
              ),
              const Spacer(),
              Text(
                '$goal$unit',
                style: GoogleFonts.manrope(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: s.tertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 3.5,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double progress;
  final Color color, trackColor;

  const _ArcPainter({required this.progress, required this.color, required this.trackColor});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 6;
    const sw = 6.0;

    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.progress != progress;
}
