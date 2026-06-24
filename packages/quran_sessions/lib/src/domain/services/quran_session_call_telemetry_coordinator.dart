import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../boundaries/call/quran_session_call_telemetry_gateway.dart';
import '../../boundaries/call/session_call_provider_event_hub.dart';
import '../../domain/entities/quran_session_call_telemetry_event.dart';
import '../../domain/entities/session_call_provider_event.dart';
import '../../domain/entities/session_participant_role.dart';

/// Non-blocking call telemetry: idempotent events, deduped joins, retry queue.
class QuranSessionCallTelemetryCoordinator {
  QuranSessionCallTelemetryCoordinator({
    required this._gateway,
    this._eventHub,
    this._networkThrottle = const Duration(seconds: 60),
    @visibleForTesting DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final QuranSessionCallTelemetryGateway _gateway;
  final SessionCallProviderEventHub? _eventHub;
  final Duration _networkThrottle;
  final DateTime Function() _clock;

  final Set<String> _recordedEventIds = <String>{};
  final List<QuranSessionCallTelemetryEvent> _pending = [];
  bool _flushInProgress = false;
  StreamSubscription<SessionCallProviderEvent>? _providerSubscription;

  String? _activeSessionId;
  String? _activeActorId;
  SessionParticipantRole? _activeActorRole;
  DateTime? _lastNetworkTelemetryAt;
  int _reconnectSequence = 0;

  void bindSession({
    required String sessionId,
    required String actorId,
    required SessionParticipantRole actorRole,
  }) {
    _activeSessionId = sessionId;
    _activeActorId = actorId;
    _activeActorRole = actorRole;
    _reconnectSequence = 0;
    _providerSubscription?.cancel();
    final hub = _eventHub;
    if (hub == null) {
      return;
    }
    _providerSubscription = hub
        .streamFor(sessionId)
        .listen(
          _onProviderEvent,
          onError: (_) {},
        );
  }

  void unbindSession() {
    _providerSubscription?.cancel();
    _providerSubscription = null;
    _activeSessionId = null;
    _activeActorId = null;
    _activeActorRole = null;
    _reconnectSequence = 0;
    _lastNetworkTelemetryAt = null;
  }

  void recordJoinRequested({
    required String sessionId,
    required String actorId,
    required SessionParticipantRole actorRole,
  }) {
    _enqueue(
      _event(
        sessionId: sessionId,
        actorId: actorId,
        actorRole: actorRole,
        type: QuranSessionCallTelemetryEventType.joinRequested,
        semanticKey: 'joinRequested',
      ),
    );
  }

  void recordJoinSucceeded({
    required String sessionId,
    required String actorId,
    required SessionParticipantRole actorRole,
  }) {
    _enqueue(
      _event(
        sessionId: sessionId,
        actorId: actorId,
        actorRole: actorRole,
        type: QuranSessionCallTelemetryEventType.joinSucceeded,
        semanticKey: 'joinSucceeded',
      ),
    );
  }

  void recordJoinFailed({
    required String sessionId,
    required String actorId,
    required SessionParticipantRole actorRole,
    required String reasonCode,
  }) {
    _enqueue(
      _event(
        sessionId: sessionId,
        actorId: actorId,
        actorRole: actorRole,
        type: QuranSessionCallTelemetryEventType.joinFailed,
        semanticKey: 'joinFailed_$reasonCode',
        reasonCode: reasonCode,
      ),
    );
  }

  void recordLeave({
    required String sessionId,
    required String actorId,
    required SessionParticipantRole actorRole,
  }) {
    _enqueue(
      _event(
        sessionId: sessionId,
        actorId: actorId,
        actorRole: actorRole,
        type: QuranSessionCallTelemetryEventType.leave,
        semanticKey: 'leave',
      ),
    );
  }

  /// Records leave for the session bound via [bindSession].
  void recordLeaveForBoundSession() {
    final sessionId = _activeSessionId;
    final actorId = _activeActorId;
    final actorRole = _activeActorRole;
    if (sessionId == null || actorId == null || actorRole == null) {
      return;
    }
    recordLeave(
      sessionId: sessionId,
      actorId: actorId,
      actorRole: actorRole,
    );
  }

  void recordCallEnded({
    required String sessionId,
    required String actorId,
    required SessionParticipantRole actorRole,
  }) {
    _enqueue(
      _event(
        sessionId: sessionId,
        actorId: actorId,
        actorRole: actorRole,
        type: QuranSessionCallTelemetryEventType.callEnded,
        semanticKey: 'callEnded',
      ),
    );
  }

  void dispose() {
    unbindSession();
    _pending.clear();
    _recordedEventIds.clear();
  }

  void _onProviderEvent(SessionCallProviderEvent event) {
    final sessionId = _activeSessionId;
    final actorId = _activeActorId;
    final actorRole = _activeActorRole;
    if (sessionId == null || actorId == null || actorRole == null) {
      return;
    }
    if (event.sessionId != sessionId) {
      return;
    }

    switch (event) {
      case SessionCallParticipantConnected(:final remoteParticipantId):
        _enqueue(
          _event(
            sessionId: sessionId,
            actorId: actorId,
            actorRole: actorRole,
            type: QuranSessionCallTelemetryEventType.participantConnected,
            semanticKey: 'participantConnected_$remoteParticipantId',
            remoteParticipantId: remoteParticipantId,
          ),
        );
      case SessionCallParticipantDisconnected(:final remoteParticipantId):
        _enqueue(
          _event(
            sessionId: sessionId,
            actorId: actorId,
            actorRole: actorRole,
            type: QuranSessionCallTelemetryEventType.participantDisconnected,
            semanticKey: 'participantDisconnected_$remoteParticipantId',
            remoteParticipantId: remoteParticipantId,
          ),
        );
      case SessionCallReconnecting():
        _reconnectSequence += 1;
        _enqueue(
          _event(
            sessionId: sessionId,
            actorId: actorId,
            actorRole: actorRole,
            type: QuranSessionCallTelemetryEventType.reconnect,
            semanticKey: 'reconnect_$_reconnectSequence',
          ),
        );
      case SessionCallReconnected():
        _reconnectSequence += 1;
        _enqueue(
          _event(
            sessionId: sessionId,
            actorId: actorId,
            actorRole: actorRole,
            type: QuranSessionCallTelemetryEventType.reconnect,
            semanticKey: 'reconnect_$_reconnectSequence',
          ),
        );
      case SessionCallNetworkQualityChanged(:final level):
        final now = _clock();
        final last = _lastNetworkTelemetryAt;
        if (last != null && now.difference(last) < _networkThrottle) {
          return;
        }
        _lastNetworkTelemetryAt = now;
        final bucket =
            now.millisecondsSinceEpoch ~/ _networkThrottle.inMilliseconds;
        _enqueue(
          _event(
            sessionId: sessionId,
            actorId: actorId,
            actorRole: actorRole,
            type: QuranSessionCallTelemetryEventType.network,
            semanticKey: 'network_$bucket',
            networkQuality: level.name,
          ),
        );
      case SessionCallLocalChannelJoined():
        break;
    }
  }

  QuranSessionCallTelemetryEvent _event({
    required String sessionId,
    required String actorId,
    required SessionParticipantRole actorRole,
    required QuranSessionCallTelemetryEventType type,
    required String semanticKey,
    String? reasonCode,
    String? remoteParticipantId,
    String? networkQuality,
  }) {
    return QuranSessionCallTelemetryEvent(
      eventId: buildCallTelemetryEventId(
        sessionId: sessionId,
        actorId: actorId,
        semanticKey: semanticKey,
      ),
      sessionId: sessionId,
      actorId: actorId,
      actorRole: actorRole,
      type: type,
      clientTimestampMs: _clock().millisecondsSinceEpoch,
      reasonCode: reasonCode,
      remoteParticipantId: remoteParticipantId,
      networkQuality: networkQuality,
    );
  }

  void _enqueue(QuranSessionCallTelemetryEvent event) {
    if (!_recordedEventIds.add(event.eventId)) {
      return;
    }
    _pending.add(event);
    unawaited(_flushPending());
  }

  Future<void> _flushPending() async {
    if (_flushInProgress) {
      return;
    }
    _flushInProgress = true;
    while (_pending.isNotEmpty) {
      final event = _pending.first;
      try {
        await _gateway.recordEvent(event);
        _pending.removeAt(0);
      } on Object {
        _recordedEventIds.remove(event.eventId);
        break;
      }
    }
    _flushInProgress = false;
    if (_pending.isNotEmpty) {
      unawaited(_flushPending());
    }
  }

  @visibleForTesting
  int get pendingCount => _pending.length;

  @visibleForTesting
  bool get hasRecordedJoinSucceeded {
    return _recordedEventIds.any((id) => id.endsWith('_joinSucceeded'));
  }
}
