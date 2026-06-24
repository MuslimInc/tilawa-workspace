import 'session_call_provider.dart';

/// In-call media controls for one active session.
///
/// Presentation uses this port; implementations delegate to [SessionCallProvider].
abstract interface class SessionCallControlGateway {
  Future<void> setMicrophoneEnabled({required bool enabled});

  Future<void> setCameraEnabled({required bool enabled});

  Future<void> switchCamera();

  Future<void> setSpeakerEnabled({required bool enabled});

  Future<void> leave();
}

/// Adapts [SessionCallProvider] to [SessionCallControlGateway] for a session id.
class SessionCallControlGatewayAdapter implements SessionCallControlGateway {
  const SessionCallControlGatewayAdapter({
    required this._provider,
    required this._sessionId,
  });

  final SessionCallProvider _provider;
  final String _sessionId;

  @override
  Future<void> setMicrophoneEnabled({required bool enabled}) =>
      _provider.setMicrophoneEnabled(_sessionId, enabled: enabled);

  @override
  Future<void> setCameraEnabled({required bool enabled}) =>
      _provider.setCameraEnabled(_sessionId, enabled: enabled);

  @override
  Future<void> switchCamera() => _provider.switchCamera(_sessionId);

  @override
  Future<void> setSpeakerEnabled({required bool enabled}) =>
      _provider.setSpeakerEnabled(_sessionId, enabled: enabled);

  @override
  Future<void> leave() => _provider.leaveSession(_sessionId);
}
