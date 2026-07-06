import 'package:flutter/foundation.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa/core/bootstrap/app_launch_config.dart';
import 'package:tilawa/features/quran_sessions/domain/entities/quran_sessions_platform_config.dart';

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

RtcLaunchConfig resolveRtcLaunchConfigFromPlatformConfig(
  QuranSessionsPlatformConfig platformConfig,
  AppLaunchConfig launchConfig, {
  String distribution = const String.fromEnvironment(
    'TILAWA_DISTRIBUTION',
    defaultValue: 'local',
  ),
  bool debugMode = kDebugMode,
}) {
  var agoraAppId = launchConfig.agoraAppId;
  var livekitServerUrl = launchConfig.livekitServerUrl;
  final enabledProviders = platformConfig.enabledCallProviders;

  if (distribution == 'staging' || debugMode) {
    if (agoraAppId.trim().isEmpty && enabledProviders.contains('agora')) {
      agoraAppId = kStagingAgoraAppId;
    }
    if (livekitServerUrl.trim().isEmpty &&
        enabledProviders.contains('livekit')) {
      livekitServerUrl = kStagingLiveKitUrl;
    }
  }

  return RtcLaunchConfig(
    enabledProviders: enabledProviders,
    agoraAppId: agoraAppId.trim(),
    livekitServerUrl: livekitServerUrl.trim(),
  );
}

/// Client RTC provider for voice/video bookings (UI hint; server is authoritative).
SessionCallProviderKind resolveVoiceVideoProviderHintFromPlatformConfig(
  QuranSessionsPlatformConfig platformConfig,
  AppLaunchConfig launchConfig, {
  String distribution = const String.fromEnvironment(
    'TILAWA_DISTRIBUTION',
    defaultValue: 'local',
  ),
  bool debugMode = kDebugMode,
}) {
  final rtc = resolveRtcLaunchConfigFromPlatformConfig(
    platformConfig,
    launchConfig,
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

SessionModePolicy sessionModePolicyFromPlatformConfig(
  QuranSessionsPlatformConfig platformConfig,
  AppLaunchConfig launchConfig, {
  String distribution = const String.fromEnvironment(
    'TILAWA_DISTRIBUTION',
    defaultValue: 'local',
  ),
  bool debugMode = kDebugMode,
}) {
  final hint = resolveVoiceVideoProviderHintFromPlatformConfig(
    platformConfig,
    launchConfig,
    distribution: distribution,
    debugMode: debugMode,
  );
  return SessionModePolicy(
    enabledCallTypes: const {SessionCallType.videoCall},
    voiceVideoUseMockProvider: hint == SessionCallProviderKind.mock,
  );
}
