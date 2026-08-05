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

class DietView extends StatelessWidget {
  const DietView({super.key});

  void _openLogMeal() {
    Get.toNamed(Routes.logMeal);
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
                  // Calorie Card
                  AppCard(
                    isDark: isDark,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 96,
                          height: 96,
                          child: CustomPaint(
                            painter: _ArcPainter(
                              progress: controller.calorieProgress,
                              color: AppColors.primary,
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
                                    style: GoogleFonts.manrope(fontSize: 9, color: s.secondary),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSizes.lg),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Today\'s Calories',
                                style: GoogleFonts.manrope(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: s.secondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${controller.remainingCalories} remaining',
                                style: GoogleFonts.manrope(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: s.primary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'of ${controller.dailyCalorieGoal.value} kcal',
                                style: GoogleFonts.manrope(fontSize: 11, color: s.secondary),
                              ),
                              const SizedBox(height: AppSizes.sm),
                              Row(
                                children: [
                                  Icon(
                                    controller.totalCalories <= controller.dailyCalorieGoal.value
                                        ? LucideIcons.circle_check
                                        : LucideIcons.triangle_alert,
                                    size: 13,
                                    color: controller.totalCalories <= controller.dailyCalorieGoal.value
                                        ? AppColors.primary
                                        : AppColors.rose,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    controller.totalCalories <= controller.dailyCalorieGoal.value
                                        ? 'On track'
                                        : 'Goal exceeded',
                                    style: GoogleFonts.manrope(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: controller.totalCalories <= controller.dailyCalorieGoal.value
                                          ? AppColors.primary
                                          : AppColors.rose,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.md),

                  // Macros Section
                  AppSectionHeader(title: 'Macros', isDark: isDark),
                  const SizedBox(height: AppSizes.sm),
                  Row(
                    children: [
                      Expanded(
                        child: _MacroCard(
                          'Protein',
                          controller.totalProtein,
                          controller.proteinGoal.value,
                          'g',
                          AppColors.macroProtein,
                          isDark ? AppColors.macroProteinSoftDark : AppColors.macroProteinSoft,
                          LucideIcons.beef,
                          s,
                        ),
                      ),
                      const SizedBox(width: AppSizes.md),
                      Expanded(
                        child: _MacroCard(
                          'Carbs',
                          controller.totalCarbs,
                          controller.carbsGoal.value,
                          'g',
                          AppColors.macroCarbs,
                          isDark ? AppColors.macroCarbsSoftDark : AppColors.macroCarsbSoft,
                          LucideIcons.wheat,
                          s,
                        ),
                      ),
                      const SizedBox(width: AppSizes.md),
                      Expanded(
                        child: _MacroCard(
                          'Fats',
                          controller.totalFats,
                          controller.fatsGoal.value,
                          'g',
                          AppColors.macroFats,
                          isDark ? AppColors.macroFatsSoftDark : AppColors.macroFatsSoft,
                          LucideIcons.droplet,
                          s,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.xl),

                  // Meals Header & Log Meal Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppSectionHeader(title: 'Meals', isDark: isDark),
                      GestureDetector(
                        onTap: _openLogMeal,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.primarySoftDark : AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(LucideIcons.plus, size: 13, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text(
                                'Log meal',
                                style: GoogleFonts.manrope(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
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
                          onDismissed: (_) => controller.removeMeal(m.id),
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
                                        style: GoogleFonts.manrope(
                                          fontSize: 11,
                                          color: s.secondary,
                                        ),
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

class _MacroCard extends StatelessWidget {
  final String name, unit;
  final int current, goal;
  final Color color;
  final Color iconBg;
  final IconData icon;
  final AppStyle s;

  const _MacroCard(
    this.name,
    this.current,
    this.goal,
    this.unit,
    this.color,
    this.iconBg,
    this.icon,
    this.s,
  );

  @override
  Widget build(BuildContext context) {
    final progress = goal > 0 ? (current / goal).clamp(0.0, 1.0) : 0.0;

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
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 15, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w600, color: s.secondary),
          ),
          const SizedBox(height: 2),
          Text(
            '$current$unit',
            style: GoogleFonts.manrope(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: s.primary,
              letterSpacing: -0.3,
            ),
          ),
          Text(
            '/ $goal$unit',
            style: GoogleFonts.manrope(fontSize: 10, color: s.tertiary),
          ),
          const SizedBox(height: AppSizes.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
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
    final r = size.width / 2 - 8;
    const sw = 7.0;

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
