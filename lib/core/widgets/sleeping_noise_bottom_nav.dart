import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../routing/app_route.dart';
import '../theme/app_colors.dart';

/// Dock — no full-screen [BackdropFilter] (replaced with translucent fill for smooth frames).
class SleepingNoiseBottomNav extends StatelessWidget {
  const SleepingNoiseBottomNav({
    super.key,
    required this.currentPath,
    required this.onSelect,
  });

  final String currentPath;
  final void Function(AppRoute route) onSelect;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHighest.withValues(alpha: 0.72),
          border: Border(top: BorderSide(color: AppColors.ghostBorder)),
          boxShadow: [
            BoxShadow(
              color: AppColors.surfaceTint.withValues(alpha: 0.06),
              blurRadius: 40,
              spreadRadius: 0,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 12 + bottom * 0.35),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  label: 'Home',
                  icon: Icons.home_rounded,
                  selected: _is(AppRoute.home),
                  onTap: () => onSelect(AppRoute.home),
                ),
                _NavItem(
                  label: 'Mixer',
                  icon: Icons.tune_rounded,
                  selected: _is(AppRoute.mixer),
                  onTap: () => onSelect(AppRoute.mixer),
                ),
                _NavItem(
                  label: 'Library',
                  icon: Icons.library_music_rounded,
                  selected: _is(AppRoute.library),
                  onTap: () => onSelect(AppRoute.library),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _is(AppRoute route) {
    if (currentPath == route.path) return true;
    if (currentPath == '/' && route == AppRoute.home) return true;
    return false;
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.navActive : AppColors.navInactive;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: selected ? 28 : 26, color: color),
            const SizedBox(height: 4),
            Text(
              label.toUpperCase(),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.6,
                color: selected
                    ? AppColors.navActive
                    : AppColors.navInactive.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
