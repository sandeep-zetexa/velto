import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:velto/core/constants/app_colors.dart';
import 'package:velto/core/constants/app_sizes.dart';
import 'package:velto/core/widgets/app_widgets.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

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
              Text('Account', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w500, color: s.secondary)),
              Text('Profile', style: GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.w800, color: s.primary, letterSpacing: -0.5)),
            ]),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppSizes.lg, AppSizes.sm, AppSizes.lg, 120),
            sliver: SliverList(delegate: SliverChildListDelegate([

              // Avatar
              AppCard(isDark: isDark, child: Row(children: [
                Container(
                  width: 58, height: 58,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: isDark ? AppColors.primarySoftDark : AppColors.primarySoft),
                  child: const Icon(LucideIcons.user, color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Alex Mercer', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800, color: s.primary, letterSpacing: -0.3)),
                  const SizedBox(height: 2),
                  Text('alex.mercer@velto.io', style: GoogleFonts.manrope(fontSize: 12, color: s.secondary)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: isDark ? AppColors.primarySoftDark : AppColors.primarySoft, borderRadius: BorderRadius.circular(6)),
                    child: Text('Pro Member', style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  ),
                ])),
                Icon(LucideIcons.pen, size: 17, color: s.tertiary),
              ])),
              const SizedBox(height: AppSizes.lg),

              // Stats
              Row(children: [
                Expanded(child: _StatBand('24', 'Workouts', LucideIcons.activity, s)),
                const SizedBox(width: AppSizes.md),
                Expanded(child: _StatBand('−4.2 kg', 'Lost', LucideIcons.trending_down, s)),
                const SizedBox(width: AppSizes.md),
                Expanded(child: _StatBand('14', 'Streak', LucideIcons.zap, s)),
              ]),
              const SizedBox(height: AppSizes.xl),

              _Label('Settings', s),
              const SizedBox(height: AppSizes.sm),
              _Tile(icon: LucideIcons.user, iconBg: isDark ? AppColors.primarySoftDark : AppColors.primarySoft, iconColor: AppColors.primary, title: 'Account Information', isDark: isDark, s: s, onTap: () {}),
              _Tile(icon: LucideIcons.bell, iconBg: isDark ? AppColors.secondarySoftDark : AppColors.secondarySoft, iconColor: AppColors.secondary, title: 'Notifications', isDark: isDark, s: s, onTap: () {}),
              _Tile(
                icon: isDark ? LucideIcons.sun : LucideIcons.moon,
                iconBg: isDark ? AppColors.tertiarySoftDark : AppColors.tertiarySoft,
                iconColor: isDark ? AppColors.tertiary : AppColors.tertiary,
                title: isDark ? 'Light Mode' : 'Dark Mode',
                isDark: isDark, s: s,
                onTap: () => Get.changeThemeMode(isDark ? ThemeMode.light : ThemeMode.dark),
                trailing: Switch(
                  value: isDark,
                  onChanged: (v) => Get.changeThemeMode(v ? ThemeMode.dark : ThemeMode.light),
                  activeThumbColor: Colors.white,
                  activeTrackColor: AppColors.primary,
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: s.border,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(height: AppSizes.xl),

              _Label('Support', s),
              const SizedBox(height: AppSizes.sm),
              _Tile(icon: LucideIcons.circle_question_mark, iconBg: isDark ? AppColors.greenSoftDark : AppColors.greenSoft, iconColor: AppColors.green, title: 'Help Center', isDark: isDark, s: s, onTap: () {}),
              _Tile(icon: LucideIcons.shield_check, iconBg: isDark ? AppColors.greenSoftDark : AppColors.greenSoft, iconColor: AppColors.green, title: 'Privacy Policy', isDark: isDark, s: s, onTap: () {}),
              const SizedBox(height: AppSizes.xl),

              SizedBox(
                width: double.infinity, height: AppSizes.buttonHeight,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.rose,
                    side: BorderSide(color: AppColors.rose.withValues(alpha: 0.35)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
                  ),
                  onPressed: () {},
                  icon: const Icon(LucideIcons.log_out, size: 17),
                  label: Text('Log Out', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700)),
                ),
              ),
            ])),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  final AppStyle s;
  const _Label(this.text, this.s);
  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(),
      style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.3, color: s.secondary));
}

class _StatBand extends StatelessWidget {
  final String value, label;
  final IconData icon;
  final AppStyle s;
  const _StatBand(this.value, this.label, this.icon, this.s);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: AppSizes.md, horizontal: AppSizes.sm),
    decoration: BoxDecoration(color: s.surface, borderRadius: BorderRadius.circular(AppSizes.radiusLg), border: Border.all(color: s.border)),
    child: Column(children: [
      Icon(icon, size: 18, color: AppColors.primary),
      const SizedBox(height: 5),
      Text(value, style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w800, color: s.primary, letterSpacing: -0.2)),
      Text(label, style: GoogleFonts.manrope(fontSize: 10, color: s.secondary)),
    ]),
  );
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final Color iconBg, iconColor;
  final String title;
  final bool isDark;
  final AppStyle s;
  final Widget? trailing;
  final VoidCallback onTap;
  const _Tile({required this.icon, required this.iconBg, required this.iconColor, required this.title, required this.isDark, required this.s, this.trailing, required this.onTap});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSizes.sm),
    child: Material(
      color: s.surface,
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(AppSizes.md),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppSizes.radiusLg), border: Border.all(color: s.border)),
          child: Row(children: [
            Container(width: 36, height: 36, decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(9)), child: Icon(icon, size: 17, color: iconColor)),
            const SizedBox(width: AppSizes.md),
            Expanded(child: Text(title, style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: s.primary))),
            trailing ?? Icon(LucideIcons.chevron_right, size: 15, color: s.tertiary),
          ]),
        ),
      ),
    ),
  );
}
