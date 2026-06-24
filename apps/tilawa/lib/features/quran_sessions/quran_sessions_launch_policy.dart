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
/// When [distribution] is `staging`, Agora is enabled with [kStagingAgoraAppId]
/// unless explicit dart-defines override — so `flutter build apk --release`
/// with only `TILAWA_DISTRIBUTION=staging` can join Agora sessions.
RtcLaunchConfig resolveRtcLaunchConfig(
  AppLaunchConfig config, {
  String distribution = const String.fromEnvironment(
    'TILAWA_DISTRIBUTION',
    defaultValue: 'local',
  ),
}) {
  var enabledCsv = config.enabledCallProvidersCsv;
  var agoraAppId = config.agoraAppId;

  if (distribution == 'staging') {
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
SessionCallProviderKind resolveVoiceVideoProviderHint(AppLaunchConfig config) {
  final rtc = resolveRtcLaunchConfig(config);
  if (rtc.isAgoraEnabled) {
    return SessionCallProviderKind.agora;
  }
  if (rtc.isWebRtcEnabled &&
      config.webrtcSignalingServerUrl.trim().isNotEmpty) {
    return SessionCallProviderKind.webrtc;
  }
  return SessionCallProviderKind.mock;
}

/// Booking UI policy derived from [AppLaunchConfig] RTC flags.
SessionModePolicy sessionModePolicyFromLaunchConfig(AppLaunchConfig config) {
  final hint = resolveVoiceVideoProviderHint(config);
  return SessionModePolicy(
    voiceVideoUseMockProvider: hint == SessionCallProviderKind.mock,
  );
}
