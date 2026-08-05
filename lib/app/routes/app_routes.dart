part of 'app_pages.dart';

abstract class Routes {
  Routes._();

  static const home = _Paths.home;
  static const logMeal = _Paths.logMeal;
}

abstract class _Paths {
  _Paths._();

  static const home = '/';
  static const logMeal = '/log-meal';
}

