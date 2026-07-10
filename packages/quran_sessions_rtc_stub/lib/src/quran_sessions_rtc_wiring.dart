import 'package:get_it/get_it.dart';
import 'package:quran_sessions/quran_sessions.dart';

/// Stub wiring when [quran_sessions_rtc_sdk] is excluded from the dependency graph.
class QuranSessionsRtcWiring {
  QuranSessionsRtcWiring._();

  /// Whether native RTC SDK implementations are linked into this build.
  static const bool hasNativeSdks = false;

  static void registerPools(
    GetIt sl, {
    required bool registerAgora,
    required bool registerLivekit,
  }) {}

  static SessionCallProvider? createAgoraProvider(
    GetIt sl, {
    required String appId,
    required CallTokenProvider tokenProvider,
    required Future<String> Function() resolveUserId,
    SessionCallProviderEventHub? eventHub,
  }) => null;

  static SessionCallProvider? createLiveKitProvider(
    GetIt sl, {
    required String serverUrl,
    required CallTokenProvider tokenProvider,
    required Future<String> Function() resolveUserId,
    SessionCallProviderEventHub? eventHub,
  }) => null;

  static InAppCallSurfaceBuilder? buildInAppCallSurface({
    required GetIt sl,
    SessionCallProviderEventHub? eventHub,
  }) => null;
}
