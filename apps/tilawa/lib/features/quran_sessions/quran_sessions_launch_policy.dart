import 'package:flutter/foundation.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa/core/bootstrap/app_launch_config.dart';

/// Public LiveKit server URL for staging builds (token minting stays server-side).
///
/// LiveKit Cloud project ID (console reference only): `p_2n1vvcqjfqy`.
const String kStagingLiveKitUrl = 'wss://tilawa-7whzug8z.livekit.cloud';

/// Public Agora App ID for staging builds (token minting stays server-side).
const String kStagingAgoraAppId = 'aacd48a930944ecea29bec112f229eb9';

/// Effective RTC flags used to wire [SessionCallProvider] implementations.
class RtcLaunchConfig {
  const RtcLaunchConfig({
    required this.enabledProviders,
    required this.agoraAppId,
    required this.livekitServerUrl,
  });

  final Set<String> enabledProviders;
  final String agoraAppId;
  final String livekitServerUrl;

  bool get isAgoraEnabled =>
      enabledProviders.contains('agora') && agoraAppId.trim().isNotEmpty;

  bool get isLiveKitEnabled =>
      enabledProviders.contains('livekit') &&
      livekitServerUrl.trim().isNotEmpty;
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
/// When [distribution] is `staging` or [debugMode] is true, LiveKit is enabled
/// by default unless explicit dart-defines override — so `flutter run` (debug)
/// and staging release builds can join LiveKit sessions without Agora defines.
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
  var livekitServerUrl = config.livekitServerUrl;

  if (distribution == 'staging' || debugMode) {
    var enabled = parseEnabledCallProviders(
      AppLaunchConfig(enabledCallProvidersCsv: enabledCsv),
    );
    if (!enabled.contains('livekit') && !enabled.contains('agora')) {
      final trimmed = enabledCsv.trim();
      enabledCsv = trimmed.isEmpty
          ? 'external,mock,livekit'
          : '$trimmed,livekit';
    }
    enabled = parseEnabledCallProviders(
      AppLaunchConfig(enabledCallProvidersCsv: enabledCsv),
    );
    if (agoraAppId.trim().isEmpty && enabled.contains('agora')) {
      agoraAppId = kStagingAgoraAppId;
    }
    if (livekitServerUrl.trim().isEmpty && enabled.contains('livekit')) {
      livekitServerUrl = kStagingLiveKitUrl;
    }
  }

  return RtcLaunchConfig(
    enabledProviders: parseEnabledCallProviders(
      AppLaunchConfig(enabledCallProvidersCsv: enabledCsv),
    ),
    agoraAppId: agoraAppId.trim(),
    livekitServerUrl: livekitServerUrl.trim(),
  );
}

/// Client RTC provider for voice/video bookings (UI hint; server is authoritative).
///
/// Mirrors [RTC_PROVIDER_PRIORITY] in Cloud Functions when launch config matches
/// Firestore `quran_session_platform_config/global.enabledCallProviders`.
///
/// Production (`play_production`) ships external + mock only; native Agora/LiveKit
/// are excluded from the release dependency graph via `configure_rtc_deps.dart`.
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
  if (rtc.isLiveKitEnabled) {
    return SessionCallProviderKind.livekit;
  }
  if (rtc.isAgoraEnabled) {
    return SessionCallProviderKind.agora;
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
