import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:velto/core/constants/app_colors.dart';

class AppTheme {
  AppTheme._();

  static TextTheme _text(Color primary, Color secondary, Color tertiary) {
    final base = GoogleFonts.manropeTextTheme();
    return base.copyWith(
      displayLarge:  base.displayLarge?.copyWith(color: primary, fontWeight: FontWeight.w800),
      displayMedium: base.displayMedium?.copyWith(color: primary, fontWeight: FontWeight.w800),
      headlineLarge: base.headlineLarge?.copyWith(color: primary, fontWeight: FontWeight.w700),
      headlineMedium:base.headlineMedium?.copyWith(color: primary, fontWeight: FontWeight.w700),
      headlineSmall: base.headlineSmall?.copyWith(color: primary, fontWeight: FontWeight.w700),
      titleLarge:    base.titleLarge?.copyWith(color: primary, fontWeight: FontWeight.w700),
      titleMedium:   base.titleMedium?.copyWith(color: primary, fontWeight: FontWeight.w600),
      titleSmall:    base.titleSmall?.copyWith(color: primary, fontWeight: FontWeight.w600),
      bodyLarge:     base.bodyLarge?.copyWith(color: primary),
      bodyMedium:    base.bodyMedium?.copyWith(color: secondary),
      bodySmall:     base.bodySmall?.copyWith(color: tertiary),
      labelLarge:    base.labelLarge?.copyWith(color: primary, fontWeight: FontWeight.w600),
      labelMedium:   base.labelMedium?.copyWith(color: secondary),
      labelSmall:    base.labelSmall?.copyWith(color: tertiary),
    );
  }

  static TextStyle _appBarTitle(Color color) => GoogleFonts.manrope(
    color: color,
    fontSize: 22,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.3,
  );

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      tertiary: AppColors.tertiary,
      surface: AppColors.surfaceLight,
      error: AppColors.rose,
    ),
    scaffoldBackgroundColor: AppColors.bgLight,
    textTheme: _text(
      AppColors.textPrimaryLight,
      AppColors.textSecondaryLight,
      AppColors.textTertiaryLight,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      iconTheme: const IconThemeData(color: AppColors.textPrimaryLight),
      titleTextStyle: _appBarTitle(AppColors.textPrimaryLight),
    ),
  );

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primaryDark,
      onPrimary: Color(0xFF042017),
      secondary: AppColors.secondary,
      tertiary: AppColors.tertiary,
      surface: AppColors.surfaceDark,
      error: AppColors.rose,
    ),
    scaffoldBackgroundColor: AppColors.bgDark,
    textTheme: _text(
      AppColors.textPrimaryDark,
      AppColors.textSecondaryDark,
      AppColors.textTertiaryDark,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      iconTheme: const IconThemeData(color: AppColors.textPrimaryDark),
      titleTextStyle: _appBarTitle(AppColors.textPrimaryDark),
    ),
  );
}
