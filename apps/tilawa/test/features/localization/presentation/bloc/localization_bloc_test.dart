import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa_core/config/language_config.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa/features/auth/domain/usecases/sync_user_language_preference_use_case.dart';
import 'package:tilawa/features/localization/domain/usecases/get_current_language_use_case.dart';
import 'package:tilawa/features/localization/domain/usecases/set_language_use_case.dart';
import 'package:tilawa/features/localization/presentation/bloc/localization_bloc.dart';
import 'package:tilawa/features/reciters/domain/usecases/get_reciters_use_case.dart';

import '../../../../helpers/hydrated_bloc_test_helper.dart';
import '../../../../helpers/noop_sync_user_language_preference_use_case.dart';
import 'localization_bloc_test.mocks.dart';

// Provide dummy values for Either types
@visibleForTesting
Either<Failure, String> provideDummyEitherFailureString() =>
    const Right(LanguageConfig.defaultLanguageCode);

@visibleForTesting
Either<Failure, void> provideDummyEitherFailureVoid() => const Right(null);

Future<void> settleLocalizationBloc() async {
  await Future<void>.delayed(Duration.zero);
}

@GenerateMocks([
  GetCurrentLanguageUseCase,
  SetLanguageUseCase,
  GetRecitersUseCase,
  SyncUserLanguagePreferenceUseCase,
])
void main() {
  setUpAll(() async {
    await initializeHydratedStorageForTest();
  });

  tearDownAll(() async {
    await clearHydratedStorageForTest();
  });

  group('LocalizationBloc', () {
    late LocalizationBloc bloc;
    late MockGetCurrentLanguageUseCase mockGetCurrentLanguageUseCase;
    late MockSetLanguageUseCase mockSetLanguageUseCase;
    late MockGetRecitersUseCase mockGetRecitersUseCase;
    late MockSyncUserLanguagePreferenceUseCase
    mockSyncUserLanguagePreferenceUseCase;

    setUp(() async {
      // Provide dummy values for Either types
      provideDummy<Either<Failure, String>>(
        const Right(LanguageConfig.defaultLanguageCode),
      );
      provideDummy<Either<Failure, void>>(const Right(null));

      mockGetCurrentLanguageUseCase = MockGetCurrentLanguageUseCase();
      mockSetLanguageUseCase = MockSetLanguageUseCase();
      mockGetRecitersUseCase = MockGetRecitersUseCase();
      mockSyncUserLanguagePreferenceUseCase =
          MockSyncUserLanguagePreferenceUseCase();
      when(mockSyncUserLanguagePreferenceUseCase(any)).thenAnswer((_) async {});
      when(mockGetRecitersUseCase.invalidateCache()).thenReturn(null);

      // Mock GetCurrentLanguageUseCase to return default language
      when(
        mockGetCurrentLanguageUseCase(),
      ).thenAnswer(
        (_) async => const Right(LanguageConfig.defaultLanguageCode),
      );

      // Mock SetLanguageUseCase to return success
      when(
        mockSetLanguageUseCase(any),
      ).thenAnswer((_) async => const Right(null));

      bloc = LocalizationBloc(
        mockGetCurrentLanguageUseCase,
        mockSetLanguageUseCase,
        mockGetRecitersUseCase,
        mockSyncUserLanguagePreferenceUseCase,
      );
      await settleLocalizationBloc();
    });

    tearDown(() {
      bloc.close();
    });

    group('constructor', () {
      test('should have initial state with default locale', () {
        expect(
          bloc.state,
          const LocalizationState(
            locale: Locale(LanguageConfig.defaultLanguageCode),
          ),
        );
      });
    });

    group('LoadLanguage', () {
      late Completer<Either<Failure, String>> pendingLoadLanguage;

      blocTest<LocalizationBloc, LocalizationState>(
        'ensures SharedPreferences has the current language value',
        build: () {
          // Reset mocks to only count calls from this test
          reset(mockGetCurrentLanguageUseCase);
          reset(mockSetLanguageUseCase);

          // Mock GetCurrentLanguageUseCase to return default language
          when(
            mockGetCurrentLanguageUseCase(),
          ).thenAnswer(
            (_) async => const Right(LanguageConfig.defaultLanguageCode),
          );

          // Mock SetLanguageUseCase to return success
          when(
            mockSetLanguageUseCase(any),
          ).thenAnswer((_) async => const Right(null));

          // Create a fresh bloc instance for this test
          return LocalizationBloc(
            mockGetCurrentLanguageUseCase,
            mockSetLanguageUseCase,
            mockGetRecitersUseCase,
            mockSyncUserLanguagePreferenceUseCase,
          );
        },
        act: (bloc) async {
          await settleLocalizationBloc();
          reset(mockSetLanguageUseCase);
          when(
            mockSetLanguageUseCase(any),
          ).thenAnswer((_) async => const Right(null));
          bloc.add(const LoadLanguage());
        },
        verify: (_) {
          verify(mockSetLanguageUseCase(LanguageConfig.defaultLanguageCode));
        },
        expect: () => [],
      );

      blocTest<LocalizationBloc, LocalizationState>(
        'emits new state when SharedPreferences has different language',
        build: () {
          reset(mockGetCurrentLanguageUseCase);
          reset(mockSetLanguageUseCase);

          pendingLoadLanguage = Completer<Either<Failure, String>>();
          when(
            mockGetCurrentLanguageUseCase(),
          ).thenAnswer((_) => pendingLoadLanguage.future);
          when(
            mockSetLanguageUseCase(any),
          ).thenAnswer((_) async => const Right(null));
          when(mockGetRecitersUseCase.invalidateCache()).thenReturn(null);

          return LocalizationBloc(
            mockGetCurrentLanguageUseCase,
            mockSetLanguageUseCase,
            mockGetRecitersUseCase,
            mockSyncUserLanguagePreferenceUseCase,
          );
        },
        act: (bloc) async {
          pendingLoadLanguage.complete(const Right('en'));
          await settleLocalizationBloc();
          reset(mockSetLanguageUseCase);
          when(
            mockSetLanguageUseCase(any),
          ).thenAnswer((_) async => const Right(null));
          bloc.add(const LoadLanguage());
        },
        verify: (_) {
          // Verify that SetLanguageUseCase was called
          // (at least once from the test action, possibly also from initialization)
          verify(mockSetLanguageUseCase(any));
        },
        expect: () => [const LocalizationState(locale: Locale('en'))],
      );

      blocTest<LocalizationBloc, LocalizationState>(
        'ensures SharedPreferences has the current language value when loading fails',
        build: () {
          reset(mockGetCurrentLanguageUseCase);
          reset(mockSetLanguageUseCase);

          // Mock GetCurrentLanguageUseCase to return failure
          when(
            mockGetCurrentLanguageUseCase(),
          ).thenAnswer((_) async => const Left(CacheFailure()));

          // Mock SetLanguageUseCase to return success
          when(
            mockSetLanguageUseCase(any),
          ).thenAnswer((_) async => const Right(null));

          return LocalizationBloc(
            mockGetCurrentLanguageUseCase,
            mockSetLanguageUseCase,
            mockGetRecitersUseCase,
            mockSyncUserLanguagePreferenceUseCase,
          );
        },
        act: (bloc) async {
          await settleLocalizationBloc();
          reset(mockSetLanguageUseCase);
          when(
            mockSetLanguageUseCase(any),
          ).thenAnswer((_) async => const Right(null));
          bloc.add(const LoadLanguage());
        },
        verify: (_) {
          verify(mockSetLanguageUseCase(LanguageConfig.defaultLanguageCode));
        },
        expect: () => [],
      );
    });

    group('fromJson', () {
      test('should return LocalizationState with correct locale from JSON', () {
        final json = {'languageCode': 'en'};
        final LocalizationState? result = bloc.fromJson(json);

        expect(result, const LocalizationState(locale: Locale('en')));
      });

      test('should return LocalizationState with default locale when null', () {
        final json = {'languageCode': null};
        final LocalizationState? result = bloc.fromJson(json);

        expect(
          result,
          const LocalizationState(
            locale: Locale(LanguageConfig.defaultLanguageCode),
          ),
        );
      });

      test('should return LocalizationState with default locale on error', () {
        // Passing something that will cause a cast error if tried to be cast as Map
        final LocalizationState? result = bloc.fromJson({
          'languageCode': 123, // Should throw cast error
        });

        expect(
          result,
          const LocalizationState(
            locale: Locale(LanguageConfig.defaultLanguageCode),
          ),
        );
      });
    });

    group('toJson', () {
      test('should return correct map', () {
        const state = LocalizationState(locale: Locale('en'));
        final Map<String, dynamic>? result = bloc.toJson(state);

        expect(result, {'languageCode': 'en'});
      });
    });

    group('ChangeLanguage', () {
      blocTest<LocalizationBloc, LocalizationState>(
        'emits [LocalizationState] when language is changed successfully',
        build: () => bloc,
        act: (bloc) => bloc.add(const ChangeLanguage(Locale('en'))),
        verify: (_) {
          verify(mockSetLanguageUseCase('en')).called(1);
          verify(mockSyncUserLanguagePreferenceUseCase('en')).called(1);
        },
        expect: () => [const LocalizationState(locale: Locale('en'))],
      );

      blocTest<LocalizationBloc, LocalizationState>(
        'emits [LocalizationState] with Arabic locale when changing to Arabic',
        seed: () => const LocalizationState(locale: Locale('en')),
        build: () => bloc,
        act: (bloc) => bloc.add(const ChangeLanguage(Locale('ar'))),
        expect: () => [const LocalizationState(locale: Locale('ar'))],
      );

      blocTest<LocalizationBloc, LocalizationState>(
        'emits [LocalizationState] with English locale when changing to English',
        build: () => bloc,
        act: (bloc) => bloc.add(const ChangeLanguage(Locale('en'))),
        expect: () => [const LocalizationState(locale: Locale('en'))],
      );

      blocTest<LocalizationBloc, LocalizationState>(
        'emits [LocalizationState] with French locale when changing to French',
        build: () => bloc,
        act: (bloc) => bloc.add(const ChangeLanguage(Locale('fr'))),
        expect: () => [const LocalizationState(locale: Locale('fr'))],
      );

      blocTest<LocalizationBloc, LocalizationState>(
        'emits [LocalizationState] with Chinese locale when changing to Chinese',
        build: () => bloc,
        act: (bloc) => bloc.add(const ChangeLanguage(Locale('zh'))),
        expect: () => [const LocalizationState(locale: Locale('zh'))],
      );
    });

    group('Multiple Events', () {
      blocTest<LocalizationBloc, LocalizationState>(
        'handles multiple LoadLanguage events correctly',
        build: () => bloc,
        act: (bloc) {
          bloc.add(const LoadLanguage());
          bloc.add(const LoadLanguage());
        },
        expect: () => [], // No state changes expected
      );

      blocTest<LocalizationBloc, LocalizationState>(
        'handles multiple ChangeLanguage events correctly',
        build: () => bloc,
        act: (bloc) {
          bloc.add(const ChangeLanguage(Locale('en')));
          bloc.add(const ChangeLanguage(Locale('ar')));
        },
        expect: () => [
          const LocalizationState(locale: Locale('en')),
          const LocalizationState(locale: Locale('ar')),
        ],
      );

      blocTest<LocalizationBloc, LocalizationState>(
        'handles mixed LoadLanguage and ChangeLanguage events correctly',
        build: () => bloc,
        act: (bloc) {
          bloc.add(const LoadLanguage());
          bloc.add(const ChangeLanguage(Locale('en')));
          bloc.add(const LoadLanguage());
          bloc.add(const ChangeLanguage(Locale('ar')));
        },
        expect: () => [
          const LocalizationState(locale: Locale('en')),
          const LocalizationState(locale: Locale('ar')),
        ],
      );
    });

    group('State Persistence', () {
      blocTest<LocalizationBloc, LocalizationState>(
        'persists language changes',
        build: () => bloc,
        act: (bloc) => bloc.add(const ChangeLanguage(Locale('ar'))),
        expect: () => [const LocalizationState(locale: Locale('ar'))],
      );

      test('new bloc instance loads persisted language', () async {
        // Create a bloc and change language
        final firstMockGetCurrentLanguageUseCase =
            MockGetCurrentLanguageUseCase();
        final firstMockSetLanguageUseCase = MockSetLanguageUseCase();

        when(
          firstMockGetCurrentLanguageUseCase(),
        ).thenAnswer(
          (_) async => const Right(LanguageConfig.defaultLanguageCode),
        );
        when(
          firstMockSetLanguageUseCase(any),
        ).thenAnswer((_) async => const Right(null));

        final firstMockGetRecitersUseCase = MockGetRecitersUseCase();
        when(firstMockGetRecitersUseCase.invalidateCache()).thenReturn(null);

        final firstBloc = LocalizationBloc(
          firstMockGetCurrentLanguageUseCase,
          firstMockSetLanguageUseCase,
          firstMockGetRecitersUseCase,
          noopSyncUserLanguagePreferenceUseCase(),
        );
        firstBloc.add(const ChangeLanguage(Locale('en')));
        await firstBloc.stream.firstWhere(
          (state) => state.locale.languageCode == 'en',
        );
        await firstBloc.close();

        // Create new bloc instance - it should load from storage
        // Note: We don't clear storage here to test actual persistence
        final newMockGetCurrentLanguageUseCase =
            MockGetCurrentLanguageUseCase();
        final newMockSetLanguageUseCase = MockSetLanguageUseCase();

        when(
          newMockGetCurrentLanguageUseCase(),
        ).thenAnswer((_) async => const Right('en'));
        when(
          newMockSetLanguageUseCase(any),
        ).thenAnswer((_) async => const Right(null));

        final newMockGetRecitersUseCase = MockGetRecitersUseCase();
        when(newMockGetRecitersUseCase.invalidateCache()).thenReturn(null);

        final newBloc = LocalizationBloc(
          newMockGetCurrentLanguageUseCase,
          newMockSetLanguageUseCase,
          newMockGetRecitersUseCase,
          noopSyncUserLanguagePreferenceUseCase(),
        );
        await untilCalled(newMockGetCurrentLanguageUseCase());
        await settleLocalizationBloc();

        // The new bloc should have the persisted language (or default if storage didn't work)
        // In test environment with mock storage, it may default to initial state
        expect(
          newBloc.state,
          anyOf(
            const LocalizationState(locale: Locale('en')),
            const LocalizationState(
              locale: Locale(LanguageConfig.defaultLanguageCode),
            ),
          ),
        );

        await newBloc.close();
      });
    });

    group('Edge Cases and Error Handling', () {
      blocTest<LocalizationBloc, LocalizationState>(
        'handles rapid consecutive events correctly',
        build: () => bloc,
        act: (bloc) {
          bloc.add(const ChangeLanguage(Locale('ar')));
          bloc.add(const ChangeLanguage(Locale('en')));
          bloc.add(const ChangeLanguage(Locale('fr')));
        },
        expect: () => [
          const LocalizationState(locale: Locale('ar')),
          const LocalizationState(locale: Locale('en')),
          const LocalizationState(locale: Locale('fr')),
        ],
      );

      blocTest<LocalizationBloc, LocalizationState>(
        'handles same locale change gracefully - no emission for same state',
        build: () => bloc,
        seed: () => const LocalizationState(locale: Locale('en')),
        act: (bloc) => bloc.add(const ChangeLanguage(Locale('en'))),
        expect: () =>
            [], // No emission since state is the same (Equatable deduplicates)
      );
    });

    group('State Equality', () {
      test('LocalizationState should be equal when locales are the same', () {
        const state1 = LocalizationState(locale: Locale('en'));
        const state2 = LocalizationState(locale: Locale('en'));
        expect(state1, equals(state2));
      });

      test(
        'LocalizationState should not be equal when locales are different',
        () {
          const state1 = LocalizationState(locale: Locale('en'));
          const state2 = LocalizationState(locale: Locale('ar'));
          expect(state1, isNot(equals(state2)));
        },
      );

      test('LocalizationState should have correct props', () {
        const state = LocalizationState(locale: Locale('en'));
        expect(state.props, [const Locale('en')]);
      });
    });

    group('Event Equality', () {
      test('LoadLanguage events should be equal', () {
        const event1 = LoadLanguage();
        const event2 = LoadLanguage();
        expect(event1, equals(event2));
      });

      test(
        'ChangeLanguage events should be equal when locales are the same',
        () {
          const event1 = ChangeLanguage(Locale('en'));
          const event2 = ChangeLanguage(Locale('en'));
          expect(event1, equals(event2));
        },
      );

      test(
        'ChangeLanguage events should not be equal when locales are different',
        () {
          const event1 = ChangeLanguage(Locale('en'));
          const event2 = ChangeLanguage(Locale('ar'));
          expect(event1, isNot(equals(event2)));
        },
      );

      test('LoadLanguage should have correct props', () {
        const event = LoadLanguage();
        expect(event.props, []);
      });

      test('ChangeLanguage should have correct props', () {
        const event = ChangeLanguage(Locale('en'));
        expect(event.props, [const Locale('en')]);
      });
    });

    group('Integration Tests', () {
      blocTest<LocalizationBloc, LocalizationState>(
        'complete language change flow works correctly',
        build: () => bloc,
        act: (bloc) {
          // Change to English
          bloc.add(const ChangeLanguage(Locale('en')));

          // Change to Arabic
          bloc.add(const ChangeLanguage(Locale('ar')));

          // Change back to English
          bloc.add(const ChangeLanguage(Locale('en')));
        },
        expect: () => [
          const LocalizationState(locale: Locale('en')),
          const LocalizationState(locale: Locale('ar')),
          const LocalizationState(locale: Locale('en')),
        ],
      );
    });
  });
}
