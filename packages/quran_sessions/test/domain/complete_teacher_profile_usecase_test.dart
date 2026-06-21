import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/src/domain/entities/session_policy.dart';
import 'package:quran_sessions/src/domain/entities/user_profile.dart';
import 'package:quran_sessions/src/domain/failures/quran_sessions_failure.dart';
import 'package:quran_sessions/src/domain/usecases/complete_teacher_profile_usecase.dart';

import '../helpers/fakes/fake_session_policy_repository.dart';
import '../helpers/fakes/fake_user_profile_repository.dart';

void main() {
  late FakeUserProfileRepository repo;
  late FakeSessionPolicyRepository policyRepo;
  late CompleteTeacherProfileUseCase useCase;

  setUp(() {
    repo = FakeUserProfileRepository();
    policyRepo = FakeSessionPolicyRepository();
    // Default config: minimum teacher age = 18.
    useCase = CompleteTeacherProfileUseCase(repo, policyRepo);
  });

  DateTime ageYears(int years) {
    final now = DateTime.now();
    return DateTime(now.year - years, now.month, now.day);
  }

  Future<QuranSessionsFailure?> failureFor(DateTime dob) async {
    final r = await useCase.call(
      userId: 'teacher_1',
      gender: UserGender.male,
      dateOfBirth: dob,
    );
    return r.fold((f) => f, (_) => null);
  }

  Future<UserProfile?> profileFor(DateTime dob) async {
    final r = await useCase.call(
      userId: 'teacher_1',
      gender: UserGender.male,
      dateOfBirth: dob,
    );
    return r.fold((_) => null, (p) => p);
  }

  group('valid DOB', () {
    test('30-year-old succeeds', () async {
      check(await profileFor(ageYears(30))).isNotNull();
    });

    test('exactly the minimum age (18) is accepted', () async {
      check(await failureFor(ageYears(18))).isNull();
    });

    test('1900-01-01 is accepted', () async {
      check(await failureFor(DateTime(1900))).isNull();
    });
  });

  group('too young DOB', () {
    test(
      '17-year-old (younger than 18) returns DateOfBirthTooRecent',
      () async {
        check(
          await failureFor(ageYears(17)),
        ).isA<DateOfBirthTooRecentFailure>();
      },
    );

    test('a 16-year-old is accepted once the limit is lowered to 16', () async {
      final sixteen = ageYears(16);
      check(await failureFor(sixteen)).isA<DateOfBirthTooRecentFailure>();
      policyRepo.globalPolicy = const QuranSessionSafetyPolicy(
        minimumTeacherAgeYears: 16,
      );
      check(await failureFor(sixteen)).isNull();
    });
  });

  group('future DOB', () {
    test('tomorrow returns FutureDateOfBirthFailure', () async {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      check(await failureFor(tomorrow)).isA<FutureDateOfBirthFailure>();
    });

    test('far future returns FutureDateOfBirthFailure', () async {
      check(
        await failureFor(DateTime(2099, 12, 31)),
      ).isA<FutureDateOfBirthFailure>();
    });
  });

  group('invalid DOB', () {
    test('1899 returns InvalidDateOfBirthFailure', () async {
      check(
        await failureFor(DateTime(1899, 1, 1)),
      ).isA<InvalidDateOfBirthFailure>();
    });
  });

  test('policy repository failure is propagated', () async {
    policyRepo.failWith = const NetworkFailure();
    check(await failureFor(ageYears(30))).isA<NetworkFailure>();
  });

  test('profile repository failure is propagated after valid DOB', () async {
    repo.failWith = const NetworkFailure();
    check(await failureFor(ageYears(30))).isA<NetworkFailure>();
  });
}
