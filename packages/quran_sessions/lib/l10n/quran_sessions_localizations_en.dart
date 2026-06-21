// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'quran_sessions_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class QuranSessionsLocalizationsEn extends QuranSessionsLocalizations {
  QuranSessionsLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get errorNetwork => 'No internet connection.';

  @override
  String get errorTimeout => 'Request timed out. Please try again.';

  @override
  String get errorSessionExpired =>
      'Your session expired. Please sign in again.';

  @override
  String get errorForbidden =>
      'You do not have permission to perform this action.';

  @override
  String get errorServer => 'A server error occurred. Please try again later.';

  @override
  String get unauthorized => 'You are not authorized to perform this action.';

  @override
  String notFound(Object resource) {
    return '$resource not found.';
  }

  @override
  String validationError(Object code, Object field) {
    return 'Validation error: $field ($code).';
  }

  @override
  String get slotUnavailable =>
      'This slot is no longer available. Please choose another.';

  @override
  String get bookingConflict => 'You have another session at the same time.';

  @override
  String get profileIncompletePrefix => 'Your profile is incomplete.';

  @override
  String profileIncompleteFields(Object fields) {
    return 'Required information: $fields.';
  }

  @override
  String get gender_male => 'male';

  @override
  String get gender_female => 'female';

  @override
  String get gender_male_students => 'males';

  @override
  String get gender_female_students => 'females';

  @override
  String get ageNotAllowedChild =>
      'This teacher does not accept child students.';

  @override
  String get ageNotAllowedOther =>
      'Your age group is not accepted by this teacher.';

  @override
  String get teacherNotVerified =>
      'This teacher is not verified yet and cannot be booked.';

  @override
  String accountBlockedWithReason(Object reason) {
    return 'Your account is suspended because: $reason.';
  }

  @override
  String get accountBlocked =>
      'Your account is suspended. Please contact support.';

  @override
  String get guardianApprovalRequired =>
      'Booking for this student requires guardian approval first.';

  @override
  String policyViolation(Object detail, Object policy) {
    return 'Booking rejected due to policy \"$policy\": $detail.';
  }

  @override
  String get marketNotEnabledWithCity =>
      'Sessions are not available in your city right now. Try another city.';

  @override
  String get marketNotEnabled =>
      'Sessions are not available in your country right now.';

  @override
  String get teacherNotInMarket =>
      'This teacher is not available in your area. Please choose another.';

  @override
  String get teacherApplicationNotFound => 'No teacher application was found.';

  @override
  String get teacherApplicationAlreadyPending =>
      'You already have a teacher application under review.';

  @override
  String get teacherApplicationRejected =>
      'Your application was rejected. You may reapply after the cooldown.';

  @override
  String get teacherApplicationSuspended =>
      'Your teacher application is temporarily suspended.';

  @override
  String get teacherApplicationRevoked =>
      'Your teacher application has been revoked.';

  @override
  String get teacherPhoneRequired =>
      'A phone number is required to complete the teacher application.';

  @override
  String get invalidTeacherPhone =>
      'The phone number is invalid. Please enter a proper international number.';

  @override
  String get phoneCountryMismatch =>
      'The phone number does not match the selected country.';

  @override
  String get invalidPhoneForSelectedCountry =>
      'The phone number violates the selected country\'s rules.';

  @override
  String teacherApplicationIncomplete(Object reason) {
    return 'Teacher application incomplete: $reason';
  }

  @override
  String reapplicationTooSoon(Object date) {
    return 'You cannot reapply before $date.';
  }

  @override
  String get teacherProfileNotApproved =>
      'The teacher profile is not approved yet.';

  @override
  String get teacherProfileNotActive => 'The teacher profile is not active.';

  @override
  String get paymentDeclined =>
      'Payment was declined. Please use another method.';

  @override
  String get paymentCancelled => 'Payment was cancelled.';

  @override
  String get paymentProviderFailure =>
      'Failed to process payment. Please try again.';

  @override
  String get cacheFailure => 'Failed to read local data.';

  @override
  String get unknownFailure => 'An unexpected error occurred.';
}
