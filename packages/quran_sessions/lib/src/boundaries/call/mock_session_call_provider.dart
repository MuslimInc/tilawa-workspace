import 'package:flutter/foundation.dart';

import '../../domain/entities/call_join_request.dart';
import '../../domain/entities/session_call_provider_kind.dart';
import '../../domain/entities/session_call_provider_event.dart';
import '../../domain/entities/session_participant_role.dart';
import 'call_room.dart';
import 'session_call_provider.dart';
import 'session_call_provider_event_hub.dart';

class _MockInCallControlState {
  bool microphoneEnabled = true;
  bool cameraEnabled = true;
  bool speakerEnabled = false;
}

/// Free Beta placeholder for in-app voice/video until Agora/WebRTC ships.
class MockSessionCallProvider implements SessionCallProvider {
  const MockSessionCallProvider({this.onJoin, this.eventHub});

  final void Function(CallJoinRequest request)? onJoin;
  final SessionCallProviderEventHub? eventHub;

  static final Map<String, _MockInCallControlState> _controlState =
      <String, _MockInCallControlState>{};

  static _MockInCallControlState _stateFor(String sessionId) =>
      _controlState.putIfAbsent(sessionId, _MockInCallControlState.new);

  @visibleForTesting
  static void resetControlState() => _controlState.clear();

  @override
  Future<CallRoom> join(CallJoinRequest request) async {
    onJoin?.call(request);
    final channelId = request.providerSessionId ?? request.sessionId;
    eventHub?.emit(
      SessionCallLocalChannelJoined(sessionId: request.sessionId),
    );
    eventHub?.emit(
      SessionCallParticipantConnected(
        sessionId: request.sessionId,
        remoteParticipantId: request.role == SessionParticipantRole.teacher
            ? 'mock_remote_student'
            : 'mock_remote_teacher',
      ),
    );
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
  Future<void> leaveSession(String sessionId) async {
    _controlState.remove(sessionId);
  }

  @override
  Future<void> endSession(String sessionId) async {
    _controlState.remove(sessionId);
  }

  @override
  Future<void> setMicrophoneMuted(
    String sessionId, {
    required bool muted,
  }) => setMicrophoneEnabled(sessionId, enabled: !muted);

  @override
  Future<void> setMicrophoneEnabled(
    String sessionId, {
    required bool enabled,
  }) async {
    _stateFor(sessionId).microphoneEnabled = enabled;
  }

  @override
  Future<void> setCameraEnabled(
    String sessionId, {
    required bool enabled,
  }) async {
    _stateFor(sessionId).cameraEnabled = enabled;
  }

  @override
  Future<void> switchCamera(String sessionId) async {}

  @override
  Future<void> setSpeakerEnabled(
    String sessionId, {
    required bool enabled,
  }) async {
    _stateFor(sessionId).speakerEnabled = enabled;
  }
}
