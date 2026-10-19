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

  Exercise? _configuringExercise;
  int _sets = 3;
  int _reps = 10;
  double _weight = 20.0;

  @override
  void initState() {
    super.initState();
    _selectedMuscle = widget.initialMuscle ?? 'All';
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
    setState(() {
      _configuringExercise = ex;
      _sets = ex.defaultSets;
      _reps = ex.defaultReps;
      _weight = ex.defaultWeight;
    });
  }

  void _confirmAdd() {
    if (_configuringExercise != null) {
      widget.onExerciseSelected(
        _configuringExercise!,
        _sets,
        _reps,
        _weight,
      );
      Navigator.pop(context);
    }
  }

  IconData _iconForMuscle(String muscle) {
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
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg, vertical: AppSizes.xs),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _configuringExercise == null ? 'Select Exercise' : 'Configure Sets & Weight',
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: s.primary,
                    letterSpacing: -0.3,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    if (_configuringExercise != null) {
                      setState(() => _configuringExercise = null);
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  icon: Icon(
                    _configuringExercise != null ? LucideIcons.arrow_left : LucideIcons.x,
                    color: s.secondary,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          Expanded(
            child: _configuringExercise == null
                ? _buildExerciseCatalog(s, isDark)
                : _buildConfigView(s, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCatalog(AppStyle s, bool isDark) {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSizes.lg, AppSizes.md, AppSizes.lg, AppSizes.sm),
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
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
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
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.dumbbell, size: 36, color: s.tertiary),
                          const SizedBox(height: 8),
                          Text(
                            'No exercises found',
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: s.secondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(AppSizes.lg),
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
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: s.brandSoft,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    _iconForMuscle(ex.targetMuscle),
                                    size: 20,
                                    color: s.brand,
                                  ),
                                ),
                                const SizedBox(width: AppSizes.md),
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

  Widget _buildConfigView(AppStyle s, bool isDark) {
    final ex = _configuringExercise!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selected Exercise Header Card
          Container(
            padding: const EdgeInsets.all(AppSizes.md),
            decoration: BoxDecoration(
              color: s.brandSoft,
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              border: Border.all(color: s.brand.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_iconForMuscle(ex.targetMuscle), size: 24, color: s.brand),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ex.name,
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: s.primary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Target: ${ex.targetMuscle} · ${ex.equipment}',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          color: s.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSizes.xl),

          // Sets Stepper
          _stepperRow(
            title: 'Number of Sets',
            valueDisplay: '$_sets sets',
            onMinus: () {
              if (_sets > 1) setState(() => _sets--);
            },
            onPlus: () {
              setState(() => _sets++);
            },
            s: s,
            isDark: isDark,
          ),

          const SizedBox(height: AppSizes.md),

          // Reps Stepper
          _stepperRow(
            title: 'Target Reps per Set',
            valueDisplay: '$_reps reps',
            onMinus: () {
              if (_reps > 1) setState(() => _reps--);
            },
            onPlus: () {
              setState(() => _reps++);
            },
            s: s,
            isDark: isDark,
          ),

          const SizedBox(height: AppSizes.md),

          // Starting Weight Stepper
          _stepperRow(
            title: 'Starting Weight',
            valueDisplay: '${_weight > 0 ? _weight.toStringAsFixed(1) : "Bodyweight"} ${_weight > 0 ? "kg" : ""}',
            onMinus: () {
              if (_weight >= 2.5) {
                setState(() => _weight -= 2.5);
              } else {
                setState(() => _weight = 0.0);
              }
            },
            onPlus: () {
              setState(() => _weight += 2.5);
            },
            s: s,
            isDark: isDark,
          ),

          const SizedBox(height: AppSizes.xxl),

          AppButton.primary(
            text: 'Add to Workout Day',
            icon: LucideIcons.plus,
            size: AppButtonSize.lg,
            fullWidth: true,
            onPressed: _confirmAdd,
          ),
        ],
      ),
    );
  }

  Widget _stepperRow({
    required String title,
    required String valueDisplay,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
    required AppStyle s,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark2 : AppColors.bgLight,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: s.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: s.primary,
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: onMinus,
                icon: const Icon(LucideIcons.minus, size: 16),
                style: IconButton.styleFrom(
                  backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
                  padding: const EdgeInsets.all(6),
                  minimumSize: const Size(32, 32),
                ),
              ),
              Container(
                constraints: const BoxConstraints(minWidth: 80),
                alignment: Alignment.center,
                child: Text(
                  valueDisplay,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: s.primary,
                  ),
                ),
              ),
              IconButton(
                onPressed: onPlus,
                icon: const Icon(LucideIcons.plus, size: 16),
                style: IconButton.styleFrom(
                  backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
                  padding: const EdgeInsets.all(6),
                  minimumSize: const Size(32, 32),
                ),
              ),
            ],
          ),
        ],
      ),
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
