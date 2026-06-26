import 'package:flutter/foundation.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa/core/bootstrap/app_launch_config.dart';

/// Public Agora App ID for staging builds (token minting stays server-side).
const String kStagingAgoraAppId = 'aacd48a930944ecea29bec112f229eb9';

/// Effective RTC flags used to wire [SessionCallProvider] implementations.
class RtcLaunchConfig {
  const RtcLaunchConfig({
    required this.enabledProviders,
    required this.agoraAppId,
  });

  final Set<String> enabledProviders;
  final String agoraAppId;

  bool get isAgoraEnabled =>
      enabledProviders.contains('agora') && agoraAppId.trim().isNotEmpty;

  bool get isWebRtcEnabled => enabledProviders.contains('webrtc');
}

Set<String> parseEnabledCallProviders(AppLaunchConfig config) {
  if (config.enabledCallProvidersCsv.trim().isEmpty) {
    return {'external', 'mock'};
  }
  return config.enabledCallProvidersCsv
      .split(',')
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toSet();
}

/// Resolves client RTC wiring from [AppLaunchConfig] and build distribution.
///
/// When [distribution] is `staging` or [debugMode] is true, Agora is enabled
/// with [kStagingAgoraAppId] unless explicit dart-defines override — so
/// `flutter run` (debug) and `flutter build apk --release` with only
/// `TILAWA_DISTRIBUTION=staging` can join Agora sessions without extra defines.
RtcLaunchConfig resolveRtcLaunchConfig(
  AppLaunchConfig config, {
  String distribution = const String.fromEnvironment(
    'TILAWA_DISTRIBUTION',
    defaultValue: 'local',
  ),
  bool debugMode = kDebugMode,
}) {
  var enabledCsv = config.enabledCallProvidersCsv;
  var agoraAppId = config.agoraAppId;

  if (distribution == 'staging' || debugMode) {
    final enabled = parseEnabledCallProviders(
      AppLaunchConfig(enabledCallProvidersCsv: enabledCsv),
    );
    if (!enabled.contains('agora')) {
      final trimmed = enabledCsv.trim();
      enabledCsv = trimmed.isEmpty ? 'external,mock,agora' : '$trimmed,agora';
    }
    if (agoraAppId.trim().isEmpty) {
      agoraAppId = kStagingAgoraAppId;
    }
  }

  return RtcLaunchConfig(
    enabledProviders: parseEnabledCallProviders(
      AppLaunchConfig(enabledCallProvidersCsv: enabledCsv),
    ),
    agoraAppId: agoraAppId.trim(),
  );
}

/// Client RTC provider for voice/video bookings (UI hint; server is authoritative).
///
/// Mirrors [RTC_PROVIDER_PRIORITY] in Cloud Functions when launch config matches
/// Firestore `quran_session_platform_config/global.enabledCallProviders`.
///
/// Production (`play_production`) must set `agora` (or `webrtc`) in both
/// Firestore and `TILAWA_LAUNCH_*` defines — mock is a dev fallback only when
/// no RTC provider is configured with credentials.
SessionCallProviderKind resolveVoiceVideoProviderHint(
  AppLaunchConfig config, {
  String distribution = const String.fromEnvironment(
    'TILAWA_DISTRIBUTION',
    defaultValue: 'local',
  ),
  bool debugMode = kDebugMode,
}) {
  final rtc = resolveRtcLaunchConfig(
    config,
    distribution: distribution,
    debugMode: debugMode,
  );
  if (rtc.isAgoraEnabled) {
    return SessionCallProviderKind.agora;
  }
  if (rtc.isWebRtcEnabled &&
      config.webrtcSignalingServerUrl.trim().isNotEmpty) {
    return SessionCallProviderKind.webrtc;
  }
  return SessionCallProviderKind.mock;
}

/// Resolves effective tutor booking mode for client UI hints.
///
/// Server is authoritative on create; this drives pre-submit copy only.
QuranTutorBookingMode resolveQuranTutorBookingModeHint({
  AppLaunchConfig? launchConfig,
  String? firestoreModeRaw,
  String distribution = const String.fromEnvironment(
    'TILAWA_DISTRIBUTION',
    defaultValue: 'local',
  ),
  bool debugMode = kDebugMode,
}) {
  if (distribution != 'play_production' && debugMode) {
    const defineOverride = String.fromEnvironment(
      'TILAWA_LAUNCH_QURAN_TUTOR_BOOKING_MODE',
      defaultValue: '',
    );
    final fromDefine = QuranTutorBookingModeParsing.tryParse(
      defineOverride.isEmpty ? null : defineOverride,
    );
    if (fromDefine != null) {
      return fromDefine;
    }
  }
  final fromFirestore = QuranTutorBookingModeParsing.tryParse(
    firestoreModeRaw,
  );
  if (fromFirestore != null) {
    return fromFirestore;
  }
  return distributionDefaultQuranTutorBookingMode(distribution: distribution);
}

/// Booking UI policy derived from [AppLaunchConfig] RTC flags.
SessionModePolicy sessionModePolicyFromLaunchConfig(
  AppLaunchConfig config, {
  String distribution = const String.fromEnvironment(
    'TILAWA_DISTRIBUTION',
    defaultValue: 'local',
  ),
  bool debugMode = kDebugMode,
}) {
  final hint = resolveVoiceVideoProviderHint(
    config,
    distribution: distribution,
    debugMode: debugMode,
  );
  return SessionModePolicy(
    voiceVideoUseMockProvider: hint == SessionCallProviderKind.mock,
  );
}
