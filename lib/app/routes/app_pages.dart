import 'package:get/get.dart';
import 'package:velto/features/home/bindings/home_binding.dart';
import 'package:velto/features/home/views/home_view.dart';
import 'package:velto/features/diet/views/log_meal_view.dart';
import 'package:velto/features/diet/views/add_meal_view.dart';
import 'package:velto/features/workout/views/add_routine_view.dart';

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
    GetPage(
      name: _Paths.addMeal,
      page: () => const AddMealView(),
    ),
    GetPage(
      name: _Paths.addRoutine,
      page: () => const AddRoutineView(),
    ),
  ];
}

