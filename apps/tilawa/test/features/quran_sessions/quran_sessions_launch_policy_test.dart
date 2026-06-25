import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa/core/bootstrap/app_launch_config.dart';
import 'package:tilawa/features/quran_sessions/quran_sessions_launch_policy.dart';

void main() {
  test('resolveVoiceVideoProviderHint picks agora when app id present', () {
    const config = AppLaunchConfig(
      enabledCallProvidersCsv: 'external,mock,agora',
      agoraAppId: kStagingAgoraAppId,
    );

    expect(
      resolveVoiceVideoProviderHint(config),
      SessionCallProviderKind.agora,
    );
    expect(
      sessionModePolicyFromLaunchConfig(config).voiceVideoUseMockProvider,
      isFalse,
    );
  });

  test(
    'resolveVoiceVideoProviderHint falls back to mock without agora app id',
    () {
      const config = AppLaunchConfig(
        enabledCallProvidersCsv: 'external,mock,agora',
      );

      expect(
        resolveVoiceVideoProviderHint(config, debugMode: false),
        SessionCallProviderKind.mock,
      );
    },
  );

  test(
    'staging distribution injects agora defaults when dart-defines omitted',
    () {
      const config = AppLaunchConfig(
        enabledCallProvidersCsv: 'external,mock',
      );

      final rtc = resolveRtcLaunchConfig(config, distribution: 'staging');

      expect(rtc.isAgoraEnabled, isTrue);
      expect(rtc.agoraAppId, kStagingAgoraAppId);
      expect(
        resolveVoiceVideoProviderHint(config, debugMode: false),
        SessionCallProviderKind.mock,
      );
      expect(
        resolveRtcLaunchConfig(
          config,
          distribution: 'staging',
        ).enabledProviders,
        contains('agora'),
      );
    },
  );

  test('local release keeps agora off without explicit dart-defines', () {
    const config = AppLaunchConfig();

    final rtc = resolveRtcLaunchConfig(
      config,
      distribution: 'local',
      debugMode: false,
    );

    expect(rtc.isAgoraEnabled, isFalse);
    expect(rtc.enabledProviders, containsAll(['external', 'mock']));
  });

  test(
    'debug build injects agora defaults when dart-defines omitted',
    () {
      const config = AppLaunchConfig(
        enabledCallProvidersCsv: 'external,mock',
      );

      final rtc = resolveRtcLaunchConfig(
        config,
        distribution: 'local',
        debugMode: true,
      );

      expect(rtc.isAgoraEnabled, isTrue);
      expect(rtc.agoraAppId, kStagingAgoraAppId);
      expect(rtc.enabledProviders, contains('agora'));
    },
  );

  test('staging respects explicit agora dart-defines over defaults', () {
    const customId = 'custom-agora-app-id';
    const config = AppLaunchConfig(
      enabledCallProvidersCsv: 'external,mock,agora',
      agoraAppId: customId,
    );

    final rtc = resolveRtcLaunchConfig(config, distribution: 'staging');

    expect(rtc.agoraAppId, customId);
    expect(rtc.isAgoraEnabled, isTrue);
  });

  test(
    'play_production release keeps agora and webrtc out of provider set',
    () {
      const config = AppLaunchConfig();

      final rtc = resolveRtcLaunchConfig(
        config,
        distribution: 'play_production',
        debugMode: false,
      );

      expect(rtc.enabledProviders, containsAll(['external', 'mock']));
      expect(rtc.enabledProviders, isNot(contains('agora')));
      expect(rtc.enabledProviders, isNot(contains('webrtc')));
      expect(rtc.isAgoraEnabled, isFalse);
      expect(rtc.isWebRtcEnabled, isFalse);
      expect(
        resolveVoiceVideoProviderHint(
          config,
          distribution: 'play_production',
          debugMode: false,
        ),
        SessionCallProviderKind.mock,
      );
    },
  );
}
