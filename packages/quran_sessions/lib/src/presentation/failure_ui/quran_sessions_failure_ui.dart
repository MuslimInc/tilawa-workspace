import 'package:flutter/widgets.dart';
import 'package:quran_sessions/l10n/quran_sessions_localizations.dart';

import '../../domain/failures/quran_sessions_failure.dart';
import '../../domain/services/vacation_override_validator.dart';
import '../../domain/services/weekly_schedule_validator.dart';
import '../../domain/value_objects/teacher_public_name.dart';
import '../forms/teacher_application_validation_l10n.dart';

/// Extension that converts a typed [QuranSessionsFailure] into a
/// user-facing, localised message.
///
/// The **default** implementation returns Arabic developer-facing strings so
/// the package is self-contained during development.
///
/// The host app MUST override this by defining its own extension in the
/// app's l10n layer:
///
/// ```dart
/// // In apps/tilawa/lib/core/extensions/failure_l10n.dart
/// extension TilawaFailureL10n on QuranSessionsFailure {
///   @override
///   String toLocalizedMessage(BuildContext context) => switch (this) {
///     NetworkFailure()         => context.l10n.errorNetwork,
///     ...
///   };
/// }
/// ```
///
/// Screens call: `state.failure.toLocalizedMessage(context)`
/// Neither BLoCs nor states ever produce a String.
extension QuranSessionsFailureUi on QuranSessionsFailure {
  String toLocalizedMessage(BuildContext context) {
    final loc = QuranSessionsLocalizations.of(context);
    return switch (this) {
      // ── Network / transport ─────────────────────────────────────────────────
      NetworkFailure() => loc.errorNetwork,
      TimeoutFailure() => loc.errorTimeout,

      // ── Server / HTTP ───────────────────────────────────────────────────────
      ServerFailure(statusCode: final c) when c == 401 =>
        loc.errorSessionExpired,
      ServerFailure(statusCode: final c) when c == 403 => loc.errorForbidden,
      ServerFailure() => loc.errorServer,
      UnauthorizedFailure() => loc.unauthorized,

      // ── Domain / resource ───────────────────────────────────────────────────
      NotFoundFailure(resourceType: final t) => loc.notFound(t),
      ValidationFailure(field: final f, code: final c) =>
        f == VacationOverrideValidator.field &&
                c == VacationOverrideValidator.overlapsExistingCode
            ? loc.availabilityVacationOverlapError
            : f == WeeklyScheduleValidator.field &&
                  c == WeeklyScheduleValidator.invalidRangeCode
            ? loc.availabilityRangeInvalid
            : f == WeeklyScheduleValidator.field &&
                  c == WeeklyScheduleValidator.overlappingRangesCode
            ? loc.availabilityRangeOverlap
            : f == WeeklyScheduleValidator.field &&
                  c == WeeklyScheduleValidator.noOpenDaysCode
            ? loc.availabilityNoOpenDaysError
            : f == ValidateTeacherPublicName.field
            ? loc.messageForPublicNameFailure(
                ValidationFailure(field: f, code: c),
              )
            : loc.validationError(c, f),

      // ── Booking ─────────────────────────────────────────────────────────────
      SlotUnavailableFailure() => loc.slotUnavailable,
      BookingConflictFailure() => loc.bookingConflict,
      GroupBookingNotSupportedFailure() => loc.groupBookingNotSupported,
      UnsupportedSessionModeFailure() => loc.unsupportedSessionMode,
      MeetingLinkUnavailableFailure() => loc.meetingLinkUnavailable,
      CallProviderUnavailableFailure() => loc.callProviderUnavailable,
      InvalidTransitionFailure(action: final action) => loc.validationError(
        'invalid_transition',
        action,
      ),
      UnauthorizedActorFailure(action: final action, actorRole: final actor) =>
        loc.validationError('unauthorized_actor', '$action:$actor'),
      ReasonRequiredFailure(action: final action) => loc.validationError(
        'reason_required',
        action,
      ),

      // ── Profile / eligibility ───────────────────────────────────────────────
      ProfileIncompleteFailure(missingFields: final fields) =>
        '${loc.profileIncompletePrefix} ${loc.profileIncompleteFields(fields.map((f) => _profileFieldLabel(loc, f)).join(', '))}',

      GenderNotAllowedFailure() => loc.profileIncompletePrefix,

      AgeNotAllowedFailure(studentAgeGroup: final ag) =>
        ag == 'child' ? loc.ageNotAllowedChild : loc.ageNotAllowedOther,

      TeacherNotVerifiedFailure() => loc.teacherNotVerified,

      AccountBlockedFailure(reason: final r) =>
        r != null
            ? loc.accountBlockedWithReason(_restrictionReasonAr(r))
            : loc.accountBlocked,

      GuardianApprovalRequiredFailure() => loc.guardianApprovalRequired,

      PolicyViolationFailure(policyName: final p, detail: final d) =>
        loc.policyViolation(d, p),

      // ── Market / location ───────────────────────────────────────────────────
      MarketCatalogEmptyFailure() => loc.marketCatalogEmpty,
      MarketNotEnabledFailure(cityId: final c) =>
        c != null ? loc.marketNotEnabledWithCity : loc.marketNotEnabled,

      TeacherNotInMarketFailure() => loc.teacherNotInMarket,

      // ── Date of birth ───────────────────────────────────────────────────────
      DateOfBirthRequiredFailure() => loc.dateOfBirthRequired,
      FutureDateOfBirthFailure() => loc.futureDateOfBirth,
      DateOfBirthTooRecentFailure() => loc.dateOfBirthTooRecent,
      InvalidDateOfBirthFailure() => loc.invalidDateOfBirth,

      // ── Teacher application ─────────────────────────────────────────────────
      TeacherApplicationNotFoundFailure() => loc.teacherApplicationNotFound,
      TeacherApplicationAlreadyPendingFailure() =>
        loc.teacherApplicationAlreadyPending,
      TeacherApplicationRejectedFailure() => loc.teacherApplicationRejected,
      TeacherApplicationSuspendedFailure() => loc.teacherApplicationSuspended,
      TeacherApplicationRevokedFailure() => loc.teacherApplicationRevoked,
      TeacherPhoneNumberRequiredFailure() => loc.teacherPhoneRequired,
      InvalidTeacherPhoneNumberFailure() => loc.invalidTeacherPhone,
      InvalidPhoneForSelectedCountryFailure() =>
        loc.invalidPhoneForSelectedCountry,
      PhoneCountryMismatchFailure() => loc.phoneCountryMismatch,
      TeacherApplicationIncompleteFailure(reason: final r) =>
        loc.teacherApplicationIncomplete(r),
      ReapplicationTooSoonFailure(cooldownEndsAt: final d) =>
        loc.reapplicationTooSoon('${d.day}/${d.month}/${d.year}'),

      // ── Teacher profile ─────────────────────────────────────────────────────
      TeacherProfileNotApprovedFailure() => loc.teacherProfileNotApproved,
      TeacherProfileNotActiveFailure() => loc.teacherProfileNotActive,

      // ── Payment ─────────────────────────────────────────────────────────────
      PaymentDeclinedFailure() => loc.paymentDeclined,
      PaymentCancelledFailure() => loc.paymentCancelled,
      PaymentProviderFailure() => loc.paymentProviderFailure,

      // ── Storage ─────────────────────────────────────────────────────────────
      CacheFailure() => loc.cacheFailure,

      // ── Catch-all ───────────────────────────────────────────────────────────
      UnknownFailure() => loc.unknownFailure,
    };
  }
}

// ── Label helpers ─────────────────────────────────────────────────────────────

String _profileFieldLabel(QuranSessionsLocalizations loc, String field) =>
    switch (field) {
      'gender' => loc.profileFieldGender,
      'dateOfBirth' => loc.profileFieldDateOfBirth,
      'displayName' => loc.profileFieldDisplayName,
      ValidateTeacherPublicName.field => loc.publicTeacherName,
      'countryCode' => loc.profileFieldCountry,
      'cityId' => loc.profileFieldCity,
      _ => field,
    };

String _restrictionReasonAr(String reason) => switch (reason) {
  'falseIdentity' => 'بيانات هوية مزيفة',
  'policyViolation' => 'مخالفة السياسات',
  'safetyConcern' => 'مخاوف تتعلق بالسلامة',
  'abuseReport' => 'بلاغ إساءة',
  'repeatedNoShow' => 'غياب متكرر',
  'adminDecision' => 'قرار إداري',
  _ => reason,
};
