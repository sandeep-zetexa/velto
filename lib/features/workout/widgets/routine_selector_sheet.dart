import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:velto/app/routes/app_pages.dart';
import 'package:velto/core/constants/app_colors.dart';
import 'package:velto/core/constants/app_sizes.dart';
import 'package:velto/core/widgets/app_widgets.dart';
import 'package:velto/features/workout/controllers/workout_controller.dart';
import 'package:velto/features/workout/models/workout_routine.dart';

class RoutineSelectorSheet extends StatelessWidget {
  final WorkoutController controller;

  const RoutineSelectorSheet({super.key, required this.controller});

  static Future<void> show(BuildContext context, WorkoutController controller) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RoutineSelectorSheet(controller: controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = AppStyle(isDark);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
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
            padding: const EdgeInsets.fromLTRB(AppSizes.md, AppSizes.xs, AppSizes.xs, AppSizes.xs),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Workout Routines',
                            style: GoogleFonts.manrope(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: s.primary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Obx(() => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: s.brandSoft,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${controller.allRoutines.length}',
                                  style: GoogleFonts.manrope(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: s.brand,
                                  ),
                                ),
                              )),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tap any plan to activate or customize',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          color: s.secondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(LucideIcons.x, color: s.secondary, size: 20),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Routine Cards List
          Expanded(
            child: Obx(() {
              final routines = controller.allRoutines.toList();

              if (routines.isEmpty) {
                return AppEmptyState(
                  isDark: isDark,
                  icon: LucideIcons.dumbbell,
                  title: 'No Workout Routines',
                  subtitle: 'You haven\'t created any workout splits yet.\nTap below to build your first routine.',
                  actionLabel: 'Create Routine',
                  onAction: () {
                    Navigator.pop(context);
                    Get.toNamed(Routes.addRoutine);
                  },
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(AppSizes.md, AppSizes.sm, AppSizes.md, AppSizes.sm),
                itemCount: routines.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final routine = routines[index];
                  final isActive = routine.isActive;

                  return Material(
                    color: isDark ? AppColors.surfaceDark2 : Colors.white,
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    child: InkWell(
                      onTap: isActive
                          ? null
                          : () {
                              controller.switchActiveRoutine(routine.id);
                              Navigator.pop(context);
                            },
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                          border: Border.all(
                            color: isActive ? s.brand : s.border,
                            width: isActive ? 1.5 : 1.0,
                          ),
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: s.brand.withValues(alpha: isDark ? 0.2 : 0.08),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Header: Icon, Name, Frequency & Active Status
                            Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? s.brandSoft
                                        : (isDark ? AppColors.surfaceDark : AppColors.secondarySoft),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    LucideIcons.dumbbell,
                                    size: 16,
                                    color: isActive ? s.brand : s.secondary,
                                  ),
                                ),
                                const SizedBox(width: AppSizes.sm + 2),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        routine.name,
                                        style: GoogleFonts.manrope(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w800,
                                          color: s.primary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                            decoration: BoxDecoration(
                                              color: s.brandSoft,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              '${routine.totalWorkoutsInWeek}d/week',
                                              style: GoogleFonts.manrope(
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.w700,
                                                color: s.brand,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                            decoration: BoxDecoration(
                                              color: isDark ? AppColors.surfaceDark : AppColors.secondarySoft,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              '${routine.totalExercisesInWeek} exercises',
                                              style: GoogleFonts.manrope(
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.w600,
                                                color: s.secondary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                if (isActive)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                                    decoration: BoxDecoration(
                                      color: s.brandSoft,
                                      borderRadius: BorderRadius.circular(AppSizes.radiusRound),
                                      border: Border.all(color: s.brand.withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(LucideIcons.check, size: 11, color: s.brand),
                                        const SizedBox(width: 3),
                                        Text(
                                          'ACTIVE',
                                          style: GoogleFonts.manrope(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                            color: s.brand,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  AppButton.soft(
                                    text: 'Switch',
                                    size: AppButtonSize.xs,
                                    icon: LucideIcons.arrow_right,
                                    onPressed: () {
                                      controller.switchActiveRoutine(routine.id);
                                      Navigator.pop(context);
                                    },
                                  ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            // 2. Horizontally Scrollable 7-Day Rhythm Strip
                            Container(
                              padding: const EdgeInsets.all(AppSizes.sm),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.surfaceDark : AppColors.bgLight,
                                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                                border: Border.all(color: s.border.withValues(alpha: 0.6)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(LucideIcons.calendar_days, size: 11, color: s.secondary),
                                          const SizedBox(width: 4),
                                          Text(
                                            '7-Day Breakdown',
                                            style: GoogleFonts.manrope(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w700,
                                              color: s.secondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Swipe for all days',
                                            style: GoogleFonts.manrope(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w600,
                                              color: s.tertiary,
                                            ),
                                          ),
                                          const SizedBox(width: 1),
                                          Icon(LucideIcons.chevron_right, size: 10, color: s.tertiary),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    physics: const BouncingScrollPhysics(),
                                    child: Row(
                                      children: routine.days.asMap().entries.map((entry) {
                                        final index = entry.key;
                                        final d = entry.value;
                                        final isRest = d.isRestDay;
                                        final isToday = index == controller.todayDayIndex;

                                        return Container(
                                          width: 116,
                                          height: 82,
                                          margin: EdgeInsets.only(
                                            right: index == routine.days.length - 1 ? 0 : 7,
                                          ),
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: isRest
                                                ? (isToday
                                                    ? (isDark ? s.brand.withValues(alpha: 0.12) : s.brandSoft)
                                                    : (isDark ? AppColors.surfaceDark2 : Colors.white))
                                                : (isActive
                                                    ? (isToday ? s.brand.withValues(alpha: 0.22) : s.brandSoft)
                                                    : (isToday
                                                        ? (isDark ? s.brand.withValues(alpha: 0.15) : s.brandSoft)
                                                        : (isDark ? AppColors.surfaceDark2 : Colors.white))),
                                            borderRadius: BorderRadius.circular(AppSizes.radiusSm + 2),
                                            border: Border.all(
                                              color: isToday
                                                  ? s.brand
                                                  : (isRest
                                                      ? s.border.withValues(alpha: 0.5)
                                                      : (isActive ? s.brand.withValues(alpha: 0.35) : s.border)),
                                              width: isToday ? 1.5 : 1.0,
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    d.dayShort,
                                                    style: GoogleFonts.manrope(
                                                      fontSize: 10.5,
                                                      fontWeight: isToday ? FontWeight.w800 : FontWeight.w700,
                                                      color: isToday
                                                          ? s.brand
                                                          : (isRest ? s.tertiary : s.secondary),
                                                    ),
                                                  ),
                                                  if (isToday)
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                                      decoration: BoxDecoration(
                                                        color: s.brand,
                                                        borderRadius: BorderRadius.circular(3),
                                                      ),
                                                      child: Text(
                                                        'TODAY',
                                                        style: GoogleFonts.manrope(
                                                          fontSize: 7,
                                                          fontWeight: FontWeight.w800,
                                                          color: Colors.white,
                                                          letterSpacing: 0.2,
                                                        ),
                                                      ),
                                                    )
                                                  else if (isRest)
                                                    Icon(LucideIcons.sparkles, size: 11, color: s.tertiary),
                                                ],
                                              ),
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    isRest ? 'Rest Day' : d.musclesDisplay,
                                                    style: GoogleFonts.manrope(
                                                      fontSize: 11,
                                                      fontWeight: isToday ? FontWeight.w800 : FontWeight.w700,
                                                      color: isToday
                                                          ? s.brand
                                                          : (isActive ? s.brand : s.primary),
                                                      height: 1.15,
                                                    ),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    isRest
                                                        ? 'Recovery'
                                                        : (d.exercises.isEmpty
                                                            ? 'No exercises'
                                                            : '${d.exercises.length} ex · ${d.totalSets} sets'),
                                                    style: GoogleFonts.manrope(
                                                      fontSize: 9,
                                                      fontWeight: FontWeight.w500,
                                                      color: isToday
                                                          ? s.brand.withValues(alpha: 0.85)
                                                          : s.secondary,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 8),

                            // 3. Compact Bottom Focus & Actions Bar
                            Row(
                              children: [
                                Icon(LucideIcons.target, size: 11, color: s.secondary),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    _routineFocus(routine),
                                    style: GoogleFonts.manrope(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w500,
                                      color: s.secondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.pop(context);
                                    Get.toNamed(Routes.addRoutine, arguments: routine);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(LucideIcons.pencil, size: 12, color: s.secondary),
                                        const SizedBox(width: 3),
                                        Text(
                                          'Edit',
                                          style: GoogleFonts.manrope(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: s.secondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 2),
                                GestureDetector(
                                  onTap: () => _confirmDeleteRoutine(context, controller, routine),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(LucideIcons.trash_2, size: 12, color: AppColors.rose),
                                        const SizedBox(width: 3),
                                        Text(
                                          'Delete',
                                          style: GoogleFonts.manrope(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.rose,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),

          // Bottom Action: Create New Routine
          Container(
            padding: EdgeInsets.fromLTRB(
              AppSizes.md,
              AppSizes.sm + 2,
              AppSizes.md,
              MediaQuery.of(context).padding.bottom + AppSizes.sm,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark2 : s.surface,
              border: Border(top: BorderSide(color: s.border.withValues(alpha: 0.7))),
            ),
            child: AppButton.primary(
              text: 'Create New Workout Routine',
              icon: LucideIcons.plus,
              size: AppButtonSize.md,
              fullWidth: true,
              onPressed: () {
                Navigator.pop(context);
                Get.toNamed(Routes.addRoutine);
              },
            ),
          ),
        ],
      ),
    );
  }



  String _routineFocus(WorkoutRoutine routine) {
    final workoutDays = routine.days.where((d) => !d.isRestDay && d.muscles.isNotEmpty);
    final musclesSet = <String>{};
    for (final d in workoutDays) {
      for (final m in d.muscles) {
        if (!m.toLowerCase().contains('rest')) {
          musclesSet.add(m);
        }
      }
    }
    if (musclesSet.isEmpty) return 'General Fitness & Recovery';
    return 'Focus: ${musclesSet.take(4).join(" · ")}';
  }

  void _confirmDeleteRoutine(BuildContext context, WorkoutController controller, WorkoutRoutine routine) {
    if (controller.allRoutines.length <= 1) {
      Get.snackbar(
        'Cannot Delete Schedule',
        'You must have at least one active workout schedule.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Delete Workout Schedule?',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
        ),
        content: Text('Are you sure you want to delete "${routine.name}"? This schedule will be permanently removed.'),
        actions: [
          AppButton.text(
            text: 'Cancel',
            size: AppButtonSize.sm,
            onPressed: () => Navigator.pop(ctx),
          ),
          AppButton.danger(
            text: 'Delete Schedule',
            icon: LucideIcons.trash_2,
            size: AppButtonSize.sm,
            onPressed: () async {
              Navigator.pop(ctx);
              await controller.deleteRoutine(routine.id);
            },
          ),
        ],
      ),
    );
  }
}
