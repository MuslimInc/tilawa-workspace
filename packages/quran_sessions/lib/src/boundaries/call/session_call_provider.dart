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
}
