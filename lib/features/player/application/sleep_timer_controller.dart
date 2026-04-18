import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../mixer/application/mixer_controller.dart';
import 'audio_controller.dart';

class SleepTimerState {
  const SleepTimerState({
    required this.active,
    required this.remaining,
    this.endsAt,
  });

  factory SleepTimerState.initial() => const SleepTimerState(
        active: false,
        remaining: Duration.zero,
      );

  final bool active;
  final Duration remaining;
  final DateTime? endsAt;

  SleepTimerState copyWith({
    bool? active,
    Duration? remaining,
    DateTime? endsAt,
    bool clearEndsAt = false,
  }) {
    return SleepTimerState(
      active: active ?? this.active,
      remaining: remaining ?? this.remaining,
      endsAt: clearEndsAt ? null : (endsAt ?? this.endsAt),
    );
  }
}

final sleepTimerControllerProvider =
    StateNotifierProvider<SleepTimerController, SleepTimerState>((ref) {
  return SleepTimerController(ref);
});

class SleepTimerController extends StateNotifier<SleepTimerState> {
  SleepTimerController(this._ref) : super(SleepTimerState.initial());

  final Ref _ref;
  Timer? _ticker;

  void start(Duration duration) {
    if (duration <= Duration.zero) {
      cancel();
      return;
    }

    final endsAt = DateTime.now().add(duration);
    state = state.copyWith(
      active: true,
      remaining: duration,
      endsAt: endsAt,
    );
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _syncFromNow();
    });
  }

  void cancel() {
    _ticker?.cancel();
    _ticker = null;
    state = SleepTimerState.initial();
  }

  void _syncFromNow() {
    final endsAt = state.endsAt;
    if (endsAt == null) {
      cancel();
      return;
    }

    final remaining = endsAt.difference(DateTime.now());
    if (remaining <= Duration.zero) {
      unawaited(_finishTimer());
      return;
    }
    state = state.copyWith(active: true, remaining: remaining);
  }

  Future<void> _finishTimer() async {
    cancel();
    await _ref.read(mixerControllerProvider.notifier).stopMix();
    await _ref.read(audioControllerProvider.notifier).pause();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
