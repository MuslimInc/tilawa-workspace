import 'package:flutter/widgets.dart';
import 'package:quran_sessions/l10n/quran_sessions_localizations.dart';

import '../../domain/failures/quran_sessions_failure.dart';

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
      ValidationFailure(field: final f, code: final c) => loc.validationError(
        c,
        f,
      ),

      // ── Booking ─────────────────────────────────────────────────────────────
      SlotUnavailableFailure() => loc.slotUnavailable,
      BookingConflictFailure() => loc.bookingConflict,

      // ── Profile / eligibility ───────────────────────────────────────────────
      ProfileIncompleteFailure(missingFields: final fields) =>
        '${loc.profileIncompletePrefix} ${loc.profileIncompleteFields(fields.map(_fieldAr).join(', '))}',

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
      MarketNotEnabledFailure(cityId: final c) =>
        c != null ? loc.marketNotEnabledWithCity : loc.marketNotEnabled,

      TeacherNotInMarketFailure() => loc.teacherNotInMarket,

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

// ── Label helpers (Arabic) ────────────────────────────────────────────────────

String _fieldAr(String field) => switch (field) {
  'gender' => 'الجنس',
  'dateOfBirth' => 'تاريخ الميلاد',
  'displayName' => 'الاسم الكامل',
  'countryCode' => 'الدولة',
  'cityId' => 'المدينة',
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
