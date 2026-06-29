import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa/core/telemetry/distribution_config.dart';

/// Well-known session id for QA LiveKit smoke tests (no Firestore session doc).
///
/// Token minting uses the `issueDebugLiveKitToken` callable (auth + non-production
/// only). LiveKit room name: [kDebugLiveKitRoomName].
const String kDebugLiveKitSessionId = 'debug-livekit-test';

/// Deterministic LiveKit room for debug joins — must match Cloud Function
/// [DEBUG_LIVEKIT_ROOM_NAME] in `issueDebugLiveKitToken.ts`.
const String kDebugLiveKitRoomName = 'debug-livekit-test';

/// Toast when [issueDebugLiveKitToken] is missing on the Firebase project.
const String kDebugLiveKitCallableNotDeployedMessage =
    'Deploy issueDebugLiveKitToken Cloud Function '
    '(firebase deploy --only functions:issueDebugLiveKitToken)';

/// Toast when the debug callable rejects the caller (signed out or stale auth).
const String kDebugLiveKitAuthRequiredMessage =
    'Sign in again to test LiveKit. Firebase Auth session may have expired.';

/// Maps [issueDebugLiveKitToken] callable errors for QA debug joins only.
RtcCallJoinFailure mapDebugLiveKitTokenCallableFailure(
  FirebaseFunctionsException error,
) {
  return switch (error.code) {
    'not-found' => const RtcCallJoinFailure(
      reasonCode: 'debug_callable_not_deployed',
    ),
    'unauthenticated' || 'permission-denied' => const RtcCallJoinFailure(
      reasonCode: 'debug_callable_unauthorized',
    ),
    _ => const RtcCallJoinFailure(reasonCode: 'debug_callable_failed'),
  };
}

/// Whether QA/debug LiveKit tooling may appear in the app UI.
///
/// Visible in debug builds or staging distribution builds — never in
/// `play_production` release builds.
bool isQuranSessionsDebugToolsVisible({
  bool debugMode = kDebugMode,
  String distribution = DistributionConfig.distribution,
}) {
  if (debugMode) {
    return true;
  }
  return distribution == 'staging';
}
