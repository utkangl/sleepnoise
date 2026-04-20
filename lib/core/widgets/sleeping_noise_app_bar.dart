import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../features/player/application/playback_visibility.dart';
import '../legal/open_legal_url.dart';
import '../theme/app_colors.dart';

/// Glass-style header: light blur + very low-opacity fill so scrolled content shows through.
class SleepingNoiseAppBar extends ConsumerWidget {
  const SleepingNoiseAppBar({super.key});

  /// Header height (excluding system top inset).
  static const double height = 64;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Mini player aktifse alt taraf zaten dolu; bottom sheet'i o yüzden
    // yukarı kaydırıyoruz ki "playing card" ile çakışmasın.
    final hasPlayback = ref.watch(anyPlaybackActiveProvider);
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.18),
            border: Border(
              bottom: BorderSide(
                color: AppColors.ghostBorder.withValues(alpha: 0.4),
              ),
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 48),
              Expanded(
                child: Center(
                  child: Text(
                    'SleepingNoise',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                      color: AppColors.onSurface,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.45),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Menü',
                onPressed: () =>
                    _showAppBarMenu(context, hasPlayback: hasPlayback),
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: AppColors.onSurface.withValues(alpha: 0.92),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// PopupMenu yerine alttan açılan modal: hem mobil için ergonomik, hem
/// uygulamanın glass-stiline uyan bir yerleşim sunar.
Future<void> _showAppBarMenu(
  BuildContext context, {
  required bool hasPlayback,
}) async {
  // Mini player varken sheet'i mini player + biraz boşluk kadar yukarı al;
  // yoksa standart 16 px alt boşluk yeterli.
  final extraBottom = hasPlayback ? 110.0 : 0.0;
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    isScrollControlled: true,
    builder: (sheetContext) {
      return SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + extraBottom),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.ghostBorder.withValues(alpha: 0.4),
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SheetTile(
                      icon: Icons.shield_outlined,
                      label: 'Gizlilik politikası',
                      onTap: () async {
                        Navigator.of(sheetContext).pop();
                        await openPrivacyPolicy(context);
                      },
                    ),
                    _SheetTile(
                      icon: Icons.description_outlined,
                      label: 'Kullanım şartları',
                      onTap: () async {
                        Navigator.of(sheetContext).pop();
                        await openTermsOfUse(context);
                      },
                    ),
                    Divider(
                      height: 1,
                      color: AppColors.ghostBorder.withValues(alpha: 0.35),
                      indent: 16,
                      endIndent: 16,
                    ),
                    _SheetTile(
                      icon: Icons.info_outline_rounded,
                      label: 'Hakkında',
                      onTap: () async {
                        Navigator.of(sheetContext).pop();
                        final info = await PackageInfo.fromPlatform();
                        if (!context.mounted) return;
                        await _showAboutSheet(
                          context,
                          info,
                          hasPlayback: hasPlayback,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

Future<void> _showAboutSheet(
  BuildContext context,
  PackageInfo info, {
  required bool hasPlayback,
}) async {
  final extraBottom = hasPlayback ? 110.0 : 0.0;
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    isScrollControlled: true,
    builder: (sheetContext) {
      return SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + extraBottom),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.ghostBorder.withValues(alpha: 0.4),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'SleepingNoise',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Sürüm ${info.version} (${info.buildNumber})',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Uykuya yardımcı ambiyans ve beyaz gürültü sesleri.',
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '© 2026',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 18),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        child: const Text('Kapat'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _SheetTile extends StatelessWidget {
  const _SheetTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: AppColors.spectralLavender, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
