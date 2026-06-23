import 'call_room.dart';

/// Abstracts in-app voice/video call initiation.
///
/// MVP: [ExternalMeetingCallProvider] opens a URL.
/// Production RTC: register Agora/WebRTC implementations from
/// `quran_sessions_rtc` in [RoutingSessionCallProvider] via DI.
abstract interface class CallProvider {
  /// Joins or creates a call room for the given [sessionId].
  Future<CallRoom> joinSession(String sessionId);

  /// Leaves the call without ending it for the other participant.
  Future<void> leaveSession(String sessionId);

  /// Ends the call for all participants.
  Future<void> endSession(String sessionId);
}
