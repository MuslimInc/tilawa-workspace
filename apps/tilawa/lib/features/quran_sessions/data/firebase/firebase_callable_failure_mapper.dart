import 'package:cloud_functions/cloud_functions.dart';
import 'package:quran_sessions/quran_sessions.dart';

/// Maps [FirebaseFunctionsException] from Quran Sessions callables to typed
/// [QuranSessionsFailure] values for user-facing Arabic messages.
QuranSessionsFailure mapQuranSessionsCallableFailure(
  FirebaseFunctionsException error, {
  String? slotId,
  String? teacherId,
  SessionCallType? callType,
}) {
  final lifecycleCode = _readLifecycleCode(error);

  if (lifecycleCode != null) {
    return _mapLifecycleCode(
      lifecycleCode,
      error,
      slotId: slotId,
      teacherId: teacherId,
      callType: callType,
    );
  }

  return switch (error.code) {
    'unauthenticated' => const UnauthorizedFailure(),
    'permission-denied' => const UnauthorizedFailure(),
    'already-exists' => SlotUnavailableFailure(slotId ?? ''),
    'unavailable' => const NetworkFailure(),
    'resource-exhausted' => const NetworkFailure(),
    'deadline-exceeded' => const TimeoutFailure(),
    'failed-precondition' => _mapFailedPreconditionMessage(error),
    'invalid-argument' => const ValidationFailure(
      field: 'request',
      code: 'invalid',
    ),
    'not-found' => NotFoundFailure(
      teacherId != null ? 'TeacherProfile($teacherId)' : 'booking',
    ),
    'internal' => const ServerFailure(statusCode: 500),
    'aborted' => const TimeoutFailure(),
    _ => const UnknownFailure(),
  };
}

String? _readLifecycleCode(FirebaseFunctionsException error) {
  final details = error.details;
  if (details is! Map) {
    return null;
  }
  final code = details['code'];
  return code is String ? code : null;
}

QuranSessionsFailure _mapLifecycleCode(
  String code,
  FirebaseFunctionsException error, {
  String? slotId,
  String? teacherId,
  SessionCallType? callType,
}) {
  final details = error.details is Map ? error.details as Map : const {};

  return switch (code) {
    'session_epoch_stale' ||
    'session_epoch_required' => const ServerFailure(statusCode: 401),
    'account_blocked' => AccountBlockedFailure(
      accountId: teacherId ?? '',
      reason: details['restrictionReason'] as String?,
    ),
    'profile_incomplete' => ProfileIncompleteFailure(
      missingFields: _stringList(details['missingFields']),
    ),
    'market_not_enabled' => MarketNotEnabledFailure(
      countryCode: details['countryCode'] as String? ?? '',
      cityId: details['cityId'] as String?,
    ),
    'teacher_not_verified' => TeacherNotVerifiedFailure(
      teacherId: teacherId ?? details['teacherId'] as String? ?? '',
    ),
    'gender_not_allowed' => GenderNotAllowedFailure(
      teacherGender: details['teacherGender'] as String? ?? '',
      studentGender: details['studentGender'] as String? ?? '',
    ),
    'age_not_allowed' => AgeNotAllowedFailure(
      studentAgeGroup: details['studentAgeGroup'] as String? ?? 'child',
    ),
    'guardian_approval_required' => GuardianApprovalRequiredFailure(
      studentId: details['guardianId'] as String? ?? '',
    ),
    'guardian_approval_invalid' => const ValidationFailure(
      field: 'guardianApproval',
      code: 'invalid',
    ),
    'meeting_link_required' => const MeetingLinkUnavailableFailure(),
    'group_booking_not_supported' => const GroupBookingNotSupportedFailure(),
    'unsupported_session_mode' => UnsupportedSessionModeFailure(
      callType: callType?.name ?? details['callType'] as String? ?? '',
    ),
    'unsupported_call_provider' => const CallProviderUnavailableFailure(),
    'payment_provider_unavailable' => const PaymentProviderFailure(),
    'slot_unavailable' => SlotUnavailableFailure(slotId ?? ''),
    'invalid_transition' => InvalidTransitionFailure(
      action: details['action'] as String? ?? 'create_booking',
      actorRole: details['actorRole'] as String? ?? 'student',
    ),
    'reason_required' => ReasonRequiredFailure(
      action: details['action'] as String? ?? 'booking',
    ),
    'late_student_cancellation_blocked' => const BookingConflictFailure(),
    'unauthorized_actor' || 'not_participant' => const UnauthorizedFailure(),
    _ => const UnknownFailure(),
  };
}

QuranSessionsFailure _mapFailedPreconditionMessage(
  FirebaseFunctionsException error,
) {
  final lifecycleCode = _readLifecycleCode(error);
  if (lifecycleCode != null) {
    return _mapLifecycleCode(lifecycleCode, error);
  }

  final message = error.message ?? '';
  if (message.contains('Session revoked') ||
      message.contains('session_epoch_stale')) {
    return const ServerFailure(statusCode: 401);
  }
  if (message.contains('Session epoch required') ||
      message.contains('session_epoch_required')) {
    return const ServerFailure(statusCode: 401);
  }
  if (message.contains('Slot unavailable')) {
    return const SlotUnavailableFailure('');
  }
  if (message.contains('meeting URL') ||
      message.contains('meeting_link_required')) {
    return const MeetingLinkUnavailableFailure();
  }
  if (message.contains('Paid bookings are disabled')) {
    return const PaymentProviderFailure();
  }
  return const UnknownFailure();
}

List<String> _stringList(Object? raw) {
  if (raw is! List) {
    return const ['profile'];
  }
  return raw.whereType<String>().toList();
}
