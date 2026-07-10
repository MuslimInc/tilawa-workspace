import 'session_call_provider_kind.dart';
import 'session_call_type.dart';
import 'session_participant_role.dart';

/// Inputs required to join a session through a [SessionCallProvider].
///
/// Join tokens and channel ids are resolved server-side; the client never
/// fabricates credentials.
class CallJoinRequest {
  const CallJoinRequest({
    required this.sessionId,
    required this.role,
    required this.callType,
    required this.providerKind,
    this.joinUrl,
    this.providerSessionId,
    this.joinToken,
    this.forceTakeover = false,
  });

  final String sessionId;
  final SessionParticipantRole role;
  final SessionCallType callType;
  final SessionCallProviderKind providerKind;

  /// External meeting URL when [providerKind] is [SessionCallProviderKind.external].
  final String? joinUrl;

  /// Provider room / channel id (server-issued).
  final String? providerSessionId;

  /// Short-lived join token (server-issued only).
  final String? joinToken;

  /// ADR-008 Phase 2: user-initiated takeover of the caller's own other
  /// device for a live session. False for normal joins.
  final bool forceTakeover;
}
