import 'package:cloud_functions/cloud_functions.dart';
import 'package:get_it/get_it.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa/core/bootstrap/app_launch_config.dart';
import 'package:tilawa/core/di/get_it_idempotent.dart';
import 'package:tilawa/features/auth/data/services/device_identity_service.dart';
import 'package:tilawa/features/auth/domain/services/callable_session_payload_builder.dart';
import 'package:tilawa/features/quran_sessions/data/external_meeting_url_launcher.dart';
import 'package:tilawa/features/quran_sessions/data/firebase/firebase_call_token_provider.dart';
import 'package:tilawa/features/quran_sessions/quran_sessions_feature_flags.dart';
import 'package:tilawa/features/quran_sessions/quran_sessions_launch_policy.dart';
import 'package:tilawa/features/quran_sessions/rtc/quran_sessions_rtc_impl.dart';

/// Wires RTC [SessionCallProvider] implementations when launch config enables them.
class QuranSessionsRtcModule {
  QuranSessionsRtcModule._();

  static InAppCallSurfaceBuilder? buildInAppCallSurfaceBuilder(GetIt sl) {
    if (!QuranSessionsRtcWiring.hasNativeSdks) {
      return null;
    }

    final eventHub = sl.isRegistered<SessionCallProviderEventHub>()
        ? sl<SessionCallProviderEventHub>()
        : null;

    return (
      context, {
      required sessionId,
      required callType,
      required callProviderKind,
    }) {
      final builder = QuranSessionsRtcWiring.buildInAppCallSurface(
        sl: sl,
        eventHub: eventHub,
      );
      return builder?.call(
        context,
        sessionId: sessionId,
        callType: callType,
        callProviderKind: callProviderKind,
      );
    };
  }

  static SessionCallProvider buildRoutingProvider(
    GetIt sl,
    AppLaunchConfig config,
  ) {
    final rtc = resolveRtcLaunchConfigFromPlatformConfig(
      quranSessionsEffectivePlatformConfig(),
      config,
    );
    final eventHub = sl.isRegistered<SessionCallProviderEventHub>()
        ? sl<SessionCallProviderEventHub>()
        : null;

    SessionCallProvider? agora;
    SessionCallProvider? livekit;
    if (rtc.isAgoraEnabled || rtc.isLiveKitEnabled) {
      final tokenProvider = sl<CallTokenProvider>();
      Future<String> resolveUserId() async {
        final uid = sl<AuthSessionProvider>().currentUserId;
        if (uid == null || uid.isEmpty) {
          throw const UnauthorizedFailure();
        }
        return uid;
      }

      if (rtc.isAgoraEnabled) {
        agora = QuranSessionsRtcWiring.createAgoraProvider(
          sl,
          appId: rtc.agoraAppId,
          tokenProvider: tokenProvider,
          resolveUserId: resolveUserId,
          eventHub: eventHub,
        );
      }
      if (rtc.isLiveKitEnabled) {
        livekit = QuranSessionsRtcWiring.createLiveKitProvider(
          sl,
          serverUrl: rtc.livekitServerUrl,
          tokenProvider: tokenProvider,
          resolveUserId: resolveUserId,
          eventHub: eventHub,
        );
      }
    }

    return RoutingSessionCallProvider(
      external: ExternalMeetingCallProvider(
        getMeetingUrl: (sessionId) async {
          final result = await sl<SessionRepository>().getSessionById(
            sessionId,
          );
          return result.fold(
            (_) => '',
            (session) => session.joinUrl ?? '',
          );
        },
        urlLauncher: launchExternalMeetingUrl,
      ),
      mock: MockSessionCallProvider(eventHub: eventHub),
      agora: agora,
      livekit: livekit,
    );
  }

  static void register(GetIt sl, AppLaunchConfig config) {
    final rtc = resolveRtcLaunchConfigFromPlatformConfig(
      quranSessionsEffectivePlatformConfig(),
      config,
    );
    final needsTokenProvider = rtc.isAgoraEnabled || rtc.isLiveKitEnabled;
    if (needsTokenProvider) {
      sl.registerLazySingletonIfAbsent<CallTokenProvider>(
        () => FirebaseCallTokenProvider(
          sl<CallableSessionPayloadBuilder>(),
          sl<DeviceIdentityService>(),
          functions: FirebaseFunctions.instanceFor(region: 'us-central1'),
        ),
      );
    }
    QuranSessionsRtcWiring.registerPools(
      sl,
      registerAgora: rtc.isAgoraEnabled,
      registerLivekit: rtc.isLiveKitEnabled,
    );
  }
}
