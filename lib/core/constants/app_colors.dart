import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Brand ────────────────────────────────────────────────────────────────
  // ── Brand ────────────────────────────────────────────────────────────────
  static const Color primary     = Color(0xFF064E3B); // Forest Green (Light mode)
  static const Color primaryDark = Color(0xFF10B981); // Emerald / Mint (Dark mode)
  static const Color secondary   = Color(0xFF475569); // Slate Blue-Gray
  static const Color tertiary    = Color(0xFF6B342D); // Terracotta/Burgundy

  /// Adaptive brand color for current theme mode.
  static Color brand(bool isDark) => isDark ? primaryDark : primary;

  /// Adaptive soft brand tint background for current theme mode.
  static Color brandSoft(bool isDark) => isDark ? primarySoftDark : primarySoft;

  // ── Tints (light) ────────────────────────────────────────────────────────
  static const Color primarySoft   = Color(0xFFECFDF5);
  static const Color secondarySoft = Color(0xFFF1F5F9);
  static const Color tertiarySoft  = Color(0xFFFDF0EF);

  // ── Tints (dark - luminous translucent) ───────────────────────────────────
  static const Color primarySoftDark   = Color(0x2610B981); // 15% emerald
  static const Color secondarySoftDark = Color(0x1F94A3B8); // 12% slate
  static const Color tertiarySoftDark  = Color(0x24F59E0B); // 14% amber

  // ── Semantic – stat cards & icons ────────────────────────────────────────
  static const Color green         = Color(0xFF10B981);
  static const Color greenSoft     = Color(0xFFD1FAE5);
  static const Color greenSoftDark = Color(0x2610B981);

  static const Color amber         = Color(0xFFF59E0B);
  static const Color amberSoft     = Color(0xFFFEF3C7);
  static const Color amberSoftDark = Color(0x26F59E0B);

  static const Color rose          = Color(0xFFF43F5E);
  static const Color roseSoft      = Color(0xFFFFE4E6);
  static const Color roseSoftDark  = Color(0x26F43F5E);

  static const Color blue          = Color(0xFF3B82F6);
  static const Color blueSoft      = Color(0xFFDBEAFE);
  static const Color blueSoftDark  = Color(0x263B82F6);

  // ── Macro nutrients ──────────────────────────────────────────────────────
  // Protein – bold cobalt blue
  static const Color macroProtein         = Color(0xFF3B82F6);
  static const Color macroProteinSoft     = Color(0xFFDBEAFE);
  static const Color macroProteinSoftDark = Color(0x263B82F6);

  // Carbs – vibrant orange
  static const Color macroCarbs         = Color(0xFFF97316);
  static const Color macroCarsbSoft     = Color(0xFFFFEDD5);
  static const Color macroCarbsSoft     = macroCarsbSoft;
  static const Color macroCarbsSoftDark = Color(0x26F97316);

  // Fats – dark golden yellow
  static const Color macroFats         = Color(0xFFEAB308);
  static const Color macroFatsSoft     = Color(0xFFFEF9C3);
  static const Color macroFatsSoftDark = Color(0x26EAB308);

  // ── Neutral – Light Theme ─────────────────────────────────────────────────
  static const Color bgLight            = Color(0xFFF8FAFC);
  static const Color surfaceLight       = Color(0xFFFFFFFF);
  static const Color borderLight        = Color(0xFFE2E8F0);
  static const Color textPrimaryLight   = Color(0xFF0D1B15);
  static const Color textSecondaryLight = Color(0xFF475569);
  static const Color textTertiaryLight  = Color(0xFF94A3B8);

  // ── Neutral – Dark Theme (Obsidian & Crisp Charcoal) ─────────────────────
  static const Color bgDark             = Color(0xFF0C0E12); // True obsidian dark
  static const Color surfaceDark        = Color(0xFF16181F); // Clean elevated dark card
  static const Color surfaceDark2       = Color(0xFF1F222B); // Inner elevated well
  static const Color borderDark         = Color(0xFF282C37); // Subtle border
  static const Color textPrimaryDark    = Color(0xFFF8FAFC); // Crisp off-white
  static const Color textSecondaryDark  = Color(0xFF94A3B8); // Slate silver
  static const Color textTertiaryDark   = Color(0xFF64748B); // Muted slate
}
