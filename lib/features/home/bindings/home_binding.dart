import 'package:get/get.dart';
import 'package:velto/features/dashboard/controllers/dashboard_controller.dart';
import 'package:velto/features/diet/controllers/diet_controller.dart';
import 'package:velto/features/home/controllers/home_controller.dart';
import 'package:velto/features/workout/controllers/workout_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeController>(() => HomeController());
    Get.lazyPut<DashboardController>(() => DashboardController());
    Get.lazyPut<WorkoutController>(() => WorkoutController());
    Get.lazyPut<DietController>(() => DietController());
  }
}
