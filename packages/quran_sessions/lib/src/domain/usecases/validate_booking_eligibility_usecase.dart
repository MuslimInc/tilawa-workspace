import 'package:dartz_plus/dartz_plus.dart';

import '../entities/session_pricing_type.dart';
import '../entities/teacher_verification_status.dart';
import '../entities/user_profile.dart';
import '../failures/quran_sessions_failure.dart';
import '../repositories/market_config_repository.dart';
import '../repositories/session_policy_repository.dart';
import '../repositories/teacher_repository.dart';
import '../repositories/user_profile_repository.dart';

/// Validates that a student is eligible to book a session with a given teacher.
///
/// All eligibility rules live here — in the domain layer — so the checks
/// cannot be bypassed by the UI. BLoCs call this before loading slots or
/// confirming a booking.
///
/// Returns [Right(null)] when eligible, or a typed failure describing exactly
/// why the booking is not allowed.
class ValidateBookingEligibilityUseCase {
  const ValidateBookingEligibilityUseCase({
    required UserProfileRepository profileRepository,
    required SessionPolicyRepository policyRepository,
    required TeacherRepository teacherRepository,
    required MarketConfigRepository marketConfigRepository,
  }) : _profileRepo = profileRepository,
       _policyRepo = policyRepository,
       _teacherRepo = teacherRepository,
       _marketRepo = marketConfigRepository;

  final UserProfileRepository _profileRepo;
  final SessionPolicyRepository _policyRepo;
  final TeacherRepository _teacherRepo;
  final MarketConfigRepository _marketRepo;

  Future<Either<QuranSessionsFailure, void>> call({
    required String studentId,
    required String teacherId,
  }) async {
    // ── 1. Student profile ─────────────────────────────────────────────────
    final studentResult = await _profileRepo.getProfile(studentId);
    if (studentResult.isLeft()) return studentResult.map((_) {});

    final student = studentResult.fold((_) => throw StateError(''), (p) => p);

    if (!student.isActive) {
      return Left(
        AccountBlockedFailure(
          accountId: studentId,
          reason: student.restrictionReason?.name,
        ),
      );
    }
    if (!student.isComplete) {
      // isComplete now requires gender, dateOfBirth, countryCode, cityId.
      return Left(
        ProfileIncompleteFailure(missingFields: student.missingFields),
      );
    }

    // ── 2. Market check ────────────────────────────────────────────────────
    final marketResult = await _marketRepo.getMarketConfig(
      student.countryCode!,
    );
    if (marketResult.isLeft()) return marketResult.map((_) {});

    final market = marketResult.fold((_) => throw StateError(''), (m) => m);

    if (!market.isEnabled) {
      return Left(
        MarketNotEnabledFailure(countryCode: student.countryCode!),
      );
    }

    final city = market.cityById(student.cityId!);
    if (city != null && !city.isEnabled) {
      return Left(
        MarketNotEnabledFailure(
          countryCode: student.countryCode!,
          cityId: student.cityId,
        ),
      );
    }

    // ── 3. Teacher ─────────────────────────────────────────────────────────
    final teacherResult = await _teacherRepo.getTeacherById(teacherId);
    if (teacherResult.isLeft()) return teacherResult.map((_) {});

    final teacher = teacherResult.fold((_) => throw StateError(''), (t) => t);

    if (teacher.verificationStatus != TeacherVerificationStatus.verified) {
      return Left(TeacherNotVerifiedFailure(teacherId: teacherId));
    }

    // ── 3b. Teacher pricing in student market ──────────────────────────────
    // Free teachers skip this check. Paid teachers must have a price
    // configured for the student's market — if not, booking is rejected.
    if (teacher.pricingType != SessionPricingType.free) {
      final priceResult = await _teacherRepo.resolveTeacherPrice(
        teacherId,
        countryCode: student.countryCode!,
        cityId: student.cityId!,
      );
      if (priceResult.isLeft()) return priceResult.map((_) {});
      final resolvedPrice = priceResult.fold(
        (_) => throw StateError(''),
        (p) => p,
      );
      if (resolvedPrice == null) {
        return Left(
          TeacherNotInMarketFailure(
            teacherId: teacherId,
            countryCode: student.countryCode!,
          ),
        );
      }
    }

    // ── 4. Global safety policy ────────────────────────────────────────────
    final policyResult = await _policyRepo.getGlobalPolicy();
    if (policyResult.isLeft()) return policyResult.map((_) {});

    final policy = policyResult.fold((_) => throw StateError(''), (p) => p);

    // ── 5. Teacher eligibility policy ──────────────────────────────────────
    final teacherPolicyResult = await _policyRepo.getTeacherEligibilityPolicy(
      teacherId,
    );
    if (teacherPolicyResult.isLeft()) return teacherPolicyResult.map((_) {});

    final teacherPolicy = teacherPolicyResult.fold(
      (_) => throw StateError(''),
      (p) => p,
    );

    // ── 6. Determine age group ─────────────────────────────────────────────
    final ageGroup = student.ageGroup(policy.childAgeThreshold);

    // ── 7. Gender check ────────────────────────────────────────────────────
    final studentGender = student.gender!;
    final teacherGender = teacher.gender;

    if (!policy.isGenderCombinationAllowed(
      teacherGender: teacherGender,
      studentGender: studentGender,
      teacherPolicy: teacherPolicy,
    )) {
      return Left(
        GenderNotAllowedFailure(
          teacherGender: teacherGender.name,
          studentGender: studentGender.name,
        ),
      );
    }

    // ── 8. Age check ───────────────────────────────────────────────────────
    if (ageGroup == UserAgeGroup.child) {
      if (!teacherPolicy.canTeachChildren) {
        return Left(AgeNotAllowedFailure(studentAgeGroup: ageGroup.name));
      }
      if (teacherPolicy.requiresGuardianApprovalForChildren ||
          policy.requireGuardianApprovalForChildren) {
        return Left(GuardianApprovalRequiredFailure(studentId: studentId));
      }
    }

    return const Right(null);
  }
}
