import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/src/domain/entities/session_policy.dart';
import 'package:quran_sessions/src/domain/entities/user_profile.dart';
import 'package:quran_sessions/src/domain/failures/quran_sessions_failure.dart';
import 'package:quran_sessions/src/domain/usecases/complete_student_profile_usecase.dart';

import '../helpers/fakes/fake_session_policy_repository.dart';
import '../helpers/fakes/fake_user_profile_repository.dart';

const _userId = 'student_1';

void main() {
  late FakeUserProfileRepository repo;
  late FakeSessionPolicyRepository policyRepo;
  late CompleteStudentProfileUseCase useCase;

  setUp(() {
    repo = FakeUserProfileRepository();
    policyRepo = FakeSessionPolicyRepository();
    // Default config: minimum student age = 3.
    useCase = CompleteStudentProfileUseCase(repo, policyRepo);
  });

  // Age-relative helpers so tests are clock-independent.
  DateTime ageYears(int years) {
    final now = DateTime.now();
    return DateTime(now.year - years, now.month, now.day);
  }

  Future<QuranSessionsFailure?> failureFor(DateTime dob) async {
    final r = await useCase.call(
      userId: _userId,
      gender: UserGender.male,
      dateOfBirth: dob,
      countryCode: 'EG',
      countryName: 'مصر',
      cityId: 'cairo',
      cityName: 'القاهرة',
      currencyCode: 'EGP',
      timezone: 'Africa/Cairo',
    );
    return r.fold((f) => f, (_) => null);
  }

  Future<UserProfile?> profileFor(DateTime dob) async {
    final r = await useCase.call(
      userId: _userId,
      gender: UserGender.male,
      dateOfBirth: dob,
      countryCode: 'EG',
      countryName: 'مصر',
      cityId: 'cairo',
      cityName: 'القاهرة',
      currencyCode: 'EGP',
      timezone: 'Africa/Cairo',
    );
    return r.fold((_) => null, (p) => p);
  }

  // ── Valid DOB (default min age 3) ─────────────────────────────────────────────

  group('valid DOB', () {
    test('10-year-old succeeds and persists profile', () async {
      final dob = ageYears(10);
      final profile = await profileFor(dob);
      check(profile).isNotNull();
      check(profile!.dateOfBirth).equals(dob);
    });

    test('exactly the minimum age (3) is accepted', () async {
      check(await failureFor(ageYears(3))).isNull();
    });

    test('1900-01-01 is accepted (oldest allowed)', () async {
      check(await failureFor(DateTime(1900))).isNull();
    });
  });

  // ── Too young for the configured minimum ──────────────────────────────────────

  group('too young DOB', () {
    test('1-year-old (younger than 3) returns DateOfBirthTooRecent', () async {
      check(await failureFor(ageYears(1))).isA<DateOfBirthTooRecentFailure>();
    });

    test('config change to 5 rejects a 4-year-old (was valid at 3)', () async {
      final fourYearOld = ageYears(4);
      // Valid under the default (3)…
      check(await failureFor(fourYearOld)).isNull();
      // …then config bumps the minimum to 5 — no code change, new limit wins.
      policyRepo.globalPolicy = const QuranSessionSafetyPolicy(
        minimumStudentAgeYears: 5,
      );
      check(
        await failureFor(fourYearOld),
      ).isA<DateOfBirthTooRecentFailure>();
    });
  });

  // ── Future DOB ────────────────────────────────────────────────────────────────

  group('future DOB', () {
    test('tomorrow returns FutureDateOfBirthFailure', () async {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      check(await failureFor(tomorrow)).isA<FutureDateOfBirthFailure>();
    });

    test('repository is never called when DOB is invalid', () async {
      final initialProfile = (await repo.getProfile(
        _userId,
      )).fold((_) => null, (p) => p);
      await failureFor(DateTime(2099, 12, 31));
      final afterProfile = (await repo.getProfile(
        _userId,
      )).fold((_) => null, (p) => p);
      check(afterProfile).equals(initialProfile);
    });
  });

  // ── Invalid DOB (too old) ─────────────────────────────────────────────────────

  group('invalid DOB', () {
    test('1899-12-31 returns InvalidDateOfBirthFailure', () async {
      check(
        await failureFor(DateTime(1899, 12, 31)),
      ).isA<InvalidDateOfBirthFailure>();
    });

    test('year 1800 returns InvalidDateOfBirthFailure', () async {
      check(
        await failureFor(DateTime(1800, 1, 1)),
      ).isA<InvalidDateOfBirthFailure>();
    });
  });

  // ── Final-gate behaviour & propagation ────────────────────────────────────────

  test('valid profile saves all fields', () async {
    final profile = await profileFor(ageYears(20));
    check(profile).isNotNull();
    check(profile!.gender).equals(UserGender.male);
    check(profile.countryCode).equals('EG');
    check(profile.cityId).equals('cairo');
  });

  test('policy repository failure is propagated', () async {
    policyRepo.failWith = const NetworkFailure();
    check(await failureFor(ageYears(20))).isA<NetworkFailure>();
  });

  test('profile repository failure is propagated after valid DOB', () async {
    repo.failWith = const ServerFailure(statusCode: 500);
    check(await failureFor(ageYears(20))).isA<ServerFailure>();
  });
}
