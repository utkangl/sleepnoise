import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Asset’ten gelen sessiz video. [shouldPlay] false iken decoder’ı kapatır
/// (pause); bütçe ve batarya için. Opaklık animasyonu sırasında videonun
/// donmaması için `shouldPlay` ve `opacity` kararları bağımsızdır: caller,
/// fade boyunca videoyu görünür tutmak için `shouldPlay: true` gönderebilir.
///
/// [loop] varsayılan true; false yapılırsa video bir kez oynatılır ve sona
/// gelince [onCompleted] tetiklenir (yedek sinyal). [endCrossfadeLeadIn] +
/// [onEndCrossfadeLeadIn] verilirse, bitişe bu kadar süre kala crossfade
/// başlatılabilir — böylece donmuş son kareye bakılmaz.
class LoopingAssetVideo extends StatefulWidget {
  const LoopingAssetVideo({
    super.key,
    required this.asset,
    required this.shouldPlay,
    required this.opacity,
    this.fit = BoxFit.cover,
    this.fadeDuration = const Duration(milliseconds: 380),
    this.loop = true,
    this.onReady,
    this.onCompleted,
    this.endCrossfadeLeadIn,
    this.onEndCrossfadeLeadIn,
  });

  final String asset;
  final bool shouldPlay;

  /// 0..1 arası; sadece görsel opaklık. Oynat/duraklat kararı alınmaz.
  final double opacity;
  final BoxFit fit;
  final Duration fadeDuration;

  /// false ise video sona gelince [onCompleted] çağrılır.
  final bool loop;

  /// Video controller initialize olup ilk frame’i çizmeye hazır olduğunda
  /// (her asset değişiminde tekrar) tetiklenir. Caller, crossfade gibi
  /// görsel geçişleri buradaki sinyale göre tetikleyebilir.
  final VoidCallback? onReady;

  /// Sadece [loop] false iken: video sonuna ulaşıldığında bir kez tetiklenir.
  final VoidCallback? onCompleted;

  /// [loop] false iken: sürenin sonuna bu kadar süre kala [onEndCrossfadeLeadIn]
  /// bir kez tetiklenir (ör. bir sonraki klibi yüklemek için).
  final Duration? endCrossfadeLeadIn;

  final VoidCallback? onEndCrossfadeLeadIn;

  @override
  State<LoopingAssetVideo> createState() => _LoopingAssetVideoState();
}

class _LoopingAssetVideoState extends State<LoopingAssetVideo> {
  VideoPlayerController? _controller;
  bool _initialized = false;

  // Eski controller üzerinde devam eden play/pause future’ları yeni kurulan
  // controller’ı bozmasın diye nesil sayacı.
  int _gen = 0;

  // play / pause çağrılarını sırala: video_player’da bir önceki çağrı bitmeden
  // gelen sonraki çağrı bazen sessizce yutuluyor → video frame’de donuyor.
  Future<void> _queue = Future<void>.value();

  // Bu controller için onCompleted bir kez tetiklendi mi? Aynı playthrough'da
  // tekrar tekrar fire etmeyi engeller.
  bool _completedFired = false;

  bool _nearEndFired = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load(widget.asset));
  }

  Future<void> _load(String asset) async {
    final myGen = ++_gen;
    _queue = Future<void>.value();
    _completedFired = false;
    _nearEndFired = false;
    // KRİTİK: video_player varsayılan olarak audio focus alır; volume 0
    // olsa bile bu, just_audio (tek-ses oynatıcı) ve mixer kanallarının
    // arka planda otomatik duraklamasına yol açar. [mixWithOthers] ile
    // odağı paylaşıp NP'deki ses akışını koruyoruz.
    final c = VideoPlayerController.asset(
      asset,
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    )
      ..setVolume(0)
      ..setLooping(widget.loop);
    try {
      await c.initialize();
    } catch (_) {
      try {
        await c.dispose();
      } catch (_) {}
      return;
    }
    if (!mounted || myGen != _gen) {
      try {
        await c.dispose();
      } catch (_) {}
      return;
    }
    c.addListener(_handleControllerTick);
    setState(() {
      _controller = c;
      _initialized = true;
    });
    // Bazı platformlarda init’in hemen ardından play() yutulabiliyor; bir
    // sonraki frame’de tetiklemek bunu büyük oranda gideriyor.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || myGen != _gen) return;
      _enqueueDesired();
      widget.onReady?.call();
    });
  }

  void _handleControllerTick() {
    final c = _controller;
    if (c == null) return;
    final v = c.value;
    if (!v.isInitialized) return;
    final dur = v.duration;
    if (dur <= Duration.zero) return;

    if (!widget.loop &&
        widget.onEndCrossfadeLeadIn != null &&
        widget.endCrossfadeLeadIn != null &&
        !_nearEndFired) {
      var triggerPos = dur - widget.endCrossfadeLeadIn!;
      if (triggerPos < Duration.zero) {
        triggerPos = Duration.zero;
      }
      if (v.position >= triggerPos) {
        _nearEndFired = true;
        widget.onEndCrossfadeLeadIn!();
      }
    }

    if (widget.loop || _completedFired) return;
    // 80ms tolerans: video_player position bazen tam duration'a ulaşmadan
    // playback biter; isCompleted veya position threshold'u tetikler.
    final atEnd = v.position >= dur - const Duration(milliseconds: 80);
    if (atEnd) {
      _completedFired = true;
      widget.onCompleted?.call();
    }
  }

  void _enqueueDesired() {
    final myGen = _gen;
    _queue = _queue
        .then(
          (_) => _applyDesired(myGen),
        )
        .catchError((Object _) async => _applyDesired(myGen));
  }

  Future<void> _applyDesired(int myGen) async {
    if (!mounted || myGen != _gen) return;
    final c = _controller;
    if (c == null || !_initialized) return;
    final desired = widget.shouldPlay;
    try {
      if (desired) {
        await c.play();
      } else {
        await c.pause();
      }
    } catch (_) {}
    if (!mounted || myGen != _gen) return;
    // İstek await sırasında değiştiyse veya platform tarafı uygulamadıysa
    // tekrar dene; ikinci deneme genelde tutuyor.
    final actuallyPlaying = c.value.isPlaying;
    final wantedNow = widget.shouldPlay;
    if (actuallyPlaying != wantedNow) {
      try {
        if (wantedNow) {
          await c.play();
        } else {
          await c.pause();
        }
      } catch (_) {}
    }
  }

  @override
  void didUpdateWidget(covariant LoopingAssetVideo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.asset != oldWidget.asset) {
      unawaited(_swap(widget.asset));
      return;
    }
    if (widget.loop != oldWidget.loop) {
      _controller?.setLooping(widget.loop);
    }
    if (widget.shouldPlay != oldWidget.shouldPlay) {
      _enqueueDesired();
    }
  }

  Future<void> _swap(String asset) async {
    _gen++;
    final old = _controller;
    setState(() {
      _controller = null;
      _initialized = false;
    });
    if (old != null) {
      unawaited(() async {
        try {
          old.removeListener(_handleControllerTick);
        } catch (_) {}
        try {
          await old.pause();
        } catch (_) {}
        try {
          await old.dispose();
        } catch (_) {}
      }());
    }
    await _load(asset);
  }

  @override
  void dispose() {
    _gen++;
    final c = _controller;
    if (c != null) {
      unawaited(() async {
        try {
          c.removeListener(_handleControllerTick);
        } catch (_) {}
        try {
          await c.dispose();
        } catch (_) {}
      }());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    final visible = widget.opacity.clamp(0.0, 1.0).toDouble();
    if (c == null || !_initialized) {
      return const SizedBox.expand();
    }
    final size = c.value.size;
    final w = size.width <= 0 ? 1.0 : size.width;
    final h = size.height <= 0 ? 1.0 : size.height;
    // [TweenAnimationBuilder] [AnimatedOpacity]'den farklı olarak ilk
    // mount'ta da `begin` → `end` arası animasyon yürütür; bu sayede yeni
    // bir asset hazır olunca yumuşak bir fade-in elde edilir. Sonraki
    // opacity değişikliklerinde de mevcut değerden yeni hedefe doğru
    // geçişi otomatik yapar.
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: visible),
      duration: widget.fadeDuration,
      curve: Curves.easeInOut,
      builder: (context, value, child) =>
          Opacity(opacity: value, child: child),
      child: ClipRect(
        child: SizedBox.expand(
          child: FittedBox(
            fit: widget.fit,
            child: SizedBox(
              width: w,
              height: h,
              child: VideoPlayer(c),
            ),
          ),
        ),
      ),
    );
  }
}
