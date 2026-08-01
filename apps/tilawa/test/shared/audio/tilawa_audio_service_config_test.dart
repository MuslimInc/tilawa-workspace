import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/shared/audio/tilawa_audio_service_config.dart';

void main() {
  test('keeps ongoing media FGS while playing with bounded artwork decode', () {
    const config = TilawaAudioServiceConfig.value;

    expect(config.androidNotificationOngoing, isTrue);
    expect(config.androidStopForegroundOnPause, isTrue);
    expect(
      config.androidNotificationChannelId,
      TilawaAudioServiceConfig.androidNotificationChannelId,
    );
    expect(
      config.artDownscaleWidth,
      TilawaAudioServiceConfig.artDownscaleWidth,
    );
    expect(
      config.artDownscaleHeight,
      TilawaAudioServiceConfig.artDownscaleHeight,
    );
  });
}
