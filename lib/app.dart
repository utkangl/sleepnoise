import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/mixer/application/mixer_controller.dart';
import 'features/player/application/audio_controller.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';

final GoRouter appRouter = createAppRouter();

class SleepingNoiseApp extends ConsumerStatefulWidget {
  const SleepingNoiseApp({super.key});

  @override
  ConsumerState<SleepingNoiseApp> createState() => _SleepingNoiseAppState();
}

class _SleepingNoiseAppState extends ConsumerState<SleepingNoiseApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      return;
    }
    ref.read(audioControllerProvider.notifier).refreshFromPlayer();
    ref.read(mixerControllerProvider.notifier).refreshFromPlayers();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SleepingNoise',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      routerConfig: appRouter,
    );
  }
}
