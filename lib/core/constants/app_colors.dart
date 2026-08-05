import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Brand ────────────────────────────────────────────────────────────────
  static const Color primary   = Color(0xFF064E3B); // Forest Green
  static const Color secondary = Color(0xFF475569); // Slate Blue-Gray
  static const Color tertiary  = Color(0xFF6B342D); // Terracotta/Burgundy

  // ── Tints (light) ────────────────────────────────────────────────────────
  static const Color primarySoft   = Color(0xFFECFDF5);
  static const Color secondarySoft = Color(0xFFF1F5F9);
  static const Color tertiarySoft  = Color(0xFFFDF0EF);

  // ── Tints (dark) ─────────────────────────────────────────────────────────
  static const Color primarySoftDark   = Color(0xFF022C22);
  static const Color secondarySoftDark = Color(0xFF1E293B);
  static const Color tertiarySoftDark  = Color(0xFF3B1009);

  // ── Semantic – stat cards & icons ────────────────────────────────────────
  static const Color green     = Color(0xFF10B981);
  static const Color greenSoft = Color(0xFFD1FAE5);
  static const Color greenSoftDark = Color(0xFF064E3B);

  static const Color amber     = Color(0xFFF59E0B);
  static const Color amberSoft = Color(0xFFFEF3C7);
  static const Color amberSoftDark = Color(0xFF2D220A);

  static const Color rose      = Color(0xFFF43F5E);
  static const Color roseSoft  = Color(0xFFFFE4E6);
  static const Color roseSoftDark = Color(0xFF2D0A10);

  static const Color blue      = Color(0xFF3B82F6);
  static const Color blueSoft  = Color(0xFFDBEAFE);
  static const Color blueSoftDark = Color(0xFF0A1A2D);

  // ── Macro nutrients ──────────────────────────────────────────────────────
  // Protein – bold cobalt blue (strength, muscle, cold)
  static const Color macroProtein         = Color(0xFF2563EB);
  static const Color macroProteinSoft     = Color(0xFFDBEAFE);
  static const Color macroProteinSoftDark = Color(0xFF0C1E3D);

  // Carbs – vibrant orange (energy, warmth, quick fuel)
  static const Color macroCarbs         = Color(0xFFF97316);
  static const Color macroCarsbSoft     = Color(0xFFFFEDD5);
  static const Color macroCarbsSoftDark = Color(0xFF3A1700);

  // Fats – dark golden yellow (oils, avocado, butter — rich and warm)
  static const Color macroFats         = Color(0xFFCA8A04);
  static const Color macroFatsSoft     = Color(0xFFFEF9C3);
  static const Color macroFatsSoftDark = Color(0xFF2D2000);

  // ── Neutral – Light Theme ─────────────────────────────────────────────────
  static const Color bgLight          = Color(0xFFF8FAFC);
  static const Color surfaceLight     = Color(0xFFFFFFFF);
  static const Color borderLight      = Color(0xFFE2E8F0);
  static const Color textPrimaryLight   = Color(0xFF0D1B15);
  static const Color textSecondaryLight = Color(0xFF475569); // = secondary
  static const Color textTertiaryLight  = Color(0xFF94A3B8);

  // ── Neutral – Dark Theme ──────────────────────────────────────────────────
  static const Color bgDark           = Color(0xFF080E0B);
  static const Color surfaceDark      = Color(0xFF0F1812);
  static const Color surfaceDark2     = Color(0xFF172118);
  static const Color borderDark       = Color(0xFF1E2E26);
  static const Color textPrimaryDark    = Color(0xFFF1F8F5);
  static const Color textSecondaryDark  = Color(0xFF94A3B8);
  static const Color textTertiaryDark   = Color(0xFF4B6458);
}
