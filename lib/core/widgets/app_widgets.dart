import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:velto/core/constants/app_colors.dart';
import 'package:velto/core/constants/app_sizes.dart';

/// Resolved colour tokens for the current theme mode.
class AppStyle {
  final Color primary;
  final Color secondary;
  final Color tertiary;
  final Color surface;
  final Color border;

  AppStyle(bool isDark)
      : primary   = isDark ? AppColors.textPrimaryDark   : AppColors.textPrimaryLight,
        secondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
        tertiary  = isDark ? AppColors.textTertiaryDark  : AppColors.textTertiaryLight,
        surface   = isDark ? AppColors.surfaceDark       : AppColors.surfaceLight,
        border    = isDark ? AppColors.borderDark        : AppColors.borderLight;
}

/// Standard bordered card container.
class AppCard extends StatelessWidget {
  final Widget child;
  final bool isDark;
  final EdgeInsets? padding;

  const AppCard({super.key, required this.child, required this.isDark, this.padding});

  @override
  Widget build(BuildContext context) {
    final s = AppStyle(isDark);
    return Container(
      padding: padding ?? const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: s.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: s.border),
      ),
      child: child,
    );
  }
}

/// Circular bordered icon button (top-right notification etc).
class AppIconBtn extends StatelessWidget {
  final IconData icon;
  final bool isDark;

  const AppIconBtn({super.key, required this.icon, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final s = AppStyle(isDark);
    return Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        color: s.surface, shape: BoxShape.circle,
        border: Border.all(color: s.border),
      ),
      child: Icon(icon, size: 18, color: s.primary),
    );
  }
}

/// Section header with optional right-side action link.
class AppSectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final bool isDark;

  const AppSectionHeader({super.key, required this.title, this.action, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final s = AppStyle(isDark);
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(title, style: GoogleFonts.manrope(
          fontSize: 15, fontWeight: FontWeight.w700, color: s.primary, letterSpacing: -0.2)),
      if (action != null)
        Text(action!, style: GoogleFonts.manrope(
            fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
    ]);
  }
}

/// List row: icon swatch + title + subtitle + chevron.
class AppActivityRow extends StatelessWidget {
  final IconData icon;
  final Color iconBg, iconColor;
  final String title, sub;
  final bool isDark;

  const AppActivityRow({
    super.key,
    required this.icon, required this.iconBg, required this.iconColor,
    required this.title, required this.sub, required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final s = AppStyle(isDark);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.sm),
      child: AppCard(
        isDark: isDark,
        padding: const EdgeInsets.all(AppSizes.md),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: s.primary)),
            const SizedBox(height: 2),
            Text(sub, style: GoogleFonts.manrope(fontSize: 11, color: s.secondary)),
          ])),
          Icon(LucideIcons.chevron_right, size: 15, color: s.tertiary),
        ]),
      ),
    );
  }
}
