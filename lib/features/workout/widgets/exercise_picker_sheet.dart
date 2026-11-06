import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:velto/core/constants/app_colors.dart';
import 'package:velto/core/constants/app_sizes.dart';
import 'package:velto/core/widgets/app_widgets.dart';
import 'package:velto/features/workout/models/exercise.dart';
import 'package:velto/features/workout/services/workout_service.dart';
class ExercisePickerSheet extends StatefulWidget {
  final String? initialMuscle;
  final Function(Exercise exercise, int sets, int reps, double weight) onExerciseSelected;

  const ExercisePickerSheet({
    super.key,
    this.initialMuscle,
    required this.onExerciseSelected,
  });

  static Future<void> show({
    required BuildContext context,
    String? initialMuscle,
    required Function(Exercise exercise, int sets, int reps, double weight) onExerciseSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ExercisePickerSheet(
        initialMuscle: initialMuscle,
        onExerciseSelected: onExerciseSelected,
      ),
    );
  }

  @override
  State<ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends State<ExercisePickerSheet> {
  final WorkoutService _workoutService = WorkoutService();
  late String _selectedMuscle;
  String _searchQuery = '';
  List<Exercise> _exercises = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialMuscle?.trim() ?? 'All';
    _selectedMuscle = WorkoutService.muscleGroups.firstWhere(
      (m) => m.toLowerCase() == initial.toLowerCase(),
      orElse: () => WorkoutService.muscleGroups.firstWhere(
        (m) => initial.toLowerCase().contains(m.toLowerCase()) && m != 'All',
        orElse: () => 'All',
      ),
    );
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    setState(() => _isLoading = true);
    final list = await _workoutService.getExercises(
      muscle: _selectedMuscle == 'All' ? null : _selectedMuscle,
      query: _searchQuery,
    );
    setState(() {
      _exercises = list;
      _isLoading = false;
    });
  }

  void _onMuscleChanged(String muscle) {
    setState(() {
      _selectedMuscle = muscle;
    });
    _loadExercises();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _loadExercises();
  }

  void _selectExercise(Exercise ex) {
    widget.onExerciseSelected(ex, ex.defaultSets, ex.defaultReps, ex.defaultWeight);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = AppStyle(isDark);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      padding: EdgeInsets.only(bottom: bottomInset),
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
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding, vertical: AppSizes.xs),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Select Exercise',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: s.primary,
                      letterSpacing: -0.3,
                    ),
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

          Expanded(child: _buildExerciseCatalog(s, isDark)),
        ],
      ),
    );
  }

  Widget _buildExerciseCatalog(AppStyle s, bool isDark) {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSizes.screenPadding, AppSizes.md, AppSizes.screenPadding, AppSizes.sm),
          child: AppSearchBar(
            hintText: 'Search bench press, squat, pull-ups...',
            isDark: isDark,
            onChanged: _onSearchChanged,
          ),
        ),

        // Muscle filter horizontal bar
        SizedBox(
          height: 38,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
            itemCount: WorkoutService.muscleGroups.length,
            itemBuilder: (context, index) {
              final muscle = WorkoutService.muscleGroups[index];
              final isSelected = _selectedMuscle.toLowerCase() == muscle.toLowerCase();

              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: GestureDetector(
                  onTap: () => _onMuscleChanged(muscle),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? s.brand
                          : (isDark ? AppColors.surfaceDark2 : AppColors.secondarySoft),
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      border: Border.all(
                        color: isSelected ? s.brand : s.border,
                      ),
                    ),
                    child: Text(
                      muscle,
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: isSelected ? Colors.white : s.secondary,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: AppSizes.sm),

        // Exercise List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _exercises.isEmpty
                  ? AppEmptyState(
                      isDark: isDark,
                      icon: LucideIcons.dumbbell,
                      title: 'No exercises found',
                      subtitle: 'Try adjusting your search query or muscle filter.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(AppSizes.screenPadding),
                      itemCount: _exercises.length,
                      separatorBuilder: (_, _) => const SizedBox(height: AppSizes.sm),
                      itemBuilder: (context, index) {
                        final ex = _exercises[index];
                        return InkWell(
                          onTap: () => _selectExercise(ex),
                          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                          child: Container(
                            padding: const EdgeInsets.all(AppSizes.md),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.surfaceDark2 : AppColors.bgLight,
                              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                              border: Border.all(color: s.border),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        ex.name,
                                        style: GoogleFonts.manrope(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: s.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Row(
                                        children: [
                                          _badge(ex.targetMuscle, s.brand, s.brandSoft),
                                          const SizedBox(width: 4),
                                          _badge(ex.equipment, s.secondary, isDark ? AppColors.surfaceDark : Colors.white),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${ex.defaultSets} × ${ex.defaultReps}',
                                      style: GoogleFonts.manrope(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: s.primary,
                                      ),
                                    ),
                                    Text(
                                      ex.defaultWeight > 0 ? '${ex.defaultWeight.toStringAsFixed(0)} kg' : 'BW',
                                      style: GoogleFonts.manrope(
                                        fontSize: 11,
                                        color: s.secondary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 6),
                                Icon(LucideIcons.plus, size: 16, color: s.brand),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _badge(String text, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: GoogleFonts.manrope(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
