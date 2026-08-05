import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:velto/core/constants/app_colors.dart';
import 'package:velto/core/constants/app_sizes.dart';
import 'package:velto/core/widgets/app_widgets.dart';

class DietView extends StatelessWidget {
  const DietView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = AppStyle(isDark);

    final meals = [
      // _Meal('Breakfast', '8:00 AM', 'Avocado Toast & Egg Whites', 350, LucideIcons.sun, isDark ? AppColors.tertiarySoftDark : AppColors.tertiarySoft, AppColors.tertiary),
      // _Meal('Lunch', '1:00 PM', 'Grilled Chicken & Quinoa', 520, LucideIcons.utensils, isDark ? AppColors.primarySoftDark : AppColors.primarySoft, AppColors.primary),
      // _Meal('Dinner', '7:30 PM', 'Baked Salmon & Broccoli', 480, LucideIcons.moon, isDark ? AppColors.secondarySoftDark : AppColors.secondarySoft, AppColors.secondary),
      // _Meal('Snack', '4:00 PM', 'Almonds & Protein Shake', 290, LucideIcons.cookie, isDark ? AppColors.greenSoftDark : AppColors.greenSoft, AppColors.green),
    ];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true, snap: true, toolbarHeight: 72,
            title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Nutrition', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w500, color: s.secondary)),
              Text('Diet', style: GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.w800, color: s.primary, letterSpacing: -0.5)),
            ]),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppSizes.lg, AppSizes.sm, AppSizes.lg, 120),
            sliver: SliverList(delegate: SliverChildListDelegate([

              // Calorie Card
              AppCard(isDark: isDark, child: Row(children: [
                SizedBox(
                  width: 96, height: 96,
                  child: CustomPaint(
                    painter: _ArcPainter(progress: 1640 / 2200, color: AppColors.primary, trackColor: s.border),
                    child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text('1,640', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800, color: s.primary, letterSpacing: -0.5)),
                      Text('kcal', style: GoogleFonts.manrope(fontSize: 9, color: s.secondary)),
                    ])),
                  ),
                ),
                const SizedBox(width: AppSizes.lg),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Today\'s Calories', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w600, color: s.secondary)),
                  const SizedBox(height: 4),
                  Text('560 remaining', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800, color: s.primary, letterSpacing: -0.3)),
                  const SizedBox(height: 4),
                  Text('of 2,200 kcal', style: GoogleFonts.manrope(fontSize: 11, color: s.secondary)),
                  const SizedBox(height: AppSizes.sm),
                  Row(children: [
                    const Icon(LucideIcons.circle_check, size: 13, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text('On track', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary)),
                  ]),
                ])),
              ])),
              const SizedBox(height: AppSizes.md),

              AppSectionHeader(title: 'Macros', isDark: isDark),
              const SizedBox(height: AppSizes.sm),
              Row(children: [
                Expanded(child: _MacroCard('Protein', 110, 150, 'g', AppColors.macroProtein, isDark ? AppColors.macroProteinSoftDark : AppColors.macroProteinSoft, LucideIcons.beef, s)),
                const SizedBox(width: AppSizes.md),
                Expanded(child: _MacroCard('Carbs', 180, 220, 'g', AppColors.macroCarbs, isDark ? AppColors.macroCarbsSoftDark : AppColors.macroCarsbSoft, LucideIcons.wheat, s)),
                const SizedBox(width: AppSizes.md),
                Expanded(child: _MacroCard('Fats', 50, 70, 'g', AppColors.macroFats, isDark ? AppColors.macroFatsSoftDark : AppColors.macroFatsSoft, LucideIcons.droplet, s)),
              ]),
              const SizedBox(height: AppSizes.xl),

              // Meals
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                AppSectionHeader(title: 'Meals', isDark: isDark),
                GestureDetector(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: isDark ? AppColors.primarySoftDark : AppColors.primarySoft, borderRadius: BorderRadius.circular(8)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(LucideIcons.plus, size: 13, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text('Log meal', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
                    ]),
                  ),
                ),
              ]),
              const SizedBox(height: AppSizes.md),

              if (meals.isEmpty)
                AppEmptyState(
                  isDark: isDark,
                  icon: LucideIcons.utensils_crossed,
                  title: 'Nothing logged yet',
                  subtitle: 'Tap "Log meal" to track your\nfirst meal of the day.',
                  actionLabel: '+ Log meal',
                  onAction: () {},
                )
              else
                ...meals.map((m) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.sm),
                  child: AppCard(isDark: isDark, padding: const EdgeInsets.all(AppSizes.md), child: Row(children: [
                    Container(width: 44, height: 44, decoration: BoxDecoration(color: m.iconBg, borderRadius: BorderRadius.circular(11)), child: Icon(m.icon, size: 20, color: m.iconColor)),
                    const SizedBox(width: AppSizes.md),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Text(m.name, style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: s.primary)),
                        const SizedBox(width: 6),
                        Text('· ${m.time}', style: GoogleFonts.manrope(fontSize: 11, color: s.secondary)),
                      ]),
                      const SizedBox(height: 2),
                      Text(m.item, style: GoogleFonts.manrope(fontSize: 11, color: s.secondary)),
                    ])),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text('${m.calories}', style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w800, color: s.primary)),
                      Text('kcal', style: GoogleFonts.manrope(fontSize: 10, color: s.secondary)),
                    ]),
                  ])),
                )),
            ])),
          ),
        ],
      ),
    );
  }
}

class _Meal {
  final String name, time, item;
  final int calories;
  final IconData icon;
  final Color iconBg, iconColor;
  const _Meal(this.name, this.time, this.item, this.calories, this.icon, this.iconBg, this.iconColor);
}

class _MacroCard extends StatelessWidget {
  final String name, unit;
  final int current, goal;
  final Color color;
  final Color iconBg;
  final IconData icon;
  final AppStyle s;
  const _MacroCard(this.name, this.current, this.goal, this.unit, this.color, this.iconBg, this.icon, this.s);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSizes.md),
    decoration: BoxDecoration(color: s.surface, borderRadius: BorderRadius.circular(AppSizes.radiusLg), border: Border.all(color: s.border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 30, height: 30,
        decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 15, color: color),
      ),
      const SizedBox(height: 8),
      Text(name, style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w600, color: s.secondary)),
      const SizedBox(height: 2),
      Text('$current$unit', style: GoogleFonts.manrope(fontSize: 17, fontWeight: FontWeight.w800, color: s.primary, letterSpacing: -0.3)),
      Text('/ $goal$unit', style: GoogleFonts.manrope(fontSize: 10, color: s.tertiary)),
      const SizedBox(height: AppSizes.sm),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(value: current / goal, minHeight: 4, backgroundColor: color.withValues(alpha: 0.12), valueColor: AlwaysStoppedAnimation<Color>(color)),
      ),
    ]),
  );
}

class _ArcPainter extends CustomPainter {
  final double progress;
  final Color color, trackColor;
  const _ArcPainter({required this.progress, required this.color, required this.trackColor});
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 8;
    const sw = 7.0;
    canvas.drawCircle(c, r, Paint()..color = trackColor..style = PaintingStyle.stroke..strokeWidth = sw..strokeCap = StrokeCap.round);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), -math.pi / 2, 2 * math.pi * progress, false, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = sw..strokeCap = StrokeCap.round);
  }
  @override
  bool shouldRepaint(_ArcPainter old) => old.progress != progress;
}
