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

/// Universal empty-state placeholder widget.
///
/// Show this whenever a list or section has no data to display.
/// [icon] defaults to [LucideIcons.inbox] if not provided.
/// Supply [actionLabel] + [onAction] to render a tappable call-to-action.
class AppEmptyState extends StatelessWidget {
  final IconData? icon;
  final Color? iconColor;
  final Color? iconBg;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool isDark;

  const AppEmptyState({
    super.key,
    this.icon,
    this.iconColor,
    this.iconBg,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final s = AppStyle(isDark);
    final resolvedIconColor = iconColor ?? AppColors.primary;
    final resolvedIconBg = iconBg ??
        (isDark ? AppColors.primarySoftDark : AppColors.primarySoft);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon bubble
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: resolvedIconBg,
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            ),
            child: Icon(
              icon ?? LucideIcons.inbox,
              size: 28,
              color: resolvedIconColor,
            ),
          ),
          const SizedBox(height: AppSizes.md),

          // Title
          Text(
            title,
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: s.primary,
              letterSpacing: -0.2,
            ),
          ),

          // Subtitle
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(fontSize: 12, color: s.secondary),
            ),
          ],

          // Optional action button
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSizes.md),
            GestureDetector(
              onTap: onAction,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: resolvedIconBg,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: Text(
                  actionLabel!,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: resolvedIconColor,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
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

/// Dynamic reusable AppBar widget for standard screens.
class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;
  final bool isDark;

  const AppAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.showBackButton = false,
    this.onBackPressed,
    this.actions,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final s = AppStyle(isDark);
    return AppBar(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      leading: showBackButton
          ? IconButton(
              icon: Icon(LucideIcons.arrow_left, color: s.primary),
              onPressed: onBackPressed ?? () => Navigator.maybePop(context),
            )
          : null,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (subtitle != null)
            Text(
              subtitle!,
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: s.secondary,
              ),
            ),
          Text(
            title,
            style: GoogleFonts.manrope(
              fontSize: subtitle != null ? 24 : 20,
              fontWeight: FontWeight.w800,
              color: s.primary,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(subtitle != null ? 72 : 56);
}

/// Dynamic reusable SliverAppBar widget for scrollable screens.
class AppSliverAppBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final bool isDark;

  const AppSliverAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final s = AppStyle(isDark);
    return SliverAppBar(
      floating: true,
      snap: true,
      toolbarHeight: subtitle != null ? 72 : 56,
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      elevation: 0,
      scrolledUnderElevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (subtitle != null)
            Text(
              subtitle!,
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: s.secondary,
              ),
            ),
          Text(
            title,
            style: GoogleFonts.manrope(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: s.primary,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
      actions: actions,
    );
  }
}

