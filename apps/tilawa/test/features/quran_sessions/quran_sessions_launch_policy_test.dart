import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa/core/bootstrap/app_launch_config.dart';
import 'package:tilawa/features/quran_sessions/quran_sessions_launch_policy.dart';

void main() {
  test('resolveVoiceVideoProviderHint picks livekit when url present', () {
    const config = AppLaunchConfig(
      enabledCallProvidersCsv: 'external,mock,livekit',
      livekitServerUrl: kStagingLiveKitUrl,
    );

    expect(
      resolveVoiceVideoProviderHint(config),
      SessionCallProviderKind.livekit,
    );
    expect(
      sessionModePolicyFromLaunchConfig(config).isEnabled(
        SessionCallType.videoCall,
      ),
      isTrue,
    );
    expect(
      sessionModePolicyFromLaunchConfig(config).isEnabled(
        SessionCallType.voiceCall,
      ),
      isFalse,
    );
    expect(
      sessionModePolicyFromLaunchConfig(config).voiceVideoUseMockProvider,
      isFalse,
    );
  });

  test(
    'resolveVoiceVideoProviderHint picks agora when livekit url missing',
    () {
      const config = AppLaunchConfig(
        enabledCallProvidersCsv: 'external,mock,agora,livekit',
        agoraAppId: kStagingAgoraAppId,
      );

      expect(
        resolveVoiceVideoProviderHint(
          config,
          distribution: 'local',
          debugMode: false,
        ),
        SessionCallProviderKind.agora,
      );
    },
  );

  test(
    'resolveVoiceVideoProviderHint falls back to mock without rtc credentials',
    () {
      const config = AppLaunchConfig(
        enabledCallProvidersCsv: 'external,mock,livekit',
      );

      expect(
        resolveVoiceVideoProviderHint(config, debugMode: false),
        SessionCallProviderKind.mock,
      );
    },
  );

  test(
    'staging distribution injects livekit defaults when dart-defines omitted',
    () {
      const config = AppLaunchConfig(
        enabledCallProvidersCsv: 'external,mock',
      );

      final rtc = resolveRtcLaunchConfig(config, distribution: 'staging');

      expect(rtc.isLiveKitEnabled, isTrue);
      expect(rtc.livekitServerUrl, kStagingLiveKitUrl);
      expect(
        resolveVoiceVideoProviderHint(
          config,
          distribution: 'staging',
          debugMode: false,
        ),
        SessionCallProviderKind.livekit,
      );
      expect(
        resolveRtcLaunchConfig(
          config,
          distribution: 'staging',
        ).enabledProviders,
        contains('livekit'),
      );
    },
  );

  test('local release keeps rtc off without explicit dart-defines', () {
    const config = AppLaunchConfig();

    final rtc = resolveRtcLaunchConfig(
      config,
      distribution: 'local',
      debugMode: false,
    );

    expect(rtc.isAgoraEnabled, isFalse);
    expect(rtc.isLiveKitEnabled, isFalse);
    expect(rtc.enabledProviders, containsAll(['external', 'mock']));
  });

  test(
    'debug build injects livekit defaults when dart-defines omitted',
    () {
      const config = AppLaunchConfig(
        enabledCallProvidersCsv: 'external,mock',
      );

      final rtc = resolveRtcLaunchConfig(
        config,
        distribution: 'local',
        debugMode: true,
      );

      expect(rtc.isLiveKitEnabled, isTrue);
      expect(rtc.livekitServerUrl, kStagingLiveKitUrl);
      expect(rtc.enabledProviders, contains('livekit'));
    },
  );

  test('staging respects explicit agora dart-defines over livekit', () {
    const customId = 'custom-agora-app-id';
    const config = AppLaunchConfig(
      enabledCallProvidersCsv: 'external,mock,agora,livekit',
      agoraAppId: customId,
      livekitServerUrl: kStagingLiveKitUrl,
    );

    final rtc = resolveRtcLaunchConfig(config, distribution: 'staging');

    expect(rtc.agoraAppId, customId);
    expect(rtc.isAgoraEnabled, isTrue);
    expect(rtc.isLiveKitEnabled, isTrue);
    expect(
      resolveVoiceVideoProviderHint(
        config,
        distribution: 'staging',
        debugMode: false,
      ),
      SessionCallProviderKind.livekit,
    );
  });

  test(
    'play_production release keeps agora and livekit out of provider set',
    () {
      const config = AppLaunchConfig();

      final rtc = resolveRtcLaunchConfig(
        config,
        distribution: 'play_production',
        debugMode: false,
      );

      expect(rtc.enabledProviders, containsAll(['external', 'mock']));
      expect(rtc.enabledProviders, isNot(contains('agora')));
      expect(rtc.enabledProviders, isNot(contains('livekit')));
      expect(rtc.isAgoraEnabled, isFalse);
      expect(rtc.isLiveKitEnabled, isFalse);
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

  test('resolveQuranTutorBookingModeHint uses Firestore when set', () {
    expect(
      resolveQuranTutorBookingModeHint(
        firestoreModeRaw: 'autoConfirm',
        distribution: 'play_production',
      ),
      QuranTutorBookingMode.autoConfirm,
    );
  });

  test(
    'play_alpha release keeps livekit disabled without explicit url',
    () {
      const config = AppLaunchConfig(
        enabledCallProvidersCsv: 'external,mock,livekit',
      );

      final rtc = resolveRtcLaunchConfig(
        config,
        distribution: 'play_alpha',
        debugMode: false,
      );

      expect(rtc.enabledProviders, contains('livekit'));
      expect(rtc.isLiveKitEnabled, isFalse);
      expect(rtc.livekitServerUrl, isEmpty);
    },
  );

  test(
    'resolveQuranTutorBookingModeHint defaults play_production to approval',
    () {
      expect(
        resolveQuranTutorBookingModeHint(distribution: 'play_production'),
        QuranTutorBookingMode.requiresTutorApproval,
      );
    },
  );
}
