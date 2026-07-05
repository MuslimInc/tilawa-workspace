import '../entities/session_lifecycle_status.dart';
import '../policies/session_list_classifier.dart';
import '../value_objects/session_action.dart';

/// Resolves lifecycle status string from Firestore session/booking fields.
///
/// Backend may write `status: cancelled` while `lifecycleStatus` is stale on
/// `quran_sessions` docs when cancel did not propagate. Prefer legacy
/// `cancelled` status and [cancelledByRole] over an still-active lifecycle.
String? resolveLifecycleStatusRawFromFirestore(Map<String, dynamic> data) {
  final legacyStatus = data['status'] as String?;
  if (legacyStatus == 'cancelled') {
    return switch (data['cancelledByRole'] as String?) {
      'teacher' => 'cancelled_by_teacher',
      'admin' => 'cancelled_by_admin',
      _ => 'cancelled_by_student',
    };
  }

  final lifecycleRaw = data['lifecycleStatus'] as String?;
  if (lifecycleRaw != null && lifecycleRaw.trim().isNotEmpty) {
    final parsed = parseLifecycleStatusFromRaw(lifecycleRaw);
    if (!SessionListClassifier.isActionableUpcomingLifecycle(parsed)) {
      return lifecycleRaw;
    }
  }

  final reason =
      data['cancellationReason'] as String? ??
      data['lastActionReason'] as String?;
  if (reason != null) {
    final fromReason = switch (reason) {
      'tutor_cancelled' || 'tutorCancelled' => 'cancelled_by_teacher',
      'student_cancelled' || 'studentCancelled' => 'cancelled_by_student',
      _ => null,
    };
    if (fromReason != null) {
      return fromReason;
    }

    final inferred = tryParseLifecycleStatusFromRaw(reason);
    if (inferred != null &&
        !SessionListClassifier.isActionableUpcomingLifecycle(inferred)) {
      return reason;
    }
  }

  if (lifecycleRaw != null && lifecycleRaw.trim().isNotEmpty) {
    return lifecycleRaw;
  }

  return lifecycleRaw;
}

/// Resolves booking aggregate id from session/booking Firestore fields.
String resolveBookingIdFromFirestore(
  String docId,
  Map<String, dynamic> data,
) {
  for (final key in ['bookingId', 'aggregateId', 'booking_id']) {
    final raw = data[key] as String?;
    if (raw != null && raw.trim().isNotEmpty) {
      return raw.trim();
    }
  }
  return docId;
}

/// Parses backend lifecycle status strings into [SessionLifecycleStatus].
///
/// Handles canonical enum names, snake_case, and legacy aliases such as
/// `tutor_cancelled` emitted by older server paths.
SessionLifecycleStatus parseLifecycleStatusFromRaw(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return SessionLifecycleStatus.scheduled;
  }

  final camel = _snakeToCamel(trimmed);
  for (final status in SessionLifecycleStatus.values) {
    if (status.name == trimmed || status.name == camel) {
      return status;
    }
  }

  return switch (trimmed) {
    'tutor_cancelled' ||
    'tutorCancelled' ||
    'cancelled_by_tutor' ||
    'cancelledByTutor' => SessionLifecycleStatus.cancelledByTeacher,
    'student_cancelled' ||
    'studentCancelled' ||
    'cancelled_by_student' ||
    'cancelledByStudent' => SessionLifecycleStatus.cancelledByStudent,
    'admin_cancelled' ||
    'adminCancelled' ||
    'cancelled_by_admin' ||
    'cancelledByAdmin' => SessionLifecycleStatus.cancelledByAdmin,
    'cancelled' => SessionLifecycleStatus.cancelledByAdmin,
    'rejected' ||
    'rejected_by_tutor' ||
    'rejectedByTutor' => SessionLifecycleStatus.rejectedByTutor,
    'pending' ||
    'pending_tutor_approval' ||
    'pendingTutorApproval' => SessionLifecycleStatus.pendingTutorApproval,
    'pending_payment' ||
    'pendingPayment' => SessionLifecycleStatus.pendingPayment,
    'in_progress' || 'inProgress' => SessionLifecycleStatus.inProgress,
    'no_show' ||
    'noShow' ||
    'teacher_no_show' ||
    'teacherNoShow' => SessionLifecycleStatus.teacherNoShow,
    'student_no_show' ||
    'studentNoShow' => SessionLifecycleStatus.studentNoShow,
    'both_no_show' || 'bothNoShow' => SessionLifecycleStatus.bothNoShow,
    _ => SessionLifecycleStatus.scheduled,
  };
}

/// Parses backend audit action strings into [SessionAction].
SessionAction parseSessionActionFromRaw(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return SessionAction.confirmBooking;
  }

  final camel = _snakeToCamel(trimmed);
  for (final action in SessionAction.values) {
    if (action.name == trimmed || action.name == camel) {
      return action;
    }
  }

  return switch (trimmed) {
    'tutor_cancelled' ||
    'tutorCancelled' ||
    'cancelled_by_tutor' ||
    'cancelledByTutor' => SessionAction.cancelByTeacher,
    'student_cancelled' ||
    'studentCancelled' ||
    'cancelled_by_student' ||
    'cancelledByStudent' => SessionAction.cancelByStudent,
    'admin_cancelled' ||
    'adminCancelled' ||
    'cancelled_by_admin' ||
    'cancelledByAdmin' => SessionAction.cancelByAdmin,
    // Elapsed-session finalizer (server sweep) audit actions.
    'expire_unattended_session' ||
    'expireUnattendedSession' => SessionAction.expireReservation,
    'finalize_completed_session' ||
    'finalizeCompletedSession' => SessionAction.completeSession,
    _ => SessionAction.confirmBooking,
  };
}

/// Returns parsed status when [raw] maps to a lifecycle value, else null.
SessionLifecycleStatus? tryParseLifecycleStatusFromRaw(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;

  final camel = _snakeToCamel(trimmed);
  for (final status in SessionLifecycleStatus.values) {
    if (status.name == trimmed || status.name == camel) {
      return status;
    }
  }

  return switch (trimmed) {
    'tutor_cancelled' ||
    'tutorCancelled' ||
    'cancelled_by_tutor' ||
    'cancelledByTutor' => SessionLifecycleStatus.cancelledByTeacher,
    'student_cancelled' ||
    'studentCancelled' ||
    'cancelled_by_student' ||
    'cancelledByStudent' => SessionLifecycleStatus.cancelledByStudent,
    'admin_cancelled' ||
    'adminCancelled' ||
    'cancelled_by_admin' ||
    'cancelledByAdmin' => SessionLifecycleStatus.cancelledByAdmin,
    'rejected' ||
    'rejected_by_tutor' ||
    'rejectedByTutor' => SessionLifecycleStatus.rejectedByTutor,
    _ => null,
  };
}

String _snakeToCamel(String raw) {
  if (!raw.contains('_')) return raw;
  final parts = raw.split('_');
  return parts.first +
      parts
          .skip(1)
          .map((p) => p.isEmpty ? '' : p[0].toUpperCase() + p.substring(1))
          .join();
}
