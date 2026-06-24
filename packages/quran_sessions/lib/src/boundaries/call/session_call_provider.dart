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

  /// Enables or disables the local microphone for an active in-app call.
  Future<void> setMicrophoneEnabled(
    String sessionId, {
    required bool enabled,
  });

  /// Enables or disables the local camera for an active video call.
  Future<void> setCameraEnabled(
    String sessionId, {
    required bool enabled,
  });

  /// Switches between front and back camera during a video call.
  Future<void> switchCamera(String sessionId);

  /// Routes audio to the device speaker or earpiece.
  Future<void> setSpeakerEnabled(
    String sessionId, {
    required bool enabled,
  });
}
