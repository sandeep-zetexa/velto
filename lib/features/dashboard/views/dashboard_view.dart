import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:velto/app/routes/app_pages.dart';
import 'package:velto/core/constants/app_colors.dart';
import 'package:velto/core/constants/app_sizes.dart';
import 'package:velto/core/widgets/app_widgets.dart';
import 'package:velto/features/dashboard/controllers/dashboard_controller.dart';
import 'package:velto/features/dashboard/widgets/session_muscle_map.dart';
import 'package:velto/features/home/controllers/home_controller.dart';

class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});

  void _goWorkout() {
    if (Get.isRegistered<HomeController>()) {
      Get.find<HomeController>().changeTab(1);
    }
  }

  void _goDiet() {
    if (Get.isRegistered<HomeController>()) {
      Get.find<HomeController>().changeTab(2);
    }
  }

  Future<void> _logMeal() async {
    await Get.toNamed(Routes.logMeal);
    controller.reload();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = AppStyle(isDark);

    return Scaffold(
      body: Obx(() {
        final loading = controller.isLoading.value;

        return RefreshIndicator(
          color: s.brand,
          onRefresh: controller.reload,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              AppSliverAppBar(
                title: 'Today',
                subtitle: controller.greeting,
                isDark: isDark,
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.screenPadding,
                  AppSizes.sm,
                  AppSizes.screenPadding,
                  120,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    if (loading && controller.caloriesLogged == 0 && !controller.hasActiveRoutine)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 48),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else ...[
                      // ── Overview banner ────────────────────────────────
                      AppCard(
                        isDark: isDark,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatDate(DateTime.now()),
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: s.brand,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              controller.motivationalLine,
                              style: GoogleFonts.manrope(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: s.primary,
                                height: 1.3,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: AppSizes.md),
                            Row(
                              children: [
                                _miniStat(
                                  '${controller.weekWorkoutsDone.value}',
                                  'Workouts this week',
                                  s,
                                ),
                                const SizedBox(width: AppSizes.lg),
                                _miniStat(
                                  '${controller.weekDaysLoggedMeals.value}',
                                  'Days with meals',
                                  s,
                                ),
                                const Spacer(),
                                if (controller.weekWorkoutsPlanned.value > 0)
                                  SizedBox(
                                    width: 72,
                                    height: 72,
                                    child: CustomPaint(
                                      painter: _RingPainter(
                                        progress: controller.weekConsistency,
                                        color: s.brand,
                                        trackColor: isDark
                                            ? AppColors.borderDark
                                            : AppColors.borderLight,
                                      ),
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              '${(controller.weekConsistency * 100).round()}%',
                                              style: GoogleFonts.manrope(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w800,
                                                color: s.primary,
                                              ),
                                            ),
                                            Text(
                                              'week',
                                              style: GoogleFonts.manrope(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w500,
                                                color: s.secondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSizes.lg),

                      // ── Quick actions ──────────────────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: AppButton.soft(
                              text: 'Log meal',
                              icon: LucideIcons.utensils,
                              size: AppButtonSize.md,
                              fullWidth: true,
                              onPressed: _logMeal,
                            ),
                          ),
                          const SizedBox(width: AppSizes.sm),
                          Expanded(
                            child: AppButton(
                              text: controller.hasActiveRoutine
                                  ? (controller.isRestDayToday
                                      ? 'View plan'
                                      : (controller.todayWorkoutStarted
                                          ? 'Continue'
                                          : 'Start workout'))
                                  : 'Create plan',
                              icon: LucideIcons.dumbbell,
                              size: AppButtonSize.md,
                              fullWidth: true,
                              onPressed: () {
                                if (!controller.hasActiveRoutine) {
                                  Get.toNamed(Routes.addRoutine)
                                      ?.then((_) => controller.reload());
                                } else {
                                  _goWorkout();
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.xl),

                      // ── Nutrition ──────────────────────────────────────
                      AppSectionHeader(
                        title: 'Nutrition',
                        action: 'Open diet',
                        isDark: isDark,
                        onAction: _goDiet,
                      ),
                      const SizedBox(height: AppSizes.md),
                      AppCard(
                        isDark: isDark,
                        padding: const EdgeInsets.all(AppSizes.md),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                SizedBox(
                                  width: 78,
                                  height: 78,
                                  child: CustomPaint(
                                    painter: _RingPainter(
                                      progress: controller.calorieProgress,
                                      color: s.brand,
                                      trackColor: s.border,
                                    ),
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            '${controller.caloriesLogged}',
                                            style: GoogleFonts.manrope(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w800,
                                              color: s.primary,
                                              letterSpacing: -0.4,
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
                                            'Calories today',
                                            style: GoogleFonts.manrope(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: s.secondary,
                                            ),
                                          ),
                                          _statusChip(
                                            controller.mealsLogged == 0
                                                ? 'Not started'
                                                : (controller.caloriesLogged <=
                                                        controller.calorieGoal
                                                    ? 'On track'
                                                    : 'Over goal'),
                                            controller.mealsLogged == 0
                                                ? s.secondary
                                                : (controller.caloriesLogged <=
                                                        controller.calorieGoal
                                                    ? s.brand
                                                    : AppColors.rose),
                                            controller.mealsLogged == 0
                                                ? (isDark
                                                    ? AppColors.secondarySoftDark
                                                    : AppColors.secondarySoft)
                                                : (controller.caloriesLogged <=
                                                        controller.calorieGoal
                                                    ? s.brandSoft
                                                    : (isDark
                                                        ? AppColors.roseSoftDark
                                                        : AppColors.roseSoft)),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        controller.mealsLogged == 0
                                            ? 'No meals logged yet'
                                            : '${controller.caloriesRemaining} kcal left',
                                        style: GoogleFonts.manrope(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w800,
                                          color: s.primary,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Goal ${controller.calorieGoal} kcal · ${controller.mealsLogged} meal${controller.mealsLogged == 1 ? '' : 's'}',
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
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Divider(
                                height: 1,
                                color: s.border.withValues(alpha: 0.7),
                              ),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: _macroMini(
                                    'Protein',
                                    controller.proteinLogged,
                                    controller.proteinGoal,
                                    AppColors.macroProtein,
                                    s,
                                  ),
                                ),
                                Expanded(
                                  child: _macroMini(
                                    'Carbs',
                                    controller.carbsLogged,
                                    controller.carbsGoal,
                                    AppColors.macroCarbs,
                                    s,
                                  ),
                                ),
                                Expanded(
                                  child: _macroMini(
                                    'Fats',
                                    controller.fatsLogged,
                                    controller.fatsGoal,
                                    AppColors.macroFats,
                                    s,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSizes.xl),

                      // ── Today's workout ────────────────────────────────
                      AppSectionHeader(
                        title: "Today's workout",
                        action: 'Open workout',
                        isDark: isDark,
                        onAction: _goWorkout,
                      ),
                      const SizedBox(height: AppSizes.md),
                      if (!controller.hasActiveRoutine)
                        AppEmptyState(
                          isDark: isDark,
                          icon: LucideIcons.dumbbell,
                          title: 'No workout plan yet',
                          subtitle:
                              'Create a weekly routine so Velto can show today\'s session here.',
                          actionLabel: 'Create plan',
                          onAction: () {
                            Get.toNamed(Routes.addRoutine)
                                ?.then((_) => controller.reload());
                          },
                        )
                      else
                        AppCard(
                          isDark: isDark,
                          padding: const EdgeInsets.all(AppSizes.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  if (controller.isRestDayToday) ...[
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? AppColors.greenSoftDark
                                            : AppColors.greenSoft,
                                        borderRadius: BorderRadius.circular(11),
                                      ),
                                      child: const Icon(
                                        LucideIcons.sparkles,
                                        size: 20,
                                        color: AppColors.green,
                                      ),
                                    ),
                                    const SizedBox(width: AppSizes.md),
                                  ],
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          controller.todayWorkoutFocus,
                                          style: GoogleFonts.manrope(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: s.primary,
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          controller.todayRoutineName,
                                          style: GoogleFonts.manrope(
                                            fontSize: 12,
                                            color: s.secondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (controller.todayWorkoutComplete)
                                    _statusChip(
                                      'Done',
                                      AppColors.green,
                                      isDark
                                          ? AppColors.greenSoftDark
                                          : AppColors.greenSoft,
                                    )
                                  else if (controller.isRestDayToday)
                                    _statusChip(
                                      'Rest',
                                      AppColors.green,
                                      isDark
                                          ? AppColors.greenSoftDark
                                          : AppColors.greenSoft,
                                    )
                                  else if (controller.todayWorkoutStarted)
                                    _statusChip(
                                      '${controller.todaySetsDone}/${controller.todaySetsTotal}',
                                      s.brand,
                                      s.brandSoft,
                                    ),
                                ],
                              ),
                              if (!controller.isRestDayToday) ...[
                                const SizedBox(height: AppSizes.md),
                                SessionMuscleMap(
                                  muscles: SessionMuscleMap.fromLabels(
                                    controller.todayMuscleLabels,
                                  ),
                                  accent: s.brand,
                                  body: isDark
                                      ? const Color(0xFF2A2E38)
                                      : const Color(0xFFE2E8F0),
                                  outline: isDark
                                      ? const Color(0xFF3D4454)
                                      : const Color(0xFFCBD5E1),
                                  caption: s.tertiary,
                                ),
                              ],
                              if (!controller.isRestDayToday &&
                                  controller.todaySetsTotal > 0) ...[
                                const SizedBox(height: AppSizes.md),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(3),
                                  child: LinearProgressIndicator(
                                    value: controller.todayWorkoutProgress,
                                    minHeight: 5,
                                    backgroundColor: isDark
                                        ? AppColors.surfaceDark2
                                        : AppColors.secondarySoft,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      controller.todayWorkoutComplete
                                          ? AppColors.green
                                          : s.brand,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  controller.todayWorkoutStarted
                                      ? '${controller.todaySetsDone} of ${controller.todaySetsTotal} sets complete'
                                      : '${controller.todaySetsTotal} sets planned · tap Continue to train',
                                  style: GoogleFonts.manrope(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: s.secondary,
                                  ),
                                ),
                              ],
                              if (controller.isRestDayToday) ...[
                                const SizedBox(height: AppSizes.sm),
                                Text(
                                  'No lifting today. Focus on recovery, sleep, and hitting your macros.',
                                  style: GoogleFonts.manrope(
                                    fontSize: 12,
                                    color: s.secondary,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      const SizedBox(height: AppSizes.xl),

                      // ── Recent activity ────────────────────────────────
                      AppSectionHeader(
                        title: 'Recent activity',
                        isDark: isDark,
                      ),
                      const SizedBox(height: AppSizes.md),
                      if (controller.recentActivity.isEmpty)
                        AppEmptyState(
                          isDark: isDark,
                          icon: LucideIcons.activity,
                          title: 'Nothing logged yet',
                          subtitle:
                              'Meals and workouts you track will show up here.',
                          actionLabel: 'Log a meal',
                          onAction: _logMeal,
                        )
                      else
                        ...controller.recentActivity.map((a) {
                          final meta = _activityMeta(a.type, isDark, s);
                          return AppActivityRow(
                            icon: meta.$1,
                            iconBg: meta.$2,
                            iconColor: meta.$3,
                            title: a.title,
                            sub: a.subtitle,
                            isDark: isDark,
                          );
                        }),
                    ],
                  ]),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  (IconData, Color, Color) _activityMeta(
    DashboardActivityType type,
    bool isDark,
    AppStyle s,
  ) {
    switch (type) {
      case DashboardActivityType.workout:
        return (LucideIcons.dumbbell, s.brandSoft, s.brand);
      case DashboardActivityType.meal:
        return (
          LucideIcons.utensils,
          isDark ? AppColors.amberSoftDark : AppColors.amberSoft,
          AppColors.amber,
        );
      case DashboardActivityType.nutrition:
        return (
          LucideIcons.apple,
          isDark ? AppColors.greenSoftDark : AppColors.greenSoft,
          AppColors.green,
        );
    }
  }

  Widget _statusChip(String label, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.manrope(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _macroMini(
    String name,
    int current,
    int goal,
    Color color,
    AppStyle s,
  ) {
    return Column(
      children: [
        Text(
          name,
          style: GoogleFonts.manrope(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: s.secondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${current}g',
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          '/ ${goal}g',
          style: GoogleFonts.manrope(
            fontSize: 10,
            color: s.tertiary,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]}';
  }
}

Widget _miniStat(String value, String label, AppStyle s) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: s.primary,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.manrope(fontSize: 11, color: s.secondary),
        ),
      ],
    );

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color, trackColor;

  const _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 7;
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
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}
