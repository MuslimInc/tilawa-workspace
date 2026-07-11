/// Domain entities and value objects for the Quran learning **packages**
/// feature (prepaid eight-session private entitlement).
///
/// These are pure, framework-free types. All authoritative mutation happens on
/// the server (Cloud Functions); the client treats these aggregates as
/// read-only projections plus command inputs. See
/// `specs/042-quran-learning-packages/data-model.md`.
///
/// ## Credit conservation invariant
///
/// A [StudentPackage] is a prepaid credit aggregate backed by an immutable
/// [PackageCreditMovement] ledger. At all times the following holds
/// ([StudentPackageCounters.isConsistent]):
///
/// ```text
/// issuedCredits + adjustPositive
///     == available + reserved + consumed + expired + adjustNegative
/// ```
///
/// with every counter `>= 0`. `restoredCredits` is a monotonic informational
/// tally of `restore` movements (a restore moves a credit from `reserved` back
/// to `available`, so it does not change the conservation sum). `consumed` and
/// `expired` are terminal and never decremented.
///
/// Movement effects on the counters:
///
/// | Movement          | available | reserved | consumed | expired | tally            |
/// |-------------------|-----------|----------|----------|---------|------------------|
/// | `issue(n)`        | `+n`      |          |          |         | `issued = n`     |
/// | `reserve`         | `-1`      | `+1`     |          |         |                  |
/// | `consume`         |           | `-1`     | `+1`     |         |                  |
/// | `restore`         | `+1`      | `-1`     |          |         | `restored += 1`  |
/// | `expire(k)`       | `-k`      |          |          | `+k`    |                  |
/// | `adjustPositive(q)`| `+q`     |          |          |         | `adjustPos += q` |
/// | `adjustNegative(q)`| `-q`     |          |          |         | `adjustNeg += q` |
library;

import 'package:equatable/equatable.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Enums
// ─────────────────────────────────────────────────────────────────────────────

/// Lifecycle of a market-scoped [PackagePlan].
enum PackagePlanStatus { draft, active, paused, retired }

/// Lifecycle of a [PackageOrder] (pre-activation purchase request).
enum PackageOrderStatus {
  pendingPayment,
  confirmed,
  rejected,
  expired,
  cancelled,
}

/// Terminal/active lifecycle of a [StudentPackage] entitlement.
///
/// A temporary operational hold is represented by [suspended] and is distinct
/// from the terminal states so history stays readable.
enum StudentPackageStatus { active, completed, expired, cancelled, suspended }

/// Kind of an immutable [PackageCreditMovement]. One movement per semantic
/// lifecycle event, keyed by a deterministic id.
enum PackageCreditMovementType {
  issue,
  reserve,
  consume,
  restore,
  expire,
  adjustPositive,
  adjustNegative,
}

extension PackageCreditMovementTypeX on PackageCreditMovementType {
  /// Whether this movement type requires a privileged (finance/support) actor
  /// and a non-empty rationale.
  bool get requiresPrivilegedActor =>
      this == PackageCreditMovementType.adjustPositive ||
      this == PackageCreditMovementType.adjustNegative;
}

// ─────────────────────────────────────────────────────────────────────────────
// Value objects
// ─────────────────────────────────────────────────────────────────────────────

/// Immutable commercial terms snapshotted onto an order/package at purchase
/// time. A later [PackagePlan] edit never rewrites a purchased snapshot.
class PackageTermsSnapshot extends Equatable {
  const PackageTermsSnapshot({
    required this.planId,
    required this.marketCode,
    required this.sessionCount,
    required this.sessionDurationMinutes,
    required this.validityDays,
    required this.cancellationCutoffHours,
    required this.priceMinor,
    required this.currencyCode,
    required this.compatibilityMeetingAllowance,
    required this.policyVersion,
    this.allowChildLearner = false,
  });

  final String planId;

  /// ISO 3166-1 alpha-2 market, e.g. `EG`. Egypt-only while the MVP gate holds.
  final String marketCode;

  /// Number of prepaid sessions. Fixed at 8 for the MVP.
  final int sessionCount;

  final int sessionDurationMinutes;

  /// Days from activation until the entitlement expires.
  final int validityDays;

  /// Protected cancellation window before session start (12h for MVP).
  final int cancellationCutoffHours;

  /// Integer minor units, never a floating amount (e.g. `120000` = 1200.00 EGP).
  final int priceMinor;

  /// ISO 4217, e.g. `EGP`.
  final String currencyCode;

  /// Number of free compatibility meetings granted with this package.
  final int compatibilityMeetingAllowance;

  /// Version of the plan policy captured at purchase, for lossless auditing.
  final String policyVersion;

  /// Whether this plan permits a child learner (requires verified guardian).
  final bool allowChildLearner;

  double get priceMajor => priceMinor / 100;

  @override
  List<Object?> get props => [
    planId,
    marketCode,
    sessionCount,
    sessionDurationMinutes,
    validityDays,
    cancellationCutoffHours,
    priceMinor,
    currencyCode,
    compatibilityMeetingAllowance,
    policyVersion,
    allowChildLearner,
  ];
}

/// Off-app manual payment instruction snapshot captured on an order.
class PackagePaymentInstructionSnapshot extends Equatable {
  const PackagePaymentInstructionSnapshot({
    required this.instructionVersion,
    required this.methodCode,
    required this.displayInstructions,
    required this.paymentReference,
  });

  final String instructionVersion;

  /// Machine-readable payment channel, e.g. `instapay`, `vodafone_cash`.
  final String methodCode;

  /// Localized human instructions shown to the learner/guardian.
  final String displayInstructions;

  /// Unique reference the payer must include so admins can reconcile.
  final String paymentReference;

  @override
  List<Object?> get props => [
    instructionVersion,
    methodCode,
    displayInstructions,
    paymentReference,
  ];
}

/// Authoritative credit counters for a [StudentPackage].
///
/// See the library-level doc for the full conservation invariant.
class StudentPackageCounters extends Equatable {
  const StudentPackageCounters({
    required this.issuedCredits,
    required this.availableCredits,
    required this.reservedCredits,
    required this.consumedCredits,
    required this.restoredCredits,
    required this.expiredCredits,
    required this.adjustPositiveTotal,
    required this.adjustNegativeTotal,
  });

  /// Counters for a freshly activated package of [sessionCount] credits.
  factory StudentPackageCounters.issued(int sessionCount) {
    assert(sessionCount > 0, 'sessionCount must be positive');
    return StudentPackageCounters(
      issuedCredits: sessionCount,
      availableCredits: sessionCount,
      reservedCredits: 0,
      consumedCredits: 0,
      restoredCredits: 0,
      expiredCredits: 0,
      adjustPositiveTotal: 0,
      adjustNegativeTotal: 0,
    );
  }

  final int issuedCredits;
  final int availableCredits;
  final int reservedCredits;
  final int consumedCredits;

  /// Monotonic tally of `restore` movements (informational, not part of the
  /// conservation sum).
  final int restoredCredits;
  final int expiredCredits;
  final int adjustPositiveTotal;
  final int adjustNegativeTotal;

  /// All counters are non-negative.
  bool get allNonNegative =>
      issuedCredits >= 0 &&
      availableCredits >= 0 &&
      reservedCredits >= 0 &&
      consumedCredits >= 0 &&
      restoredCredits >= 0 &&
      expiredCredits >= 0 &&
      adjustPositiveTotal >= 0 &&
      adjustNegativeTotal >= 0;

  /// Left/right sides of the conservation invariant.
  int get sources => issuedCredits + adjustPositiveTotal;
  int get sinks =>
      availableCredits +
      reservedCredits +
      consumedCredits +
      expiredCredits +
      adjustNegativeTotal;

  /// True when counters are non-negative and the conservation invariant holds.
  bool get isConsistent => allNonNegative && sources == sinks;

  /// Whether the package has no more usable or reserved credits.
  bool get isExhausted => availableCredits == 0 && reservedCredits == 0;

  @override
  List<Object?> get props => [
    issuedCredits,
    availableCredits,
    reservedCredits,
    consumedCredits,
    restoredCredits,
    expiredCredits,
    adjustPositiveTotal,
    adjustNegativeTotal,
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
// Aggregates
// ─────────────────────────────────────────────────────────────────────────────

/// Market-scoped product configuration controlled by a package-config admin.
class PackagePlan extends Equatable {
  const PackagePlan({
    required this.planId,
    required this.marketCode,
    required this.localizedName,
    required this.localizedDescription,
    required this.terms,
    required this.status,
    required this.eligibleTeacherIds,
    required this.policyVersion,
    required this.updatedAt,
    this.autoRenew = false,
  });

  final String planId;
  final String marketCode;

  /// Localized display strings keyed by language code (e.g. `ar`, `en`).
  final Map<String, String> localizedName;
  final Map<String, String> localizedDescription;

  final PackageTermsSnapshot terms;
  final PackagePlanStatus status;

  /// Teacher ids eligible to deliver this plan (empty = rule-based eligibility).
  final List<String> eligibleTeacherIds;

  final String policyVersion;
  final DateTime updatedAt;

  /// Always false for the MVP (no recurring billing).
  final bool autoRenew;

  bool get isPurchasable => status == PackagePlanStatus.active;

  @override
  List<Object?> get props => [
    planId,
    marketCode,
    localizedName,
    localizedDescription,
    terms,
    status,
    eligibleTeacherIds,
    policyVersion,
    updatedAt,
    autoRenew,
  ];
}

/// Pre-activation purchase request. Confirmation creates exactly one
/// [StudentPackage]; rejection creates none.
class PackageOrder extends Equatable {
  const PackageOrder({
    required this.orderId,
    required this.planId,
    required this.learnerId,
    required this.teacherId,
    required this.marketCode,
    required this.terms,
    required this.paymentInstruction,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    this.guardianId,
    this.cityId,
    this.compatibilityMeetingId,
    this.idempotencyKey,
    this.resultingPackageId,
    this.rejectionReason,
    this.resolvedByActorId,
    this.resolvedAt,
  });

  final String orderId;
  final String planId;
  final String learnerId;
  final String teacherId;
  final String marketCode;
  final PackageTermsSnapshot terms;
  final PackagePaymentInstructionSnapshot paymentInstruction;
  final PackageOrderStatus status;
  final DateTime createdAt;
  final DateTime expiresAt;

  /// Present when a guardian purchases on behalf of a child learner.
  final String? guardianId;
  final String? cityId;
  final String? compatibilityMeetingId;
  final String? idempotencyKey;

  /// Set only once [status] is [PackageOrderStatus.confirmed].
  final String? resultingPackageId;
  final String? rejectionReason;
  final String? resolvedByActorId;
  final DateTime? resolvedAt;

  bool get isPending => status == PackageOrderStatus.pendingPayment;
  bool get isTerminal => !isPending;

  @override
  List<Object?> get props => [
    orderId,
    planId,
    learnerId,
    teacherId,
    marketCode,
    terms,
    paymentInstruction,
    status,
    createdAt,
    expiresAt,
    guardianId,
    cityId,
    compatibilityMeetingId,
    idempotencyKey,
    resultingPackageId,
    rejectionReason,
    resolvedByActorId,
    resolvedAt,
  ];
}

/// Authoritative entitlement aggregate. Holds credit counters, lifecycle,
/// and a monotonic [version] for optimistic concurrency on the server.
class StudentPackage extends Equatable {
  const StudentPackage({
    required this.packageId,
    required this.orderId,
    required this.planId,
    required this.learnerId,
    required this.teacherId,
    required this.marketCode,
    required this.terms,
    required this.counters,
    required this.status,
    required this.version,
    required this.activatedAt,
    required this.expiresAt,
    required this.policyVersion,
    this.guardianId,
    this.completedAt,
    this.lastMovementId,
    this.suspended = false,
  });

  final String packageId;
  final String orderId;
  final String planId;
  final String learnerId;
  final String teacherId;
  final String marketCode;
  final PackageTermsSnapshot terms;
  final StudentPackageCounters counters;
  final StudentPackageStatus status;

  /// Optimistic-concurrency version; each atomic mutation increments it.
  final int version;

  final DateTime activatedAt;
  final DateTime expiresAt;
  final String policyVersion;

  final String? guardianId;
  final DateTime? completedAt;
  final String? lastMovementId;

  /// Temporary operational hold, orthogonal to the terminal [status].
  final bool suspended;

  bool get isActive => status == StudentPackageStatus.active && !suspended;

  /// Credits currently available to reserve for a booking.
  int get availableCredits => counters.availableCredits;

  bool get isExpired => status == StudentPackageStatus.expired;

  /// Whether a new booking can reserve a credit right now.
  bool canReserve(DateTime now) =>
      isActive && counters.availableCredits > 0 && now.isBefore(expiresAt);

  @override
  List<Object?> get props => [
    packageId,
    orderId,
    planId,
    learnerId,
    teacherId,
    marketCode,
    terms,
    counters,
    status,
    version,
    activatedAt,
    expiresAt,
    policyVersion,
    guardianId,
    completedAt,
    lastMovementId,
    suspended,
  ];
}

/// Immutable ledger record. Never updated or deleted by clients; keyed by a
/// deterministic [movementId] so the same semantic event is idempotent.
class PackageCreditMovement extends Equatable {
  const PackageCreditMovement({
    required this.movementId,
    required this.packageId,
    required this.type,
    required this.quantity,
    required this.reasonCode,
    required this.policyVersion,
    required this.createdAt,
    this.bookingId,
    this.sessionId,
    this.orderId,
    this.actorId,
    this.idempotencyKey,
  });

  final String movementId;
  final String packageId;
  final PackageCreditMovementType type;

  /// Always a positive magnitude; [type] carries the direction.
  final int quantity;

  final String reasonCode;
  final String policyVersion;
  final DateTime createdAt;

  final String? bookingId;
  final String? sessionId;
  final String? orderId;

  /// The privileged actor for adjustment movements; null for system events.
  final String? actorId;
  final String? idempotencyKey;

  @override
  List<Object?> get props => [
    movementId,
    packageId,
    type,
    quantity,
    reasonCode,
    policyVersion,
    createdAt,
    bookingId,
    sessionId,
    orderId,
    actorId,
    idempotencyKey,
  ];
}
