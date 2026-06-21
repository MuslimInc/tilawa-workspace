import '../domain/failures/quran_sessions_failure.dart';

/// Date-of-birth validation driven entirely by a configured **minimum age**.
///
/// There are no hardcoded cutoff dates. The maximum acceptable birth date is
/// computed at call time as `today - minimumAgeYears`, where `minimumAgeYears`
/// comes from remote configuration (see
/// [QuranSessionSafetyPolicy.minimumStudentAgeYears] /
/// [QuranSessionSafetyPolicy.minimumTeacherAgeYears]). Changing the remote
/// value changes the limit at runtime — no code change required.
///
/// The same [latestBirthDate] computation feeds both the date picker
/// (`lastDate`) and this validator, so the UI and the domain can never drift.
///
/// Rules (in priority order):
/// 1. DOB is **required** — null is rejected.
/// 2. DOB must be **≤ today** (date-only; time/zone components are dropped).
/// 3. DOB must be **≥ [earliest]** — a sanity floor, not an age policy.
/// 4. DOB must be **on or before [latestBirthDate]** (i.e. the person is at
///    least `minimumAgeYears` old). The boundary day itself is accepted.
abstract final class DobValidator {
  /// Sanity floor for a plausible birth year. This is *not* the age cutoff —
  /// the age cutoff is always derived from the configured minimum age. It only
  /// guards against absurd input (e.g. year 0) and bounds the picker's
  /// `firstDate`.
  static final earliest = DateTime(1900);

  /// The latest birth date that satisfies [minimumAgeYears]: `today` shifted
  /// back by [minimumAgeYears] whole years (date-only).
  ///
  /// A person born exactly on this date turns [minimumAgeYears] today, so the
  /// date is **inclusive** (accepted). This is the value the picker must use as
  /// its `lastDate`.
  ///
  /// [today] is injectable for testing; defaults to `DateTime.now()`.
  static DateTime latestBirthDate({
    required int minimumAgeYears,
    DateTime? today,
  }) {
    final now = today ?? DateTime.now();
    // Date-only, then shift the year. DateTime normalises invalid days
    // (e.g. Feb 29 in a non-leap target year rolls to Mar 1).
    return DateTime(now.year - minimumAgeYears, now.month, now.day);
  }

  /// Validates [dob] against the configured [minimumAgeYears].
  ///
  /// Returns, in priority order:
  /// - [DateOfBirthRequiredFailure] if [dob] is null,
  /// - [FutureDateOfBirthFailure] if [dob] is after today,
  /// - [InvalidDateOfBirthFailure] if [dob] is before [earliest],
  /// - [DateOfBirthTooRecentFailure] if the person is younger than
  ///   [minimumAgeYears],
  /// - `null` when [dob] is valid.
  ///
  /// [today] is injectable for testing; defaults to `DateTime.now()`.
  static QuranSessionsFailure? validate(
    DateTime? dob, {
    required int minimumAgeYears,
    DateTime? today,
  }) {
    if (dob == null) return const DateOfBirthRequiredFailure();

    final now = today ?? DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final dobDate = DateTime(dob.year, dob.month, dob.day);

    if (dobDate.isAfter(todayDate)) return const FutureDateOfBirthFailure();
    if (dobDate.isBefore(earliest)) return const InvalidDateOfBirthFailure();

    final maxBirthDate = latestBirthDate(
      minimumAgeYears: minimumAgeYears,
      today: todayDate,
    );
    if (dobDate.isAfter(maxBirthDate)) {
      return const DateOfBirthTooRecentFailure();
    }
    return null;
  }
}
