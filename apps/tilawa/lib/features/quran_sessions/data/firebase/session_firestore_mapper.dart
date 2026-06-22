import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quran_sessions/quran_sessions.dart';

DateTime readFirestoreDateTime(Object? raw) {
  if (raw is Timestamp) return raw.toDate().toUtc();
  if (raw is String) return DateTime.parse(raw).toUtc();
  if (raw is DateTime) return raw.toUtc();
  throw FormatException('Unsupported Firestore datetime: $raw');
}

SessionAggregate mapBookingDocToAggregate(
  String bookingId,
  Map<String, dynamic> data,
) {
  final lifecycleRaw = data['lifecycleStatus'] as String?;
  final lifecycleStatus = lifecycleRaw == null
      ? SessionLifecycleStatus.scheduled
      : SessionLifecycleStatus.values.firstWhere(
          (s) => s.name == lifecycleRaw,
          orElse: () => SessionLifecycleStatus.scheduled,
        );
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
    paymentReference: data['paymentReference'] as String?,
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
    action: SessionAction.values.firstWhere(
      (a) => a.name == _snakeToCamel(actionRaw),
      orElse: () => SessionAction.confirmBooking,
    ),
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

SessionLifecycleStatus _parseLifecycle(String raw) {
  return SessionLifecycleStatus.values.firstWhere(
    (s) => s.name == raw,
    orElse: () => SessionLifecycleStatus.scheduled,
  );
}

String _snakeToCamel(String raw) {
  final parts = raw.split('_');
  if (parts.length == 1) return raw;
  return parts.first +
      parts
          .skip(1)
          .map((p) => p.isEmpty ? '' : p[0].toUpperCase() + p.substring(1))
          .join();
}
