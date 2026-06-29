import 'package:cloud_functions/cloud_functions.dart';
import 'package:get_it/get_it.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:quran_sessions_rtc/quran_sessions_rtc.dart';
import 'package:tilawa/core/bootstrap/app_launch_config.dart';
import 'package:tilawa/core/di/get_it_idempotent.dart';
import 'package:tilawa/features/auth/domain/services/callable_session_payload_builder.dart';
import 'package:tilawa/features/quran_sessions/data/external_meeting_url_launcher.dart';
import 'package:tilawa/features/quran_sessions/data/firebase/firebase_call_token_provider.dart';
import 'package:tilawa/features/quran_sessions/quran_sessions_launch_policy.dart';

/// Wires RTC [SessionCallProvider] implementations when launch config enables them.
class QuranSessionsRtcModule {
  QuranSessionsRtcModule._();

  static SessionCallProvider buildRoutingProvider(
    GetIt sl,
    AppLaunchConfig config,
  ) {
    final rtc = resolveRtcLaunchConfig(config);
    final eventHub = sl.isRegistered<SessionCallProviderEventHub>()
        ? sl<SessionCallProviderEventHub>()
        : null;

    SessionCallProvider? agora;
    if (rtc.isAgoraEnabled) {
      final enginePool = sl<AgoraRtcEnginePool>();
      agora = AgoraCallProvider(
        appId: rtc.agoraAppId,
        tokenProvider: sl<CallTokenProvider>(),
        resolveUserId: () async {
          final uid = sl<AuthSessionProvider>().currentUserId;
          if (uid == null || uid.isEmpty) {
            throw const UnauthorizedFailure();
          }
          return uid;
        },
        enginePool: enginePool,
        eventHub: eventHub,
      );
    }

    SessionCallProvider? livekit;
    if (rtc.enabledProviders.contains('livekit')) {
      livekit = LiveKitCallProvider(
        serverUrl: rtc.livekitServerUrl,
        tokenProvider: sl<CallTokenProvider>(),
        resolveUserId: () async {
          final uid = sl<AuthSessionProvider>().currentUserId;
          if (uid == null || uid.isEmpty) {
            throw const UnauthorizedFailure();
          }
          return uid;
        },
        roomPool: sl<LiveKitRoomPool>(),
        eventHub: eventHub,
      );
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
    final rtc = resolveRtcLaunchConfig(config);
    final needsTokenProvider =
        rtc.isAgoraEnabled || rtc.enabledProviders.contains('livekit');
    if (needsTokenProvider) {
      sl.registerLazySingletonIfAbsent<CallTokenProvider>(
        () => FirebaseCallTokenProvider(
          sl<CallableSessionPayloadBuilder>(),
          functions: FirebaseFunctions.instanceFor(region: 'us-central1'),
        ),
      );
    }
    if (rtc.isAgoraEnabled) {
      sl.registerLazySingletonIfAbsent<AgoraRtcEnginePool>(
        () => AgoraRtcEnginePool(),
      );
    }
    if (rtc.enabledProviders.contains('livekit')) {
      sl.registerLazySingletonIfAbsent<LiveKitRoomPool>(
        () => LiveKitRoomPool(),
      );
    }
  }
}
