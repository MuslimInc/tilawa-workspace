import '../entities/quran_session.dart';
import '../entities/session_aggregate.dart';
import '../entities/session_lifecycle_status.dart';
import '../entities/session_pricing_type.dart';
import '../policies/configurable_cancellation_policy.dart';
import '../value_objects/actor_role.dart';

/// Whether a student may open the cancel flow for [aggregate].
bool canStudentCancelSession(
  SessionAggregate aggregate, {
  ConfigurableCancellationPolicy policy =
      const ConfigurableCancellationPolicy(),
}) {
  final status = aggregate.lifecycleStatus;
  if (status == SessionLifecycleStatus.pendingTutorApproval) {
    return true;
  }
  if (status != SessionLifecycleStatus.scheduled &&
      status != SessionLifecycleStatus.confirmed &&
      status != SessionLifecycleStatus.rescheduled) {
    return false;
  }
  final policyKey = policy.describe(
    actor: ActorRole.student,
    sessionStartsAt: aggregate.startsAt,
    pricingType: aggregate.pricingType,
  );
  return policyKey != 'cancellation_blocked_within_notice';
}

/// Whether a student may cancel [session] from list cards.
bool canStudentCancelQuranSession(
  QuranSession session, {
  ConfigurableCancellationPolicy policy =
      const ConfigurableCancellationPolicy(),
  SessionPricingType pricingType = SessionPricingType.free,
}) {
  final status = session.effectiveLifecycleStatus;
  if (status == SessionLifecycleStatus.pendingTutorApproval) {
    return true;
  }
  if (status != SessionLifecycleStatus.scheduled &&
      status != SessionLifecycleStatus.confirmed &&
      status != SessionLifecycleStatus.rescheduled) {
    return false;
  }
  final policyKey = policy.describe(
    actor: ActorRole.student,
    sessionStartsAt: session.startsAt,
    pricingType: pricingType,
  );
  return policyKey != 'cancellation_blocked_within_notice';
}

/// Whether the owning teacher may cancel [aggregate] (accepted sessions only).
bool canTeacherCancelSession(SessionAggregate aggregate) {
  final status = aggregate.lifecycleStatus;
  return status == SessionLifecycleStatus.scheduled ||
      status == SessionLifecycleStatus.confirmed;
}

/// Whether the owning teacher may cancel [session] from dashboard cards.
bool canTeacherCancelQuranSession(QuranSession session) {
  final status = session.effectiveLifecycleStatus;
  return status == SessionLifecycleStatus.scheduled ||
      status == SessionLifecycleStatus.confirmed;
}

/// Whether [viewerRole] may open cancel for [aggregate].
bool canViewerCancelSession(
  SessionAggregate aggregate,
  ActorRole? viewerRole, {
  ConfigurableCancellationPolicy policy =
      const ConfigurableCancellationPolicy(),
}) {
  return switch (viewerRole) {
    ActorRole.teacher => canTeacherCancelSession(aggregate),
    ActorRole.student => canStudentCancelSession(aggregate, policy: policy),
    _ => false,
  };
}
