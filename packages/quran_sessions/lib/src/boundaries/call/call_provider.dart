import 'call_room.dart';

/// Abstracts in-app voice/video call initiation.
///
/// MVP: injected as [ExternalMeetingCallProvider] (just opens a URL).
/// V2:  injected as [AgoraCallProvider].
/// V3:  injected as [WebRtcCallProvider].
///
/// This package never imports Agora, WebRTC, or any call SDK directly.
abstract interface class CallProvider {
  /// Joins or creates a call room for the given [sessionId].
  Future<CallRoom> joinSession(String sessionId);

  /// Leaves the call without ending it for the other participant.
  Future<void> leaveSession(String sessionId);

  /// Ends the call for all participants.
  Future<void> endSession(String sessionId);
}
