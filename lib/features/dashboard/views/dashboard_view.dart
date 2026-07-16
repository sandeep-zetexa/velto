import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:velto/core/constants/app_colors.dart';
import 'package:velto/core/constants/app_sizes.dart';
import 'package:velto/core/widgets/app_widgets.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = AppStyle(isDark);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true, snap: true, toolbarHeight: 72,
            title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Good morning', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w500, color: s.secondary)),
              Text('Alex 👋', style: GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.w800, color: s.primary, letterSpacing: -0.4)),
            ]),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: AppSizes.md),
                child: AppIconBtn(icon: LucideIcons.bell, isDark: isDark),
              ),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppSizes.lg, AppSizes.sm, AppSizes.lg, 120),
            sliver: SliverList(delegate: SliverChildListDelegate([

              // ── Progress Banner ───────────────────────────────────────
              AppCard(isDark: isDark, child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Week 3 · Phase 1', style: GoogleFonts.manrope(
                      fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                  const SizedBox(height: 4),
                  Text('Keep the momentum\ngoing!', style: GoogleFonts.manrope(
                      fontSize: 18, fontWeight: FontWeight.w800, color: s.primary, height: 1.25, letterSpacing: -0.3)),
                  const SizedBox(height: AppSizes.md),
                  Row(children: [
                    _miniStat('12', 'Workouts', s),
                    const SizedBox(width: AppSizes.lg),
                    _miniStat('−2.4 kg', 'Lost', s),
                  ]),
                ])),
                const SizedBox(width: AppSizes.md),
                SizedBox(
                  width: 80, height: 80,
                  child: CustomPaint(
                    painter: _RingPainter(progress: 0.67, color: AppColors.primary, trackColor: isDark ? AppColors.borderDark : AppColors.borderLight),
                    child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text('67%', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800, color: s.primary)),
                      Text('Goal', style: GoogleFonts.manrope(fontSize: 9, fontWeight: FontWeight.w500, color: s.secondary)),
                    ])),
                  ),
                ),
              ])),
              const SizedBox(height: AppSizes.xl),

              // ── Stat Cards ────────────────────────────────────────────
              AppSectionHeader(title: "Today's Stats", isDark: isDark),
              const SizedBox(height: AppSizes.md),
              Row(children: [
                Expanded(child: _StatCard(icon: LucideIcons.flame, iconBg: isDark ? AppColors.tertiarySoftDark : AppColors.tertiarySoft, iconColor: AppColors.tertiary, value: '480', unit: 'kcal', label: 'Burned', s: s)),
                const SizedBox(width: AppSizes.md),
                Expanded(child: _StatCard(icon: LucideIcons.footprints, iconBg: isDark ? AppColors.secondarySoftDark : AppColors.secondarySoft, iconColor: AppColors.secondary, value: '7.4k', unit: 'steps', label: 'Steps', s: s)),
              ]),
              const SizedBox(height: AppSizes.md),
              Row(children: [
                Expanded(child: _StatCard(icon: LucideIcons.clock, iconBg: isDark ? AppColors.primarySoftDark : AppColors.primarySoft, iconColor: AppColors.primary, value: '42', unit: 'min', label: 'Active', s: s)),
                const SizedBox(width: AppSizes.md),
                Expanded(child: _StatCard(icon: LucideIcons.droplet, iconBg: isDark ? AppColors.blueSoftDark : AppColors.blueSoft, iconColor: AppColors.blue, value: '1.2', unit: 'L', label: 'Hydration', s: s)),
              ]),
              const SizedBox(height: AppSizes.xl),

              // ── Activity ──────────────────────────────────────────────
              AppSectionHeader(title: 'Recent Activity', action: 'See all', isDark: isDark),
              const SizedBox(height: AppSizes.md),
              AppActivityRow(icon: LucideIcons.dumbbell, iconBg: isDark ? AppColors.primarySoftDark : AppColors.primarySoft, iconColor: AppColors.primary, title: 'Leg Day Strength', sub: 'Today · 45 min', isDark: isDark),
              AppActivityRow(icon: LucideIcons.activity, iconBg: isDark ? AppColors.secondarySoftDark : AppColors.secondarySoft, iconColor: AppColors.secondary, title: 'Morning Run', sub: 'Yesterday · 32 min', isDark: isDark),
              AppActivityRow(icon: LucideIcons.apple, iconBg: isDark ? AppColors.greenSoftDark : AppColors.greenSoft, iconColor: AppColors.green, title: 'Nutrition Goal Met', sub: '2 days ago', isDark: isDark),
            ])),
          ),
        ],
      ),
    );
  }
}

Widget _miniStat(String value, String label, AppStyle s) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text(value, style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800, color: s.primary)),
    Text(label, style: GoogleFonts.manrope(fontSize: 11, color: s.secondary)),
  ],
);

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg, iconColor;
  final String value, unit, label;
  final AppStyle s;
  const _StatCard({required this.icon, required this.iconBg, required this.iconColor, required this.value, required this.unit, required this.label, required this.s});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSizes.md),
    decoration: BoxDecoration(color: s.surface, borderRadius: BorderRadius.circular(AppSizes.radiusLg), border: Border.all(color: s.border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 34, height: 34, decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(9)), child: Icon(icon, size: 16, color: iconColor)),
      const SizedBox(height: AppSizes.sm),
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text(value, style: GoogleFonts.manrope(fontSize: 22, fontWeight: FontWeight.w800, color: s.primary, letterSpacing: -0.4)),
        const SizedBox(width: 3),
        Padding(padding: const EdgeInsets.only(bottom: 3),
          child: Text(unit, style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w500, color: s.secondary))),
      ]),
      Text(label, style: GoogleFonts.manrope(fontSize: 11, color: s.secondary)),
    ]),
  );
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color, trackColor;
  const _RingPainter({required this.progress, required this.color, required this.trackColor});
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 7;
    const sw = 6.0;
    canvas.drawCircle(c, r, Paint()..color = trackColor..style = PaintingStyle.stroke..strokeWidth = sw..strokeCap = StrokeCap.round);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), -math.pi / 2, 2 * math.pi * progress, false, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = sw..strokeCap = StrokeCap.round);
  }
  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}
