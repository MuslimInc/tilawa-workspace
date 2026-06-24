import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa/features/auth/domain/services/callable_session_payload_builder.dart';

/// Sends call telemetry via [recordCallTelemetryEvent] Cloud Function.
class FirebaseCallTelemetryGateway implements QuranSessionCallTelemetryGateway {
  FirebaseCallTelemetryGateway(
    this._payloadBuilder, {
    this._functions,
    @visibleForTesting this.recordEventInvoker,
  });

  final FirebaseFunctions? _functions;
  final CallableSessionPayloadBuilder _payloadBuilder;
  final Future<Map<String, dynamic>> Function(Map<String, dynamic> payload)?
  recordEventInvoker;

  @override
  Future<void> recordEvent(QuranSessionCallTelemetryEvent event) async {
    final payload = await _payloadBuilder.withSessionEpoch({
      'sessionId': event.sessionId,
      'eventId': event.eventId,
      'eventType': event.type.name,
      'actorRole': event.actorRole.name,
      'clientTimestampMs': event.clientTimestampMs,
      if (event.reasonCode != null) 'reasonCode': event.reasonCode,
      if (event.remoteParticipantId != null)
        'remoteParticipantId': event.remoteParticipantId,
      if (event.networkQuality != null) 'networkQuality': event.networkQuality,
      if (event.metadata.isNotEmpty) 'metadata': event.metadata,
    });

    final invoker = recordEventInvoker;
    if (invoker != null) {
      await invoker(payload);
      return;
    }

    final functions = _functions;
    if (functions == null) {
      throw StateError(
        'FirebaseCallTelemetryGateway requires FirebaseFunctions when '
        'recordEventInvoker is unset.',
      );
    }
    await functions
        .httpsCallable('recordCallTelemetryEvent')
        .call<Map<String, dynamic>>(payload);
  }
}
