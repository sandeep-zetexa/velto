import 'package:velto/features/workout/models/exercise.dart';
import 'package:velto/features/workout/models/routine_day.dart';

/// Represents a persistent historical record of exercises and sets performed on a specific date.
/// Preserves the exact routine name, plan, and tick states (done / not done) as they were on that day,
/// even if the user switches active routines on subsequent days.
class DailyWorkoutLog {
  final String date; // "yyyy-MM-dd"
  final String routineId;
  final String routineName;
  final String dayName;
  final List<String> muscles;
  final bool isRestDay;
  final List<WorkoutExerciseItem> exercises;

  const DailyWorkoutLog({
    required this.date,
    required this.routineId,
    required this.routineName,
    required this.dayName,
    required this.muscles,
    this.isRestDay = false,
    this.exercises = const [],
  });

  /// Factory creating an initial daily log snapshot from an active RoutineDay
  factory DailyWorkoutLog.fromRoutineDay({
    required String date,
    required String routineId,
    required String routineName,
    required RoutineDay day,
  }) {
    return DailyWorkoutLog(
      date: date,
      routineId: routineId,
      routineName: routineName,
      dayName: day.dayName,
      muscles: day.muscles,
      isRestDay: day.isRestDay,
      exercises: day.exercises.map((e) {
        return e.copyWith(
          sets: e.sets.map((s) => s.copyWith()).toList(),
        );
      }).toList(),
    );
  }

  int get totalSets => exercises.fold(0, (sum, e) => sum + e.targetSets);

  int get completedSets => exercises.fold(
        0,
        (sum, e) => sum + e.sets.where((s) => s.isCompleted).length,
      );

  bool get isCompleted =>
      !isRestDay &&
      exercises.isNotEmpty &&
      exercises.every(
          (e) => e.sets.isNotEmpty && e.sets.every((s) => s.isCompleted));

  String get musclesDisplay {
    if (isRestDay) return 'Rest & Recovery';
    if (muscles.isEmpty) return 'No focus selected';
    return muscles.join(' + ');
  }

  DailyWorkoutLog copyWith({
    String? date,
    String? routineId,
    String? routineName,
    String? dayName,
    List<String>? muscles,
    bool? isRestDay,
    List<WorkoutExerciseItem>? exercises,
  }) {
    return DailyWorkoutLog(
      date: date ?? this.date,
      routineId: routineId ?? this.routineId,
      routineName: routineName ?? this.routineName,
      dayName: dayName ?? this.dayName,
      muscles: muscles ?? this.muscles,
      isRestDay: isRestDay ?? this.isRestDay,
      exercises: exercises ?? this.exercises,
    );
  }

  /// Minimal storage JSON storing only exerciseId references and set results
  Map<String, dynamic> toMinimalJson() => {
        'date': date,
        'routineId': routineId,
        'routineName': routineName,
        'dayName': dayName,
        'muscles': muscles,
        'isRestDay': isRestDay,
        'exercises': exercises.map((e) => e.toMinimalJson()).toList(),
      };

  factory DailyWorkoutLog.fromMinimalJson(
    Map<String, dynamic> json,
    Map<String, Exercise> exerciseMap,
  ) {
    return DailyWorkoutLog(
      date: json['date'] as String,
      routineId: json['routineId'] as String? ?? '',
      routineName: json['routineName'] as String? ?? 'Workout Plan',
      dayName: json['dayName'] as String? ?? '',
      muscles: (json['muscles'] as List<dynamic>?)
              ?.map((m) => m.toString())
              .toList() ??
          const [],
      isRestDay: json['isRestDay'] as bool? ?? false,
      exercises: (json['exercises'] as List<dynamic>?)
              ?.map((e) {
                final itemMap = Map<String, dynamic>.from(e as Map);
                final exId = itemMap['exerciseId'] as String? ?? '';
                final resolved = exerciseMap[exId];
                if (resolved == null) return null;
                return WorkoutExerciseItem.fromMinimalJson(itemMap, resolved);
              })
              .whereType<WorkoutExerciseItem>()
              .toList() ??
          const [],
    );
  }
}
