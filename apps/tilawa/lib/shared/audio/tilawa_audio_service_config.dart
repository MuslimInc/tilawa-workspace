import 'package:audio_service/audio_service.dart';

/// Android media-session / FGS knobs for Quran (and radio) background playback.
///
/// Kept as a named constant so tests can lock the contract without calling
/// [AudioService.init]. While playing, ongoing notification keeps
/// `mediaPlayback` FGS elevated; pause drops FGS priority by design.
abstract final class TilawaAudioServiceConfig {
  static const String androidNotificationChannelId =
      'com.tilawa.app.channel.audio';
  static const String androidNotificationChannelName = 'Audio playback';
  static const int artDownscaleWidth = 256;
  static const int artDownscaleHeight = 256;

  static const AudioServiceConfig value = AudioServiceConfig(
    androidNotificationChannelId: androidNotificationChannelId,
    androidNotificationChannelName: androidNotificationChannelName,
    androidNotificationOngoing: true,
    // Required companion of ongoing=true; while paused the service drops
    // FGS priority (killable). While playing, FGS stays elevated.
    androidStopForegroundOnPause: true,
    // Bound artwork decode RAM during long background listens (LMK risk).
    artDownscaleWidth: artDownscaleWidth,
    artDownscaleHeight: artDownscaleHeight,
  );
}
