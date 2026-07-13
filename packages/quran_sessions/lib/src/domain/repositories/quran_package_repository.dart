import 'package:dartz_plus/dartz_plus.dart';

import '../entities/quran_learning_package.dart';
import '../failures/quran_package_failure.dart';

/// Bounded, role-safe **read** access to package aggregates.
///
/// Implementations live in the host app (`apps/tilawa`) and read only
/// projections the caller is authorized to see. All lists are paginated; no
/// implementation may scan the credit-movement ledger to compute a balance —
/// counters live on [StudentPackage].
abstract interface class QuranPackageRepository {
  /// Purchasable plans for a market (bounded).
  Future<Either<QuranPackageFailure, List<PackagePlan>>> getPurchasablePlans({
    required String marketCode,
  });

  /// A single plan by id.
  Future<Either<QuranPackageFailure, PackagePlan>> getPlan(String planId);

  /// Role-safe package summary with authoritative counters.
  Future<Either<QuranPackageFailure, StudentPackage>> getPackage(
    String packageId,
  );

  /// Active/most-recent packages visible to [learnerId] (bounded).
  Future<Either<QuranPackageFailure, List<StudentPackage>>> getLearnerPackages(
    String learnerId,
  );

  /// One page of the immutable movement ledger for a package, newest first.
  Future<Either<QuranPackageFailure, PackageActivityPage>> getPackageActivity(
    String packageId, {
    int limit = 20,
    String? startAfterMovementId,
  });

  /// A learner's orders, newest first (bounded).
  Future<Either<QuranPackageFailure, List<PackageOrder>>> getLearnerOrders(
    String learnerId,
  );

  /// A single order by id.
  Future<Either<QuranPackageFailure, PackageOrder>> getOrder(String orderId);
}

/// A bounded page of credit movements plus an opaque cursor.
class PackageActivityPage {
  const PackageActivityPage({
    required this.movements,
    required this.nextCursorMovementId,
  });

  final List<PackageCreditMovement> movements;

  /// `null` when there are no more pages.
  final String? nextCursorMovementId;

  bool get hasMore => nextCursorMovementId != null;
}

/// Server-only **command** gateway. Every method maps to an authenticated,
/// idempotent Cloud Function callable. Clients never write operational
/// documents directly; these calls are the sole mutation path.
abstract interface class QuranPackageCommandGateway {
  /// `createQuranPackageOrder`. Creates a pending order and returns it with the
  /// immutable terms + payment instructions.
  Future<Either<QuranPackageFailure, PackageOrder>> createOrder({
    required String planId,
    required String teacherId,
    String? learnerId,
    String? compatibilityMeetingId,
    required String idempotencyKey,
  });

  /// `cancelQuranPackageOrder`. Owner/guardian cancels a pending order.
  Future<Either<QuranPackageFailure, PackageOrder>> cancelOrder({
    required String orderId,
    required String reason,
    required String idempotencyKey,
  });

  /// `createQuranPackageBooking`. Reserves one credit and books a slot
  /// atomically; returns the updated package with authoritative counters.
  Future<Either<QuranPackageFailure, PackageBookingResult>> createBooking({
    required String packageId,
    required String slotId,
    required String requestedCallTypeId,
    String? note,
    required String idempotencyKey,
  });
}

/// Result of a package booking command: the created booking/session ids plus
/// the authoritative post-reservation balance.
class PackageBookingResult {
  const PackageBookingResult({
    required this.bookingId,
    required this.sessionId,
    required this.package,
  });

  final String bookingId;
  final String sessionId;
  final StudentPackage package;
}
