import 'package:bloc_test/bloc_test.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa/features/auth/domain/entities/email_registration_step.dart';
import 'package:tilawa/features/auth/presentation/cubit/email_registration_cubit.dart';
import 'package:tilawa/features/auth/presentation/cubit/email_registration_state.dart';

import '../bloc/auth_bloc_test.mocks.dart';

class _FakeGetMarketConfigUseCase implements GetMarketConfigUseCase {
  @override
  Future<Either<QuranSessionsFailure, List<MarketCountry>>>
  supportedCountries() async {
    return const Right(<MarketCountry>[
      MarketCountry(
        countryCode: 'EG',
        countryName: 'Egypt',
        currencyCode: 'EGP',
        timezone: 'Africa/Cairo',
        isEnabled: true,
        sortOrder: 0,
      ),
    ]);
  }

  @override
  Future<Either<QuranSessionsFailure, List<MarketCity>>> citiesByCountry(
    String countryCode,
  ) async {
    return const Right(<MarketCity>[
      MarketCity(
        cityId: 'cairo',
        cityName: 'Cairo',
        countryCode: 'EG',
        timezone: 'Africa/Cairo',
        currencyCode: 'EGP',
        isEnabled: true,
        sortOrder: 0,
      ),
    ]);
  }

  @override
  Future<Either<QuranSessionsFailure, MarketConfig>> call(
    String countryCode,
  ) => throw UnimplementedError();

  @override
  Future<Either<QuranSessionsFailure, List<MarketConfig>>> allMarkets() =>
      throw UnimplementedError();

  @override
  Future<Either<QuranSessionsFailure, MarketConfig>> getMarketConfig(
    String countryCode,
  ) => throw UnimplementedError();

  @override
  Future<Either<QuranSessionsFailure, List<MarketConfig>>>
  getSupportedMarkets() => throw UnimplementedError();

  @override
  Future<Either<QuranSessionsFailure, CityConfig>> getCityConfig(
    String countryCode,
    String cityId,
  ) => throw UnimplementedError();
}

class _FakeGetSessionPolicyUseCase implements GetSessionPolicyUseCase {
  @override
  Future<Either<QuranSessionsFailure, QuranSessionSafetyPolicy>> call() async {
    return const Right(
      QuranSessionSafetyPolicy(
        childAgeThreshold: 13,
        minimumStudentAgeYears: 5,
        requireGuardianApprovalForChildren: true,
      ),
    );
  }
}

void main() {
  late EmailRegistrationCubit cubit;
  late MockRegisterWithEmailUseCase registerWithEmail;

  setUp(() {
    registerWithEmail = MockRegisterWithEmailUseCase();
    cubit = EmailRegistrationCubit(
      _FakeGetMarketConfigUseCase(),
      _FakeGetSessionPolicyUseCase(),
      registerWithEmail,
    );
  });

  tearDown(() async {
    await cubit.close();
  });

  blocTest<EmailRegistrationCubit, EmailRegistrationState>(
    'advances from account to personal when account step is valid',
    build: () => cubit,
    act: (EmailRegistrationCubit c) async {
      await c.initialize();
      c
        ..emailChanged('user@example.com')
        ..passwordChanged('secret1')
        ..confirmPasswordChanged('secret1')
        ..goNext();
    },
    verify: (EmailRegistrationCubit c) {
      expect(c.state.currentStep, EmailRegistrationStep.personal);
    },
  );

  blocTest<EmailRegistrationCubit, EmailRegistrationState>(
    'back preserves draft data',
    build: () => cubit,
    act: (EmailRegistrationCubit c) async {
      await c.initialize();
      c
        ..emailChanged('user@example.com')
        ..passwordChanged('secret1')
        ..confirmPasswordChanged('secret1')
        ..goNext()
        ..displayNameChanged('Saved Name')
        ..goBack();
    },
    verify: (EmailRegistrationCubit c) {
      expect(c.state.currentStep, EmailRegistrationStep.account);
      expect(c.state.draft.email, 'user@example.com');
      expect(c.state.draft.displayName, 'Saved Name');
    },
  );

  blocTest<EmailRegistrationCubit, EmailRegistrationState>(
    'account step validation surfaces email error',
    build: () => cubit,
    act: (EmailRegistrationCubit c) async {
      await c.initialize();
      c.emailChanged('bad');
      c.goNext();
    },
    verify: (EmailRegistrationCubit c) {
      expect(c.state.currentStep, EmailRegistrationStep.account);
      expect(c.state.fieldError('email'), isNotNull);
    },
  );
}
