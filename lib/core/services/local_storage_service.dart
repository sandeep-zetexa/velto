import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local persistence service managing device storage for routines, meals,
/// and date-keyed daily workout/diet logs using minimal storage footprints.
/// Includes an in-memory fallback for test and headless environments.
class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  SharedPreferences? _prefs;
  final Map<String, String> _memoryStore = {};

  Future<SharedPreferences?> get prefs async {
    if (_prefs != null) return _prefs;
    try {
      if (WidgetsBinding.instance.runtimeType.toString().contains('Test')) {
        return null;
      }
      _prefs = await SharedPreferences.getInstance();
      return _prefs;
    } catch (_) {
      // In unit test or environment without native plugins, use in-memory store
      return null;
    }
  }

  // ── Keys ──────────────────────────────────────────────────────────────────
  static const String _keyActiveRoutineId = 'velto_active_routine_id';
  static const String _keyCustomRoutines = 'velto_custom_routines_minimal';
  static const String _keyWorkoutDailyLogs = 'velto_workout_daily_logs';
  static const String _keyCustomMeals = 'velto_custom_meals_minimal';
  static const String _keyDietDailyLogs = 'velto_diet_daily_logs';

  /// Helper to convert DateTime to ISO date key: "yyyy-MM-dd"
  static String formatDateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  // ── Workout Routines (Minimal Storage) ────────────────────────────────────

  Future<String?> getActiveRoutineId() async {
    try {
      final p = await prefs;
      if (p != null) return p.getString(_keyActiveRoutineId);
    } catch (_) {}
    return _memoryStore[_keyActiveRoutineId];
  }

  Future<void> setActiveRoutineId(String routineId) async {
    _memoryStore[_keyActiveRoutineId] = routineId;
    try {
      final p = await prefs;
      if (p != null) await p.setString(_keyActiveRoutineId, routineId);
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> getCustomRoutinesMinimal() async {
    String? jsonStr;
    try {
      final p = await prefs;
      if (p != null) jsonStr = p.getString(_keyCustomRoutines);
    } catch (_) {}
    jsonStr ??= _memoryStore[_keyCustomRoutines];

    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final list = jsonDecode(jsonStr) as List<dynamic>;
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveCustomRoutinesMinimal(List<Map<String, dynamic>> routines) async {
    final encoded = jsonEncode(routines);
    _memoryStore[_keyCustomRoutines] = encoded;
    try {
      final p = await prefs;
      if (p != null) await p.setString(_keyCustomRoutines, encoded);
    } catch (_) {}
  }

  // ── Daily Workout Progress Logs (Date-Keyed) ──────────────────────────────

  /// Get daily workout log for a specific date (e.g. "2026-10-28")
  Future<Map<String, dynamic>?> getWorkoutDailyLog(String dateKey) async {
    final allLogs = await getAllWorkoutDailyLogs();
    return allLogs[dateKey];
  }

  Future<Map<String, Map<String, dynamic>>> getAllWorkoutDailyLogs() async {
    String? jsonStr;
    try {
      final p = await prefs;
      if (p != null) jsonStr = p.getString(_keyWorkoutDailyLogs);
    } catch (_) {}
    jsonStr ??= _memoryStore[_keyWorkoutDailyLogs];

    if (jsonStr == null || jsonStr.isEmpty) return {};
    try {
      final raw = jsonDecode(jsonStr) as Map<String, dynamic>;
      return raw.map((k, v) => MapEntry(k, Map<String, dynamic>.from(v as Map)));
    } catch (_) {
      return {};
    }
  }

  Future<void> saveWorkoutDailyLog(String dateKey, Map<String, dynamic> log) async {
    final all = await getAllWorkoutDailyLogs();
    all[dateKey] = log;
    final encoded = jsonEncode(all);
    _memoryStore[_keyWorkoutDailyLogs] = encoded;
    try {
      final p = await prefs;
      if (p != null) await p.setString(_keyWorkoutDailyLogs, encoded);
    } catch (_) {}
  }

  // ── Custom Saved Meals (Minimal Storage) ──────────────────────────────────

  Future<List<Map<String, dynamic>>> getCustomSavedMealsMinimal() async {
    String? jsonStr;
    try {
      final p = await prefs;
      if (p != null) jsonStr = p.getString(_keyCustomMeals);
    } catch (_) {}
    jsonStr ??= _memoryStore[_keyCustomMeals];

    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final list = jsonDecode(jsonStr) as List<dynamic>;
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveCustomSavedMealsMinimal(List<Map<String, dynamic>> meals) async {
    final encoded = jsonEncode(meals);
    _memoryStore[_keyCustomMeals] = encoded;
    try {
      final p = await prefs;
      if (p != null) await p.setString(_keyCustomMeals, encoded);
    } catch (_) {}
  }

  // ── Daily Diet Logs (Date-Keyed) ──────────────────────────────────────────

  Future<Map<String, dynamic>?> getDietDailyLog(String dateKey) async {
    final all = await getAllDietDailyLogs();
    return all[dateKey];
  }

  Future<Map<String, Map<String, dynamic>>> getAllDietDailyLogs() async {
    String? jsonStr;
    try {
      final p = await prefs;
      if (p != null) jsonStr = p.getString(_keyDietDailyLogs);
    } catch (_) {}
    jsonStr ??= _memoryStore[_keyDietDailyLogs];

    if (jsonStr == null || jsonStr.isEmpty) return {};
    try {
      final raw = jsonDecode(jsonStr) as Map<String, dynamic>;
      return raw.map((k, v) => MapEntry(k, Map<String, dynamic>.from(v as Map)));
    } catch (_) {
      return {};
    }
  }

  Future<void> saveDietDailyLog(String dateKey, Map<String, dynamic> log) async {
    final all = await getAllDietDailyLogs();
    all[dateKey] = log;
    final encoded = jsonEncode(all);
    _memoryStore[_keyDietDailyLogs] = encoded;
    try {
      final p = await prefs;
      if (p != null) await p.setString(_keyDietDailyLogs, encoded);
    } catch (_) {}
  }

  /// Clears stored test data if needed
  Future<void> clearAll() async {
    _memoryStore.clear();
    try {
      final p = await prefs;
      if (p != null) await p.clear();
    } catch (_) {}
  }
}
