import '../../domain/entities/call_join_request.dart';
import '../../domain/entities/session_call_provider_kind.dart';
import 'call_room.dart';
import 'session_call_provider.dart';

/// Free Beta placeholder for in-app voice/video until Agora/WebRTC ships.
class MockSessionCallProvider implements SessionCallProvider {
  const MockSessionCallProvider({this.onJoin});

  final void Function(CallJoinRequest request)? onJoin;

  @override
  Future<CallRoom> join(CallJoinRequest request) async {
    onJoin?.call(request);
    final channelId = request.providerSessionId ?? request.sessionId;
    return CallRoom(
      sessionId: request.sessionId,
      channelId: channelId,
      token: request.joinToken,
      extraData: {
        'providerKind': SessionCallProviderKind.mock.name,
        'callType': request.callType.name,
        'role': request.role.name,
        'betaPlaceholder': true,
      },
    );
  }

  @override
  Future<void> leaveSession(String sessionId) async {}

  @override
  Future<void> endSession(String sessionId) async {}
}
