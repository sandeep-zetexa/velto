class Exercise {
  final String id;
  final String name;
  final String targetMuscle; // e.g. Chest, Back, Shoulders, Biceps, Triceps, Quads, Hamstrings, Glutes, Calves, Abs, Cardio
  final List<String> secondaryMuscles;
  final String category; // e.g. Upper Body, Lower Body, Core, Cardio
  final String equipment; // Barbell, Dumbbell, Cable, Machine, Bodyweight
  final int defaultSets;
  final int defaultReps;
  final double defaultWeight;
  final String? instructions;
  final String? svg;

  static const String defaultPlaceholderSvg =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">'
      '<path d="m6.5 6.5 11 11"/>'
      '<path d="m21 21-1-1"/>'
      '<path d="m3 3 1 1"/>'
      '<path d="m18 22 4-4"/>'
      '<path d="m2 6 4-4"/>'
      '<path d="m3 10 7-7"/>'
      '<path d="m14 21 7-7"/>'
      '</svg>';

  const Exercise({
    required this.id,
    required this.name,
    required this.targetMuscle,
    this.secondaryMuscles = const [],
    required this.category,
    required this.equipment,
    this.defaultSets = 3,
    this.defaultReps = 10,
    this.defaultWeight = 20.0,
    this.instructions,
    this.svg,
  });

  Exercise copyWith({
    String? id,
    String? name,
    String? targetMuscle,
    List<String>? secondaryMuscles,
    String? category,
    String? equipment,
    int? defaultSets,
    int? defaultReps,
    double? defaultWeight,
    String? instructions,
    String? svg,
  }) =>
      Exercise(
        id: id ?? this.id,
        name: name ?? this.name,
        targetMuscle: targetMuscle ?? this.targetMuscle,
        secondaryMuscles: secondaryMuscles ?? this.secondaryMuscles,
        category: category ?? this.category,
        equipment: equipment ?? this.equipment,
        defaultSets: defaultSets ?? this.defaultSets,
        defaultReps: defaultReps ?? this.defaultReps,
        defaultWeight: defaultWeight ?? this.defaultWeight,
        instructions: instructions ?? this.instructions,
        svg: svg ?? this.svg,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'targetMuscle': targetMuscle,
        'secondaryMuscles': secondaryMuscles,
        'category': category,
        'equipment': equipment,
        'defaultSets': defaultSets,
        'defaultReps': defaultReps,
        'defaultWeight': defaultWeight,
        'instructions': instructions,
        'svg': svg ?? defaultPlaceholderSvg,
      };

  factory Exercise.fromJson(Map<String, dynamic> json) => Exercise(
        id: json['id'] as String,
        name: json['name'] as String,
        targetMuscle: json['targetMuscle'] as String,
        secondaryMuscles: (json['secondaryMuscles'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        category: json['category'] as String,
        equipment: json['equipment'] as String,
        defaultSets: json['defaultSets'] as int? ?? 3,
        defaultReps: json['defaultReps'] as int? ?? 10,
        defaultWeight: (json['defaultWeight'] as num?)?.toDouble() ?? 20.0,
        instructions: json['instructions'] as String?,
        svg: json['svg'] as String? ?? defaultPlaceholderSvg,
      );
}

class ExerciseSet {
  final int setNumber;
  final int reps;
  final double weight;
  final bool isCompleted;

  const ExerciseSet({
    required this.setNumber,
    required this.reps,
    required this.weight,
    this.isCompleted = false,
  });

  ExerciseSet copyWith({
    int? setNumber,
    int? reps,
    double? weight,
    bool? isCompleted,
  }) =>
      ExerciseSet(
        setNumber: setNumber ?? this.setNumber,
        reps: reps ?? this.reps,
        weight: weight ?? this.weight,
        isCompleted: isCompleted ?? this.isCompleted,
      );

  Map<String, dynamic> toJson() => {
        'setNumber': setNumber,
        'reps': reps,
        'weight': weight,
        'isCompleted': isCompleted,
      };

  factory ExerciseSet.fromJson(Map<String, dynamic> json) => ExerciseSet(
        setNumber: json['setNumber'] as int,
        reps: json['reps'] as int,
        weight: (json['weight'] as num).toDouble(),
        isCompleted: json['isCompleted'] as bool? ?? false,
      );
}

class WorkoutExerciseItem {
  final String id;
  final Exercise exercise;
  final int targetSets;
  final int targetReps;
  final double targetWeight;
  final List<ExerciseSet> sets;
  final String? notes;

  const WorkoutExerciseItem({
    required this.id,
    required this.exercise,
    required this.targetSets,
    required this.targetReps,
    required this.targetWeight,
    required this.sets,
    this.notes,
  });

  factory WorkoutExerciseItem.create({
    required Exercise exercise,
    int? targetSets,
    int? targetReps,
    double? targetWeight,
    String? notes,
  }) {
    final setsCount = targetSets ?? exercise.defaultSets;
    final repsCount = targetReps ?? exercise.defaultReps;
    final weight = targetWeight ?? exercise.defaultWeight;

    return WorkoutExerciseItem(
      id: '${exercise.id}_${DateTime.now().microsecondsSinceEpoch}',
      exercise: exercise,
      targetSets: setsCount,
      targetReps: repsCount,
      targetWeight: weight,
      sets: List.generate(
        setsCount,
        (i) => ExerciseSet(
          setNumber: i + 1,
          reps: repsCount,
          weight: weight,
        ),
      ),
      notes: notes,
    );
  }

  WorkoutExerciseItem copyWith({
    String? id,
    Exercise? exercise,
    int? targetSets,
    int? targetReps,
    double? targetWeight,
    List<ExerciseSet>? sets,
    String? notes,
  }) {
    return WorkoutExerciseItem(
      id: id ?? this.id,
      exercise: exercise ?? this.exercise,
      targetSets: targetSets ?? this.targetSets,
      targetReps: targetReps ?? this.targetReps,
      targetWeight: targetWeight ?? this.targetWeight,
      sets: sets ?? this.sets,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'exercise': exercise.toJson(),
        'targetSets': targetSets,
        'targetReps': targetReps,
        'targetWeight': targetWeight,
        'sets': sets.map((s) => s.toJson()).toList(),
        'notes': notes,
      };

  /// Minimal storage representation saving only exerciseId reference and set configurations.
  Map<String, dynamic> toMinimalJson() => {
        'id': id,
        'exerciseId': exercise.id,
        'targetSets': targetSets,
        'targetReps': targetReps,
        'targetWeight': targetWeight,
        'sets': sets.map((s) => s.toJson()).toList(),
        'notes': notes,
      };

  factory WorkoutExerciseItem.fromJson(Map<String, dynamic> json) =>
      WorkoutExerciseItem(
        id: json['id'] as String,
        exercise: Exercise.fromJson(json['exercise'] as Map<String, dynamic>),
        targetSets: json['targetSets'] as int? ?? 3,
        targetReps: json['targetReps'] as int? ?? 10,
        targetWeight: (json['targetWeight'] as num?)?.toDouble() ?? 20.0,
        sets: (json['sets'] as List<dynamic>?)
                ?.map((s) => ExerciseSet.fromJson(s as Map<String, dynamic>))
                .toList() ??
            const [],
        notes: json['notes'] as String?,
      );

  factory WorkoutExerciseItem.fromMinimalJson(
    Map<String, dynamic> json,
    Exercise resolvedExercise,
  ) =>
      WorkoutExerciseItem(
        id: json['id'] as String,
        exercise: resolvedExercise,
        targetSets: json['targetSets'] as int? ?? resolvedExercise.defaultSets,
        targetReps: json['targetReps'] as int? ?? resolvedExercise.defaultReps,
        targetWeight: (json['targetWeight'] as num?)?.toDouble() ?? resolvedExercise.defaultWeight,
        sets: (json['sets'] as List<dynamic>?)
                ?.map((s) => ExerciseSet.fromJson(s as Map<String, dynamic>))
                .toList() ??
            const [],
        notes: json['notes'] as String?,
      );
}
