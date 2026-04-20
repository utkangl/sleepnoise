import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bumped when the user taps the already-selected bottom nav tab ([AppRoute.path] key).
final tabReselectProvider = StateProvider<Map<String, int>>((ref) => {});

void bumpTabReselect(WidgetRef ref, String path) {
  ref.read(tabReselectProvider.notifier).update((m) {
    final n = Map<String, int>.from(m);
    n[path] = (n[path] ?? 0) + 1;
    return n;
  });
}

void listenTabScrollToTop(
  WidgetRef ref,
  String routePath,
  ScrollController controller,
) {
  ref.listen<Map<String, int>>(tabReselectProvider, (prev, next) {
    final g = next[routePath] ?? 0;
    final pg = prev?[routePath] ?? 0;
    if (g <= pg) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!controller.hasClients) return;
      controller.animateTo(
        0,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    });
  });
}

void listenLibraryTabScrollToTop(
  WidgetRef ref,
  String routePath,
  TabController tabController,
  ScrollController catalog,
  ScrollController favorites,
) {
  ref.listen<Map<String, int>>(tabReselectProvider, (prev, next) {
    final g = next[routePath] ?? 0;
    final pg = prev?[routePath] ?? 0;
    if (g <= pg) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = tabController.index == 0 ? catalog : favorites;
      if (!c.hasClients) return;
      c.animateTo(
        0,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    });
  });
}
