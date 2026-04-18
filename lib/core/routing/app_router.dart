import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/presentation/home_screen.dart';
import '../../features/library/presentation/library_screen.dart';
import '../../features/mixer/presentation/mixer_screen.dart';
import '../../features/onboarding/onboarding_prefs.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/player/presentation/expanded_player_screen.dart';
import '../shell/main_shell.dart';
import 'app_route.dart';

final GlobalKey<NavigatorState> _rootKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

GoRouter createAppRouter() {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: AppRoute.home.path,
    redirect: (context, state) async {
      final done = await OnboardingPrefs.isCompleted();
      final path = state.uri.path;
      if (!done && path != AppRoute.onboarding.path) {
        return AppRoute.onboarding.path;
      }
      if (done && path == AppRoute.onboarding.path) {
        return AppRoute.home.path;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoute.onboarding.path,
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: const OnboardingScreen(),
        ),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            MainShell(currentPath: state.uri.path, child: child),
        routes: [
          GoRoute(
            path: AppRoute.home.path,
            pageBuilder: (context, state) =>
                NoTransitionPage(key: state.pageKey, child: const HomeScreen()),
          ),
          GoRoute(
            path: AppRoute.mixer.path,
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const MixerScreen(),
            ),
          ),
          GoRoute(
            path: AppRoute.library.path,
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const LibraryScreen(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoute.nowPlaying.path,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 260),
          child: const ExpandedPlayerScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            );
          },
        ),
      ),
    ],
  );
}
