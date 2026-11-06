import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:velto/core/constants/app_colors.dart';
import 'package:velto/core/constants/app_sizes.dart';
import 'package:velto/core/widgets/app_widgets.dart';
import 'package:velto/features/workout/controllers/add_routine_controller.dart';
import 'package:velto/features/workout/models/exercise.dart';
import 'package:velto/features/workout/models/routine_day.dart';
import 'package:velto/features/workout/widgets/exercise_picker_sheet.dart';

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
                  Text('Name', style: _sectionStyle(s)),
                  const SizedBox(height: AppSizes.xs),
                  AppCard(
                    isDark: isDark,
                    padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 14),
                    child: TextField(
                      controller: controller.nameController,
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: s.primary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'e.g. Push Pull Legs',
                        hintStyle: GoogleFonts.manrope(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: s.tertiary,
                        ),
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.lg),
                  Text('Week', style: _sectionStyle(s)),
                  const SizedBox(height: 2),
                  Text(
                    'Pick a day, then add the exercises for it.',
                    style: GoogleFonts.manrope(fontSize: 12, color: s.secondary, height: 1.35),
                  ),
                  const SizedBox(height: AppSizes.sm),
                  Obx(() => _weekStrip(controller, s, isDark)),
                  const SizedBox(height: AppSizes.md),
                  Obx(() => _dayEditor(context, controller, s, isDark)),
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

  TextStyle _sectionStyle(AppStyle s) {
    return GoogleFonts.manrope(
      fontSize: 13,
      fontWeight: FontWeight.w800,
      color: s.secondary,
      letterSpacing: 0.4,
    );
  }

  Widget _weekStrip(AddRoutineController controller, AppStyle s, bool isDark) {
    final selectedIndex = controller.selectedDayIndex.value;

    return SizedBox(
      height: 64,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: controller.days.length,
        itemBuilder: (context, index) {
          final day = controller.days[index];
          final isSelected = selectedIndex == index;

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
                      _chipStatus(day),
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
  }

  Widget _dayEditor(
    BuildContext context,
    AddRoutineController controller,
    AppStyle s,
    bool isDark,
  ) {
    final day = controller.currentDay;

    return AppCard(
      isDark: isDark,
      padding: const EdgeInsets.all(AppSizes.md),
      child: Column(
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
            _daySummary(day),
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: s.secondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: AppSizes.md),
          _restRow(controller, day, s, isDark),
          if (day.isRestDay) ...[
            const SizedBox(height: AppSizes.md),
            Text(
              'Nothing to lift. Sleep and meals are the work today.',
              style: GoogleFonts.manrope(fontSize: 13, color: s.secondary, height: 1.4),
            ),
          ] else ...[
            const SizedBox(height: AppSizes.md),
            Text('Exercises', style: _sectionStyle(s)),
            const SizedBox(height: AppSizes.sm),
            if (day.exercises.isEmpty)
              Text(
                'No exercises on ${day.dayName} yet.',
                style: GoogleFonts.manrope(fontSize: 13, color: s.secondary),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: day.exercises.length,
                separatorBuilder: (_, _) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final item = day.exercises[index];
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark2 : AppColors.bgLight,
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
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: s.primary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _exerciseMeta(item),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.manrope(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: s.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => controller.removeExercise(index),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.roseSoftDark : AppColors.roseSoft,
                              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                            ),
                            child: const Icon(LucideIcons.trash_2, size: 15, color: AppColors.rose),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: AppSizes.md),
            AppButton.primary(
              text: 'Add exercise',
              icon: LucideIcons.plus,
              size: AppButtonSize.md,
              fullWidth: true,
              onPressed: () => _openExercisePicker(context, controller),
            ),
          ],
        ],
      ),
    );
  }

  Widget _restRow(AddRoutineController controller, RoutineDay day, AppStyle s, bool isDark) {
    return Material(
      color: day.isRestDay
          ? (isDark ? AppColors.blueSoftDark : AppColors.blueSoft)
          : (isDark ? AppColors.surfaceDark2 : AppColors.bgLight),
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      child: InkWell(
        onTap: () => controller.toggleRestDay(!day.isRestDay),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            border: Border.all(
              color: day.isRestDay ? AppColors.blue : s.border,
              width: day.isRestDay ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                LucideIcons.sparkles,
                size: 22,
                color: day.isRestDay ? AppColors.blue : s.secondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rest day',
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: s.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Skip training on ${day.dayName}',
                      style: GoogleFonts.manrope(fontSize: 13, color: s.secondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: day.isRestDay ? AppColors.blue : (isDark ? AppColors.surfaceDark : Colors.white),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  border: Border.all(color: day.isRestDay ? AppColors.blue : s.border),
                ),
                child: Text(
                  day.isRestDay ? 'On' : 'Off',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: day.isRestDay ? Colors.white : s.secondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _chipStatus(RoutineDay day) {
    if (day.isRestDay) return 'Rest';
    if (day.exercises.isNotEmpty) return '${day.exercises.length} ex';
    return 'Empty';
  }

  String _daySummary(RoutineDay day) {
    if (day.isRestDay) return 'No training';
    final focus = day.muscles.where((m) => m.toLowerCase() != 'rest').toList();
    final count = day.exercises.length;
    if (count == 0 && focus.isEmpty) return 'Nothing planned yet';
    if (count == 0) return 'Focus set · add exercises';
    final countLabel = count == 1 ? '1 exercise' : '$count exercises';
    if (focus.isEmpty) return countLabel;
    final shown = focus.length <= 2 ? focus.join(', ') : '${focus.take(2).join(', ')} + ${focus.length - 2}';
    return '$countLabel · $shown';
  }

  String _exerciseMeta(WorkoutExerciseItem item) {
    final weight = item.targetWeight > 0
        ? ' · ${item.targetWeight.toStringAsFixed(item.targetWeight % 1 == 0 ? 0 : 1)} kg'
        : '';
    return '${item.exercise.targetMuscle} · ${item.targetSets}×${item.targetReps}$weight';
  }

  void _openExercisePicker(BuildContext context, AddRoutineController controller) {
    ExercisePickerSheet.show(
      context: context,
      onExerciseSelected: (Exercise exercise, int sets, int reps, double weight) {
        controller.addExerciseToCurrentDay(exercise);
      },
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
