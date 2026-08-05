import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:velto/core/constants/app_colors.dart';

class MealModel {
  final String id;
  final String category;
  final String time;
  final String title;
  final int calories;
  final int protein;
  final int carbs;
  final int fats;

  const MealModel({
    required this.id,
    required this.category,
    required this.time,
    required this.title,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
  });

  IconData get icon {
    switch (category.toLowerCase()) {
      case 'breakfast':
        return LucideIcons.sun;
      case 'lunch':
        return LucideIcons.utensils;
      case 'dinner':
        return LucideIcons.moon;
      case 'snack':
      default:
        return LucideIcons.cookie;
    }
  }

  Color getIconBg(bool isDark) {
    switch (category.toLowerCase()) {
      case 'breakfast':
        return isDark ? AppColors.amberSoftDark : AppColors.amberSoft;
      case 'lunch':
        return isDark ? AppColors.primarySoftDark : AppColors.primarySoft;
      case 'dinner':
        return isDark ? AppColors.secondarySoftDark : AppColors.secondarySoft;
      case 'snack':
      default:
        return isDark ? AppColors.tertiarySoftDark : AppColors.tertiarySoft;
    }
  }

  Color getIconColor(bool isDark) {
    switch (category.toLowerCase()) {
      case 'breakfast':
        return AppColors.amber;
      case 'lunch':
        return AppColors.primary;
      case 'dinner':
        return AppColors.secondary;
      case 'snack':
      default:
        return AppColors.tertiary;
    }
  }
}
