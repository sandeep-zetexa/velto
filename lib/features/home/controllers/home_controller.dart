import 'package:get/get.dart';
import 'package:velto/features/dashboard/controllers/dashboard_controller.dart';

class HomeController extends GetxController {
  final RxInt currentIndex = 0.obs;

  void changeTab(int index) {
    currentIndex.value = index;
    if (index == 0 && Get.isRegistered<DashboardController>()) {
      Get.find<DashboardController>().reload();
    }
  }
}
