import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:velto/core/widgets/app_bottom_nav_bar.dart';
import 'package:velto/features/home/controllers/home_controller.dart';
import 'package:velto/features/dashboard/views/dashboard_view.dart';
import 'package:velto/features/workout/views/workout_view.dart';
import 'package:velto/features/diet/views/diet_view.dart';
import 'package:velto/features/profile/views/profile_view.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = const [
      DashboardView(),
      WorkoutView(),
      DietView(),
      ProfileView(),
    ];

    return Obx(
      () => Scaffold(
        extendBody: true,
        body: IndexedStack(
          index: controller.currentIndex.value,
          children: pages,
        ),
        bottomNavigationBar: AppBottomNavBar(
          currentIndex: controller.currentIndex.value,
          onTap: controller.changeTab,
        ),
      ),
    );
  }
}
