import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:velto/app/routes/app_pages.dart';
import 'package:velto/core/constants/app_colors.dart';
import 'package:velto/core/constants/app_sizes.dart';
import 'package:velto/core/widgets/app_widgets.dart';
import 'package:velto/features/workout/controllers/workout_controller.dart';
import 'package:velto/features/workout/models/exercise.dart';
import 'package:velto/features/workout/models/exercise_volume.dart';
import 'package:velto/features/workout/models/routine_day.dart';
import 'package:velto/features/workout/models/workout_routine.dart';
import 'package:velto/features/workout/services/workout_service.dart';
import 'package:velto/features/workout/widgets/exercise_picker_sheet.dart';
import 'package:velto/features/workout/widgets/routine_selector_sheet.dart';

class WorkoutView extends StatelessWidget {
  const WorkoutView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = AppStyle(isDark);
    final controller = Get.isRegistered<WorkoutController>()
        ? Get.find<WorkoutController>()
        : Get.put(WorkoutController());

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          AppSliverAppBar(
            title: 'Workout',
            subtitle: 'Your weekly plan',
            isDark: isDark,
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppSizes.screenPadding, AppSizes.sm, AppSizes.screenPadding, 120),
            sliver: Obx(() {
              final activeRoutine = controller.activeRoutine.value;

              if (controller.isLoading.value && controller.allRoutines.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              // ── Empty State: No active routine ─────────────────────────────
              if (activeRoutine == null) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: AppEmptyState(
                    isDark: isDark,
                    icon: LucideIcons.dumbbell,
                    title: 'No plan yet',
                    subtitle:
                        'Build a weekly split so you always know\nwhat to train today.',
                    actionLabel: 'Create plan',
                    onAction: () => Get.toNamed(Routes.addRoutine),
                  ),
                );
              }

              final selectedDay = controller.selectedDay;
              if (selectedDay == null) {
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              }
              final selectedIndex = controller.selectedDayIndex.value;
              final todayIndex = controller.todayDayIndex;
              final isViewingToday = selectedIndex == todayIndex;

              return SliverList(
                delegate: SliverChildListDelegate([
                  // 1. Active Routine Switcher Bar
                  AppCard(
                    isDark: isDark,
                    padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          onTap: () => RoutineSelectorSheet.show(context, controller),
                          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: s.brandSoft,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(LucideIcons.dumbbell, size: 16, color: s.brand),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        controller.effectiveRoutineName,
                                        style: GoogleFonts.manrope(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: s.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(LucideIcons.chevron_down, size: 14, color: s.secondary),
                                    ],
                                  ),
                                  Text(
                                    'Active plan · tap to switch',
                                    style: GoogleFonts.manrope(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: s.secondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        AppButton.soft(
                          text: 'All Plans',
                          icon: LucideIcons.layers,
                          size: AppButtonSize.xs,
                          onPressed: () => RoutineSelectorSheet.show(context, controller),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSizes.md),

                  // 2. Interactive Weekly Day Strip (Mon - Sun)
                  AppCard(
                    isDark: isDark,
                    padding: const EdgeInsets.all(AppSizes.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'This week',
                              style: GoogleFonts.manrope(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: s.primary,
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: s.brandSoft,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${activeRoutine.totalWorkoutsInWeek} workouts / week',
                                    style: GoogleFonts.manrope(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: s.brand,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () => Get.toNamed(Routes.addRoutine, arguments: activeRoutine),
                                  child: Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: Icon(LucideIcons.pencil, size: 14, color: s.secondary),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => _confirmDeleteSchedule(context, controller, activeRoutine),
                                  child: const Padding(
                                    padding: EdgeInsets.all(4),
                                    child: Icon(LucideIcons.trash_2, size: 14, color: AppColors.rose),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSizes.md),

                        // 7-Day Calendar Strip (Day Name & Date)
                        Row(
                          children: List.generate(activeRoutine.days.length, (index) {
                            final day = activeRoutine.days[index];
                            final isSelected = selectedIndex == index;
                            final isToday = todayIndex == index;

                            final now = DateTime.now();
                            final mondayOfWeek = DateTime(now.year, now.month, now.day)
                                .subtract(Duration(days: now.weekday - 1));
                            final dayDate = mondayOfWeek.add(Duration(days: index));
                            final dateNum = '${dayDate.day}';

                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 2.5),
                                child: GestureDetector(
                                  onTap: () => controller.selectDay(index),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? s.brand
                                          : (isToday
                                              ? (isDark ? s.brand.withValues(alpha: 0.16) : s.brandSoft)
                                              : (isDark ? AppColors.surfaceDark2 : AppColors.surfaceLight)),
                                      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                                      border: Border.all(
                                        color: isSelected
                                            ? s.brand
                                            : (isToday
                                                ? s.brand
                                                : s.border.withValues(alpha: 0.7)),
                                        width: isSelected || isToday ? 1.5 : 1.0,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: s.brand.withValues(alpha: isDark ? 0.3 : 0.22),
                                                blurRadius: 8,
                                                offset: const Offset(0, 3),
                                              )
                                            ]
                                          : null,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Day Name (e.g. Mon, Tue)
                                        Text(
                                          day.dayShort,
                                          style: GoogleFonts.manrope(
                                            fontSize: 11,
                                            fontWeight: isSelected
                                                ? FontWeight.w700
                                                : (isToday ? FontWeight.w700 : FontWeight.w600),
                                            color: isSelected
                                                ? Colors.white.withValues(alpha: 0.9)
                                                : (isToday ? s.brand : s.secondary),
                                          ),
                                        ),
                                        const SizedBox(height: 4),

                                        // Date Number (e.g. 19, 20)
                                        Text(
                                          dateNum,
                                          style: GoogleFonts.manrope(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: isSelected
                                                ? Colors.white
                                                : (isToday ? s.brand : s.primary),
                                          ),
                                        ),
                                        if (isToday) ...[
                                          const SizedBox(height: 3),
                                          Container(
                                            width: 4,
                                            height: 4,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: isSelected ? Colors.white : s.brand,
                                            ),
                                          ),
                                        ] else ...[
                                          const SizedBox(height: 7),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),

                        // Subtle divider & concise active day focus row
                        const SizedBox(height: AppSizes.md),
                        Divider(height: 1, thickness: 1, color: s.border.withValues(alpha: 0.5)),
                        const SizedBox(height: AppSizes.sm + 4),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Day Focus & Volume Target
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          selectedDay.isRestDay
                                              ? 'Rest & recovery'
                                              : selectedDay.musclesDisplay,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.manrope(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: s.primary,
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                      ),
                                      if (isViewingToday) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                          decoration: BoxDecoration(
                                            color: s.brand,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'TODAY',
                                            style: GoogleFonts.manrope(
                                              fontSize: 8.5,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    selectedDay.isRestDay
                                        ? 'Recover, hydrate, and eat well'
                                        : '${selectedDay.exercises.length} exercises · ${selectedDay.totalSets} sets',
                                    style: GoogleFonts.manrope(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                      color: s.secondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Right Action: Jump to Today or Completed badge
                            if (!isViewingToday)
                              GestureDetector(
                                onTap: () => controller.selectDay(controller.todayDayIndex),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: s.brandSoft,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(LucideIcons.calendar, size: 11, color: s.brand),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Jump to Today',
                                        style: GoogleFonts.manrope(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                          color: s.brand,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else if (!selectedDay.isRestDay && selectedDay.completedSets > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.greenSoftDark : AppColors.greenSoft,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(LucideIcons.circle_check, size: 12, color: AppColors.green),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${selectedDay.completedSets}/${selectedDay.totalSets} Done',
                                      style: GoogleFonts.manrope(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),

                        // Linear Progress Indicator if workout started
                        if (!selectedDay.isRestDay && selectedDay.totalSets > 0 && selectedDay.completedSets > 0) ...[
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: selectedDay.completionProgress,
                              minHeight: 3,
                              backgroundColor: isDark ? AppColors.surfaceDark : AppColors.secondarySoft,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.green),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSizes.lg),

                    // 4. Exercises List
                    if (selectedDay.isRestDay)
                      Container(
                        padding: const EdgeInsets.all(AppSizes.xl),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDark2 : AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                          border: Border.all(color: s.border),
                        ),
                        child: Column(
                          children: [
                            Icon(LucideIcons.sparkles, size: 40, color: AppColors.green),
                            const SizedBox(height: AppSizes.sm),
                            Text(
                              'Rest day',
                              style: GoogleFonts.manrope(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: s.primary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'No heavy lifting today.\nFocus on recovery, sleep, and nutrition.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                color: s.secondary,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (selectedDay.exercises.isEmpty)
                      AppEmptyState(
                        isDark: isDark,
                        icon: LucideIcons.dumbbell,
                        title: 'No exercises for ${selectedDay.dayName}',
                        subtitle:
                            'Add moves for ${selectedDay.musclesDisplay} to start training.',
                        actionLabel: 'Add exercises',
                        onAction: () =>
                            _openAddExercise(context, controller, selectedDay),
                      )
                    else ...[
                      // Exercises List Header with Quick Add & Expand/Collapse All
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSizes.sm),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'EXERCISES (${selectedDay.exercises.length})',
                              style: GoogleFonts.manrope(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: s.tertiary,
                                letterSpacing: 0.8,
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(
                                  onTap: () => _openAddExercise(context, controller, selectedDay),
                                  borderRadius: BorderRadius.circular(6),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(LucideIcons.plus, size: 12, color: s.brand),
                                        const SizedBox(width: 3),
                                        Text(
                                          'Add',
                                          style: GoogleFonts.manrope(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: s.brand,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  width: 1,
                                  height: 12,
                                  color: s.border.withValues(alpha: 0.8),
                                ),
                                const SizedBox(width: 6),
                                InkWell(
                                  onTap: () {
                                    if (controller.areAllExpanded(selectedDay)) {
                                      controller.collapseAll();
                                    } else {
                                      controller.expandAll(selectedDay);
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(6),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          controller.areAllExpanded(selectedDay)
                                              ? LucideIcons.chevron_up
                                              : LucideIcons.chevron_down,
                                          size: 12,
                                          color: s.secondary,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          controller.areAllExpanded(selectedDay) ? 'Collapse All' : 'Expand All',
                                          style: GoogleFonts.manrope(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: s.secondary,
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

                      // Collapsible Exercise Cards
                      ...List.generate(selectedDay.exercises.length, (exIndex) {
                        final item = selectedDay.exercises[exIndex];
                        final completedCount = item.sets.where((s) => s.isCompleted).length;
                        final isAllDone = completedCount == item.sets.length && item.sets.isNotEmpty;
                        final isExpanded = controller.isExerciseExpanded(item.id, exIndex);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSizes.md),
                          child: AppCard(
                            isDark: isDark,
                            padding: const EdgeInsets.all(AppSizes.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Exercise Header Row (Tappable to expand / collapse)
                                InkWell(
                                  onTap: () => controller.toggleExerciseExpanded(item.id, exIndex),
                                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                                  child: Row(
                                    children: [
                                      if (isAllDone) ...[
                                        const Icon(LucideIcons.check, size: 16, color: AppColors.green),
                                        const SizedBox(width: 8),
                                      ],
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.exercise.name,
                                              style: GoogleFonts.manrope(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w800,
                                                color: s.primary,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Row(
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    item.exercise.targetMuscle,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: GoogleFonts.manrope(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w700,
                                                      color: s.brand,
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  '  ·  ${item.sets.length} sets',
                                                  style: GoogleFonts.manrope(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: s.secondary,
                                                  ),
                                                ),
                                                if (completedCount > 0)
                                                  Text(
                                                    '  ·  $completedCount done',
                                                    style: GoogleFonts.manrope(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w700,
                                                      color: isAllDone ? AppColors.green : s.secondary,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            if (!isExpanded)
                                              _VolumeCompare(
                                                item: item,
                                                last: controller.previousVolume[item.exercise.id],
                                                s: s,
                                                isDark: isDark,
                                                compact: true,
                                              ),
                                          ],
                                        ),
                                      ),
                                      // Remove exercise option
                                      IconButton(
                                        onPressed: () => controller.removeExerciseFromCurrentDay(item.id),
                                        icon: const Icon(LucideIcons.trash_2, size: 15, color: AppColors.rose),
                                        tooltip: 'Remove exercise',
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      const SizedBox(width: 2),
                                      // Expand/Collapse Chevron indicator
                                      AnimatedRotation(
                                        turns: isExpanded ? 0.5 : 0.0,
                                        duration: const Duration(milliseconds: 200),
                                        child: Icon(
                                          LucideIcons.chevron_down,
                                          size: 18,
                                          color: s.tertiary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Expandable Content with smooth cross-fade animation
                                ClipRect(
                                  child: AnimatedCrossFade(
                                    crossFadeState: isExpanded
                                        ? CrossFadeState.showSecond
                                        : CrossFadeState.showFirst,
                                    duration: const Duration(milliseconds: 200),
                                    firstChild: const SizedBox.shrink(),
                                    secondChild: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: AppSizes.sm + 2),
                                        Divider(height: 1, color: s.border.withValues(alpha: 0.6)),
                                        const SizedBox(height: AppSizes.sm),
                                        _VolumeCompare(
                                          item: item,
                                          last: controller.previousVolume[item.exercise.id],
                                          s: s,
                                          isDark: isDark,
                                        ),

                                        // Sets Section: Individual reps & weight for every set
                                        Column(
                                          children: [
                                            // Column headers
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                              child: Row(
                                                children: [
                                                  SizedBox(
                                                    width: 48,
                                                    child: Text(
                                                      'SETS',
                                                      style: GoogleFonts.manrope(
                                                        fontSize: 9,
                                                        fontWeight: FontWeight.w700,
                                                        color: s.tertiary,
                                                        letterSpacing: 0.5,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                            flex: 4,
                                            child: Center(
                                              child: Text(
                                                'WEIGHT',
                                                style: GoogleFonts.manrope(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w700,
                                                  color: s.tertiary,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            flex: 4,
                                            child: Center(
                                              child: Text(
                                                'REPS',
                                                style: GoogleFonts.manrope(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w700,
                                                  color: s.tertiary,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          SizedBox(
                                            width: 28,
                                            child: Center(
                                              child: Text(
                                                'DONE',
                                                style: GoogleFonts.manrope(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w700,
                                                  color: s.tertiary,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Individual Set Rows
                                    ...List.generate(item.sets.length, (setIdx) {
                                      final currentSet = item.sets[setIdx];
                                      final isDone = currentSet.isCompleted;

                                      return Container(
                                        margin: const EdgeInsets.only(top: 4),
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: isDone
                                              ? (isDark ? AppColors.greenSoftDark : AppColors.greenSoft)
                                              : (isDark ? AppColors.surfaceDark2 : AppColors.bgLight),
                                          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                                          border: Border.all(
                                            color: isDone ? AppColors.green.withValues(alpha: 0.4) : s.border,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            // Set Label (e.g. Set 1, Set 2)
                                            SizedBox(
                                              width: 44,
                                              child: Text(
                                                'Set ${setIdx + 1}',
                                                style: GoogleFonts.manrope(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: isDone ? AppColors.green : s.primary,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 4),

                                            // Independent Weight stepper for this set
                                            Expanded(
                                              flex: 4,
                                              child: _setStepper(
                                                value: '${currentSet.weight > 0 ? currentSet.weight.toStringAsFixed(1) : "BW"}${currentSet.weight > 0 ? " kg" : ""}',
                                                onMinus: () => controller.updateSetWeight(item, setIdx, -2.5),
                                                onPlus: () => controller.updateSetWeight(item, setIdx, 2.5),
                                                s: s,
                                                isDark: isDark,
                                              ),
                                            ),

                                            const SizedBox(width: 6),

                                            // Independent Reps stepper for this set
                                            Expanded(
                                              flex: 4,
                                              child: _setStepper(
                                                value: '${currentSet.reps} reps',
                                                onMinus: () => controller.updateSetReps(item, setIdx, -1),
                                                onPlus: () => controller.updateSetReps(item, setIdx, 1),
                                                s: s,
                                                isDark: isDark,
                                              ),
                                            ),

                                            const SizedBox(width: 6),

                                            // Completion Toggle Checkbox
                                            GestureDetector(
                                              behavior: HitTestBehavior.opaque,
                                              onTap: () => controller.toggleSetCompletion(item, setIdx),
                                              child: AnimatedContainer(
                                                duration: const Duration(milliseconds: 150),
                                                width: 32,
                                                height: 32,
                                                decoration: BoxDecoration(
                                                  color: isDone ? AppColors.green : (isDark ? AppColors.surfaceDark : Colors.white),
                                                  borderRadius: BorderRadius.circular(7),
                                                  border: Border.all(
                                                    color: isDone ? AppColors.green : s.border,
                                                    width: 1.5,
                                                  ),
                                                ),
                                                alignment: Alignment.center,
                                                child: isDone
                                                    ? const Icon(LucideIcons.check, size: 16, color: Colors.white)
                                                    : null,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),

                                    // Add Set & Remove Set Action Row
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        TextButton.icon(
                                          onPressed: () => controller.addSet(item),
                                          icon: Icon(LucideIcons.plus, size: 13, color: s.brand),
                                          label: Text(
                                            'Add Set',
                                            style: GoogleFonts.manrope(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: s.brand,
                                            ),
                                          ),
                                        ),
                                        if (item.sets.length > 1)
                                          TextButton.icon(
                                            onPressed: () => controller.removeSet(item, item.sets.length - 1),
                                            icon: const Icon(LucideIcons.minus, size: 13, color: AppColors.rose),
                                            label: Text(
                                              'Remove Set',
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
                      ],
                    ),
                  ),
                );
              }),
            ],

                    // Add Exercise on the fly button
                    if (!selectedDay.isRestDay) ...[
                      const SizedBox(height: AppSizes.sm),
                      AppButton.outline(
                        text: 'Add exercise',
                        icon: LucideIcons.plus,
                        size: AppButtonSize.md,
                        fullWidth: true,
                        onPressed: () =>
                            _openAddExercise(context, controller, selectedDay),
                      ),
                    ],
                ]),
              );
            }),
          ),
        ],
      ),
    );
  }

  void _openAddExercise(
    BuildContext context,
    WorkoutController controller,
    dynamic day,
  ) {
    String initialMuscle = 'All';
    if (day is RoutineDay && day.muscles.isNotEmpty) {
      for (final m in day.muscles) {
        final cleanM = m.replaceAll('+', ' ').split(' ').firstWhere(
          (w) => WorkoutService.muscleGroups.any((g) => g.toLowerCase() == w.toLowerCase()),
          orElse: () => '',
        );
        if (cleanM.isNotEmpty) {
          final matched = WorkoutService.muscleGroups.firstWhere(
            (g) => g.toLowerCase() == cleanM.toLowerCase(),
            orElse: () => 'All',
          );
          if (matched != 'All') {
            initialMuscle = matched;
            break;
          }
        }
      }
    }

    ExercisePickerSheet.show(
      context: context,
      initialMuscle: initialMuscle,
      onExerciseSelected: (Exercise exercise, int sets, int reps, double weight) async {
        await controller.addExerciseToCurrentDay(exercise);
      },
    );
  }

  Widget _setStepper({
    required String value,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
    required AppStyle s,
    required bool isDark,
  }) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: s.border.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onMinus,
            child: Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark2 : AppColors.secondarySoft,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(LucideIcons.minus, size: 13, color: s.primary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.manrope(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: s.primary,
              ),
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onPlus,
            child: Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark2 : AppColors.secondarySoft,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(LucideIcons.plus, size: 13, color: s.primary),
            ),
          ),
        ],
      ),
    );
  }


  void _confirmDeleteSchedule(BuildContext context, WorkoutController controller, WorkoutRoutine routine) {
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

/// Shows this session's volume against the last time the exercise was logged.
class _VolumeCompare extends StatelessWidget {
  final WorkoutExerciseItem item;
  final ExerciseVolumeRecord? last;
  final AppStyle s;
  final bool isDark;

  final bool compact;

  const _VolumeCompare({
    required this.item,
    required this.last,
    required this.s,
    required this.isDark,
    this.compact = false,
  });

  int get _currentReps => item.sets.fold(0, (sum, set) => sum + set.reps);

  @override
  Widget build(BuildContext context) {
    final current = _currentReps;
    if (last == null && current == 0) return const SizedBox.shrink();

    final delta = last == null ? null : current - last!.totalReps;
    final hasProgress = last != null && current > 0;

    late final String detail;
    Color? deltaColor;
    if (last == null) {
      detail = 'Now $current reps';
    } else if (current == 0) {
      detail = 'Now 0 · last ${last!.totalReps}';
    } else if (delta == 0) {
      detail = 'Now $current · matched last time';
    } else {
      final sign = delta! > 0 ? '+' : '−';
      detail = 'Now $current · last ${last!.totalReps} · $sign${delta.abs()}';
      deltaColor = delta > 0 ? AppColors.green : AppColors.rose;
    }

    if (compact) {
      return Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Text(
          detail,
          style: GoogleFonts.manrope(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: deltaColor ?? s.secondary,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.sm),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark2 : AppColors.bgLight,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(color: s.border.withValues(alpha: 0.7)),
        ),
        child: Row(
          children: [
            Icon(
              hasProgress && delta != null && delta > 0
                  ? LucideIcons.trending_up
                  : hasProgress && delta != null && delta < 0
                      ? LucideIcons.trending_down
                      : LucideIcons.chart_column,
              size: 14,
              color: deltaColor ?? s.brand,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Volume',
                    style: GoogleFonts.manrope(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: s.secondary,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    detail,
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: deltaColor ?? s.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
