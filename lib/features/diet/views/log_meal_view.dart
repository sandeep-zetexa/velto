import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:velto/core/constants/app_colors.dart';
import 'package:velto/core/constants/app_sizes.dart';
import 'package:velto/core/widgets/app_widgets.dart';

class LogMealView extends StatelessWidget {
  const LogMealView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: AppAppBar(
        title: 'Log Meal',
        showBackButton: true,
        onBackPressed: () => Get.back(),
        isDark: isDark,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Column(
          children: [
            AppSearchBar(
              hintText: 'Search ingredients',
              isDark: isDark,
              onChanged: (value) {
                debugPrint('Search query: $value');
              },
            ),
          ],
        ),
      ),
    );
  }
}
