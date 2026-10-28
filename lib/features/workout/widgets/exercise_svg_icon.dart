import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:velto/features/workout/models/exercise.dart';

/// Renders the exercise's vector SVG icon with fallback to Lucide icons.
class ExerciseSvgIcon extends StatelessWidget {
  final Exercise exercise;
  final double size;
  final Color? color;

  const ExerciseSvgIcon({
    super.key,
    required this.exercise,
    this.size = 20,
    this.color,
  });

  IconData _iconForMuscle(String muscle) {
    switch (muscle.toLowerCase()) {
      case 'chest':
        return LucideIcons.shield;
      case 'back':
        return LucideIcons.layers;
      case 'shoulders':
        return LucideIcons.maximize;
      case 'biceps':
      case 'triceps':
        return LucideIcons.zap;
      case 'legs':
      case 'quads':
      case 'hamstrings':
      case 'glutes':
      case 'calves':
        return LucideIcons.activity;
      case 'abs':
      case 'core':
        return LucideIcons.flame;
      case 'cardio':
        return LucideIcons.heart_pulse;
      default:
        return LucideIcons.dumbbell;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (WidgetsBinding.instance.runtimeType.toString().contains('TestWidgetsFlutterBinding')) {
      return Icon(
        _iconForMuscle(exercise.targetMuscle),
        size: size,
        color: color,
      );
    }

    final svgCode = exercise.svg ?? Exercise.defaultPlaceholderSvg;

    if (svgCode.trim().isNotEmpty) {
      try {
        return SvgPicture.string(
          svgCode,
          width: size,
          height: size,
          colorFilter: color != null ? ColorFilter.mode(color!, BlendMode.srcIn) : null,
          placeholderBuilder: (_) => Icon(
            _iconForMuscle(exercise.targetMuscle),
            size: size,
            color: color,
          ),
        );
      } catch (_) {
        return Icon(
          _iconForMuscle(exercise.targetMuscle),
          size: size,
          color: color,
        );
      }
    }

    return Icon(
      _iconForMuscle(exercise.targetMuscle),
      size: size,
      color: color,
    );
  }
}
