import '../../domain/entities/call_join_request.dart';
import 'call_room.dart';

/// Domain boundary for joining voice, video, or external meetings.
///
/// Implementations live in `boundaries/call/` and are injected by the host app.
/// Booking use cases never import Agora, WebRTC, or `url_launcher`.
abstract interface class SessionCallProvider {
  Future<CallRoom> join(CallJoinRequest request);

  Future<void> leaveSession(String sessionId);

  Future<void> endSession(String sessionId);

  /// Mutes or unmutes the local microphone for an active in-app call.
  ///
  /// No-op for external/mock providers until a session is joined in-app.
  Future<void> setMicrophoneMuted(
    String sessionId, {
    required bool muted,
  });
}
