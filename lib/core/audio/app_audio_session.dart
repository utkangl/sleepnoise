import 'package:audio_session/audio_session.dart';

/// Tek bir paylaşılan oturum + iOS’ta [mixWithOthers]: mixer’daki birden fazla
/// [AudioPlayer] aynı anda çalabilsin; her oyuncu [handleAudioSessionActivation:false]
/// ile bu oturumu bozmasın.
Future<void> ensureSleepingNoiseAudioSession() async {
  final session = await AudioSession.instance;
  await session.configure(
    AudioSessionConfiguration.music().copyWith(
      avAudioSessionCategoryOptions:
          AVAudioSessionCategoryOptions.mixWithOthers,
      androidWillPauseWhenDucked: false,
    ),
  );
  await session.setActive(true);
}
