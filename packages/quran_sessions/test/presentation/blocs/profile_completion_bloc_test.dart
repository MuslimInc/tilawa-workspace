import 'package:bloc_test/bloc_test.dart';
import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/src/domain/entities/market_config.dart';
import 'package:quran_sessions/src/domain/entities/session_policy.dart';
import 'package:quran_sessions/src/domain/entities/user_profile.dart';
import 'package:quran_sessions/src/domain/failures/quran_sessions_failure.dart';
import 'package:quran_sessions/src/domain/usecases/complete_student_profile_usecase.dart';
import 'package:quran_sessions/src/domain/usecases/get_market_config_usecase.dart';
import 'package:quran_sessions/src/domain/usecases/get_session_policy_usecase.dart';
import 'package:quran_sessions/src/domain/usecases/get_user_profile_usecase.dart';
import 'package:quran_sessions/src/presentation/blocs/profile_completion/profile_completion_bloc.dart';
import 'package:quran_sessions/src/presentation/blocs/profile_completion/profile_completion_event.dart';
import 'package:quran_sessions/src/presentation/blocs/profile_completion/profile_completion_state.dart';

import '../../helpers/fakes/fake_market_config_repository.dart';
import '../../helpers/fakes/fake_session_policy_repository.dart';
import '../../helpers/fakes/fake_user_profile_repository.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

final _cairo = const CityConfig(
  cityId: 'cairo',
  cityName: 'القاهرة',
  countryCode: 'EG',
  timezone: 'Africa/Cairo',
  currencyCode: 'EGP',
  isEnabled: true,
  minSessionPrice: 100,
  maxSessionPrice: 2000,
);

final _egypt = MarketConfig(
  countryCode: 'EG',
  countryName: 'مصر',
  currencyCode: 'EGP',
  defaultCityId: 'cairo',
  isEnabled: true,
  minSessionPrice: 100,
  maxSessionPrice: 2000,
  platformCommissionPercent: 15,
  cities: [_cairo],
);

const _userId = 'student_1';

// Default configured minimum student age used across most tests.
const _minStudentAge = 3;

// A DOB exactly [years] old relative to the real clock — keeps tests
// independent of the date they run on (the BLoC uses DateTime.now()).
DateTime _ageYears(int years) {
  final now = DateTime.now();
  return DateTime(now.year - years, now.month, now.day);
}

ProfileCompletionBloc _makeBloc({
  FakeUserProfileRepository? profileRepo,
  FakeMarketConfigRepository? marketRepo,
  FakeSessionPolicyRepository? policyRepo,
}) {
  final pr = profileRepo ?? FakeUserProfileRepository();
  final mr = marketRepo ?? FakeMarketConfigRepository();
  final plr = policyRepo ?? FakeSessionPolicyRepository();
  return ProfileCompletionBloc(
    getUserProfile: GetUserProfileUseCase(pr),
    completeStudentProfile: CompleteStudentProfileUseCase(pr, plr),
    getMarketConfig: GetMarketConfigUseCase(mr),
    getSessionPolicy: GetSessionPolicyUseCase(plr),
  );
}

// A fully-loaded editing state with gender + market pre-selected.
ProfileCompletionEditing _loadedEditing({
  DateTime? selectedDateOfBirth,
  QuranSessionsFailure? dobFailure,
  int minimumStudentAgeYears = _minStudentAge,
}) => ProfileCompletionEditing(
  userId: _userId,
  availableMarkets: [_egypt],
  minimumStudentAgeYears: minimumStudentAgeYears,
  selectedGender: UserGender.male,
  selectedDateOfBirth: selectedDateOfBirth,
  dobFailure: dobFailure,
  selectedMarket: _egypt,
  selectedCity: _cairo,
);

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('load', () {
    blocTest<ProfileCompletionBloc, ProfileCompletionState>(
      'emits [Loading, Editing] on success',
      build: _makeBloc,
      act: (b) => b.add(const ProfileLoadRequested(userId: _userId)),
      expect: () => [
        isA<ProfileCompletionLoading>(),
        isA<ProfileCompletionEditing>(),
      ],
    );

    blocTest<ProfileCompletionBloc, ProfileCompletionState>(
      'loaded state carries the configured minimum student age',
      build: () {
        final plr = FakeSessionPolicyRepository()
          ..globalPolicy = const QuranSessionSafetyPolicy(
            minimumStudentAgeYears: 5,
          );
        return _makeBloc(policyRepo: plr);
      },
      act: (b) => b.add(const ProfileLoadRequested(userId: _userId)),
      expect: () => [
        isA<ProfileCompletionLoading>(),
        isA<ProfileCompletionEditing>().having(
          (s) => s.minimumStudentAgeYears,
          'minimumStudentAgeYears',
          5,
        ),
      ],
    );

    blocTest<ProfileCompletionBloc, ProfileCompletionState>(
      'emits [Loading, Failure] when profile repo fails',
      build: () {
        final pr = FakeUserProfileRepository()
          ..failWith = const NetworkFailure();
        return _makeBloc(profileRepo: pr);
      },
      act: (b) => b.add(const ProfileLoadRequested(userId: _userId)),
      expect: () => [
        isA<ProfileCompletionLoading>(),
        isA<ProfileCompletionFailure>(),
      ],
    );

    blocTest<ProfileCompletionBloc, ProfileCompletionState>(
      'emits [Loading, Failure] when market repo fails',
      build: () {
        final mr = FakeMarketConfigRepository()
          ..failWith = const NetworkFailure();
        return _makeBloc(marketRepo: mr);
      },
      act: (b) => b.add(const ProfileLoadRequested(userId: _userId)),
      expect: () => [
        isA<ProfileCompletionLoading>(),
        isA<ProfileCompletionFailure>(),
      ],
    );

    blocTest<ProfileCompletionBloc, ProfileCompletionState>(
      'emits [Loading, Failure] when policy repo fails',
      build: () {
        final plr = FakeSessionPolicyRepository()
          ..failWith = const NetworkFailure();
        return _makeBloc(policyRepo: plr);
      },
      act: (b) => b.add(const ProfileLoadRequested(userId: _userId)),
      expect: () => [
        isA<ProfileCompletionLoading>(),
        isA<ProfileCompletionFailure>(),
      ],
    );
  });

  // ── Gender ──────────────────────────────────────────────────────────────────

  group('gender selection', () {
    blocTest<ProfileCompletionBloc, ProfileCompletionState>(
      'GenderSelected updates selectedGender',
      build: _makeBloc,
      seed: () => _loadedEditing(),
      act: (b) => b.add(GenderSelected(UserGender.female)),
      expect: () => [
        isA<ProfileCompletionEditing>().having(
          (s) => s.selectedGender,
          'selectedGender',
          UserGender.female,
        ),
      ],
    );
  });

  // ── Date of birth ───────────────────────────────────────────────────────────

  group('DateOfBirthSet — valid date', () {
    final validDob = DateTime(2000, 6, 21); // far older than any min age

    blocTest<ProfileCompletionBloc, ProfileCompletionState>(
      'valid past date is stored and dobFailure is cleared',
      build: _makeBloc,
      seed: () => _loadedEditing(),
      act: (b) => b.add(DateOfBirthSet(validDob)),
      expect: () => [
        isA<ProfileCompletionEditing>()
            .having((s) => s.selectedDateOfBirth, 'dob', validDob)
            .having((s) => s.dobFailure, 'dobFailure', isNull),
      ],
    );

    blocTest<ProfileCompletionBloc, ProfileCompletionState>(
      'exactly the minimum age (3) is accepted (inclusive boundary)',
      build: _makeBloc,
      seed: () => _loadedEditing(),
      act: (b) => b.add(DateOfBirthSet(_ageYears(_minStudentAge))),
      expect: () => [
        isA<ProfileCompletionEditing>()
            .having((s) => s.selectedDateOfBirth, 'dob', isNotNull)
            .having((s) => s.dobFailure, 'dobFailure', isNull),
      ],
    );

    blocTest<ProfileCompletionBloc, ProfileCompletionState>(
      'oldest allowed date (1900-01-01) is accepted',
      build: _makeBloc,
      seed: () => _loadedEditing(),
      act: (b) => b.add(DateOfBirthSet(DateTime(1900))),
      expect: () => [
        isA<ProfileCompletionEditing>()
            .having((s) => s.selectedDateOfBirth, 'dob', isNotNull)
            .having((s) => s.dobFailure, 'dobFailure', isNull),
      ],
    );

    blocTest<ProfileCompletionBloc, ProfileCompletionState>(
      'valid DOB clears a pre-existing dobFailure',
      build: _makeBloc,
      seed: () => _loadedEditing(
        dobFailure: const FutureDateOfBirthFailure(),
      ),
      act: (b) => b.add(DateOfBirthSet(DateTime(2000, 6, 21))),
      expect: () => [
        isA<ProfileCompletionEditing>().having(
          (s) => s.dobFailure,
          'dobFailure',
          isNull,
        ),
      ],
    );
  });

  group('DateOfBirthSet — future date', () {
    blocTest<ProfileCompletionBloc, ProfileCompletionState>(
      'tomorrow → clears selectedDateOfBirth, sets FutureDateOfBirthFailure',
      build: _makeBloc,
      seed: () => _loadedEditing(),
      act: (b) {
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        b.add(DateOfBirthSet(tomorrow));
      },
      expect: () => [
        isA<ProfileCompletionEditing>()
            .having((s) => s.selectedDateOfBirth, 'dob', isNull)
            .having(
              (s) => s.dobFailure,
              'dobFailure',
              isA<FutureDateOfBirthFailure>(),
            ),
      ],
    );

    blocTest<ProfileCompletionBloc, ProfileCompletionState>(
      'future DOB: canSubmit is false even if all other fields are filled',
      build: _makeBloc,
      seed: () => _loadedEditing(),
      act: (b) {
        final future = DateTime(DateTime.now().year + 1, 1, 1);
        b.add(DateOfBirthSet(future));
      },
      verify: (b) {
        final s = b.state as ProfileCompletionEditing;
        check(s.canSubmit).isFalse();
      },
    );
  });

  group('DateOfBirthSet — too young (configured minimum age)', () {
    blocTest<ProfileCompletionBloc, ProfileCompletionState>(
      'younger than min age → clears DOB, sets DateOfBirthTooRecentFailure',
      build: _makeBloc,
      seed: () => _loadedEditing(),
      act: (b) => b.add(DateOfBirthSet(_ageYears(1))), // 1 yr < min 3
      expect: () => [
        isA<ProfileCompletionEditing>()
            .having((s) => s.selectedDateOfBirth, 'dob', isNull)
            .having(
              (s) => s.dobFailure,
              'dobFailure',
              isA<DateOfBirthTooRecentFailure>(),
            ),
      ],
    );

    blocTest<ProfileCompletionBloc, ProfileCompletionState>(
      'too-young DOB: canSubmit is false even if all other fields are filled',
      build: _makeBloc,
      seed: () => _loadedEditing(),
      act: (b) => b.add(DateOfBirthSet(_ageYears(1))),
      verify: (b) {
        final s = b.state as ProfileCompletionEditing;
        check(s.canSubmit).isFalse();
      },
    );

    blocTest<ProfileCompletionBloc, ProfileCompletionState>(
      'a 4-year-old is rejected when the configured minimum is 5',
      build: _makeBloc,
      // The picker rule and validator both read minimumStudentAgeYears from
      // state — here it is 5, so a 4-year-old is too young.
      seed: () => _loadedEditing(minimumStudentAgeYears: 5),
      act: (b) => b.add(DateOfBirthSet(_ageYears(4))),
      expect: () => [
        isA<ProfileCompletionEditing>()
            .having((s) => s.selectedDateOfBirth, 'dob', isNull)
            .having(
              (s) => s.dobFailure,
              'dobFailure',
              isA<DateOfBirthTooRecentFailure>(),
            ),
      ],
    );
  });

  group('DateOfBirthSet — invalid date', () {
    blocTest<ProfileCompletionBloc, ProfileCompletionState>(
      '1899-12-31 → sets InvalidDateOfBirthFailure',
      build: _makeBloc,
      seed: () => _loadedEditing(),
      act: (b) => b.add(DateOfBirthSet(DateTime(1899, 12, 31))),
      expect: () => [
        isA<ProfileCompletionEditing>()
            .having((s) => s.selectedDateOfBirth, 'dob', isNull)
            .having(
              (s) => s.dobFailure,
              'dobFailure',
              isA<InvalidDateOfBirthFailure>(),
            ),
      ],
    );
  });

  // ── canSubmit ───────────────────────────────────────────────────────────────

  group('canSubmit', () {
    ProfileCompletionEditing editing({
      UserGender? gender = UserGender.male,
      DateTime? dob,
      QuranSessionsFailure? dobFailure,
      MarketConfig? market,
      CityConfig? city,
    }) => ProfileCompletionEditing(
      userId: _userId,
      availableMarkets: [_egypt],
      minimumStudentAgeYears: _minStudentAge,
      selectedGender: gender,
      selectedDateOfBirth: dob,
      dobFailure: dobFailure,
      selectedMarket: market,
      selectedCity: city,
    );

    test('false when no gender', () {
      check(
        editing(
          gender: null,
          dob: DateTime(2000),
          market: _egypt,
          city: _cairo,
        ).canSubmit,
      ).isFalse();
    });

    test('false when no DOB', () {
      check(editing(market: _egypt, city: _cairo).canSubmit).isFalse();
    });

    test('false when dobFailure is set', () {
      check(
        editing(
          dob: DateTime(2000),
          dobFailure: const FutureDateOfBirthFailure(),
          market: _egypt,
          city: _cairo,
        ).canSubmit,
      ).isFalse();
    });

    test('false when no market', () {
      check(editing(dob: DateTime(2000)).canSubmit).isFalse();
    });

    test('false when no city', () {
      check(editing(dob: DateTime(2000), market: _egypt).canSubmit).isFalse();
    });

    test('true when all fields valid', () {
      check(
        editing(dob: DateTime(2000), market: _egypt, city: _cairo).canSubmit,
      ).isTrue();
    });
  });

  // ── Submit ──────────────────────────────────────────────────────────────────

  group('ProfileSubmitted', () {
    blocTest<ProfileCompletionBloc, ProfileCompletionState>(
      'cannot complete profile without DOB — submit is a no-op',
      build: _makeBloc,
      seed: () => ProfileCompletionEditing(
        userId: _userId,
        availableMarkets: [_egypt],
        minimumStudentAgeYears: _minStudentAge,
        selectedGender: UserGender.male, // no DOB
        selectedMarket: _egypt,
        selectedCity: _cairo,
      ),
      act: (b) => b.add(ProfileSubmitted(userId: _userId)),
      expect: () => [],
    );

    blocTest<ProfileCompletionBloc, ProfileCompletionState>(
      'cannot complete profile with future DOB',
      build: _makeBloc,
      seed: () => ProfileCompletionEditing(
        userId: _userId,
        availableMarkets: [_egypt],
        minimumStudentAgeYears: _minStudentAge,
        selectedGender: UserGender.male,
        selectedDateOfBirth: null, // future rejected → cleared
        dobFailure: const FutureDateOfBirthFailure(),
        selectedMarket: _egypt,
        selectedCity: _cairo,
      ),
      act: (b) => b.add(ProfileSubmitted(userId: _userId)),
      expect: () => [],
    );

    blocTest<ProfileCompletionBloc, ProfileCompletionState>(
      'cannot complete profile with a too-young DOB',
      build: _makeBloc,
      seed: () => ProfileCompletionEditing(
        userId: _userId,
        availableMarkets: [_egypt],
        minimumStudentAgeYears: _minStudentAge,
        selectedGender: UserGender.male,
        selectedDateOfBirth: null, // too-young rejected → cleared
        dobFailure: const DateOfBirthTooRecentFailure(),
        selectedMarket: _egypt,
        selectedCity: _cairo,
      ),
      act: (b) => b.add(ProfileSubmitted(userId: _userId)),
      expect: () => [],
    );

    blocTest<ProfileCompletionBloc, ProfileCompletionState>(
      'cannot complete profile without gender',
      build: _makeBloc,
      seed: () => ProfileCompletionEditing(
        userId: _userId,
        availableMarkets: [_egypt],
        minimumStudentAgeYears: _minStudentAge,
        selectedDateOfBirth: DateTime(2000, 1, 1), // no gender
        selectedMarket: _egypt,
        selectedCity: _cairo,
      ),
      act: (b) => b.add(ProfileSubmitted(userId: _userId)),
      expect: () => [],
    );

    blocTest<ProfileCompletionBloc, ProfileCompletionState>(
      'cannot complete profile without country/city',
      build: _makeBloc,
      seed: () => ProfileCompletionEditing(
        userId: _userId,
        availableMarkets: [_egypt],
        minimumStudentAgeYears: _minStudentAge,
        selectedGender: UserGender.male,
        selectedDateOfBirth: DateTime(2000, 1, 1),
        // no market, no city
      ),
      act: (b) => b.add(ProfileSubmitted(userId: _userId)),
      expect: () => [],
    );

    blocTest<ProfileCompletionBloc, ProfileCompletionState>(
      'valid profile completes successfully',
      build: _makeBloc,
      seed: () => _loadedEditing(selectedDateOfBirth: DateTime(2000, 1, 1)),
      act: (b) => b.add(ProfileSubmitted(userId: _userId)),
      expect: () => [
        isA<ProfileCompletionSaving>(),
        isA<ProfileCompletionSaved>(),
      ],
    );

    blocTest<ProfileCompletionBloc, ProfileCompletionState>(
      'repository failure emits ProfileCompletionFailure',
      build: () {
        final pr = FakeUserProfileRepository()
          ..failWith = const ServerFailure(statusCode: 500);
        return _makeBloc(profileRepo: pr);
      },
      seed: () => _loadedEditing(selectedDateOfBirth: DateTime(2000, 1, 1)),
      act: (b) => b.add(ProfileSubmitted(userId: _userId)),
      expect: () => [
        isA<ProfileCompletionSaving>(),
        isA<ProfileCompletionFailure>(),
      ],
    );
  });

  // ── Country / City ──────────────────────────────────────────────────────────

  group('country and city selection', () {
    blocTest<ProfileCompletionBloc, ProfileCompletionState>(
      'CountrySelected clears city',
      build: _makeBloc,
      seed: () => _loadedEditing(selectedDateOfBirth: DateTime(2000)),
      act: (b) => b.add(CountrySelected(_egypt)),
      expect: () => [
        isA<ProfileCompletionEditing>().having(
          (s) => s.selectedCity,
          'selectedCity',
          isNull,
        ),
      ],
    );

    blocTest<ProfileCompletionBloc, ProfileCompletionState>(
      'CitySelected stores city',
      build: _makeBloc,
      seed: () => ProfileCompletionEditing(
        userId: _userId,
        availableMarkets: [_egypt],
        minimumStudentAgeYears: _minStudentAge,
        selectedGender: UserGender.male,
        selectedDateOfBirth: DateTime(2000),
        selectedMarket: _egypt,
        // no city pre-selected
      ),
      act: (b) => b.add(CitySelected(_cairo)),
      expect: () => [
        isA<ProfileCompletionEditing>().having(
          (s) => s.selectedCity,
          'selectedCity',
          _cairo,
        ),
      ],
    );
  });
}
