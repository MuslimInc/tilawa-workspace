import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:quran_sessions_rtc_stub/quran_sessions_rtc_stub.dart';
import 'package:tilawa/core/bootstrap/app_launch_config.dart';
import 'package:tilawa/features/quran_sessions/quran_sessions_launch_policy.dart';

void main() {
  test('stub wiring has no native SDKs linked', () {
    expect(QuranSessionsRtcWiring.hasNativeSdks, isFalse);
  });

  test('stub wiring skips pool registration and sdk providers', () {
    final sl = GetIt.asNewInstance();
    QuranSessionsRtcWiring.registerPools(
      sl,
      registerAgora: true,
      registerLivekit: true,
    );

    expect(
      QuranSessionsRtcWiring.createAgoraProvider(
        sl,
        appId: kStagingAgoraAppId,
        tokenProvider: _NoopTokenProvider(),
        resolveUserId: () async => 'user',
      ),
      isNull,
    );
    expect(
      QuranSessionsRtcWiring.createLiveKitProvider(
        sl,
        serverUrl: kStagingLiveKitUrl,
        tokenProvider: _NoopTokenProvider(),
        resolveUserId: () async => 'user',
      ),
      isNull,
    );
  });

  test('play_production launch config keeps rtc on external and mock only', () {
    const config = AppLaunchConfig();
    final rtc = resolveRtcLaunchConfig(
      config,
      distribution: 'play_production',
      debugMode: false,
    );

    expect(rtc.enabledProviders, containsAll(['external', 'mock']));
    expect(rtc.isAgoraEnabled, isFalse);
    expect(rtc.isLiveKitEnabled, isFalse);
  });

  test('stub wiring returns null in-app call surface builder', () {
    final sl = GetIt.asNewInstance();

    expect(
      QuranSessionsRtcWiring.buildInAppCallSurface(sl: sl),
      isNull,
    );
  });
}

class _NoopTokenProvider implements CallTokenProvider {
  @override
  Future<RtcJoinCredentials> fetchCredentials({
    required String sessionId,
    required String userId,
    bool forceTakeover = false,
  }) async => const RtcJoinCredentials(
    token: 'token',
    channelId: 'room',
    uid: 1,
    appId: 'app',
  );
}
