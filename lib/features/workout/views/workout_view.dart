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
import 'package:velto/features/workout/models/workout_routine.dart';
import 'package:velto/features/workout/widgets/exercise_picker_sheet.dart';
import 'package:velto/features/workout/widgets/routine_selector_sheet.dart';

class WorkoutView extends StatelessWidget {
  const WorkoutView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = AppStyle(isDark);
    final controller = Get.put(WorkoutController());

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          AppSliverAppBar(
            title: 'Workout',
            subtitle: 'Training & Routines',
            isDark: isDark,
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppSizes.lg, AppSizes.sm, AppSizes.lg, 120),
            sliver: Obx(() {
              final activeRoutine = controller.activeRoutine.value;

              if (controller.isLoading.value) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              // ── Empty State: No active routine ─────────────────────────────
              if (activeRoutine == null) {
                return SliverList(
                  delegate: SliverChildListDelegate([
                    AppEmptyState(
                      isDark: isDark,
                      icon: LucideIcons.dumbbell,
                      title: 'No Workout Routine Active',
                      subtitle: 'Choose from preset routines like Push-Pull-Legs,\nor build your custom weekly split.',
                      actionLabel: 'Select or Create Routine',
                      onAction: () => RoutineSelectorSheet.show(context, controller),
                    ),
                  ]),
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
                                        activeRoutine.name,
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
                                    'Active Plan · Tap to switch',
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
                              'Weekly Schedule',
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
                                              ? 'Rest & Muscle Recovery'
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
                                        ? 'Active recovery & hydration'
                                        : '${selectedDay.exercises.length} Exercises · ${selectedDay.totalSets} Sets Target',
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
                              'Rest & Muscle Recovery',
                              style: GoogleFonts.manrope(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: s.primary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'No heavy lifting scheduled today.\nFocus on recovery, hydration, and healthy nutrition.',
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
                        title: 'No Exercises Added for ${selectedDay.dayName}',
                        subtitle: 'Tap below to add exercises for ${selectedDay.musclesDisplay}.',
                        actionLabel: '+ Add Exercises',
                        onAction: () => _openAddExercise(context, controller, selectedDay),
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
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: isAllDone
                                              ? (isDark ? AppColors.greenSoftDark : AppColors.greenSoft)
                                              : s.brandSoft,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          isAllDone
                                              ? LucideIcons.check
                                              : _exerciseIcon(item.exercise.targetMuscle),
                                          size: 18,
                                          color: isAllDone ? AppColors.green : s.brand,
                                        ),
                                      ),
                                      const SizedBox(width: AppSizes.md),
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
                                            const SizedBox(height: 3),
                                            Row(
                                              children: [
                                                _badge(item.exercise.targetMuscle, s.brand, s.brandSoft),
                                                const SizedBox(width: 4),
                                                _badge(
                                                  '${item.sets.length} sets',
                                                  s.secondary,
                                                  isDark ? AppColors.surfaceDark2 : AppColors.bgLight,
                                                ),
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                                  decoration: BoxDecoration(
                                                    color: isAllDone
                                                        ? (isDark ? AppColors.greenSoftDark : AppColors.greenSoft)
                                                        : (isDark ? AppColors.surfaceDark2 : AppColors.bgLight),
                                                    borderRadius: BorderRadius.circular(4),
                                                    border: Border.all(
                                                      color: isAllDone
                                                          ? AppColors.green.withValues(alpha: 0.4)
                                                          : s.border,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    '$completedCount/${item.sets.length} done',
                                                    style: GoogleFonts.manrope(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w700,
                                                      color: isAllDone ? AppColors.green : s.secondary,
                                                    ),
                                                  ),
                                                ),
                                              ],
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
                                        const SizedBox(height: AppSizes.md),
                                        Divider(height: 1, color: s.border.withValues(alpha: 0.6)),
                                        const SizedBox(height: AppSizes.sm),

                                // Interactive Quick Increment Controls: Weight, Reps, Sets
                                Container(
                                  padding: const EdgeInsets.all(AppSizes.sm),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.surfaceDark2 : AppColors.bgLight,
                                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                                    border: Border.all(color: s.border),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      // Weight Stepper
                                      _inlineStepper(
                                        label: 'WEIGHT',
                                        value: '${item.targetWeight > 0 ? item.targetWeight.toStringAsFixed(1) : "BW"} ${item.targetWeight > 0 ? "kg" : ""}',
                                        onMinus: () => controller.decreaseWeight(item),
                                        onPlus: () => controller.increaseWeight(item),
                                        s: s,
                                        isDark: isDark,
                                      ),
                                      Container(height: 28, width: 1, color: s.border),
                                      // Reps Stepper
                                      _inlineStepper(
                                        label: 'REPS',
                                        value: '${item.targetReps} reps',
                                        onMinus: () => controller.decreaseReps(item),
                                        onPlus: () => controller.increaseReps(item),
                                        s: s,
                                        isDark: isDark,
                                      ),
                                      Container(height: 28, width: 1, color: s.border),
                                      // Sets Stepper
                                      _inlineStepper(
                                        label: 'SETS',
                                        value: '${item.targetSets} sets',
                                        onMinus: () => controller.decreaseSets(item),
                                        onPlus: () => controller.increaseSets(item),
                                        s: s,
                                        isDark: isDark,
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: AppSizes.sm),

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
                                              'SET',
                                              style: GoogleFonts.manrope(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w700,
                                                color: s.tertiary,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
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
                                              onTap: () => controller.toggleSetCompletion(item, setIdx),
                                              child: AnimatedContainer(
                                                duration: const Duration(milliseconds: 150),
                                                width: 28,
                                                height: 28,
                                                decoration: BoxDecoration(
                                                  color: isDone ? AppColors.green : (isDark ? AppColors.surfaceDark : Colors.white),
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(
                                                    color: isDone ? AppColors.green : s.border,
                                                    width: 1.5,
                                                  ),
                                                ),
                                                alignment: Alignment.center,
                                                child: isDone
                                                    ? const Icon(LucideIcons.check, size: 14, color: Colors.white)
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
                        text: 'Add Exercise to Today',
                        icon: LucideIcons.plus,
                        size: AppButtonSize.md,
                        fullWidth: true,
                        onPressed: () => _openAddExercise(context, controller, selectedDay),
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
    ExercisePickerSheet.show(
      context: context,
      initialMuscle: day.muscles.firstOrNull ?? 'All',
      onExerciseSelected: (Exercise exercise, int sets, int reps, double weight) {
        controller.addExerciseToCurrentDay(
          exercise,
          sets: sets,
          reps: reps,
          weight: weight,
        );
      },
    );
  }

  Widget _inlineStepper({
    required String label,
    required String value,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
    required AppStyle s,
    required bool isDark,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: s.tertiary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: onMinus,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(LucideIcons.minus, size: 12, color: s.primary),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                value,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: s.primary,
                ),
              ),
            ),
            GestureDetector(
              onTap: onPlus,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(LucideIcons.plus, size: 12, color: s.primary),
              ),
            ),
          ],
        ),
      ],
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
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: s.border.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: onMinus,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark2 : AppColors.secondarySoft,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(LucideIcons.minus, size: 10, color: s.primary),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.manrope(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: s.primary,
              ),
            ),
          ),
          GestureDetector(
            onTap: onPlus,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark2 : AppColors.secondarySoft,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(LucideIcons.plus, size: 10, color: s.primary),
            ),
          ),
        ],
      ),
    );
  }

  IconData _exerciseIcon(String muscle) {
    switch (muscle.toLowerCase()) {
      case 'chest':
        return LucideIcons.shield;
      case 'back':
        return LucideIcons.layers;
      case 'shoulders':
        return LucideIcons.triangle;
      case 'biceps':
      case 'triceps':
        return LucideIcons.dumbbell;
      case 'legs':
        return LucideIcons.footprints;
      case 'abs':
        return LucideIcons.activity;
      case 'cardio':
        return LucideIcons.zap;
      default:
        return LucideIcons.dumbbell;
    }
  }

  Widget _badge(String text, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(
        text,
        style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w700, color: color),
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
