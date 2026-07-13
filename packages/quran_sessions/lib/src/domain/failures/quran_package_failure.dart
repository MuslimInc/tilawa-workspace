import 'package:equatable/equatable.dart';

/// Typed failure hierarchy for the Quran learning **packages** feature.
///
/// Kept as a separate sealed family from [QuranSessionsFailure] because Dart
/// `sealed` classes can only be extended within their own library. Like the
/// booking failures, these carry structured data only — never a pre-translated
/// string. The host app maps them to localized copy at the presentation layer.
///
/// Families mirror the callable contract
/// (`specs/042-quran-learning-packages/contracts/package-callable-contracts.md`):
/// catalog/market, order/payment, entitlement, compatibility, guardian/child,
/// reporting, and authorization/idempotency/internal.
sealed class QuranPackageFailure extends Equatable {
  const QuranPackageFailure();

  @override
  List<Object?> get props => [];
}

// ── Catalog / market ──────────────────────────────────────────────────────────

/// The requested plan does not exist or is not purchasable in this market.
final class PackagePlanUnavailableFailure extends QuranPackageFailure {
  const PackagePlanUnavailableFailure({required this.planId});

  final String planId;

  @override
  List<Object?> get props => [planId];
}

/// The learner's market is not open for package sales (e.g. non-Egypt).
final class PackageMarketNotEligibleFailure extends QuranPackageFailure {
  const PackageMarketNotEligibleFailure({required this.marketCode});

  final String marketCode;

  @override
  List<Object?> get props => [marketCode];
}

/// Plan terms (price/version) changed between disclosure and submission.
final class PackagePlanChangedFailure extends QuranPackageFailure {
  const PackagePlanChangedFailure({
    required this.planId,
    required this.expectedPolicyVersion,
    required this.actualPolicyVersion,
  });

  final String planId;
  final String expectedPolicyVersion;
  final String actualPolicyVersion;

  @override
  List<Object?> get props => [
    planId,
    expectedPolicyVersion,
    actualPolicyVersion,
  ];
}

/// The selected teacher is not eligible to deliver this plan.
final class PackageTeacherNotEligibleFailure extends QuranPackageFailure {
  const PackageTeacherNotEligibleFailure({required this.teacherId});

  final String teacherId;

  @override
  List<Object?> get props => [teacherId];
}

// ── Order / payment ───────────────────────────────────────────────────────────

/// The learner already has a pending order or active package that conflicts
/// with creating a new order.
final class PackageOrderConflictFailure extends QuranPackageFailure {
  const PackageOrderConflictFailure({required this.existingOrderId});

  final String existingOrderId;

  @override
  List<Object?> get props => [existingOrderId];
}

/// The order's payment window elapsed before confirmation.
final class PackageOrderExpiredFailure extends QuranPackageFailure {
  const PackageOrderExpiredFailure({required this.orderId});

  final String orderId;

  @override
  List<Object?> get props => [orderId];
}

/// A terminal decision was requested on an order that is already resolved.
/// Terminal decisions are idempotent, so the UI surfaces the existing state.
final class PackageOrderAlreadyResolvedFailure extends QuranPackageFailure {
  const PackageOrderAlreadyResolvedFailure({
    required this.orderId,
    required this.currentStatus,
  });

  final String orderId;

  /// Machine-readable [PackageOrderStatus.name].
  final String currentStatus;

  @override
  List<Object?> get props => [orderId, currentStatus];
}

/// The compatibility-meeting prerequisite for purchase was not satisfied.
final class CompatibilityMeetingRequiredFailure extends QuranPackageFailure {
  const CompatibilityMeetingRequiredFailure();
}

// ── Entitlement ───────────────────────────────────────────────────────────────

/// The package is not active (paused/suspended) and cannot be used to book.
final class PackageInactiveFailure extends QuranPackageFailure {
  const PackageInactiveFailure({required this.packageId, this.reasonCode});

  final String packageId;
  final String? reasonCode;

  @override
  List<Object?> get props => [packageId, reasonCode];
}

/// The package validity window has elapsed.
final class PackageExpiredFailure extends QuranPackageFailure {
  const PackageExpiredFailure({required this.packageId});

  final String packageId;

  @override
  List<Object?> get props => [packageId];
}

/// No credits remain (available and reserved are both zero, or none available
/// to reserve).
final class PackageExhaustedFailure extends QuranPackageFailure {
  const PackageExhaustedFailure({required this.packageId});

  final String packageId;

  @override
  List<Object?> get props => [packageId];
}

/// A booking targeted a teacher other than the package's assigned teacher.
final class PackageWrongTeacherFailure extends QuranPackageFailure {
  const PackageWrongTeacherFailure({
    required this.packageId,
    required this.expectedTeacherId,
    required this.actualTeacherId,
  });

  final String packageId;
  final String expectedTeacherId;
  final String actualTeacherId;

  @override
  List<Object?> get props => [packageId, expectedTeacherId, actualTeacherId];
}

/// A credit mutation would break the package conservation invariant. This is a
/// server-side guard; a returned instance signals a rejected mutation, never a
/// persisted inconsistency.
final class PackageCreditInvariantFailure extends QuranPackageFailure {
  const PackageCreditInvariantFailure({
    required this.packageId,
    required this.detail,
  });

  final String packageId;

  /// Machine-readable reason, e.g. `available_underflow`, `sum_mismatch`.
  final String detail;

  @override
  List<Object?> get props => [packageId, detail];
}

// ── Compatibility ─────────────────────────────────────────────────────────────

/// The learner has used all compatibility-meeting allowance for this teacher.
final class CompatibilityAllowanceExceededFailure extends QuranPackageFailure {
  const CompatibilityAllowanceExceededFailure({
    required this.teacherId,
    required this.allowance,
  });

  final String teacherId;
  final int allowance;

  @override
  List<Object?> get props => [teacherId, allowance];
}

// ── Guardian / child ──────────────────────────────────────────────────────────

/// The learner is a child and a verified guardian is required to act.
final class GuardianRequiredFailure extends QuranPackageFailure {
  const GuardianRequiredFailure({required this.learnerId});

  final String learnerId;

  @override
  List<Object?> get props => [learnerId];
}

/// The acting guardian is not an active, verified guardian of the learner.
final class UnauthorizedGuardianFailure extends QuranPackageFailure {
  const UnauthorizedGuardianFailure({
    required this.guardianId,
    required this.learnerId,
  });

  final String guardianId;
  final String learnerId;

  @override
  List<Object?> get props => [guardianId, learnerId];
}

/// The plan's child policy forbids this learner (e.g. under age threshold with
/// no guardian, or plan not child-eligible).
final class ChildPolicyViolationFailure extends QuranPackageFailure {
  const ChildPolicyViolationFailure({required this.detail});

  final String detail;

  @override
  List<Object?> get props => [detail];
}

// ── Reporting ─────────────────────────────────────────────────────────────────

/// The referenced session is not eligible for a lesson report (not completed,
/// or not a package session).
final class ReportSessionNotEligibleFailure extends QuranPackageFailure {
  const ReportSessionNotEligibleFailure({required this.sessionId});

  final String sessionId;

  @override
  List<Object?> get props => [sessionId];
}

/// A report already exists and is terminal; resubmission is rejected.
final class ReportAlreadyTerminalFailure extends QuranPackageFailure {
  const ReportAlreadyTerminalFailure({required this.sessionId});

  final String sessionId;

  @override
  List<Object?> get props => [sessionId];
}

// ── Authorization / idempotency / internal ────────────────────────────────────

/// The caller lacks the required admin claim for a privileged package command.
final class PackageAdminClaimRequiredFailure extends QuranPackageFailure {
  const PackageAdminClaimRequiredFailure({required this.requiredClaim});

  final String requiredClaim;

  @override
  List<Object?> get props => [requiredClaim];
}

/// A privileged mutation was requested without a non-empty rationale.
final class PackageRationaleRequiredFailure extends QuranPackageFailure {
  const PackageRationaleRequiredFailure({required this.operation});

  final String operation;

  @override
  List<Object?> get props => [operation];
}

/// A stored document could not be parsed into a valid aggregate.
final class PackageDataCorruptionFailure extends QuranPackageFailure {
  const PackageDataCorruptionFailure({
    required this.documentType,
    required this.detail,
  });

  final String documentType;
  final String detail;

  @override
  List<Object?> get props => [documentType, detail];
}

/// Catch-all for unexpected package errors.
final class PackageUnknownFailure extends QuranPackageFailure {
  const PackageUnknownFailure();
}
