import 'package:dartz_plus/dartz_plus.dart';

import '../entities/quran_learning_package.dart';
import '../failures/quran_package_failure.dart';
import '../repositories/quran_package_repository.dart';

/// Loads the purchasable plans for a market so the checkout screen can present
/// package disclosure before an order is created.
class GetPurchasablePackagePlansUseCase {
  const GetPurchasablePackagePlansUseCase(this._repository);

  final QuranPackageRepository _repository;

  Future<Either<QuranPackageFailure, List<PackagePlan>>> call({
    required String marketCode,
  }) {
    return _repository.getPurchasablePlans(marketCode: marketCode);
  }
}

/// Creates a pending package order via the server command gateway.
///
/// The [idempotencyKey] makes retries safe: submitting the same key twice
/// returns the same order rather than creating a duplicate.
class CreateQuranPackageOrderUseCase {
  const CreateQuranPackageOrderUseCase(this._gateway);

  final QuranPackageCommandGateway _gateway;

  Future<Either<QuranPackageFailure, PackageOrder>> call({
    required String planId,
    required String teacherId,
    required String idempotencyKey,
    String? learnerId,
    String? compatibilityMeetingId,
  }) {
    return _gateway.createOrder(
      planId: planId,
      teacherId: teacherId,
      learnerId: learnerId,
      compatibilityMeetingId: compatibilityMeetingId,
      idempotencyKey: idempotencyKey,
    );
  }
}

/// Cancels a still-pending package order. Only the owner or verified guardian
/// may cancel; the server enforces this.
class CancelQuranPackageOrderUseCase {
  const CancelQuranPackageOrderUseCase(this._gateway);

  final QuranPackageCommandGateway _gateway;

  Future<Either<QuranPackageFailure, PackageOrder>> call({
    required String orderId,
    required String reason,
    required String idempotencyKey,
  }) {
    return _gateway.cancelOrder(
      orderId: orderId,
      reason: reason,
      idempotencyKey: idempotencyKey,
    );
  }
}

/// Re-reads an order so the pending-payment screen can reflect the latest
/// server state (e.g. after an admin confirms or rejects payment).
class RefreshQuranPackageOrderUseCase {
  const RefreshQuranPackageOrderUseCase(this._repository);

  final QuranPackageRepository _repository;

  Future<Either<QuranPackageFailure, PackageOrder>> call(String orderId) {
    return _repository.getOrder(orderId);
  }
}
