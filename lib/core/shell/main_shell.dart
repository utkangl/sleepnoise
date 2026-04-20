import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/player/application/playback_visibility.dart';
import '../navigation/tab_reselect_provider.dart';
import '../routing/app_route.dart';
import '../widgets/mesh_gradient_background.dart';
import '../widgets/sleeping_noise_bottom_nav.dart';
import '../widgets/sleeping_noise_mini_player.dart';

/// Shell: mesh backdrop + tab body + optional mini player + glass bottom nav.
class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.currentPath, required this.child});

  final String currentPath;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final showMini = ref.watch(shellPlaybackChromeVisibleProvider(currentPath));
    final normalizedPath =
        currentPath == '/' || currentPath.isEmpty
            ? AppRoute.home.path
            : currentPath;

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const MeshGradientBackground(),
          RepaintBoundary(child: child),
          if (showMini)
            Positioned(
              left: 24,
              right: 24,
              bottom: bottomInset + 88,
              child: const RepaintBoundary(child: SleepingNoiseMiniPlayer()),
            ),
        ],
      ),
      bottomNavigationBar: SleepingNoiseBottomNav(
        currentPath: currentPath,
        onSelect: (route) {
          if (normalizedPath == route.path) {
            bumpTabReselect(ref, route.path);
          } else {
            context.go(route.path);
          }
        },
      ),
    );
  }
}
