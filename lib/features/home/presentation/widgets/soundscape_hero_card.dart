import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';

class SoundscapeHeroCard extends StatelessWidget {
  const SoundscapeHeroCard({
    super.key,
    required this.title,
    required this.description,
    required this.category,
    required this.playBackground,
    required this.playForeground,
    required this.onPlay,
  });

  final String title;
  final String description;
  final String category;
  final Color playBackground;
  final Color playForeground;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 24,
      blurSigma: 10,
      child: AspectRatio(
        aspectRatio: 1.0,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _CategoryHeroArt(category: category),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.1),
                      Colors.black.withValues(alpha: 0.72),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 28,
                            height: 1.1,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            height: 1.45,
                            color: AppColors.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 22),
                    Material(
                      color: playBackground,
                      shape: const CircleBorder(),
                      elevation: 8,
                      shadowColor: playBackground.withValues(alpha: 0.35),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: onPlay,
                        child: SizedBox(
                          width: 56,
                          height: 56,
                          child: Icon(
                            Icons.play_arrow_rounded,
                            color: playForeground,
                            size: 34,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryHeroArt extends StatelessWidget {
  const _CategoryHeroArt({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    final icon = switch (category) {
      'forest' => Icons.forest_rounded,
      'waterfall' => Icons.water_rounded,
      'ocean' => Icons.waves_rounded,
      'birds' => Icons.flutter_dash_rounded,
      'fire' => Icons.local_fire_department_rounded,
      'demo' => Icons.cloud_download_rounded,
      _ => Icons.music_note_rounded,
    };

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B2A4A), Color(0xFF302262)],
        ),
      ),
      child: Center(child: Icon(icon, size: 76, color: AppColors.onSurface)),
    );
  }
}
