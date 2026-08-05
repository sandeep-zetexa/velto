import 'package:get/get.dart';
import 'package:velto/features/home/bindings/home_binding.dart';
import 'package:velto/features/home/views/home_view.dart';
import 'package:velto/features/diet/views/log_meal_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const initial = Routes.home;

  static final routes = [
    GetPage(
      name: _Paths.home,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: _Paths.logMeal,
      page: () => const LogMealView(),
    ),
  ];
}

