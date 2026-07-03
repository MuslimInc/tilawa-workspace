import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quran_sessions/quran_sessions.dart';

DateTime readFirestoreDateTime(Object? raw) {
  if (raw is Timestamp) return raw.toDate().toUtc();
  if (raw is String) return DateTime.parse(raw).toUtc();
  if (raw is DateTime) return raw.toUtc();
  throw FormatException('Unsupported Firestore datetime: $raw');
}

SessionLifecycleStatus parseLifecycleStatus(String raw) =>
    parseLifecycleStatusFromRaw(raw);

SessionAllowedActions? parseAllowedActionsField(Object? raw) {
  if (raw is! List) return null;
  final actions = <SessionAllowedAction>{};
  for (final item in raw) {
    if (item is! String) continue;
    final action = switch (item) {
      'join' => SessionAllowedAction.join,
      'cancel' => SessionAllowedAction.cancel,
      'reschedule' => SessionAllowedAction.reschedule,
      'reportConcern' => SessionAllowedAction.reportConcern,
      'openDispute' => SessionAllowedAction.openDispute,
      'submitReview' => SessionAllowedAction.submitReview,
      'respondToBookingRequest' => SessionAllowedAction.respondToBookingRequest,
      _ => null,
    };
    if (action != null) actions.add(action);
  }
  return SessionAllowedActions(actions);
}

SessionAggregate mapBookingDocToAggregate(
  String bookingId,
  Map<String, dynamic> data,
) {
  final lifecycleRaw = resolveLifecycleStatusRawFromFirestore(data);
  final lifecycleStatus = lifecycleRaw == null
      ? SessionLifecycleStatus.scheduled
      : parseLifecycleStatus(lifecycleRaw);
  final pricingRaw = data['pricingType'] as String? ?? 'free';
  final pricingType = SessionPricingType.values.firstWhere(
    (p) => p.name == pricingRaw || _legacyPricing(p, pricingRaw),
    orElse: () => SessionPricingType.free,
  );

  return SessionAggregate(
    id: bookingId,
    teacherId: data['teacherId'] as String? ?? '',
    studentId: data['studentId'] as String? ?? '',
    slotId: data['slotId'] as String? ?? '',
    startsAt: readFirestoreDateTime(data['startsAt']),
    pricingType: pricingType,
    lifecycleStatus: lifecycleStatus,
    createdAt: readFirestoreDateTime(data['createdAt']),
    updatedAt: readFirestoreDateTime(data['updatedAt'] ?? data['createdAt']),
    rescheduleCount: data['rescheduleCount'] as int? ?? 0,
    cancellationReason: data['cancellationReason'] as String?,
    lastActionReason: data['lastActionReason'] as String?,
    rejectionReason: data['rejectionReason'] as String?,
    paymentReference: data['paymentReference'] as String?,
    sessionId: data['sessionId'] as String?,
    revisionSurahNumber: data['revisionSurahNumber'] as int?,
    revisionAyahNumber: data['revisionAyahNumber'] as int?,
    allowedActionsForStudent: parseAllowedActionsField(
      data['allowedActionsStudent'],
    ),
    allowedActionsForTeacher: parseAllowedActionsField(
      data['allowedActionsTeacher'],
    ),
  );
}

/// Maps a `quran_sessions` document when no matching booking exists.
SessionAggregate mapSessionDocToAggregate(
  String sessionDocId,
  Map<String, dynamic> data,
) {
  final lifecycleRaw = resolveLifecycleStatusRawFromFirestore(data);
  final lifecycleStatus = lifecycleRaw == null
      ? SessionLifecycleStatus.scheduled
      : parseLifecycleStatus(lifecycleRaw);
  final pricingRaw = data['pricingType'] as String? ?? 'free';
  final pricingType = SessionPricingType.values.firstWhere(
    (p) => p.name == pricingRaw || _legacyPricing(p, pricingRaw),
    orElse: () => SessionPricingType.free,
  );
  final bookingId = resolveBookingIdFromFirestore(sessionDocId, data);
  final startsAt = readFirestoreDateTime(data['startsAt']);
  final createdAt = data['createdAt'] != null
      ? readFirestoreDateTime(data['createdAt'])
      : startsAt;
  final updatedAt = data['updatedAt'] != null
      ? readFirestoreDateTime(data['updatedAt'])
      : createdAt;

  return SessionAggregate(
    id: bookingId,
    teacherId: data['teacherId'] as String? ?? '',
    studentId: data['studentId'] as String? ?? '',
    slotId: data['slotId'] as String? ?? '',
    startsAt: startsAt,
    pricingType: pricingType,
    lifecycleStatus: lifecycleStatus,
    createdAt: createdAt,
    updatedAt: updatedAt,
    rescheduleCount: data['rescheduleCount'] as int? ?? 0,
    cancellationReason: data['cancellationReason'] as String?,
    lastActionReason:
        data['lastActionReason'] as String? ??
        data['cancellationReason'] as String?,
    rejectionReason: data['rejectionReason'] as String?,
    paymentReference: data['paymentReference'] as String?,
    sessionId: sessionDocId,
    revisionSurahNumber: data['revisionSurahNumber'] as int?,
    revisionAyahNumber: data['revisionAyahNumber'] as int?,
  );
}

bool _legacyPricing(SessionPricingType type, String raw) {
  return switch (type) {
    SessionPricingType.fixedPerSession => raw == 'fixedPerSession',
    SessionPricingType.subscription => raw == 'subscription',
    SessionPricingType.free => raw == 'free',
  };
}

SessionAuditEvent mapEventDocToAuditEvent(Map<String, dynamic> data) {
  final previousRaw = data['previousStatus'] as String?;
  final newRaw = data['newStatus'] as String?;
  final actionRaw = data['action'] as String? ?? 'unknown';
  final actorRoleRaw = data['actorRole'] as String? ?? 'system';

  return SessionAuditEvent(
    sessionId:
        data['sessionId'] as String? ??
        data['bookingId'] as String? ??
        data['aggregateId'] as String? ??
        '',
    actorId: data['actorId'] as String? ?? 'system',
    actorRole: ActorRole.values.firstWhere(
      (r) => r.name == actorRoleRaw,
      orElse: () => ActorRole.system,
    ),
    action: parseSessionActionFromRaw(actionRaw),
    source: ActionSource.values.firstWhere(
      (s) => s.name == (data['source'] as String? ?? 'mobileApp'),
      orElse: () => ActionSource.mobileApp,
    ),
    previousStatus: previousRaw == null
        ? SessionLifecycleStatus.draft
        : _parseLifecycle(previousRaw),
    newStatus: _parseLifecycle(newRaw ?? 'scheduled'),
    createdAt: readFirestoreDateTime(data['timestamp']),
    reason: data['reason'] as String?,
  );
}

SessionLifecycleStatus _parseLifecycle(String raw) =>
    parseLifecycleStatusFromRaw(raw);
