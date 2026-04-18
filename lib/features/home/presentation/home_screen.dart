import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../player/domain/audio_catalog.dart';
import '../../player/application/playback_facade.dart';
import '../../player/application/playback_visibility.dart';
import '../../../core/routing/app_route.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/sleeping_noise_app_bar.dart';
import 'widgets/soundscape_hero_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chrome = ref.watch(
      shellPlaybackChromeVisibleProvider(AppRoute.home.path),
    );
    final bottomPad =
        MediaQuery.paddingOf(context).bottom + (chrome ? 210 : 100);
    final cards = featuredTracks.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SafeArea(bottom: false, child: SleepingNoiseAppBar()),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(24, 8, 24, bottomPad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                _heroHeader(context),
                const SizedBox(height: 28),
                for (var i = 0; i < cards.length; i++) ...[
                  SoundscapeHeroCard(
                    title: cards[i].title,
                    description: cards[i].subtitle,
                    category: cards[i].category,
                    playBackground: i.isEven
                        ? AppColors.primary
                        : AppColors.secondary,
                    playForeground: i.isEven
                        ? AppColors.onPrimary
                        : AppColors.onSecondary,
                    onPlay: () => playSingleSoundscape(ref, cards[i].id),
                  ),
                  if (i != cards.length - 1) const SizedBox(height: 20),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _heroHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dogal ses secimi',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.4,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontSize: 34,
              height: 1.05,
              fontWeight: FontWeight.w800,
            ),
            children: const [
              TextSpan(text: 'Temel '),
              TextSpan(
                text: 'ortam sesleri',
                style: TextStyle(color: AppColors.primary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
