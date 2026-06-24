import 'package:equatable/equatable.dart';

/// Typed failure hierarchy for the quran_sessions package.
///
/// Every failure subtype carries structured data — never a pre-translated
/// string. The host app provides a mapper/extension that converts these to
/// the correct localised message:
///
/// ```dart
/// // In the host app (NOT in this package):
/// extension QuranSessionsFailureL10n on QuranSessionsFailure {
///   String toLocalizedMessage(BuildContext context) => switch (this) {
///     NetworkFailure()      => context.l10n.errorNetwork,
///     ServerFailure(statusCode: 401) => context.l10n.errorUnauthorized,
///     ServerFailure()       => context.l10n.errorServer,
///     NotFoundFailure()     => context.l10n.errorNotFound,
///     UnauthorizedFailure() => context.l10n.errorUnauthorized,
///     CacheFailure()        => context.l10n.errorCache,
///     UnknownFailure()      => context.l10n.errorUnknown,
///     ValidationFailure(:final field) => context.l10n.errorValidation(field),
///     BookingConflictFailure() => context.l10n.errorBookingConflict,
///     SlotUnavailableFailure() => context.l10n.errorSlotUnavailable,
///   };
/// }
/// ```
///
/// The UI then calls `state.failure.toLocalizedMessage(context)`.
/// Neither BLoC states, BLoCs, nor repositories ever produce a localised String.
sealed class QuranSessionsFailure extends Equatable {
  const QuranSessionsFailure();

  @override
  List<Object?> get props => [];
}

// ── Network / transport ───────────────────────────────────────────────────────

final class NetworkFailure extends QuranSessionsFailure {
  const NetworkFailure();
}

final class TimeoutFailure extends QuranSessionsFailure {
  const TimeoutFailure();
}

// ── Server / HTTP ─────────────────────────────────────────────────────────────

final class ServerFailure extends QuranSessionsFailure {
  const ServerFailure({required this.statusCode});

  final int statusCode;

  @override
  List<Object?> get props => [statusCode];
}

final class UnauthorizedFailure extends QuranSessionsFailure {
  const UnauthorizedFailure();
}

// ── Domain / resource ─────────────────────────────────────────────────────────

final class NotFoundFailure extends QuranSessionsFailure {
  const NotFoundFailure(this.resourceType);

  final String resourceType;

  @override
  List<Object?> get props => [resourceType];
}

final class ValidationFailure extends QuranSessionsFailure {
  const ValidationFailure({required this.field, required this.code});

  /// The field name that failed (e.g. 'slotId', 'rating').
  final String field;

  /// Machine-readable validation code (e.g. 'required', 'out_of_range').
  final String code;

  @override
  List<Object?> get props => [field, code];
}

// ── Booking-specific ──────────────────────────────────────────────────────────

/// The requested slot was booked by another student between the user viewing
/// and submitting the booking form.
final class SlotUnavailableFailure extends QuranSessionsFailure {
  const SlotUnavailableFailure(this.slotId);

  final String slotId;

  @override
  List<Object?> get props => [slotId];
}

/// A booking could not be created because of a policy conflict (e.g. the
/// student already has a session at the same time).
final class BookingConflictFailure extends QuranSessionsFailure {
  const BookingConflictFailure();
}

/// Group bookings are not supported in Free Beta.
final class GroupBookingNotSupportedFailure extends QuranSessionsFailure {
  const GroupBookingNotSupportedFailure();
}

/// The selected session mode is disabled for this market / release.
final class UnsupportedSessionModeFailure extends QuranSessionsFailure {
  const UnsupportedSessionModeFailure({required this.callType});

  final String callType;

  @override
  List<Object?> get props => [callType];
}

/// No meeting link or call provider is configured for this session.
final class MeetingLinkUnavailableFailure extends QuranSessionsFailure {
  const MeetingLinkUnavailableFailure();
}

/// The configured call provider cannot handle this join request.
final class CallProviderUnavailableFailure extends QuranSessionsFailure {
  const CallProviderUnavailableFailure({this.reasonCode});

  /// Machine-readable hint for UI (e.g. `agora_not_registered`).
  final String? reasonCode;

  @override
  List<Object?> get props => [reasonCode];
}

/// Mic or camera permission denied before joining an in-app RTC call.
final class RtcPermissionDeniedFailure extends QuranSessionsFailure {
  const RtcPermissionDeniedFailure({required this.permission});

  final String permission;

  @override
  List<Object?> get props => [permission];
}

/// Agora/WebRTC join failed after provider routing (token, SDK, network).
final class RtcCallJoinFailure extends QuranSessionsFailure {
  const RtcCallJoinFailure({required this.reasonCode});

  final String reasonCode;

  @override
  List<Object?> get props => [reasonCode];
}

/// WebRTC signaling/TURN infrastructure is not deployed yet.
final class WebRtcSignalingUnavailableFailure extends QuranSessionsFailure {
  const WebRtcSignalingUnavailableFailure();
}

/// External meeting URL could not be opened in another app.
final class ExternalMeetingLaunchFailure extends QuranSessionsFailure {
  const ExternalMeetingLaunchFailure({this.linkCopiedToClipboard = false});

  final bool linkCopiedToClipboard;

  @override
  List<Object?> get props => [linkCopiedToClipboard];
}

/// The requested lifecycle action is not valid for the current status.
final class InvalidTransitionFailure extends QuranSessionsFailure {
  const InvalidTransitionFailure({
    required this.action,
    required this.actorRole,
    this.currentStatus,
    this.reasonCode,
  });

  final String action;
  final String actorRole;
  final String? currentStatus;
  final String? reasonCode;

  @override
  List<Object?> get props => [action, actorRole, currentStatus, reasonCode];
}

/// The actor role is not authorized to execute the lifecycle action.
final class UnauthorizedActorFailure extends QuranSessionsFailure {
  const UnauthorizedActorFailure({
    required this.action,
    required this.actorRole,
    required this.allowedActorRoles,
  });

  final String action;
  final String actorRole;
  final List<String> allowedActorRoles;

  @override
  List<Object?> get props => [action, actorRole, allowedActorRoles];
}

/// The lifecycle action requires a non-empty reason.
final class ReasonRequiredFailure extends QuranSessionsFailure {
  const ReasonRequiredFailure({required this.action});

  final String action;

  @override
  List<Object?> get props => [action];
}

// ── Profile / eligibility ─────────────────────────────────────────────────────

/// The student's profile is missing required fields before booking can proceed.
/// [missingFields] lists the machine-readable field names (e.g. 'gender').
final class ProfileIncompleteFailure extends QuranSessionsFailure {
  const ProfileIncompleteFailure({required this.missingFields});

  final List<String> missingFields;

  @override
  List<Object?> get props => [missingFields];
}

/// The teacher's gender policy does not allow a student of [studentGender]
/// to book with a teacher of [teacherGender].
final class GenderNotAllowedFailure extends QuranSessionsFailure {
  const GenderNotAllowedFailure({
    required this.teacherGender,
    required this.studentGender,
  });

  /// String representation of the teacher's gender (e.g. 'male' / 'female').
  final String teacherGender;

  /// String representation of the student's gender.
  final String studentGender;

  @override
  List<Object?> get props => [teacherGender, studentGender];
}

/// The student's age group is not permitted by the teacher's eligibility policy.
final class AgeNotAllowedFailure extends QuranSessionsFailure {
  const AgeNotAllowedFailure({required this.studentAgeGroup});

  /// 'child' or 'adult'
  final String studentAgeGroup;

  @override
  List<Object?> get props => [studentAgeGroup];
}

/// The teacher has not been verified and cannot accept bookings.
final class TeacherNotVerifiedFailure extends QuranSessionsFailure {
  const TeacherNotVerifiedFailure({required this.teacherId});

  final String teacherId;

  @override
  List<Object?> get props => [teacherId];
}

/// The account is suspended or blocked and cannot perform the requested action.
final class AccountBlockedFailure extends QuranSessionsFailure {
  const AccountBlockedFailure({
    required this.accountId,
    this.reason,
  });

  final String accountId;

  /// Machine-readable reason string (mirrors [AccountRestrictionReason.name]).
  final String? reason;

  @override
  List<Object?> get props => [accountId, reason];
}

/// A session involving a child student requires guardian approval before
/// the booking can be confirmed.
final class GuardianApprovalRequiredFailure extends QuranSessionsFailure {
  const GuardianApprovalRequiredFailure({required this.studentId});

  final String studentId;

  @override
  List<Object?> get props => [studentId];
}

/// No enabled countries or cities were returned from the market catalog.
///
/// Usually means Firestore was not seeded or every market is disabled.
final class MarketCatalogEmptyFailure extends QuranSessionsFailure {
  const MarketCatalogEmptyFailure();
}

/// The student's country/city market is not open for bookings.
///
/// Emitted when [MarketConfig.isEnabled] or [CityConfig.isEnabled] is false.
final class MarketNotEnabledFailure extends QuranSessionsFailure {
  const MarketNotEnabledFailure({
    required this.countryCode,
    this.cityId,
  });

  final String countryCode;
  final String? cityId;

  @override
  List<Object?> get props => [countryCode, cityId];
}

/// The selected teacher does not have pricing configured for the student's
/// market (country/city). The student must choose a different teacher.
final class TeacherNotInMarketFailure extends QuranSessionsFailure {
  const TeacherNotInMarketFailure({
    required this.teacherId,
    required this.countryCode,
  });

  final String teacherId;
  final String countryCode;

  @override
  List<Object?> get props => [teacherId, countryCode];
}

/// A booking was rejected because it violates a platform safety or
/// scheduling policy.
final class PolicyViolationFailure extends QuranSessionsFailure {
  const PolicyViolationFailure({
    required this.policyName,
    required this.detail,
  });

  /// Machine-readable policy identifier (e.g. 'gender_restriction').
  final String policyName;

  /// Machine-readable detail code (e.g. 'male_teacher_female_student').
  final String detail;

  @override
  List<Object?> get props => [policyName, detail];
}

// ── Storage ───────────────────────────────────────────────────────────────────

final class CacheFailure extends QuranSessionsFailure {
  const CacheFailure();
}

// ── Payment ───────────────────────────────────────────────────────────────────

/// The card or payment method was declined by the payment gateway.
/// Mapped from [ChargeDeclinedFailure] at the BLoC boundary.
final class PaymentDeclinedFailure extends QuranSessionsFailure {
  const PaymentDeclinedFailure();
}

/// The user dismissed the payment sheet without completing.
/// Mapped from [ChargeCancelledFailure] at the BLoC boundary.
final class PaymentCancelledFailure extends QuranSessionsFailure {
  const PaymentCancelledFailure();
}

/// The payment gateway returned an unexpected error.
/// Mapped from [GatewayFailure] at the BLoC boundary.
final class PaymentProviderFailure extends QuranSessionsFailure {
  const PaymentProviderFailure();
}

// ── Date of birth ─────────────────────────────────────────────────────────────

/// No date of birth was provided. DOB is a required profile field.
final class DateOfBirthRequiredFailure extends QuranSessionsFailure {
  const DateOfBirthRequiredFailure();
}

/// The provided date of birth is in the future.
/// DOB must be ≤ today (date-only comparison).
final class FutureDateOfBirthFailure extends QuranSessionsFailure {
  const FutureDateOfBirthFailure();
}

/// The provided date of birth is more recent than the MVP eligibility cutoff.
/// Temporary safety rule: DOB must be on or before 2022-01-01 — users born
/// after that date are too young to use the feature for now.
final class DateOfBirthTooRecentFailure extends QuranSessionsFailure {
  const DateOfBirthTooRecentFailure();
}

/// The provided date of birth is not a realistic/valid value.
/// MVP rule: DOB must not be before 1900-01-01.
final class InvalidDateOfBirthFailure extends QuranSessionsFailure {
  const InvalidDateOfBirthFailure();
}

// ── Teacher application ───────────────────────────────────────────────────────

/// No [TeacherApplication] exists for the given user.
/// Callers should treat this as [TeacherApplicationStatus.none].
final class TeacherApplicationNotFoundFailure extends QuranSessionsFailure {
  const TeacherApplicationNotFoundFailure();
}

/// The user already has a pending or approved application and cannot start
/// a new one.
final class TeacherApplicationAlreadyPendingFailure
    extends QuranSessionsFailure {
  const TeacherApplicationAlreadyPendingFailure();
}

/// The application was rejected and cannot be resubmitted in its current state.
final class TeacherApplicationRejectedFailure extends QuranSessionsFailure {
  const TeacherApplicationRejectedFailure();
}

/// The teacher's application is suspended — no bookings can be accepted.
final class TeacherApplicationSuspendedFailure extends QuranSessionsFailure {
  const TeacherApplicationSuspendedFailure();
}

/// The teacher's application has been permanently revoked.
final class TeacherApplicationRevokedFailure extends QuranSessionsFailure {
  const TeacherApplicationRevokedFailure();
}

/// A phone number is required before a teacher application can be submitted.
final class TeacherPhoneNumberRequiredFailure extends QuranSessionsFailure {
  const TeacherPhoneNumberRequiredFailure();
}

/// The provided phone number does not conform to E.164 format.
final class InvalidTeacherPhoneNumberFailure extends QuranSessionsFailure {
  const InvalidTeacherPhoneNumberFailure();
}

/// The provided phone number is valid E.164 but does not belong to the
/// country the applicant selected (e.g. an Egyptian number with UAE selected).
final class PhoneCountryMismatchFailure extends QuranSessionsFailure {
  const PhoneCountryMismatchFailure();
}

/// The phone number is syntactically plausible but violates the rules for
/// the selected country (wrong prefix, wrong length, or mismatched dial code).
final class InvalidPhoneForSelectedCountryFailure extends QuranSessionsFailure {
  const InvalidPhoneForSelectedCountryFailure();
}

/// The application is missing required fields and cannot advance to pending.
final class TeacherApplicationIncompleteFailure extends QuranSessionsFailure {
  const TeacherApplicationIncompleteFailure({required this.reason});

  final String reason;

  @override
  List<Object?> get props => [reason];
}

/// A re-application was attempted before the cooldown period expired.
/// [cooldownEndsAt] indicates when re-application becomes available.
final class ReapplicationTooSoonFailure extends QuranSessionsFailure {
  const ReapplicationTooSoonFailure({required this.cooldownEndsAt});

  final DateTime cooldownEndsAt;

  @override
  List<Object?> get props => [cooldownEndsAt];
}

// ── Teacher profile ───────────────────────────────────────────────────────────

/// No approved [TeacherProfile] exists for the given user.
/// The teacher's application may still be pending or rejected.
final class TeacherProfileNotApprovedFailure extends QuranSessionsFailure {
  const TeacherProfileNotApprovedFailure();
}

/// The [TeacherProfile] exists but [TeacherProfile.isActive] is false.
final class TeacherProfileNotActiveFailure extends QuranSessionsFailure {
  const TeacherProfileNotActiveFailure({required this.profileId});

  final String profileId;

  @override
  List<Object?> get props => [profileId];
}

// ── Catch-all ─────────────────────────────────────────────────────────────────

final class UnknownFailure extends QuranSessionsFailure {
  const UnknownFailure();
}
