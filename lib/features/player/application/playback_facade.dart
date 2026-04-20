import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_route.dart';
import '../../mixer/application/mixer_controller.dart';
import 'audio_controller.dart';
import 'playback_owner_controller.dart';

/// Tek bir doğal sesi başlatır: önce mevcut karışımı tamamen susturur,
/// sahibi `single` yapar, ardından oynatır. [openNowPlaying] verilirse
/// (örn. ana ekrandan tıklamada) Now Playing ekranı açılır — kullanıcı
/// hem video hem de oynatma kontrollerini hemen görsün.
Future<void> playSingleSoundscape(
  WidgetRef ref,
  String trackId, {
  BuildContext? openNowPlaying,
}) async {
  // Mix kanallarını duraklat + sahibi temizle.
  await ref.read(mixerControllerProvider.notifier).stopMix();
  // Sahibi single'a sabitle: NP açılırken doğru moda kilitlensin.
  ref.read(playbackOwnerProvider.notifier).activateSingle();
  // NP'yi hemen aç: kullanıcı geri bildirim alsın. Audio yüklenirken
  // NP "Yükleniyor…" gösterir, ardından oynatma başlar.
  if (openNowPlaying != null && openNowPlaying.mounted) {
    openNowPlaying.push(AppRoute.nowPlaying.path);
  }
  // Audio play ateşle (await değil): _ensureReady uzun sürerse bile
  // navigation bloklanmaz; NP zaten yüklenme durumunu gösterir.
  unawaited(
    ref.read(audioControllerProvider.notifier).playTrackById(trackId),
  );
}

Future<void> toggleSinglePlayPause(WidgetRef ref) async {
  final audio = ref.read(audioControllerProvider.notifier);
  final playing = ref.read(audioControllerProvider).isPlaying;
  if (playing) {
    ref.read(playbackOwnerProvider.notifier).activateSingle();
    await audio.pause();
    return;
  }
  await ref.read(mixerControllerProvider.notifier).stopMix();
  ref.read(playbackOwnerProvider.notifier).activateSingle();
  await audio.togglePlayPause();
}

Future<void> playSingleNext(WidgetRef ref) async {
  await ref.read(mixerControllerProvider.notifier).stopMix();
  ref.read(playbackOwnerProvider.notifier).activateSingle();
  await ref.read(audioControllerProvider.notifier).playNext();
}

Future<void> playSinglePrevious(WidgetRef ref) async {
  await ref.read(mixerControllerProvider.notifier).stopMix();
  ref.read(playbackOwnerProvider.notifier).activateSingle();
  await ref.read(audioControllerProvider.notifier).playPrevious();
}
