import 'package:velto/features/workout/models/exercise.dart';

class RoutineDay {
  final String dayName; // Monday, Tuesday, Wednesday, Thursday, Friday, Saturday, Sunday
  final String dayShort; // Mon, Tue, Wed, Thu, Fri, Sat, Sun
  final List<String> muscles; // e.g. ['Chest', 'Triceps'] or ['Rest']
  final bool isRestDay;
  final List<WorkoutExerciseItem> exercises;

  const RoutineDay({
    required this.dayName,
    required this.dayShort,
    required this.muscles,
    this.isRestDay = false,
    this.exercises = const [],
  });

  String get musclesDisplay {
    if (isRestDay) return 'Rest & Recovery';
    if (muscles.isEmpty) return 'No focus selected';
    return muscles.join(' + ');
  }

  int get totalSets => exercises.fold(0, (sum, item) => sum + item.targetSets);

  int get completedSets => exercises.fold(
      0, (sum, item) => sum + item.sets.where((s) => s.isCompleted).length);

  bool get isCompleted =>
      !isRestDay &&
      exercises.isNotEmpty &&
      exercises.every((item) =>
          item.sets.isNotEmpty && item.sets.every((s) => s.isCompleted));

  double get completionProgress {
    if (totalSets == 0) return 0.0;
    return (completedSets / totalSets).clamp(0.0, 1.0);
  }

  RoutineDay copyWith({
    String? dayName,
    String? dayShort,
    List<String>? muscles,
    bool? isRestDay,
    List<WorkoutExerciseItem>? exercises,
  }) {
    return RoutineDay(
      dayName: dayName ?? this.dayName,
      dayShort: dayShort ?? this.dayShort,
      muscles: muscles ?? this.muscles,
      isRestDay: isRestDay ?? this.isRestDay,
      exercises: exercises ?? this.exercises,
    );
  }

  Map<String, dynamic> toJson() => {
        'dayName': dayName,
        'dayShort': dayShort,
        'muscles': muscles,
        'isRestDay': isRestDay,
        'exercises': exercises.map((e) => e.toJson()).toList(),
      };

  factory RoutineDay.fromJson(Map<String, dynamic> json) => RoutineDay(
        dayName: json['dayName'] as String,
        dayShort: json['dayShort'] as String,
        muscles: (json['muscles'] as List<dynamic>?)
                ?.map((m) => m.toString())
                .toList() ??
            const [],
        isRestDay: json['isRestDay'] as bool? ?? false,
        exercises: (json['exercises'] as List<dynamic>?)
                ?.map((e) =>
                    WorkoutExerciseItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}
