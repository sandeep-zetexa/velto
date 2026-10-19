import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:velto/app/routes/app_pages.dart';
import 'package:velto/core/constants/app_colors.dart';
import 'package:velto/core/constants/app_sizes.dart';
import 'package:velto/core/widgets/app_widgets.dart';
import 'package:velto/features/workout/controllers/workout_controller.dart';
import 'package:velto/features/workout/models/routine_day.dart';
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
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg, vertical: AppSizes.xs),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Workout Routines',
                        style: GoogleFonts.manrope(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: s.primary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Select active plan or build your custom split',
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

              return ListView.separated(
                padding: const EdgeInsets.all(AppSizes.lg),
                itemCount: routines.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppSizes.md),
                itemBuilder: (context, index) {
                  final routine = routines[index];
                  final isActive = routine.isActive;

                  return Material(
                    color: isDark ? AppColors.surfaceDark2 : Colors.white,
                    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                    child: InkWell(
                      onTap: isActive
                          ? null
                          : () {
                              controller.switchActiveRoutine(routine.id);
                              Navigator.pop(context);
                            },
                      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                      child: Container(
                        padding: const EdgeInsets.all(AppSizes.md),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                          border: Border.all(
                            color: isActive ? s.brand : s.border,
                            width: isActive ? 1.5 : 1.0,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Header: Icon, Name, Frequency & Active Status
                            Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? s.brandSoft
                                        : (isDark ? AppColors.surfaceDark : AppColors.secondarySoft),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    LucideIcons.dumbbell,
                                    size: 18,
                                    color: isActive ? s.brand : s.secondary,
                                  ),
                                ),
                                const SizedBox(width: AppSizes.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        routine.name,
                                        style: GoogleFonts.manrope(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: s.primary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 3),
                                      Wrap(
                                        spacing: 5,
                                        runSpacing: 3,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: s.brandSoft,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              '${routine.totalWorkoutsInWeek}d/week',
                                              style: GoogleFonts.manrope(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: s.brand,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isDark ? AppColors.surfaceDark : AppColors.secondarySoft,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              '${routine.totalExercisesInWeek} ex',
                                              style: GoogleFonts.manrope(
                                                fontSize: 10,
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
                                if (isActive)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: s.brandSoft,
                                      borderRadius: BorderRadius.circular(AppSizes.radiusRound),
                                      border: Border.all(color: s.brand.withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(LucideIcons.check, size: 12, color: s.brand),
                                        const SizedBox(width: 4),
                                        Text(
                                          'ACTIVE',
                                          style: GoogleFonts.manrope(
                                            fontSize: 9.5,
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

                            const SizedBox(height: AppSizes.sm),

                            // Description
                            Text(
                              routine.description,
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                color: s.secondary,
                                height: 1.35,
                              ),
                            ),

                            const SizedBox(height: AppSizes.sm),

                            // 2. Structured 7-Day Calendar Rhythm Strip
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.surfaceDark : AppColors.bgLight,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: s.border.withValues(alpha: 0.6)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: routine.days.map((d) {
                                  final isRest = d.isRestDay;
                                  final muscleAbbr = _shortMuscleAbbr(d);

                                  return Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 2),
                                      child: Column(
                                        children: [
                                          Text(
                                            d.dayShort.substring(0, 1),
                                            style: GoogleFonts.manrope(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: isRest ? s.tertiary : s.secondary,
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Container(
                                            height: 24,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: isRest
                                                  ? Colors.transparent
                                                  : (isActive
                                                      ? s.brandSoft
                                                      : (isDark ? AppColors.surfaceDark2 : Colors.white)),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(
                                                color: isRest
                                                    ? s.border.withValues(alpha: 0.4)
                                                    : (isActive
                                                        ? s.brand.withValues(alpha: 0.3)
                                                        : s.border),
                                              ),
                                            ),
                                            child: isRest
                                                ? Icon(
                                                    LucideIcons.sparkles,
                                                    size: 11,
                                                    color: s.tertiary,
                                                  )
                                                : Text(
                                                    muscleAbbr,
                                                    style: GoogleFonts.manrope(
                                                      fontSize: 9,
                                                      fontWeight: FontWeight.w700,
                                                      color: isActive ? s.brand : s.primary,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),

                            const SizedBox(height: AppSizes.xs + 2),

                            // Focus Summary Line
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2),
                              child: Row(
                                children: [
                                  Icon(LucideIcons.target, size: 12, color: s.brand),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      _routineFocus(routine),
                                      style: GoogleFonts.manrope(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: s.secondary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: AppSizes.xs),
                            Divider(height: 1, color: s.border.withValues(alpha: 0.5)),
                            const SizedBox(height: AppSizes.xs),

                            // 3. Action Buttons & Status Footer
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    isActive ? 'Current active plan' : 'Tap card to switch',
                                    style: GoogleFonts.manrope(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isActive ? s.brand : s.tertiary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextButton.icon(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        Get.toNamed(Routes.addRoutine, arguments: routine);
                                      },
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      icon: Icon(LucideIcons.pencil, size: 12, color: s.secondary),
                                      label: Text(
                                        'Edit Plan',
                                        style: GoogleFonts.manrope(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: s.secondary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    TextButton.icon(
                                      onPressed: () => _confirmDeleteRoutine(context, controller, routine),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      icon: const Icon(LucideIcons.trash_2, size: 12, color: AppColors.rose),
                                      label: Text(
                                        'Delete',
                                        style: GoogleFonts.manrope(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.rose,
                                        ),
                                      ),
                                    ),
                                  ],
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
              AppSizes.lg,
              AppSizes.md,
              AppSizes.lg,
              MediaQuery.of(context).padding.bottom + AppSizes.md,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark2 : s.surface,
              border: Border(top: BorderSide(color: s.border)),
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

  String _shortMuscleAbbr(RoutineDay day) {
    if (day.isRestDay) return 'Rest';
    if (day.muscles.isEmpty) return 'Train';
    final first = day.muscles.first.toLowerCase();
    if (first.contains('chest')) return 'Chest';
    if (first.contains('back')) return 'Back';
    if (first.contains('leg')) return 'Legs';
    if (first.contains('shoulder')) return 'Shld';
    if (first.contains('bicep') || first.contains('tricep') || first.contains('arm')) return 'Arms';
    if (first.contains('abs') || first.contains('core')) return 'Abs';
    if (first.contains('cardio')) return 'Cardio';
    if (first.contains('push')) return 'Push';
    if (first.contains('pull')) return 'Pull';
    if (first.contains('upper')) return 'Upper';
    if (first.contains('lower')) return 'Lower';
    return day.muscles.first.length > 5 ? day.muscles.first.substring(0, 4) : day.muscles.first;
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
