part of 'app_pages.dart';

abstract class Routes {
  Routes._();

  static const home = _Paths.home;
  static const logMeal = _Paths.logMeal;
  static const addMeal = _Paths.addMeal;
  static const addRoutine = _Paths.addRoutine;
}

abstract class _Paths {
  _Paths._();

  static const home = '/';
  static const logMeal = '/log-meal';
  static const addMeal = '/add-meal';
  static const addRoutine = '/add-routine';
}

