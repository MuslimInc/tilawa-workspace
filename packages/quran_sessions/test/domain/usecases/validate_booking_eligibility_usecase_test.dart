import 'package:checks/checks.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/src/domain/entities/market_config.dart';
import 'package:quran_sessions/src/domain/entities/session_policy.dart';
import 'package:quran_sessions/src/domain/entities/session_pricing_type.dart';
import 'package:quran_sessions/src/domain/entities/teacher_verification_status.dart';
import 'package:quran_sessions/src/domain/entities/user_profile.dart';
import 'package:quran_sessions/src/domain/failures/quran_sessions_failure.dart';
import 'package:quran_sessions/src/domain/usecases/validate_booking_eligibility_usecase.dart';

import '../../helpers/fakes/fake_market_config_repository.dart';
import '../../helpers/fakes/fake_session_policy_repository.dart';
import '../../helpers/fakes/fake_teacher_repository.dart';
import '../../helpers/fakes/fake_user_profile_repository.dart';
import '../../helpers/fixtures.dart';

void main() {
  late FakeUserProfileRepository profileRepo;
  late FakeSessionPolicyRepository policyRepo;
  late FakeTeacherRepository teacherRepo;
  late FakeMarketConfigRepository marketRepo;
  late ValidateBookingEligibilityUseCase useCase;

  setUp(() {
    profileRepo = FakeUserProfileRepository(
      profile: makeProfile(
        userId: 'student_1',
        gender: UserGender.male,
        dateOfBirth: DateTime(1995, 6, 15),
        countryCode: 'EG',
        cityId: 'cairo',
      ),
    );
    policyRepo = FakeSessionPolicyRepository();
    teacherRepo = FakeTeacherRepository()
      ..teachers = [
        makeTeacher(
          id: 'teacher_1',
          pricingType: SessionPricingType.free,
        ),
      ];
    marketRepo = FakeMarketConfigRepository();
    useCase = ValidateBookingEligibilityUseCase(
      profileRepository: profileRepo,
      policyRepository: policyRepo,
      teacherRepository: teacherRepo,
      marketConfigRepository: marketRepo,
    );
  });

  Future<void> expectEligible() async {
    final result = await useCase(
      studentId: 'student_1',
      teacherId: 'teacher_1',
    );
    check(result.isRight()).isTrue();
  }

  group('ValidateBookingEligibilityUseCase', () {
    test('eligible adult student with verified free teacher', expectEligible);

    test('rejects incomplete student profile', () async {
      profileRepo = FakeUserProfileRepository(
        profile: makeProfile(userId: 'student_1'),
      );
      useCase = ValidateBookingEligibilityUseCase(
        profileRepository: profileRepo,
        policyRepository: policyRepo,
        teacherRepository: teacherRepo,
        marketConfigRepository: marketRepo,
      );

      final result = await useCase(
        studentId: 'student_1',
        teacherId: 'teacher_1',
      );

      check(result).isA<Left<QuranSessionsFailure, void>>();
      result.fold((failure) {
        check(failure).isA<ProfileIncompleteFailure>();
      }, (_) => fail('expected failure'));
    });

    test('rejects blocked student account', () async {
      profileRepo = FakeUserProfileRepository(
        profile:
            makeProfile(
              userId: 'student_1',
              gender: UserGender.male,
              dateOfBirth: DateTime(1995, 6, 15),
              countryCode: 'EG',
              cityId: 'cairo',
              accountStatus: AccountStatus.blocked,
            ).copyWith(
              restrictionReason: AccountRestrictionReason.policyViolation,
            ),
      );
      useCase = ValidateBookingEligibilityUseCase(
        profileRepository: profileRepo,
        policyRepository: policyRepo,
        teacherRepository: teacherRepo,
        marketConfigRepository: marketRepo,
      );

      final result = await useCase(
        studentId: 'student_1',
        teacherId: 'teacher_1',
      );

      check(result.fold((f) => f, (_) => null)).isA<AccountBlockedFailure>();
    });

    test('rejects unverified teacher', () async {
      teacherRepo.teachers = [
        makeTeacher(
          status: TeacherVerificationStatus.pending,
          pricingType: SessionPricingType.free,
        ),
      ];

      final result = await useCase(
        studentId: 'student_1',
        teacherId: 'teacher_1',
      );

      check(
        result.fold((f) => f, (_) => null),
      ).isA<TeacherNotVerifiedFailure>();
    });

    test('rejects disallowed gender combination', () async {
      policyRepo.globalPolicy = const QuranSessionSafetyPolicy(
        globalAllowMaleTeacherFemaleStudent: false,
      );
      profileRepo = FakeUserProfileRepository(
        profile: makeProfile(
          userId: 'student_1',
          gender: UserGender.female,
          dateOfBirth: DateTime(1995, 6, 15),
          countryCode: 'EG',
          cityId: 'cairo',
        ),
      );
      useCase = ValidateBookingEligibilityUseCase(
        profileRepository: profileRepo,
        policyRepository: policyRepo,
        teacherRepository: teacherRepo,
        marketConfigRepository: marketRepo,
      );

      final result = await useCase(
        studentId: 'student_1',
        teacherId: 'teacher_1',
      );

      check(result.fold((f) => f, (_) => null)).isA<GenderNotAllowedFailure>();
    });

    test('rejects child when teacher cannot teach children', () async {
      profileRepo = FakeUserProfileRepository(
        profile: makeProfile(
          userId: 'student_1',
          gender: UserGender.male,
          dateOfBirth: DateTime(2018, 1, 1),
          countryCode: 'EG',
          cityId: 'cairo',
        ),
      );
      policyRepo.teacherPolicies['teacher_1'] = const TeacherEligibilityPolicy(
        allowedStudentGender: TeacherAllowedStudentGender.both,
        canTeachChildren: false,
      );
      useCase = ValidateBookingEligibilityUseCase(
        profileRepository: profileRepo,
        policyRepository: policyRepo,
        teacherRepository: teacherRepo,
        marketConfigRepository: marketRepo,
      );

      final result = await useCase(
        studentId: 'student_1',
        teacherId: 'teacher_1',
      );

      check(result.fold((f) => f, (_) => null)).isA<AgeNotAllowedFailure>();
    });

    test('allows child when teacher accepts children', () async {
      profileRepo = FakeUserProfileRepository(
        profile: makeProfile(
          userId: 'student_1',
          gender: UserGender.male,
          dateOfBirth: DateTime(2018, 1, 1),
          countryCode: 'EG',
          cityId: 'cairo',
        ),
      );
      useCase = ValidateBookingEligibilityUseCase(
        profileRepository: profileRepo,
        policyRepository: policyRepo,
        teacherRepository: teacherRepo,
        marketConfigRepository: marketRepo,
      );

      final result = await useCase(
        studentId: 'student_1',
        teacherId: 'teacher_1',
      );

      check(result.isRight()).isTrue();
    });

    test('rejects paid teacher without market price', () async {
      teacherRepo.teachers = [
        makeTeacher(pricingType: SessionPricingType.fixedPerSession),
      ];
      teacherRepo.priceResolver = (_) => null;

      final result = await useCase(
        studentId: 'student_1',
        teacherId: 'teacher_1',
      );

      check(
        result.fold((f) => f, (_) => null),
      ).isA<TeacherNotInMarketFailure>();
    });

    test('allows free teacher without market price lookup', () async {
      teacherRepo.teachers = [
        makeTeacher(pricingType: SessionPricingType.free),
      ];
      teacherRepo.priceResolver = (_) => null;

      await expectEligible();
    });

    test('rejects when teacher is not found', () async {
      teacherRepo.teachers = [];

      final result = await useCase(
        studentId: 'student_1',
        teacherId: 'teacher_1',
      );

      check(result.fold((f) => f, (_) => null)).isA<NotFoundFailure>();
    });

    test('rejects disabled city in market', () async {
      marketRepo.marketConfigOverride = const MarketConfig(
        countryCode: 'EG',
        countryName: 'Egypt',
        currencyCode: 'EGP',
        defaultCityId: 'cairo',
        isEnabled: true,
        cities: [
          CityConfig(
            cityId: 'cairo',
            cityName: 'Cairo',
            countryCode: 'EG',
            timezone: 'Africa/Cairo',
            currencyCode: 'EGP',
            isEnabled: false,
          ),
        ],
        minSessionPrice: 0,
        maxSessionPrice: 1000,
        platformCommissionPercent: 0,
      );

      final result = await useCase(
        studentId: 'student_1',
        teacherId: 'teacher_1',
      );

      check(result.fold((f) => f, (_) => null)).isA<MarketNotEnabledFailure>();
    });
  });
}
