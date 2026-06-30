import 'package:flutter/material.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa/core/bootstrap/app_launch_config.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/features/quran_sessions/debug/quran_sessions_debug_tools.dart';
import 'package:tilawa/features/quran_sessions/quran_sessions_launch_policy.dart';
import 'package:tilawa/features/quran_sessions/router/quran_sessions_nav.dart';

/// Joins the fixed debug LiveKit room and opens [InAppCallShellScreen].
///
/// Requires signed-in user, LiveKit wired in DI, and
/// [isQuranSessionsDebugToolsVisible].
Future<void> joinDebugLiveKitVideoCall(BuildContext context) async {
  if (!isQuranSessionsDebugToolsVisible()) {
    throw StateError('Debug LiveKit join is disabled for this build.');
  }

  final rtc = resolveRtcLaunchConfig(getIt<AppLaunchConfig>());
  if (!rtc.isLiveKitEnabled) {
    throw StateError(
      'LiveKit is not enabled. Set TILAWA_LAUNCH_ENABLED_CALL_PROVIDERS '
      'to include livekit and configure TILAWA_LAUNCH_LIVEKIT_URL.',
    );
  }

  if (!getIt.isRegistered<SessionCallProvider>()) {
    throw StateError('SessionCallProvider is not registered.');
  }

  final provider = getIt<SessionCallProvider>();
  await provider.join(
    const CallJoinRequest(
      sessionId: kDebugLiveKitSessionId,
      role: SessionParticipantRole.student,
      callType: SessionCallType.videoCall,
      providerKind: SessionCallProviderKind.livekit,
      providerSessionId: kDebugLiveKitRoomName,
    ),
  );

  if (!context.mounted) {
    return;
  }

  await pushInAppCallShell(
    context,
    sessionId: kDebugLiveKitSessionId,
    callType: SessionCallType.videoCall,
    callProviderKind: SessionCallProviderKind.livekit,
    participantName: 'Debug LiveKit',
    participantSubtitle: 'QA smoke test',
    buildCallSurface: buildQuranSessionsInAppCallSurface(),
    createCallControlGateway: createQuranSessionsCallControlGateway,
    createCallTelemetry: createQuranSessionsCallTelemetry,
  );
}
