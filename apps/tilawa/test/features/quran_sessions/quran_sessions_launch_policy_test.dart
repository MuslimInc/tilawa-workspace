import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa/core/bootstrap/app_launch_config.dart';
import 'package:tilawa/features/quran_sessions/domain/entities/quran_sessions_platform_config.dart';
import 'package:tilawa/features/quran_sessions/quran_sessions_launch_policy.dart';

void main() {
  test('platform config picks livekit when url present', () {
    const platformConfig = QuranSessionsPlatformConfig(
      quranSessionsEnabled: true,
      studentEntryEnabled: true,
      bookingEnabled: true,
      bookingMode: 'autoConfirm',
      sessionMode: 'videoOnly',
      enabledCallProviders: {'external', 'mock', 'livekit'},
    );
    const launchConfig = AppLaunchConfig(livekitServerUrl: kStagingLiveKitUrl);

    expect(
      resolveVoiceVideoProviderHintFromPlatformConfig(
        platformConfig,
        launchConfig,
      ),
      SessionCallProviderKind.livekit,
    );
    expect(
      sessionModePolicyFromPlatformConfig(
        platformConfig,
        launchConfig,
      ).isEnabled(SessionCallType.videoCall),
      isTrue,
    );
    expect(
      sessionModePolicyFromPlatformConfig(
        platformConfig,
        launchConfig,
      ).isEnabled(SessionCallType.voiceCall),
      isFalse,
    );
    expect(
      sessionModePolicyFromPlatformConfig(
        platformConfig,
        launchConfig,
      ).voiceVideoUseMockProvider,
      isFalse,
    );
  });

  test('platform config picks agora when livekit url missing', () {
    const platformConfig = QuranSessionsPlatformConfig(
      quranSessionsEnabled: true,
      studentEntryEnabled: true,
      bookingEnabled: true,
      bookingMode: 'autoConfirm',
      sessionMode: 'videoOnly',
      enabledCallProviders: {'external', 'mock', 'agora', 'livekit'},
    );
    const launchConfig = AppLaunchConfig(agoraAppId: kStagingAgoraAppId);

    expect(
      resolveVoiceVideoProviderHintFromPlatformConfig(
        platformConfig,
        launchConfig,
        distribution: 'local',
        debugMode: false,
      ),
      SessionCallProviderKind.agora,
    );
  });

  test('platform config falls back to mock without rtc credentials', () {
    const platformConfig = QuranSessionsPlatformConfig(
      quranSessionsEnabled: true,
      studentEntryEnabled: true,
      bookingEnabled: true,
      bookingMode: 'autoConfirm',
      sessionMode: 'videoOnly',
      enabledCallProviders: {'external', 'mock', 'livekit'},
    );

    expect(
      resolveVoiceVideoProviderHintFromPlatformConfig(
        platformConfig,
        const AppLaunchConfig(),
        debugMode: false,
      ),
      SessionCallProviderKind.mock,
    );
  });

  test('staging injects livekit credential when admin enables livekit', () {
    const platformConfig = QuranSessionsPlatformConfig(
      quranSessionsEnabled: true,
      studentEntryEnabled: true,
      bookingEnabled: true,
      bookingMode: 'autoConfirm',
      sessionMode: 'videoOnly',
      enabledCallProviders: {'external', 'mock', 'livekit'},
    );

    final rtc = resolveRtcLaunchConfigFromPlatformConfig(
      platformConfig,
      const AppLaunchConfig(),
      distribution: 'staging',
      debugMode: false,
    );

    expect(rtc.isLiveKitEnabled, isTrue);
    expect(rtc.livekitServerUrl, kStagingLiveKitUrl);
    expect(rtc.enabledProviders, contains('livekit'));
  });

  test('safe fallback keeps rtc on external and mock only', () {
    final rtc = resolveRtcLaunchConfigFromPlatformConfig(
      QuranSessionsPlatformConfig.safeFallback,
      const AppLaunchConfig(),
      distribution: 'local',
      debugMode: false,
    );

    expect(rtc.isAgoraEnabled, isFalse);
    expect(rtc.isLiveKitEnabled, isFalse);
    expect(rtc.enabledProviders, containsAll(['external', 'mock']));
  });

  test('debug injects livekit credential only when admin enables livekit', () {
    const platformConfig = QuranSessionsPlatformConfig(
      quranSessionsEnabled: true,
      studentEntryEnabled: true,
      bookingEnabled: true,
      bookingMode: 'autoConfirm',
      sessionMode: 'videoOnly',
      enabledCallProviders: {'external', 'mock', 'livekit'},
    );

    final rtc = resolveRtcLaunchConfigFromPlatformConfig(
      platformConfig,
      const AppLaunchConfig(),
      distribution: 'local',
      debugMode: true,
    );

    expect(rtc.isLiveKitEnabled, isTrue);
    expect(rtc.livekitServerUrl, kStagingLiveKitUrl);
    expect(rtc.enabledProviders, contains('livekit'));
  });

  test('explicit agora credential is preserved when admin enables agora', () {
    const customId = 'custom-agora-app-id';
    const platformConfig = QuranSessionsPlatformConfig(
      quranSessionsEnabled: true,
      studentEntryEnabled: true,
      bookingEnabled: true,
      bookingMode: 'autoConfirm',
      sessionMode: 'videoOnly',
      enabledCallProviders: {'external', 'mock', 'agora', 'livekit'},
    );
    const launchConfig = AppLaunchConfig(
      agoraAppId: customId,
      livekitServerUrl: kStagingLiveKitUrl,
    );

    final rtc = resolveRtcLaunchConfigFromPlatformConfig(
      platformConfig,
      launchConfig,
      distribution: 'staging',
    );

    expect(rtc.agoraAppId, customId);
    expect(rtc.isAgoraEnabled, isTrue);
    expect(rtc.isLiveKitEnabled, isTrue);
    expect(
      resolveVoiceVideoProviderHintFromPlatformConfig(
        platformConfig,
        launchConfig,
        distribution: 'staging',
        debugMode: false,
      ),
      SessionCallProviderKind.livekit,
    );
  });

  test('play production safe fallback excludes native rtc providers', () {
    final rtc = resolveRtcLaunchConfigFromPlatformConfig(
      QuranSessionsPlatformConfig.safeFallback,
      const AppLaunchConfig(),
      distribution: 'play_production',
      debugMode: false,
    );

    expect(rtc.enabledProviders, containsAll(['external', 'mock']));
    expect(rtc.enabledProviders, isNot(contains('agora')));
    expect(rtc.enabledProviders, isNot(contains('livekit')));
    expect(rtc.isAgoraEnabled, isFalse);
    expect(rtc.isLiveKitEnabled, isFalse);
    expect(
      resolveVoiceVideoProviderHintFromPlatformConfig(
        QuranSessionsPlatformConfig.safeFallback,
        const AppLaunchConfig(),
        distribution: 'play_production',
        debugMode: false,
      ),
      SessionCallProviderKind.mock,
    );
  });

  test('play alpha keeps livekit disabled without explicit url', () {
    const platformConfig = QuranSessionsPlatformConfig(
      quranSessionsEnabled: true,
      studentEntryEnabled: true,
      bookingEnabled: true,
      bookingMode: 'autoConfirm',
      sessionMode: 'videoOnly',
      enabledCallProviders: {'external', 'mock', 'livekit'},
    );

    final rtc = resolveRtcLaunchConfigFromPlatformConfig(
      platformConfig,
      const AppLaunchConfig(),
      distribution: 'play_alpha',
      debugMode: false,
    );

    expect(rtc.enabledProviders, contains('livekit'));
    expect(rtc.isLiveKitEnabled, isFalse);
    expect(rtc.livekitServerUrl, isEmpty);
  });
}
