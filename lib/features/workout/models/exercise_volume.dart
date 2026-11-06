import 'package:velto/features/workout/models/exercise.dart';

/// One row in the exercise volume table.
///
/// A session is unique on (exerciseId, date). Volume is the sum of reps on
/// every set currently on the exercise — 3 sets of 12 is 36. It moves as
/// sets or reps change, not only when a set is checked off. Volume load is
/// the weight moved: sum of reps × kg on those sets.
class ExerciseVolumeRecord {
  final String exerciseId;
  final String date;
  final int totalReps;
  final double volumeLoadKg;
  final int completedSets;

  const ExerciseVolumeRecord({
    required this.exerciseId,
    required this.date,
    required this.totalReps,
    required this.volumeLoadKg,
    required this.completedSets,
  });

  bool get isEmpty => totalReps <= 0;

  /// Builds a row from every set on the exercise.
  /// Adding a set or changing its reps changes the total immediately.
  factory ExerciseVolumeRecord.fromSets({
    required String exerciseId,
    required String date,
    required List<ExerciseSet> sets,
  }) {
    var reps = 0;
    var load = 0.0;
    var completed = 0;
    for (final set in sets) {
      reps += set.reps;
      load += set.reps * set.weight;
      if (set.isCompleted) completed++;
    }
    return ExerciseVolumeRecord(
      exerciseId: exerciseId,
      date: date,
      totalReps: reps,
      volumeLoadKg: load,
      completedSets: completed,
    );
  }

  ExerciseVolumeRecord copyWith({
    String? exerciseId,
    String? date,
    int? totalReps,
    double? volumeLoadKg,
    int? completedSets,
  }) {
    return ExerciseVolumeRecord(
      exerciseId: exerciseId ?? this.exerciseId,
      date: date ?? this.date,
      totalReps: totalReps ?? this.totalReps,
      volumeLoadKg: volumeLoadKg ?? this.volumeLoadKg,
      completedSets: completedSets ?? this.completedSets,
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date,
        'totalReps': totalReps,
        'volumeLoadKg': volumeLoadKg,
        'completedSets': completedSets,
      };

  factory ExerciseVolumeRecord.fromJson(
    String exerciseId,
    Map<String, dynamic> json,
  ) {
    return ExerciseVolumeRecord(
      exerciseId: exerciseId,
      date: json['date'] as String? ?? '',
      totalReps: (json['totalReps'] as num?)?.toInt() ?? 0,
      volumeLoadKg: (json['volumeLoadKg'] as num?)?.toDouble() ?? 0,
      completedSets: (json['completedSets'] as num?)?.toInt() ?? 0,
    );
  }
}
