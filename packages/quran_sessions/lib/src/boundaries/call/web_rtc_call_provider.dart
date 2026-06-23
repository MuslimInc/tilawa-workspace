import '../../domain/entities/call_join_request.dart';
import 'call_provider.dart';
import 'call_room.dart';
import 'call_token_provider.dart';
import 'session_call_provider.dart';

/// Placeholder for V4 custom WebRTC integration.
///
/// ⚠️  Only pursue this if Agora pricing or vendor lock-in becomes a blocker.
/// ⚠️  DO NOT add `flutter_webrtc` as a dependency until V4 is scoped.
///
/// When implementing:
/// 1. Add `flutter_webrtc` (or equivalent) to pubspec.yaml.
/// 2. Add signalling server integration (WebSocket / SFU).
/// 3. Replace the [UnimplementedError] bodies.
class WebRtcCallProvider implements SessionCallProvider, CallProvider {
  const WebRtcCallProvider({
    required this.tokenProvider,
    required this.signalingServerUrl,
  });

  final CallTokenProvider tokenProvider;
  final String signalingServerUrl;

  @override
  Future<CallRoom> join(CallJoinRequest request) => throw UnimplementedError(
    'WebRtcCallProvider.join — V4 not yet implemented',
  );

  @override
  Future<CallRoom> joinSession(String sessionId) => throw UnimplementedError(
    'WebRtcCallProvider.joinSession — V4 not yet implemented',
  );

  @override
  Future<void> leaveSession(String sessionId) => throw UnimplementedError(
    'WebRtcCallProvider.leaveSession — V4 not yet implemented',
  );

  @override
  Future<void> endSession(String sessionId) => throw UnimplementedError(
    'WebRtcCallProvider.endSession — V4 not yet implemented',
  );
}
