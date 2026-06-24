import 'session_call_control_gateway.dart';
import '../../domain/services/quran_session_call_telemetry_coordinator.dart';

/// Records leave telemetry without blocking media control actions.
class TelemetrySessionCallControlGateway implements SessionCallControlGateway {
  TelemetrySessionCallControlGateway({
    required this._inner,
    required this._telemetry,
  });

  final SessionCallControlGateway _inner;
  final QuranSessionCallTelemetryCoordinator _telemetry;

  @override
  Future<void> setMicrophoneEnabled({required bool enabled}) =>
      _inner.setMicrophoneEnabled(enabled: enabled);

  @override
  Future<void> setCameraEnabled({required bool enabled}) =>
      _inner.setCameraEnabled(enabled: enabled);

  @override
  Future<void> switchCamera() => _inner.switchCamera();

  @override
  Future<void> setSpeakerEnabled({required bool enabled}) =>
      _inner.setSpeakerEnabled(enabled: enabled);

  @override
  Future<void> leave() async {
    _telemetry.recordLeaveForBoundSession();
    await _inner.leave();
  }
}
