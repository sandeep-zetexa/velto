import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:velto/core/constants/app_colors.dart';
import 'package:velto/core/constants/app_sizes.dart';
import 'package:velto/core/widgets/app_widgets.dart';
import 'package:velto/features/workout/controllers/add_routine_controller.dart';
import 'package:velto/features/workout/models/exercise.dart';
import 'package:velto/features/workout/widgets/exercise_picker_sheet.dart';
import 'package:velto/features/workout/widgets/exercise_svg_icon.dart';

class AddRoutineView extends StatelessWidget {
  const AddRoutineView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = AppStyle(isDark);
    final controller = Get.put(AddRoutineController());

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: AppAppBar(
        title: controller.isEditing ? 'Edit Routine' : 'Create Routine',
        showBackButton: true,
        onBackPressed: () => Get.back(),
        isDark: isDark,
        actions: [
          if (controller.isEditing)
            IconButton(
              icon: const Icon(LucideIcons.trash_2, size: 18, color: AppColors.rose),
              tooltip: 'Delete Schedule',
              onPressed: () => _confirmDelete(context, controller),
            ),
          AppButton.text(
            text: 'Save',
            onPressed: () => controller.saveRoutine(setActive: false),
            size: AppButtonSize.md,
          ),
          const SizedBox(width: AppSizes.sm),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Routine Name & Info Header Card
                  AppCard(
                    isDark: isDark,
                    padding: const EdgeInsets.all(AppSizes.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: controller.nameController,
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: s.primary,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Routine Name (e.g. 5-Day Push Pull Legs)',
                            hintStyle: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: s.tertiary,
                            ),
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            border: InputBorder.none,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSizes.lg),

                  // 2. Day-by-Day Split Builder Header
                  Text(
                    'Schedule by Day',
                    style: GoogleFonts.manrope(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: s.primary,
                    ),
                  ),
                  const SizedBox(height: AppSizes.xs),

                  // 7-Day Horizontal Selector Tabs
                  Obx(() {
                    final selectedIndex = controller.selectedDayIndex.value;

                    return SizedBox(
                      height: 64,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: controller.days.length,
                        itemBuilder: (context, index) {
                          final day = controller.days[index];
                          final isSelected = selectedIndex == index;

                          String dayStatus;
                          if (day.isRestDay) {
                            dayStatus = 'Rest';
                          } else if (day.exercises.isNotEmpty) {
                            dayStatus = '${day.exercises.length} ex';
                          } else if (day.muscles.isNotEmpty) {
                            dayStatus = day.muscles.first;
                          } else {
                            dayStatus = 'Empty';
                          }

                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => controller.selectDay(index),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                width: 58,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? s.brand
                                      : (isDark ? AppColors.surfaceDark2 : AppColors.surfaceLight),
                                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                                  border: Border.all(
                                    color: isSelected ? s.brand : s.border,
                                    width: isSelected ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      day.dayShort,
                                      style: GoogleFonts.manrope(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: isSelected ? Colors.white : s.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      dayStatus,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.manrope(
                                        fontSize: 10,
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                        color: isSelected
                                            ? Colors.white.withValues(alpha: 0.9)
                                            : (day.isRestDay ? s.tertiary : s.secondary),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }),

                  const SizedBox(height: AppSizes.lg),

                  // 3. Selected Day Configuration
                  Obx(() {
                    final day = controller.currentDay;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Day Title & Focus Summary
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  day.dayName,
                                  style: GoogleFonts.manrope(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: s.primary,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  day.musclesDisplay,
                                  style: GoogleFonts.manrope(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: day.isRestDay ? s.tertiary : s.brand,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: AppSizes.md),

                        // Muscle Part & Rest Day Chips
                        Text(
                          'Choose Focus & Muscle Parts',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: s.tertiary,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: AppSizes.xs),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            // 1. Rest Day Chip
                            GestureDetector(
                              onTap: () => controller.toggleRestDay(!day.isRestDay),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: day.isRestDay
                                      ? (isDark ? AppColors.blueSoftDark : AppColors.blueSoft)
                                      : (isDark ? AppColors.surfaceDark2 : AppColors.surfaceLight),
                                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                                  border: Border.all(
                                    color: day.isRestDay ? AppColors.blue : s.border,
                                    width: day.isRestDay ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      LucideIcons.sparkles,
                                      size: 13,
                                      color: day.isRestDay ? AppColors.blue : s.tertiary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Rest Day',
                                      style: GoogleFonts.manrope(
                                        fontSize: 12,
                                        fontWeight: day.isRestDay ? FontWeight.w700 : FontWeight.w600,
                                        color: day.isRestDay ? AppColors.blue : s.secondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // 2. Muscle Part Chips
                            ...controller.availableMuscles.map((muscle) {
                              final isSelected = !day.isRestDay && day.muscles.contains(muscle);

                              return GestureDetector(
                                onTap: () => controller.toggleMuscle(muscle),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? s.brandSoft
                                        : (isDark ? AppColors.surfaceDark2 : AppColors.surfaceLight),
                                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                                    border: Border.all(
                                      color: isSelected ? s.brand : s.border,
                                      width: isSelected ? 1.5 : 1.0,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (isSelected) ...[
                                        Icon(LucideIcons.check, size: 12, color: s.brand),
                                        const SizedBox(width: 4),
                                      ],
                                      Text(
                                        muscle,
                                        style: GoogleFonts.manrope(
                                          fontSize: 12,
                                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                          color: isSelected ? s.brand : s.secondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),

                        const SizedBox(height: AppSizes.lg),

                        if (day.isRestDay) ...[
                          // Rest Day Card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppSizes.xl),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.surfaceDark2 : AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                              border: Border.all(color: s.border),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.blueSoftDark : AppColors.blueSoft,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(LucideIcons.sparkles, size: 24, color: AppColors.blue),
                                ),
                                const SizedBox(height: AppSizes.sm),
                                Text(
                                  'Rest & Recovery',
                                  style: GoogleFonts.manrope(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: s.primary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'No workouts scheduled for ${day.dayName}. Focus on good nutrition, hydration, and muscle recovery.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.manrope(
                                    fontSize: 12,
                                    color: s.secondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          // ── Added Exercises (Clean List by Name) ─────────
                          if (day.exercises.isNotEmpty) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Added to ${day.dayShort}',
                                      style: GoogleFonts.manrope(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: s.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: s.brandSoft,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '${day.exercises.length}',
                                        style: GoogleFonts.manrope(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: s.brand,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSizes.xs),
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: day.exercises.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 6),
                              itemBuilder: (context, exIndex) {
                                final item = day.exercises[exIndex];

                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.surfaceDark2 : AppColors.surfaceLight,
                                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                                    border: Border.all(color: s.border),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.exercise.name,
                                              style: GoogleFonts.manrope(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: s.primary,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Row(
                                              children: [
                                                _chip(item.exercise.targetMuscle, s.brand, s.brandSoft),
                                                const SizedBox(width: 4),
                                                _chip(
                                                  item.exercise.equipment,
                                                  s.secondary,
                                                  isDark ? AppColors.surfaceDark : AppColors.bgLight,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () => controller.removeExercise(exIndex),
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: isDark ? AppColors.roseSoftDark : AppColors.roseSoft,
                                            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                                          ),
                                          child: Icon(LucideIcons.trash_2, size: 15, color: AppColors.rose),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: AppSizes.lg),
                          ],

                          // ── Select & Add Exercises Section ─────────────
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                day.muscles.isNotEmpty
                                    ? 'Exercises for ${day.muscles.join(" & ")}'
                                    : 'Select & Add Exercises',
                                style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: s.primary,
                                ),
                              ),
                              if (controller.filteredExercisesForCurrentDay.isNotEmpty)
                                Text(
                                  '${controller.filteredExercisesForCurrentDay.length} available',
                                  style: GoogleFonts.manrope(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: s.tertiary,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: AppSizes.xs),

                          // Quick Search Input
                          Container(
                            height: 40,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.surfaceDark2 : AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                              border: Border.all(color: s.border),
                            ),
                            child: Row(
                              children: [
                                Icon(LucideIcons.search, size: 16, color: s.tertiary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    onChanged: (val) => controller.exerciseSearchQuery.value = val,
                                    style: GoogleFonts.manrope(fontSize: 13, color: s.primary),
                                    decoration: InputDecoration(
                                      hintText: day.muscles.isNotEmpty
                                          ? 'Search ${day.muscles.join(", ")} exercises...'
                                          : 'Search all exercises...',
                                      hintStyle: GoogleFonts.manrope(fontSize: 12, color: s.tertiary),
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ),
                                if (controller.exerciseSearchQuery.value.isNotEmpty)
                                  GestureDetector(
                                    onTap: () => controller.exerciseSearchQuery.value = '',
                                    child: Icon(LucideIcons.x, size: 15, color: s.tertiary),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSizes.sm),

                          // Categorized Exercise List for Selected Body Parts
                          if (day.muscles.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: AppSizes.xl, horizontal: AppSizes.lg),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.surfaceDark2 : AppColors.surfaceLight,
                                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                                border: Border.all(color: s.border),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: s.brandSoft,
                                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                                    ),
                                    child: Icon(LucideIcons.dumbbell, size: 24, color: s.brand),
                                  ),
                                  const SizedBox(height: AppSizes.sm),
                                  Text(
                                    'No Body Parts Selected',
                                    style: GoogleFonts.manrope(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: s.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Pick muscle chips above (e.g. Chest, Back, Legs) to see exercises for ${day.dayName}.',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.manrope(
                                      fontSize: 12,
                                      color: s.secondary,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else if (controller.categorizedExercisesForCurrentDay.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(AppSizes.lg),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.surfaceDark2 : AppColors.surfaceLight,
                                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                                border: Border.all(color: s.border),
                              ),
                              child: Column(
                                children: [
                                  Icon(LucideIcons.search_x, size: 26, color: s.tertiary),
                                  const SizedBox(height: 6),
                                  Text(
                                    'No exercises found matching "${controller.exerciseSearchQuery.value}"',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.manrope(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: s.secondary,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            ...controller.categorizedExercisesForCurrentDay.entries.map((entry) {
                              final muscleName = entry.key;
                              final exercises = entry.value;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: AppSizes.md),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Muscle Category Header
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 8, top: 4),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: s.brand,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            muscleName.toUpperCase(),
                                            style: GoogleFonts.manrope(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
                                              color: s.primary,
                                              letterSpacing: 0.6,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: s.brandSoft,
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              '${exercises.length}',
                                              style: GoogleFonts.manrope(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: s.brand,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Exercises in this category
                                    ListView.separated(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: exercises.length,
                                      separatorBuilder: (_, _) => const SizedBox(height: 6),
                                      itemBuilder: (context, exIndex) {
                                        final exercise = exercises[exIndex];
                                        final isAdded = controller.isExerciseAdded(exercise);

                                        return InkWell(
                                          onTap: () => controller.toggleExercise(exercise),
                                          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                          decoration: BoxDecoration(
                                            color: isDark ? AppColors.surfaceDark2 : AppColors.surfaceLight,
                                            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                                            border: Border.all(
                                              color: isAdded ? s.brand.withValues(alpha: 0.5) : s.border,
                                              width: isAdded ? 1.5 : 1.0,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              // Exercise SVG Icon
                                              Container(
                                                width: 38,
                                                height: 38,
                                                decoration: BoxDecoration(
                                                  color: isAdded ? s.brandSoft : (isDark ? AppColors.surfaceDark : AppColors.bgLight),
                                                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                                                ),
                                                alignment: Alignment.center,
                                                child: ExerciseSvgIcon(
                                                  exercise: exercise,
                                                  size: 20,
                                                  color: isAdded ? s.brand : s.secondary,
                                                ),
                                              ),
                                              const SizedBox(width: 10),

                                              // Exercise Name & Chips
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      exercise.name,
                                                      style: GoogleFonts.manrope(
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.w700,
                                                        color: s.primary,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 3),
                                                    Row(
                                                      children: [
                                                        _chip(exercise.targetMuscle, s.brand, s.brandSoft),
                                                        const SizedBox(width: 4),
                                                        _chip(
                                                          exercise.equipment,
                                                          s.secondary,
                                                          isDark ? AppColors.surfaceDark : AppColors.bgLight,
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),

                                              // 1-Tap Add/Remove Button
                                              GestureDetector(
                                                onTap: () => controller.toggleExercise(exercise),
                                                child: AnimatedContainer(
                                                  duration: const Duration(milliseconds: 150),
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: isAdded
                                                        ? (isDark ? AppColors.greenSoftDark : AppColors.greenSoft)
                                                        : s.brandSoft,
                                                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                                                    border: Border.all(
                                                      color: isAdded ? AppColors.green : s.brand,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        isAdded ? LucideIcons.check : LucideIcons.plus,
                                                        size: 13,
                                                        color: isAdded ? AppColors.green : s.brand,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        isAdded ? 'Added' : 'Add',
                                                        style: GoogleFonts.manrope(
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.w700,
                                                          color: isAdded ? AppColors.green : s.brand,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              );
                            }),

                          const SizedBox(height: AppSizes.md),

                          // Browse Full Library Fallback
                          Center(
                            child: TextButton.icon(
                              onPressed: () => _openExercisePicker(context, controller, day.muscles.firstOrNull),
                              icon: Icon(LucideIcons.library_big, size: 15, color: s.brand),
                              label: Text(
                                'Browse all categories in library',
                                style: GoogleFonts.manrope(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: s.brand,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  }),
                  if (controller.isEditing) ...[
                    const SizedBox(height: AppSizes.xl),
                    Center(
                      child: TextButton.icon(
                        onPressed: () => _confirmDelete(context, controller),
                        icon: const Icon(LucideIcons.trash_2, size: 16, color: AppColors.rose),
                        label: Text(
                          'Delete this workout schedule',
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.rose,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.md),
                  ],
                ],
              ),
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: EdgeInsets.fromLTRB(
              AppSizes.screenPadding,
              AppSizes.md,
              AppSizes.screenPadding,
              MediaQuery.of(context).padding.bottom + AppSizes.md,
            ),
            decoration: BoxDecoration(
              color: s.surface,
              border: Border(top: BorderSide(color: s.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: AppButton.outline(
                    text: 'Save Routine',
                    size: AppButtonSize.md,
                    fullWidth: true,
                    onPressed: () => controller.saveRoutine(setActive: false),
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: AppButton.primary(
                    text: 'Save & Set Active',
                    icon: LucideIcons.check,
                    size: AppButtonSize.md,
                    fullWidth: true,
                    onPressed: () => controller.saveRoutine(setActive: true),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openExercisePicker(
    BuildContext context,
    AddRoutineController controller,
    String? preferredMuscle,
  ) {
    ExercisePickerSheet.show(
      context: context,
      initialMuscle: preferredMuscle ?? 'All',
      onExerciseSelected: (Exercise exercise, int sets, int reps, double weight) {
        controller.addExerciseToCurrentDay(
          exercise,
          targetSets: sets,
          targetReps: reps,
          targetWeight: weight,
        );
      },
    );
  }

  Widget _chip(String text, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }

  void _confirmDelete(BuildContext context, AddRoutineController controller) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Delete Workout Schedule?',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to delete "${controller.editingRoutine?.name ?? "this schedule"}"? This action cannot be undone.',
        ),
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
              await controller.deleteRoutine();
            },
          ),
        ],
      ),
    );
  }
}
