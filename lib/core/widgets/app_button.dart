import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:velto/core/constants/app_colors.dart';
import 'package:velto/core/constants/app_sizes.dart';
import 'package:velto/core/widgets/app_widgets.dart';

/// Style variants supported by [AppButton].
enum AppButtonVariant {
  primary,
  secondary,
  outline,
  soft,
  danger,
  dangerOutline,
  text,
}

/// Sizing scales supported by [AppButton].
enum AppButtonSize {
  lg,
  md,
  sm,
  xs,
}

/// A comprehensive, stateful reusable button widget matching the Velto design system.
///
/// Supports:
/// - Multiple visual variants (primary, secondary, outline, soft, danger, text)
/// - Sizing tiers (lg: 52px, md: 44px, sm: 36px, xs: 30px)
/// - Full-width or wrap-content layout
/// - Loading state with animated spinner and optional loading text
/// - Disabled state with automatic dimming
/// - Text-only, icon-only, leading icon + text, text + trailing icon
/// - Smooth tap-down scale feedback
class AppButton extends StatefulWidget {
  final String? text;
  final IconData? icon;
  final IconData? trailingIcon;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool isLoading;
  final String? loadingText;
  final bool isDisabled;
  final bool fullWidth;
  final Color? customBgColor;
  final Color? customTextColor;
  final Color? customBorderColor;
  final double? customHeight;
  final double? customBorderRadius;
  final EdgeInsetsGeometry? customPadding;

  const AppButton({
    super.key,
    this.text,
    this.icon,
    this.trailingIcon,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.md,
    this.isLoading = false,
    this.loadingText,
    this.isDisabled = false,
    this.fullWidth = false,
    this.customBgColor,
    this.customTextColor,
    this.customBorderColor,
    this.customHeight,
    this.customBorderRadius,
    this.customPadding,
  });

  /// Primary solid brand button (e.g. Save, Submit, Confirm).
  const AppButton.primary({
    super.key,
    required String this.text,
    this.icon,
    this.trailingIcon,
    required this.onPressed,
    this.size = AppButtonSize.md,
    this.isLoading = false,
    this.loadingText,
    this.isDisabled = false,
    this.fullWidth = false,
    this.customBgColor,
    this.customTextColor,
    this.customBorderColor,
    this.customHeight,
    this.customBorderRadius,
    this.customPadding,
  }) : variant = AppButtonVariant.primary;

  /// Secondary neutral button with subtle border.
  const AppButton.secondary({
    super.key,
    required String this.text,
    this.icon,
    this.trailingIcon,
    required this.onPressed,
    this.size = AppButtonSize.md,
    this.isLoading = false,
    this.loadingText,
    this.isDisabled = false,
    this.fullWidth = false,
    this.customBgColor,
    this.customTextColor,
    this.customBorderColor,
    this.customHeight,
    this.customBorderRadius,
    this.customPadding,
  }) : variant = AppButtonVariant.secondary;

  /// Transparent background with colored border.
  const AppButton.outline({
    super.key,
    required String this.text,
    this.icon,
    this.trailingIcon,
    required this.onPressed,
    this.size = AppButtonSize.md,
    this.isLoading = false,
    this.loadingText,
    this.isDisabled = false,
    this.fullWidth = false,
    this.customBgColor,
    this.customTextColor,
    this.customBorderColor,
    this.customHeight,
    this.customBorderRadius,
    this.customPadding,
  }) : variant = AppButtonVariant.outline;

  /// Soft-tinted button (light green background with brand text).
  const AppButton.soft({
    super.key,
    required String this.text,
    this.icon,
    this.trailingIcon,
    required this.onPressed,
    this.size = AppButtonSize.md,
    this.isLoading = false,
    this.loadingText,
    this.isDisabled = false,
    this.fullWidth = false,
    this.customBgColor,
    this.customTextColor,
    this.customBorderColor,
    this.customHeight,
    this.customBorderRadius,
    this.customPadding,
  }) : variant = AppButtonVariant.soft;

  /// Destructive action button (red solid or soft).
  const AppButton.danger({
    super.key,
    required String this.text,
    this.icon,
    this.trailingIcon,
    required this.onPressed,
    this.size = AppButtonSize.md,
    this.isLoading = false,
    this.loadingText,
    this.isDisabled = false,
    this.fullWidth = false,
    this.customBgColor,
    this.customTextColor,
    this.customBorderColor,
    this.customHeight,
    this.customBorderRadius,
    this.customPadding,
  }) : variant = AppButtonVariant.danger;

  /// Clean borderless text action (e.g. AppBar actions, dialog cancel).
  const AppButton.text({
    super.key,
    required String this.text,
    this.icon,
    this.trailingIcon,
    required this.onPressed,
    this.size = AppButtonSize.md,
    this.isLoading = false,
    this.loadingText,
    this.isDisabled = false,
    this.fullWidth = false,
    this.customTextColor,
    this.customHeight,
    this.customPadding,
  })  : variant = AppButtonVariant.text,
        customBgColor = null,
        customBorderColor = null,
        customBorderRadius = null;

  /// Standalone Icon-only button.
  const AppButton.icon({
    super.key,
    required IconData this.icon,
    required this.onPressed,
    this.variant = AppButtonVariant.secondary,
    this.size = AppButtonSize.md,
    this.isLoading = false,
    this.isDisabled = false,
    this.customBgColor,
    this.customTextColor,
    this.customBorderColor,
    this.customHeight,
    this.customBorderRadius,
    this.customPadding,
  })  : text = null,
        trailingIcon = null,
        loadingText = null,
        fullWidth = false;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> with SingleTickerProviderStateMixin {
  bool _isPressed = false;

  bool get _effectiveDisabled =>
      widget.isDisabled || widget.isLoading || widget.onPressed == null;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = AppStyle(isDark);

    // Sizing attributes
    final double height = widget.customHeight ?? _getDefaultHeight(widget.size);
    final double fontSize = _getDefaultFontSize(widget.size);
    final double iconSize = _getDefaultIconSize(widget.size);
    final double borderRadius =
        widget.customBorderRadius ?? _getDefaultBorderRadius(widget.size);
    final EdgeInsetsGeometry padding =
        widget.customPadding ?? _getDefaultPadding(widget.size, widget.text == null);

    // Color attributes
    final Color bgColor = widget.customBgColor ?? _getBgColor(isDark, s);
    final Color fgColor = widget.customTextColor ?? _getFgColor(isDark, s);
    final Border? border = _getBorder(isDark, s);

    // Content
    Widget content;
    if (widget.isLoading) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: iconSize,
            height: iconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(fgColor),
            ),
          ),
          if (widget.loadingText != null) ...[
            const SizedBox(width: 8),
            Text(
              widget.loadingText!,
              style: GoogleFonts.manrope(
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                color: fgColor,
              ),
            ),
          ],
        ],
      );
    } else {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.icon != null) ...[
            Icon(widget.icon, size: iconSize, color: fgColor),
            if (widget.text != null) const SizedBox(width: 6),
          ],
          if (widget.text != null)
            Flexible(
              child: Text(
                widget.text!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.manrope(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                  color: fgColor,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          if (widget.trailingIcon != null) ...[
            if (widget.text != null) const SizedBox(width: 6),
            Icon(widget.trailingIcon, size: iconSize, color: fgColor),
          ],
        ],
      );
    }

    Widget button = AnimatedScale(
      scale: _isPressed && !_effectiveDisabled ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeInOut,
      child: AnimatedOpacity(
        opacity: _effectiveDisabled ? 0.45 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          height: widget.variant == AppButtonVariant.text ? null : height,
          constraints: widget.text == null && widget.variant != AppButtonVariant.text
              ? BoxConstraints(minWidth: height)
              : null,
          padding: padding,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(borderRadius),
            border: border,
            boxShadow: widget.variant == AppButtonVariant.primary &&
                    !_effectiveDisabled &&
                    widget.size != AppButtonSize.xs
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.22),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Center(
            widthFactor: widget.fullWidth ? null : 1.0,
            child: content,
          ),
        ),
      ),
    );

    return GestureDetector(
      onTapDown: _effectiveDisabled ? null : (_) => setState(() => _isPressed = true),
      onTapUp: _effectiveDisabled ? null : (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: _effectiveDisabled ? null : widget.onPressed,
      behavior: HitTestBehavior.opaque,
      child: widget.fullWidth ? SizedBox(width: double.infinity, child: button) : button,
    );
  }

  // ── Sizing Helpers ─────────────────────────────────────────────────────────

  double _getDefaultHeight(AppButtonSize size) {
    switch (size) {
      case AppButtonSize.lg:
        return 52.0;
      case AppButtonSize.md:
        return 44.0;
      case AppButtonSize.sm:
        return 36.0;
      case AppButtonSize.xs:
        return 30.0;
    }
  }

  double _getDefaultFontSize(AppButtonSize size) {
    switch (size) {
      case AppButtonSize.lg:
        return 15.0;
      case AppButtonSize.md:
        return 14.0;
      case AppButtonSize.sm:
        return 12.5;
      case AppButtonSize.xs:
        return 11.0;
    }
  }

  double _getDefaultIconSize(AppButtonSize size) {
    switch (size) {
      case AppButtonSize.lg:
        return 18.0;
      case AppButtonSize.md:
        return 16.0;
      case AppButtonSize.sm:
        return 14.0;
      case AppButtonSize.xs:
        return 13.0;
    }
  }

  double _getDefaultBorderRadius(AppButtonSize size) {
    switch (size) {
      case AppButtonSize.lg:
        return AppSizes.radiusLg;
      case AppButtonSize.md:
        return AppSizes.radiusMd;
      case AppButtonSize.sm:
        return AppSizes.radiusMd;
      case AppButtonSize.xs:
        return AppSizes.radiusSm;
    }
  }

  EdgeInsetsGeometry _getDefaultPadding(AppButtonSize size, bool isIconOnly) {
    if (isIconOnly) {
      switch (size) {
        case AppButtonSize.lg:
          return const EdgeInsets.all(14.0);
        case AppButtonSize.md:
          return const EdgeInsets.all(10.0);
        case AppButtonSize.sm:
          return const EdgeInsets.all(8.0);
        case AppButtonSize.xs:
          return const EdgeInsets.all(6.0);
      }
    }

    switch (size) {
      case AppButtonSize.lg:
        return const EdgeInsets.symmetric(horizontal: 16.0);
      case AppButtonSize.md:
        return const EdgeInsets.symmetric(horizontal: 14.0);
      case AppButtonSize.sm:
        return const EdgeInsets.symmetric(horizontal: 12.0);
      case AppButtonSize.xs:
        return const EdgeInsets.symmetric(horizontal: 8.0);
    }
  }

  // ── Color Helpers ──────────────────────────────────────────────────────────

  Color _getBgColor(bool isDark, AppStyle s) {
    switch (widget.variant) {
      case AppButtonVariant.primary:
        return s.brand;
      case AppButtonVariant.secondary:
        return isDark ? AppColors.surfaceDark2 : AppColors.surfaceLight;
      case AppButtonVariant.outline:
        return Colors.transparent;
      case AppButtonVariant.soft:
        return s.brandSoft;
      case AppButtonVariant.danger:
        return AppColors.rose;
      case AppButtonVariant.dangerOutline:
        return Colors.transparent;
      case AppButtonVariant.text:
        return Colors.transparent;
    }
  }

  Color _getFgColor(bool isDark, AppStyle s) {
    switch (widget.variant) {
      case AppButtonVariant.primary:
        return isDark ? const Color(0xFF042017) : Colors.white;
      case AppButtonVariant.secondary:
        return s.primary;
      case AppButtonVariant.outline:
        return s.brand;
      case AppButtonVariant.soft:
        return s.brand;
      case AppButtonVariant.danger:
        return Colors.white;
      case AppButtonVariant.dangerOutline:
        return AppColors.rose;
      case AppButtonVariant.text:
        return s.brand;
    }
  }

  Border? _getBorder(bool isDark, AppStyle s) {
    if (widget.customBorderColor != null) {
      return Border.all(color: widget.customBorderColor!);
    }

    switch (widget.variant) {
      case AppButtonVariant.secondary:
        return Border.all(color: s.border);
      case AppButtonVariant.outline:
        return Border.all(color: s.brand);
      case AppButtonVariant.dangerOutline:
        return Border.all(color: AppColors.rose.withValues(alpha: 0.5));
      default:
        return null;
    }
  }
}
