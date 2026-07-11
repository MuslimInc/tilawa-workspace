/// Data-transfer objects for the Quran learning packages feature.
///
/// DTOs are dumb string/number carriers with snake_case JSON keys matching the
/// Firestore documents. All validation and enum resolution happens in the
/// mapper (`quran_package_mapper.dart`), which returns typed failures on
/// corruption rather than silently defaulting.
library;

class PackageTermsDto {
  const PackageTermsDto({
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
  final String marketCode;
  final int sessionCount;
  final int sessionDurationMinutes;
  final int validityDays;
  final int cancellationCutoffHours;
  final int priceMinor;
  final String currencyCode;
  final int compatibilityMeetingAllowance;
  final String policyVersion;
  final bool allowChildLearner;

  factory PackageTermsDto.fromJson(
    Map<String, dynamic> json,
  ) => PackageTermsDto(
    planId: json['plan_id'] as String,
    marketCode: json['market_code'] as String,
    sessionCount: (json['session_count'] as num).toInt(),
    sessionDurationMinutes: (json['session_duration_minutes'] as num).toInt(),
    validityDays: (json['validity_days'] as num).toInt(),
    cancellationCutoffHours: (json['cancellation_cutoff_hours'] as num).toInt(),
    priceMinor: (json['price_minor'] as num).toInt(),
    currencyCode: json['currency_code'] as String,
    compatibilityMeetingAllowance:
        (json['compatibility_meeting_allowance'] as num).toInt(),
    policyVersion: json['policy_version'] as String,
    allowChildLearner: json['allow_child_learner'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'plan_id': planId,
    'market_code': marketCode,
    'session_count': sessionCount,
    'session_duration_minutes': sessionDurationMinutes,
    'validity_days': validityDays,
    'cancellation_cutoff_hours': cancellationCutoffHours,
    'price_minor': priceMinor,
    'currency_code': currencyCode,
    'compatibility_meeting_allowance': compatibilityMeetingAllowance,
    'policy_version': policyVersion,
    'allow_child_learner': allowChildLearner,
  };
}

class PackagePaymentInstructionDto {
  const PackagePaymentInstructionDto({
    required this.instructionVersion,
    required this.methodCode,
    required this.displayInstructions,
    required this.paymentReference,
  });

  final String instructionVersion;
  final String methodCode;
  final String displayInstructions;
  final String paymentReference;

  factory PackagePaymentInstructionDto.fromJson(Map<String, dynamic> json) =>
      PackagePaymentInstructionDto(
        instructionVersion: json['instruction_version'] as String,
        methodCode: json['method_code'] as String,
        displayInstructions: json['display_instructions'] as String,
        paymentReference: json['payment_reference'] as String,
      );

  Map<String, dynamic> toJson() => {
    'instruction_version': instructionVersion,
    'method_code': methodCode,
    'display_instructions': displayInstructions,
    'payment_reference': paymentReference,
  };
}

class PackagePlanDto {
  const PackagePlanDto({
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
  final Map<String, dynamic> localizedName;
  final Map<String, dynamic> localizedDescription;
  final PackageTermsDto terms;
  final String status;
  final List<dynamic> eligibleTeacherIds;
  final String policyVersion;
  final String updatedAt;
  final bool autoRenew;

  factory PackagePlanDto.fromJson(Map<String, dynamic> json) => PackagePlanDto(
    planId: json['plan_id'] as String,
    marketCode: json['market_code'] as String,
    localizedName:
        (json['localized_name'] as Map?)?.cast<String, dynamic>() ?? const {},
    localizedDescription:
        (json['localized_description'] as Map?)?.cast<String, dynamic>() ??
        const {},
    terms: PackageTermsDto.fromJson(
      (json['terms'] as Map).cast<String, dynamic>(),
    ),
    status: json['status'] as String,
    eligibleTeacherIds: (json['eligible_teacher_ids'] as List?) ?? const [],
    policyVersion: json['policy_version'] as String,
    updatedAt: json['updated_at'] as String,
    autoRenew: json['auto_renew'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'plan_id': planId,
    'market_code': marketCode,
    'localized_name': localizedName,
    'localized_description': localizedDescription,
    'terms': terms.toJson(),
    'status': status,
    'eligible_teacher_ids': eligibleTeacherIds,
    'policy_version': policyVersion,
    'updated_at': updatedAt,
    'auto_renew': autoRenew,
  };
}

class PackageOrderDto {
  const PackageOrderDto({
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
  final PackageTermsDto terms;
  final PackagePaymentInstructionDto paymentInstruction;
  final String status;
  final String createdAt;
  final String expiresAt;
  final String? guardianId;
  final String? cityId;
  final String? compatibilityMeetingId;
  final String? idempotencyKey;
  final String? resultingPackageId;
  final String? rejectionReason;
  final String? resolvedByActorId;
  final String? resolvedAt;

  factory PackageOrderDto.fromJson(Map<String, dynamic> json) =>
      PackageOrderDto(
        orderId: json['order_id'] as String,
        planId: json['plan_id'] as String,
        learnerId: json['learner_id'] as String,
        teacherId: json['teacher_id'] as String,
        marketCode: json['market_code'] as String,
        terms: PackageTermsDto.fromJson(
          (json['terms'] as Map).cast<String, dynamic>(),
        ),
        paymentInstruction: PackagePaymentInstructionDto.fromJson(
          (json['payment_instruction'] as Map).cast<String, dynamic>(),
        ),
        status: json['status'] as String,
        createdAt: json['created_at'] as String,
        expiresAt: json['expires_at'] as String,
        guardianId: json['guardian_id'] as String?,
        cityId: json['city_id'] as String?,
        compatibilityMeetingId: json['compatibility_meeting_id'] as String?,
        idempotencyKey: json['idempotency_key'] as String?,
        resultingPackageId: json['resulting_package_id'] as String?,
        rejectionReason: json['rejection_reason'] as String?,
        resolvedByActorId: json['resolved_by_actor_id'] as String?,
        resolvedAt: json['resolved_at'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'order_id': orderId,
    'plan_id': planId,
    'learner_id': learnerId,
    'teacher_id': teacherId,
    'market_code': marketCode,
    'terms': terms.toJson(),
    'payment_instruction': paymentInstruction.toJson(),
    'status': status,
    'created_at': createdAt,
    'expires_at': expiresAt,
    'guardian_id': guardianId,
    'city_id': cityId,
    'compatibility_meeting_id': compatibilityMeetingId,
    'idempotency_key': idempotencyKey,
    'resulting_package_id': resultingPackageId,
    'rejection_reason': rejectionReason,
    'resolved_by_actor_id': resolvedByActorId,
    'resolved_at': resolvedAt,
  };
}

class StudentPackageCountersDto {
  const StudentPackageCountersDto({
    required this.issuedCredits,
    required this.availableCredits,
    required this.reservedCredits,
    required this.consumedCredits,
    required this.restoredCredits,
    required this.expiredCredits,
    required this.adjustPositiveTotal,
    required this.adjustNegativeTotal,
  });

  final int issuedCredits;
  final int availableCredits;
  final int reservedCredits;
  final int consumedCredits;
  final int restoredCredits;
  final int expiredCredits;
  final int adjustPositiveTotal;
  final int adjustNegativeTotal;

  factory StudentPackageCountersDto.fromJson(Map<String, dynamic> json) =>
      StudentPackageCountersDto(
        issuedCredits: (json['issued_credits'] as num).toInt(),
        availableCredits: (json['available_credits'] as num).toInt(),
        reservedCredits: (json['reserved_credits'] as num).toInt(),
        consumedCredits: (json['consumed_credits'] as num).toInt(),
        restoredCredits: (json['restored_credits'] as num).toInt(),
        expiredCredits: (json['expired_credits'] as num).toInt(),
        adjustPositiveTotal: (json['adjust_positive_total'] as num).toInt(),
        adjustNegativeTotal: (json['adjust_negative_total'] as num).toInt(),
      );

  Map<String, dynamic> toJson() => {
    'issued_credits': issuedCredits,
    'available_credits': availableCredits,
    'reserved_credits': reservedCredits,
    'consumed_credits': consumedCredits,
    'restored_credits': restoredCredits,
    'expired_credits': expiredCredits,
    'adjust_positive_total': adjustPositiveTotal,
    'adjust_negative_total': adjustNegativeTotal,
  };
}

class StudentPackageDto {
  const StudentPackageDto({
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
  final PackageTermsDto terms;
  final StudentPackageCountersDto counters;
  final String status;
  final int version;
  final String activatedAt;
  final String expiresAt;
  final String policyVersion;
  final String? guardianId;
  final String? completedAt;
  final String? lastMovementId;
  final bool suspended;

  factory StudentPackageDto.fromJson(Map<String, dynamic> json) =>
      StudentPackageDto(
        packageId: json['package_id'] as String,
        orderId: json['order_id'] as String,
        planId: json['plan_id'] as String,
        learnerId: json['learner_id'] as String,
        teacherId: json['teacher_id'] as String,
        marketCode: json['market_code'] as String,
        terms: PackageTermsDto.fromJson(
          (json['terms'] as Map).cast<String, dynamic>(),
        ),
        counters: StudentPackageCountersDto.fromJson(
          (json['counters'] as Map).cast<String, dynamic>(),
        ),
        status: json['status'] as String,
        version: (json['version'] as num).toInt(),
        activatedAt: json['activated_at'] as String,
        expiresAt: json['expires_at'] as String,
        policyVersion: json['policy_version'] as String,
        guardianId: json['guardian_id'] as String?,
        completedAt: json['completed_at'] as String?,
        lastMovementId: json['last_movement_id'] as String?,
        suspended: json['suspended'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
    'package_id': packageId,
    'order_id': orderId,
    'plan_id': planId,
    'learner_id': learnerId,
    'teacher_id': teacherId,
    'market_code': marketCode,
    'terms': terms.toJson(),
    'counters': counters.toJson(),
    'status': status,
    'version': version,
    'activated_at': activatedAt,
    'expires_at': expiresAt,
    'policy_version': policyVersion,
    'guardian_id': guardianId,
    'completed_at': completedAt,
    'last_movement_id': lastMovementId,
    'suspended': suspended,
  };
}

class PackageCreditMovementDto {
  const PackageCreditMovementDto({
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
  final String type;
  final int quantity;
  final String reasonCode;
  final String policyVersion;
  final String createdAt;
  final String? bookingId;
  final String? sessionId;
  final String? orderId;
  final String? actorId;
  final String? idempotencyKey;

  factory PackageCreditMovementDto.fromJson(Map<String, dynamic> json) =>
      PackageCreditMovementDto(
        movementId: json['movement_id'] as String,
        packageId: json['package_id'] as String,
        type: json['type'] as String,
        quantity: (json['quantity'] as num).toInt(),
        reasonCode: json['reason_code'] as String,
        policyVersion: json['policy_version'] as String,
        createdAt: json['created_at'] as String,
        bookingId: json['booking_id'] as String?,
        sessionId: json['session_id'] as String?,
        orderId: json['order_id'] as String?,
        actorId: json['actor_id'] as String?,
        idempotencyKey: json['idempotency_key'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'movement_id': movementId,
    'package_id': packageId,
    'type': type,
    'quantity': quantity,
    'reason_code': reasonCode,
    'policy_version': policyVersion,
    'created_at': createdAt,
    'booking_id': bookingId,
    'session_id': sessionId,
    'order_id': orderId,
    'actor_id': actorId,
    'idempotency_key': idempotencyKey,
  };
}
