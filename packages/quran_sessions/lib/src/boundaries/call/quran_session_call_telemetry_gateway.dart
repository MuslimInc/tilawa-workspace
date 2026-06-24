import '../../domain/entities/quran_session_call_telemetry_event.dart';

/// Persists call telemetry without blocking the join/control path.
abstract interface class QuranSessionCallTelemetryGateway {
  Future<void> recordEvent(QuranSessionCallTelemetryEvent event);
}

/// No-op gateway for hosts/tests without backend telemetry.
class NoopQuranSessionCallTelemetryGateway
    implements QuranSessionCallTelemetryGateway {
  const NoopQuranSessionCallTelemetryGateway();

  @override
  Future<void> recordEvent(QuranSessionCallTelemetryEvent event) async {}
}

/// In-memory gateway for unit tests and MVP offline mode.
class InMemoryCallTelemetryGateway implements QuranSessionCallTelemetryGateway {
  final List<QuranSessionCallTelemetryEvent> recorded = [];

  @override
  Future<void> recordEvent(QuranSessionCallTelemetryEvent event) async {
    recorded.add(event);
  }

  void clear() => recorded.clear();
}
