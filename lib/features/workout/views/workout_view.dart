import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:velto/core/constants/app_colors.dart';
import 'package:velto/core/constants/app_sizes.dart';
import 'package:velto/core/widgets/app_widgets.dart';

class WorkoutView extends StatelessWidget {
  const WorkoutView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = AppStyle(isDark);

    final routines = [
      _Routine('Leg Day Strength', '45 min', 'Intermediate', '8 exercises', Iconsax.weight,
          isDark ? AppColors.primarySoftDark : AppColors.primarySoft, AppColors.primary),
      _Routine('Core Conditioning', '20 min', 'Beginner', '5 exercises', Iconsax.chart_21,
          isDark ? AppColors.secondarySoftDark : AppColors.secondarySoft, AppColors.secondary),
      _Routine('HIIT Cardio Burn', '35 min', 'Advanced', '10 exercises', Iconsax.flash_circle,
          isDark ? AppColors.tertiarySoftDark : AppColors.tertiarySoft, AppColors.tertiary),
      _Routine('Recovery & Stretch', '15 min', 'Easy', '6 exercises', Iconsax.health,
          isDark ? AppColors.greenSoftDark : AppColors.greenSoft, AppColors.green),
    ];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true, snap: true, toolbarHeight: 72,
            title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Training', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w500, color: s.secondary)),
              Text('Workout', style: GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.w800, color: s.primary, letterSpacing: -0.4)),
            ]),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppSizes.lg, AppSizes.sm, AppSizes.lg, 120),
            sliver: SliverList(delegate: SliverChildListDelegate([

              // Weekly Strip
              AppCard(isDark: isDark, padding: const EdgeInsets.all(AppSizes.md), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('This Week', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: s.primary)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(color: isDark ? AppColors.primarySoftDark : AppColors.primarySoft, borderRadius: BorderRadius.circular(20)),
                    child: Text('3 of 5 done', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  ),
                ]),
                const SizedBox(height: AppSizes.md),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  _dayCell('M', 'Mon', true, false, isDark, s),
                  _dayCell('T', 'Tue', true, false, isDark, s),
                  _dayCell('W', 'Wed', true, false, isDark, s),
                  _dayCell('T', 'Thu', false, true, isDark, s),
                  _dayCell('F', 'Fri', false, false, isDark, s),
                  _dayCell('S', 'Sat', false, false, isDark, s),
                  _dayCell('S', 'Sun', false, false, isDark, s),
                ]),
              ])),
              const SizedBox(height: AppSizes.xl),

              // Featured Card
              AppCard(isDark: isDark, child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(width: 7, height: 7, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text("Today's Plan", style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary)),
                  ]),
                  const SizedBox(height: 6),
                  Text('Full Body Strength', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800, color: s.primary, letterSpacing: -0.3)),
                  const SizedBox(height: AppSizes.sm),
                  Row(children: [
                    _chip('55 min', isDark, s),
                    const SizedBox(width: AppSizes.sm),
                    _chip('420 kcal', isDark, s),
                  ]),
                ])),
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(color: isDark ? AppColors.primarySoftDark : AppColors.primarySoft, shape: BoxShape.circle),
                  child: const Icon(Iconsax.play_circle, color: AppColors.primary, size: 26),
                ),
              ])),
              const SizedBox(height: AppSizes.xl),

              AppSectionHeader(title: 'All Routines', action: 'See all', isDark: isDark),
              const SizedBox(height: AppSizes.md),

              ...routines.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.sm),
                child: AppCard(isDark: isDark, padding: const EdgeInsets.all(AppSizes.md), child: Row(children: [
                  Container(width: 44, height: 44, decoration: BoxDecoration(color: r.iconBg, borderRadius: BorderRadius.circular(11)), child: Icon(r.icon, size: 20, color: r.iconColor)),
                  const SizedBox(width: AppSizes.md),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(r.name, style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: s.primary)),
                    const SizedBox(height: 5),
                    Wrap(spacing: 5, children: [_tag(r.duration, isDark, s), _tag(r.exercises, isDark, s), _tag(r.level, isDark, s)]),
                  ])),
                  Icon(Iconsax.arrow_right_3, size: 15, color: s.tertiary),
                ])),
              )),
            ])),
          ),
        ],
      ),
    );
  }
}

class _Routine {
  final String name, duration, level, exercises;
  final IconData icon;
  final Color iconBg, iconColor;
  const _Routine(this.name, this.duration, this.level, this.exercises, this.icon, this.iconBg, this.iconColor);
}

Widget _dayCell(String letter, String label, bool done, bool isToday, bool isDark, AppStyle s) =>
    Column(children: [
      Text(label, style: GoogleFonts.manrope(fontSize: 9, fontWeight: FontWeight.w600, color: s.secondary)),
      const SizedBox(height: 6),
      AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 32, height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: done ? AppColors.primary : (isToday ? AppColors.primarySoft : Colors.transparent),
          border: done ? null : Border.all(color: isToday ? AppColors.primary : s.border, width: 1.5),
        ),
        alignment: Alignment.center,
        child: done
            ? const Icon(Iconsax.tick_circle, color: Colors.white, size: 14)
            : Text(letter, style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700,
                color: isToday ? AppColors.primary : s.secondary)),
      ),
    ]);

Widget _chip(String label, bool isDark, AppStyle s) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
  decoration: BoxDecoration(
    color: isDark ? AppColors.surfaceDark2 : AppColors.bgLight,
    borderRadius: BorderRadius.circular(6),
    border: Border.all(color: s.border),
  ),
  child: Text(label, style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w600, color: s.secondary)),
);

Widget _tag(String label, bool isDark, AppStyle s) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
  decoration: BoxDecoration(color: isDark ? AppColors.surfaceDark2 : AppColors.bgLight, borderRadius: BorderRadius.circular(5)),
  child: Text(label, style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w600, color: s.secondary)),
);
