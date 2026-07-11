import 'package:dartz_plus/dartz_plus.dart';

import '../../domain/entities/quran_learning_package.dart';
import '../../domain/failures/quran_package_failure.dart';
import '../dtos/quran_package_dto.dart';

/// Maps package DTOs to domain aggregates, returning a
/// [PackageDataCorruptionFailure] when a stored document violates an invariant
/// (unknown enum, inconsistent counters, negative money, unparseable date).
///
/// Money and credits are safety-critical, so — unlike the booking mappers which
/// default unknown enums — these mappers fail closed.
extension PackageTermsDtoMapper on PackageTermsDto {
  Either<QuranPackageFailure, PackageTermsSnapshot> toDomain() {
    if (priceMinor < 0) {
      return const Left(
        PackageDataCorruptionFailure(
          documentType: 'terms',
          detail: 'negative_price',
        ),
      );
    }
    if (sessionCount <= 0 ||
        sessionDurationMinutes <= 0 ||
        validityDays <= 0 ||
        cancellationCutoffHours < 0 ||
        compatibilityMeetingAllowance < 0) {
      return const Left(
        PackageDataCorruptionFailure(
          documentType: 'terms',
          detail: 'non_positive_terms',
        ),
      );
    }
    return Right(
      PackageTermsSnapshot(
        planId: planId,
        marketCode: marketCode,
        sessionCount: sessionCount,
        sessionDurationMinutes: sessionDurationMinutes,
        validityDays: validityDays,
        cancellationCutoffHours: cancellationCutoffHours,
        priceMinor: priceMinor,
        currencyCode: currencyCode,
        compatibilityMeetingAllowance: compatibilityMeetingAllowance,
        policyVersion: policyVersion,
        allowChildLearner: allowChildLearner,
      ),
    );
  }
}

extension PackagePaymentInstructionDtoMapper on PackagePaymentInstructionDto {
  PackagePaymentInstructionSnapshot toDomain() =>
      PackagePaymentInstructionSnapshot(
        instructionVersion: instructionVersion,
        methodCode: methodCode,
        displayInstructions: displayInstructions,
        paymentReference: paymentReference,
      );
}

extension PackagePlanDtoMapper on PackagePlanDto {
  Either<QuranPackageFailure, PackagePlan> toDomain() {
    final status = _parsePlanStatus(this.status);
    if (status == null) {
      return Left(
        PackageDataCorruptionFailure(
          documentType: 'plan',
          detail: 'unknown_status:${this.status}',
        ),
      );
    }
    final updated = DateTime.tryParse(updatedAt);
    if (updated == null) {
      return const Left(
        PackageDataCorruptionFailure(
          documentType: 'plan',
          detail: 'invalid_updated_at',
        ),
      );
    }
    return terms.toDomain().map(
      (terms) => PackagePlan(
        planId: planId,
        marketCode: marketCode,
        localizedName: localizedName.cast<String, String>(),
        localizedDescription: localizedDescription.cast<String, String>(),
        terms: terms,
        status: status,
        eligibleTeacherIds: eligibleTeacherIds.cast<String>(),
        policyVersion: policyVersion,
        updatedAt: updated,
        autoRenew: autoRenew,
      ),
    );
  }
}

extension PackageOrderDtoMapper on PackageOrderDto {
  Either<QuranPackageFailure, PackageOrder> toDomain() {
    final status = _parseOrderStatus(this.status);
    if (status == null) {
      return Left(
        PackageDataCorruptionFailure(
          documentType: 'order',
          detail: 'unknown_status:${this.status}',
        ),
      );
    }
    final created = DateTime.tryParse(createdAt);
    final expires = DateTime.tryParse(expiresAt);
    if (created == null || expires == null) {
      return const Left(
        PackageDataCorruptionFailure(
          documentType: 'order',
          detail: 'invalid_timestamp',
        ),
      );
    }
    return terms.toDomain().map(
      (terms) => PackageOrder(
        orderId: orderId,
        planId: planId,
        learnerId: learnerId,
        teacherId: teacherId,
        marketCode: marketCode,
        terms: terms,
        paymentInstruction: paymentInstruction.toDomain(),
        status: status,
        createdAt: created,
        expiresAt: expires,
        guardianId: guardianId,
        cityId: cityId,
        compatibilityMeetingId: compatibilityMeetingId,
        idempotencyKey: idempotencyKey,
        resultingPackageId: resultingPackageId,
        rejectionReason: rejectionReason,
        resolvedByActorId: resolvedByActorId,
        resolvedAt: resolvedAt == null ? null : DateTime.tryParse(resolvedAt!),
      ),
    );
  }
}

extension StudentPackageCountersDtoMapper on StudentPackageCountersDto {
  Either<QuranPackageFailure, StudentPackageCounters> toDomain(
    String packageId,
  ) {
    final counters = StudentPackageCounters(
      issuedCredits: issuedCredits,
      availableCredits: availableCredits,
      reservedCredits: reservedCredits,
      consumedCredits: consumedCredits,
      restoredCredits: restoredCredits,
      expiredCredits: expiredCredits,
      adjustPositiveTotal: adjustPositiveTotal,
      adjustNegativeTotal: adjustNegativeTotal,
    );
    if (!counters.allNonNegative) {
      return Left(
        PackageDataCorruptionFailure(
          documentType: 'counters',
          detail: 'negative_counter',
        ),
      );
    }
    if (!counters.isConsistent) {
      return const Left(
        PackageDataCorruptionFailure(
          documentType: 'counters',
          detail: 'invariant_violation',
        ),
      );
    }
    return Right(counters);
  }
}

extension StudentPackageDtoMapper on StudentPackageDto {
  Either<QuranPackageFailure, StudentPackage> toDomain() {
    final status = _parsePackageStatus(this.status);
    if (status == null) {
      return Left(
        PackageDataCorruptionFailure(
          documentType: 'package',
          detail: 'unknown_status:${this.status}',
        ),
      );
    }
    if (version < 0) {
      return const Left(
        PackageDataCorruptionFailure(
          documentType: 'package',
          detail: 'negative_version',
        ),
      );
    }
    final activated = DateTime.tryParse(activatedAt);
    final expires = DateTime.tryParse(expiresAt);
    if (activated == null || expires == null) {
      return const Left(
        PackageDataCorruptionFailure(
          documentType: 'package',
          detail: 'invalid_timestamp',
        ),
      );
    }
    return terms.toDomain().flatMap(
      (terms) => counters
          .toDomain(packageId)
          .map(
            (counters) => StudentPackage(
              packageId: packageId,
              orderId: orderId,
              planId: planId,
              learnerId: learnerId,
              teacherId: teacherId,
              marketCode: marketCode,
              terms: terms,
              counters: counters,
              status: status,
              version: version,
              activatedAt: activated,
              expiresAt: expires,
              policyVersion: policyVersion,
              guardianId: guardianId,
              completedAt: completedAt == null
                  ? null
                  : DateTime.tryParse(completedAt!),
              lastMovementId: lastMovementId,
              suspended: suspended,
            ),
          ),
    );
  }
}

extension PackageCreditMovementDtoMapper on PackageCreditMovementDto {
  Either<QuranPackageFailure, PackageCreditMovement> toDomain() {
    final type = _parseMovementType(this.type);
    if (type == null) {
      return Left(
        PackageDataCorruptionFailure(
          documentType: 'movement',
          detail: 'unknown_type:${this.type}',
        ),
      );
    }
    if (quantity <= 0) {
      return const Left(
        PackageDataCorruptionFailure(
          documentType: 'movement',
          detail: 'non_positive_quantity',
        ),
      );
    }
    final created = DateTime.tryParse(createdAt);
    if (created == null) {
      return const Left(
        PackageDataCorruptionFailure(
          documentType: 'movement',
          detail: 'invalid_created_at',
        ),
      );
    }
    return Right(
      PackageCreditMovement(
        movementId: movementId,
        packageId: packageId,
        type: type,
        quantity: quantity,
        reasonCode: reasonCode,
        policyVersion: policyVersion,
        createdAt: created,
        bookingId: bookingId,
        sessionId: sessionId,
        orderId: orderId,
        actorId: actorId,
        idempotencyKey: idempotencyKey,
      ),
    );
  }
}

// ── Enum parsing (fail-closed) ────────────────────────────────────────────────

PackagePlanStatus? _parsePlanStatus(String raw) => switch (raw) {
  'draft' => PackagePlanStatus.draft,
  'active' => PackagePlanStatus.active,
  'paused' => PackagePlanStatus.paused,
  'retired' => PackagePlanStatus.retired,
  _ => null,
};

PackageOrderStatus? _parseOrderStatus(String raw) => switch (raw) {
  'pending_payment' => PackageOrderStatus.pendingPayment,
  'confirmed' => PackageOrderStatus.confirmed,
  'rejected' => PackageOrderStatus.rejected,
  'expired' => PackageOrderStatus.expired,
  'cancelled' => PackageOrderStatus.cancelled,
  _ => null,
};

StudentPackageStatus? _parsePackageStatus(String raw) => switch (raw) {
  'active' => StudentPackageStatus.active,
  'completed' => StudentPackageStatus.completed,
  'expired' => StudentPackageStatus.expired,
  'cancelled' => StudentPackageStatus.cancelled,
  'suspended' => StudentPackageStatus.suspended,
  _ => null,
};

PackageCreditMovementType? _parseMovementType(String raw) => switch (raw) {
  'issue' => PackageCreditMovementType.issue,
  'reserve' => PackageCreditMovementType.reserve,
  'consume' => PackageCreditMovementType.consume,
  'restore' => PackageCreditMovementType.restore,
  'expire' => PackageCreditMovementType.expire,
  'adjust_positive' => PackageCreditMovementType.adjustPositive,
  'adjust_negative' => PackageCreditMovementType.adjustNegative,
  _ => null,
};
