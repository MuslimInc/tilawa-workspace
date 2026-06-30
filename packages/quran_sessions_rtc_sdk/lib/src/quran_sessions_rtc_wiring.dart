import 'package:get_it/get_it.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:quran_sessions_rtc/quran_sessions_rtc.dart';

import 'boundaries/call/agora_call_provider.dart';
import 'boundaries/call/agora_rtc_engine_pool.dart';
import 'boundaries/call/livekit_call_provider.dart';
import 'boundaries/call/livekit_room_pool.dart';
import 'presentation/agora_call_surface.dart';
import 'presentation/livekit_call_surface.dart';

/// Registers Agora/LiveKit pools and builds in-app call surfaces.
class QuranSessionsRtcWiring {
  QuranSessionsRtcWiring._();

  /// Whether native RTC SDK implementations are linked into this build.
  static const bool hasNativeSdks = true;

  static void registerPools(
    GetIt sl, {
    required bool registerAgora,
    required bool registerLivekit,
  }) {
    if (registerAgora && !sl.isRegistered<AgoraRtcEnginePool>()) {
      sl.registerLazySingleton<AgoraRtcEnginePool>(() => AgoraRtcEnginePool());
    }
    if (registerLivekit && !sl.isRegistered<LiveKitRoomPool>()) {
      sl.registerLazySingleton<LiveKitRoomPool>(() => LiveKitRoomPool());
    }
  }

  static SessionCallProvider? createAgoraProvider(
    GetIt sl, {
    required String appId,
    required CallTokenProvider tokenProvider,
    required Future<String> Function() resolveUserId,
    SessionCallProviderEventHub? eventHub,
  }) {
    if (appId.trim().isEmpty || !sl.isRegistered<AgoraRtcEnginePool>()) {
      return null;
    }
    return AgoraCallProvider(
      appId: appId,
      tokenProvider: tokenProvider,
      resolveUserId: resolveUserId,
      enginePool: sl<AgoraRtcEnginePool>(),
      eventHub: eventHub,
    );
  }

  static SessionCallProvider? createLiveKitProvider(
    GetIt sl, {
    required String serverUrl,
    required CallTokenProvider tokenProvider,
    required Future<String> Function() resolveUserId,
    SessionCallProviderEventHub? eventHub,
  }) {
    if (serverUrl.trim().isEmpty || !sl.isRegistered<LiveKitRoomPool>()) {
      return null;
    }
    return LiveKitCallProvider(
      serverUrl: serverUrl,
      tokenProvider: tokenProvider,
      resolveUserId: resolveUserId,
      roomPool: sl<LiveKitRoomPool>(),
      eventHub: eventHub,
    );
  }

  static InAppCallSurfaceBuilder? buildInAppCallSurface({
    required GetIt sl,
    required AgoraCallSurfaceLabels labels,
    SessionCallProviderEventHub? eventHub,
  }) {
    return (
      context, {
      required sessionId,
      required callType,
      required callProviderKind,
    }) {
      if (sl.isRegistered<LiveKitRoomPool>()) {
        final livekitSurface = buildLiveKitCallSurface(
          sessionId: sessionId,
          callType: callType,
          providerKind: callProviderKind,
          roomPool: sl<LiveKitRoomPool>(),
          labels: labels,
          eventHub: eventHub,
        );
        if (livekitSurface != null) {
          return livekitSurface;
        }
      }

      if (!sl.isRegistered<AgoraRtcEnginePool>()) {
        return null;
      }
      return buildAgoraCallSurface(
        sessionId: sessionId,
        callType: callType,
        providerKind: callProviderKind,
        enginePool: sl<AgoraRtcEnginePool>(),
        eventHub: eventHub,
        labels: labels,
      );
    };
  }
}
