import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../legal/open_legal_url.dart';
import '../theme/app_colors.dart';

/// Lightweight header — no [BackdropFilter] (blur behind scrolling content is costly).
class SleepingNoiseAppBar extends StatelessWidget {
  const SleepingNoiseAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.55),
        border: Border(bottom: BorderSide(color: AppColors.ghostBorder)),
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
          PopupMenuButton<_AppBarMenu>(
            tooltip: 'Menü',
            icon: Icon(
              Icons.more_vert_rounded,
              color: AppColors.onSurface.withValues(alpha: 0.92),
            ),
            offset: const Offset(0, 44),
            onSelected: (_AppBarMenu value) async {
              switch (value) {
                case _AppBarMenu.privacy:
                  await openPrivacyPolicy(context);
                case _AppBarMenu.terms:
                  await openTermsOfUse(context);
                case _AppBarMenu.about:
                  final info = await PackageInfo.fromPlatform();
                  if (!context.mounted) return;
                  showAboutDialog(
                    context: context,
                    applicationName: 'SleepingNoise',
                    applicationVersion:
                        '${info.version} (${info.buildNumber})',
                    applicationLegalese: '© 2026',
                    children: const [
                      Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: Text(
                          'Uykuya yardımcı ambiyans ve beyaz gürültü sesleri.',
                        ),
                      ),
                    ],
                  );
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _AppBarMenu.privacy,
                child: Text('Gizlilik politikası'),
              ),
              PopupMenuItem(
                value: _AppBarMenu.terms,
                child: Text('Kullanım şartları'),
              ),
              PopupMenuDivider(),
              PopupMenuItem(
                value: _AppBarMenu.about,
                child: Text('Hakkında'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _AppBarMenu { privacy, terms, about }
