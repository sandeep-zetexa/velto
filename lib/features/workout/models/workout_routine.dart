import 'package:velto/features/workout/models/routine_day.dart';

class WorkoutRoutine {
  final String id;
  final String name;
  final String description;
  final List<RoutineDay> days; // 7 days (Monday - Sunday)
  final bool isActive;
  final bool isCustom;
  final DateTime? createdAt;

  const WorkoutRoutine({
    required this.id,
    required this.name,
    required this.description,
    required this.days,
    this.isActive = false,
    this.isCustom = false,
    this.createdAt,
  });

  RoutineDay? getDay(String dayName) {
    try {
      return days.firstWhere(
        (d) => d.dayName.toLowerCase() == dayName.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  int get totalWorkoutsInWeek => days.where((d) => !d.isRestDay && d.exercises.isNotEmpty).length;

  int get totalExercisesInWeek => days.fold(0, (sum, d) => sum + d.exercises.length);

  WorkoutRoutine copyWith({
    String? id,
    String? name,
    String? description,
    List<RoutineDay>? days,
    bool? isActive,
    bool? isCustom,
    DateTime? createdAt,
  }) {
    return WorkoutRoutine(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      days: days ?? this.days,
      isActive: isActive ?? this.isActive,
      isCustom: isCustom ?? this.isCustom,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'days': days.map((d) => d.toJson()).toList(),
        'isActive': isActive,
        'isCustom': isCustom,
        'createdAt': createdAt?.toIso8601String(),
      };

  factory WorkoutRoutine.fromJson(Map<String, dynamic> json) => WorkoutRoutine(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        days: (json['days'] as List<dynamic>?)
                ?.map((d) => RoutineDay.fromJson(d as Map<String, dynamic>))
                .toList() ??
            const [],
        isActive: json['isActive'] as bool? ?? false,
        isCustom: json['isCustom'] as bool? ?? false,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
      );
}
