import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:velto/core/constants/app_colors.dart';
import 'package:velto/core/constants/app_sizes.dart';

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const AppBottomNavBar({super.key, required this.currentIndex, required this.onTap});

  static const _items = [
    _NavItem(icon: LucideIcons.layout_dashboard, label: 'Dashboard'),
    _NavItem(icon: LucideIcons.dumbbell,         label: 'Workout'),
    _NavItem(icon: LucideIcons.apple,            label: 'Diet'),
    _NavItem(icon: LucideIcons.user,             label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border(top: BorderSide(color: border, width: 1)),
      ),
      padding: EdgeInsets.only(
        left: AppSizes.lg,
        right: AppSizes.lg,
        top: AppSizes.sm,
        bottom: MediaQuery.of(context).padding.bottom,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_items.length, (i) => _item(i, isDark)),
      ),
    );
  }

  Widget _item(int index, bool isDark) {
    final selected = index == currentIndex;
    final item = _items[index];
    final selectedColor = isDark ? AppColors.primaryDark : AppColors.primary;
    final inactiveColor = isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            width: 48,
            height: 32,
            decoration: BoxDecoration(
              color: selected
                  ? (isDark
                      ? AppColors.primaryDark.withValues(alpha: 0.15)
                      : AppColors.primarySoft)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              item.icon,
              size: 20,
              color: selected ? selectedColor : inactiveColor,
            ),
          ),
          const SizedBox(height: 3),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 180),
            style: GoogleFonts.manrope(
              fontSize: 10.5,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? selectedColor : inactiveColor,
            ),
            child: Text(item.label),
          ),
        ],
      ),
    );
  }
}
