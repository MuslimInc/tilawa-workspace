import '../../domain/entities/call_join_request.dart';
import '../../domain/entities/session_call_provider_kind.dart';
import '../../domain/entities/session_call_type.dart';
import '../../domain/entities/session_participant_role.dart';
import '../../domain/failures/quran_sessions_failure.dart';
import 'call_provider.dart';
import 'call_room.dart';
import 'session_call_provider.dart';

/// MVP call provider — opens an external meeting link (Zoom, Google Meet, etc.)
/// supplied by the teacher when creating the session.
///
/// No SDK required. The [urlLauncher] callback lets the app inject
/// `url_launcher` without this package depending on it.
class ExternalMeetingCallProvider implements SessionCallProvider, CallProvider {
  const ExternalMeetingCallProvider({
    required this.getMeetingUrl,
    required this.urlLauncher,
  });

  /// Returns the external URL for [sessionId]. Typically reads from
  /// [SessionRepository].
  final Future<String> Function(String sessionId) getMeetingUrl;

  /// Opens the URL. Inject `launchUrl` from `url_launcher`.
  final Future<void> Function(String url) urlLauncher;

  @override
  Future<CallRoom> join(CallJoinRequest request) async {
    if (request.providerKind != SessionCallProviderKind.external) {
      throw const CallProviderUnavailableFailure();
    }
    final url = (request.joinUrl?.trim().isNotEmpty ?? false)
        ? request.joinUrl!.trim()
        : await getMeetingUrl(request.sessionId);
    if (url.isEmpty) {
      throw const MeetingLinkUnavailableFailure();
    }
    await urlLauncher(url);
    return CallRoom(sessionId: request.sessionId, meetingUrl: url);
  }

  @override
  Future<CallRoom> joinSession(String sessionId) => join(
    CallJoinRequest(
      sessionId: sessionId,
      role: SessionParticipantRole.student,
      callType: SessionCallType.externalMeeting,
      providerKind: SessionCallProviderKind.external,
    ),
  );

  @override
  Future<void> leaveSession(String sessionId) async {
    // Nothing to do — the external app manages the call lifecycle.
  }

  @override
  Future<void> endSession(String sessionId) async {
    // Nothing to do — teacher ends the call in the external app.
  }

  @override
  Future<void> setMicrophoneMuted(
    String sessionId, {
    required bool muted,
  }) async {}
}
