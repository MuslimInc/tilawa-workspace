import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../boundaries/call/quran_session_call_telemetry_gateway.dart';
import '../../boundaries/call/session_call_provider_event_hub.dart';
import '../entities/quran_session_call_telemetry_event.dart';
import '../entities/session_call_provider_event.dart';
import '../entities/session_participant_role.dart';

/// Event types that must not be dropped under queue pressure.
const Set<QuranSessionCallTelemetryEventType> _essentialTypes = {
  QuranSessionCallTelemetryEventType.joinRequested,
  QuranSessionCallTelemetryEventType.joinSucceeded,
  QuranSessionCallTelemetryEventType.joinFailed,
  QuranSessionCallTelemetryEventType.leave,
  QuranSessionCallTelemetryEventType.callEnded,
};

/// Event types considered noisy and eligible for eviction.
const Set<QuranSessionCallTelemetryEventType> _noisyTypes = {
  QuranSessionCallTelemetryEventType.network,
  QuranSessionCallTelemetryEventType.reconnect,
  QuranSessionCallTelemetryEventType.participantDisconnected,
};

/// Non-blocking call telemetry with production-grade retry,
/// deduplication, queue cap, and exponential backoff.
///
/// ## Key invariants
/// * Events in the dedupe map are **never removed on failure**,
///   preventing duplicate enqueues after backend errors.
/// * Failed events retry with bounded exponential backoff
///   (2 s → 4 s → 8 s → … → [_maxBackoff]).
/// * The pending queue is capped at [_maxQueueSize]; noisy events
///   are evicted first when an essential event needs room.
/// * Reconnect events are rate-limited to [_maxReconnectEvents]
///   per session bind to prevent network-flutter storms.
/// * Mic/camera/speaker toggles are handled by
///   [TelemetrySessionCallControlGateway] and never reach this
///   coordinator.
class QuranSessionCallTelemetryCoordinator {
  QuranSessionCallTelemetryCoordinator({
    required this._gateway,
    this._eventHub,
    this._networkThrottle = const Duration(seconds: 60),
    @visibleForTesting DateTime Function()? clock,
    @visibleForTesting this._maxRetries = 5,
    @visibleForTesting this._maxQueueSize = 50,
    @visibleForTesting this._maxReconnectEvents = 6,
    @visibleForTesting Timer Function(Duration, void Function())? timerFactory,
  }) : _clock = clock ?? DateTime.now,
       _timerFactory = timerFactory ?? Timer.new;

  final QuranSessionCallTelemetryGateway _gateway;
  final SessionCallProviderEventHub? _eventHub;
  final Duration _networkThrottle;
  final DateTime Function() _clock;
  final int _maxRetries;
  final int _maxQueueSize;
  final int _maxReconnectEvents;
  final Timer Function(Duration, void Function()) _timerFactory;

  /// Minimum backoff between retries.
  static const _baseBackoff = Duration(seconds: 2);

  /// Maximum backoff ceiling.
  static const _maxBackoff = Duration(seconds: 30);

  // -----------------------------------------------------------------------
  // Internal state
  // -----------------------------------------------------------------------

  /// Idempotency map: event IDs that have been enqueued
  /// (or are still pending). Never removed on failure.
  final Set<String> _recordedEventIds = <String>{};

  /// FIFO queue of events awaiting delivery.
  final List<QuranSessionCallTelemetryEvent> _pending = [];

  /// Whether a [_flushPending] loop is currently active.
  bool _flushInProgress = false;

  /// Per-event retry counters keyed by eventId.
  final Map<String, int> _retryCounts = {};

  /// Scheduled backoff timer (cancelled on dispose / new flush).
  Timer? _backoffTimer;

  StreamSubscription<SessionCallProviderEvent>? _providerSubscription;

  String? _activeSessionId;
  String? _activeActorId;
  SessionParticipantRole? _activeActorRole;
  DateTime? _lastNetworkTelemetryAt;
  int _reconnectSequence = 0;

  // -----------------------------------------------------------------------
  // Session lifecycle
  // -----------------------------------------------------------------------

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

  // -----------------------------------------------------------------------
  // Public record methods
  // -----------------------------------------------------------------------

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

  // -----------------------------------------------------------------------
  // Dispose
  // -----------------------------------------------------------------------

  void dispose() {
    unbindSession();
    _backoffTimer?.cancel();
    _backoffTimer = null;
    _pending.clear();
    _recordedEventIds.clear();
    _retryCounts.clear();
  }

  // -----------------------------------------------------------------------
  // Provider events
  // -----------------------------------------------------------------------

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
      case SessionCallParticipantConnected(
        :final remoteParticipantId,
      ):
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
      case SessionCallParticipantDisconnected(
        :final remoteParticipantId,
      ):
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
        if (_reconnectSequence >= _maxReconnectEvents) {
          return;
        }
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
        if (_reconnectSequence >= _maxReconnectEvents) {
          return;
        }
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

  // -----------------------------------------------------------------------
  // Event factory
  // -----------------------------------------------------------------------

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

  // -----------------------------------------------------------------------
  // Queue management
  // -----------------------------------------------------------------------

  /// Enqueues an event for delivery. Silently ignores duplicates
  /// (same eventId). Applies queue cap with priority eviction.
  void _enqueue(QuranSessionCallTelemetryEvent event) {
    if (!_recordedEventIds.add(event.eventId)) {
      return;
    }

    // Queue cap enforcement: evict noisy events first.
    if (_pending.length >= _maxQueueSize) {
      if (!_evictForRoom(event)) {
        // Could not make room — drop the incoming event unless
        // it is callEnded (never drop callEnded).
        if (event.type != QuranSessionCallTelemetryEventType.callEnded) {
          return;
        }
      }
    }

    _pending.add(event);
    _scheduleFlush();
  }

  /// Tries to evict a noisy event from the queue to make room
  /// for [incoming]. Returns true if eviction succeeded.
  bool _evictForRoom(QuranSessionCallTelemetryEvent incoming) {
    // Find the last noisy event in the queue.
    for (var i = _pending.length - 1; i >= 0; i--) {
      if (_noisyTypes.contains(_pending[i].type)) {
        final evicted = _pending.removeAt(i);
        _retryCounts.remove(evicted.eventId);
        return true;
      }
    }

    // If incoming is essential, evict the last non-callEnded.
    if (_essentialTypes.contains(incoming.type)) {
      for (var i = _pending.length - 1; i >= 0; i--) {
        if (_pending[i].type != QuranSessionCallTelemetryEventType.callEnded) {
          final evicted = _pending.removeAt(i);
          _retryCounts.remove(evicted.eventId);
          return true;
        }
      }
    }

    return false;
  }

  // -----------------------------------------------------------------------
  // Flush with bounded exponential backoff
  // -----------------------------------------------------------------------

  /// Schedules a flush if one is not already in progress or
  /// waiting on a backoff timer.
  void _scheduleFlush() {
    if (_flushInProgress || _backoffTimer?.isActive == true) {
      return;
    }
    unawaited(_flushPending());
  }

  Future<void> _flushPending() async {
    if (_flushInProgress) {
      return;
    }
    _flushInProgress = true;

    while (_pending.isNotEmpty) {
      final event = _pending.first;
      final retries = _retryCounts[event.eventId] ?? 0;

      // Max retries exceeded — drop the event.
      if (retries >= _maxRetries) {
        _pending.removeAt(0);
        _retryCounts.remove(event.eventId);
        continue;
      }

      try {
        await _gateway.recordEvent(event);
        _pending.removeAt(0);
        _retryCounts.remove(event.eventId);
      } on Object {
        // BUG FIX: Do NOT remove eventId from _recordedEventIds.
        // The event stays deduped so duplicates cannot re-enter.
        _retryCounts[event.eventId] = retries + 1;

        // Schedule backoff retry.
        final backoff = _computeBackoff(retries + 1);
        _flushInProgress = false;
        _backoffTimer?.cancel();
        _backoffTimer = _timerFactory(backoff, _scheduleFlush);
        return;
      }
    }

    _flushInProgress = false;
  }

  /// Computes exponential backoff: 2^retryCount seconds,
  /// capped at [_maxBackoff].
  Duration _computeBackoff(int retryCount) {
    final seconds = math.min(
      _baseBackoff.inSeconds * math.pow(2, retryCount - 1),
      _maxBackoff.inSeconds,
    );
    return Duration(seconds: seconds.toInt());
  }

  // -----------------------------------------------------------------------
  // @visibleForTesting getters
  // -----------------------------------------------------------------------

  @visibleForTesting
  int get pendingCount => _pending.length;

  @visibleForTesting
  bool get hasRecordedJoinSucceeded {
    return _recordedEventIds.any((id) => id.endsWith('_joinSucceeded'));
  }

  /// Whether any pending event has an essential type.
  @visibleForTesting
  bool get hasPendingEssentialEvent {
    return _pending.any((e) => _essentialTypes.contains(e.type));
  }

  /// Whether a callEnded event is in the pending queue.
  @visibleForTesting
  bool get hasPendingCallEnded {
    return _pending.any(
      (e) => e.type == QuranSessionCallTelemetryEventType.callEnded,
    );
  }
}
