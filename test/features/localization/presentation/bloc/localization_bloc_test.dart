import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:muzakri/core/config/language_config.dart';
import 'package:muzakri/features/localization/presentation/bloc/localization_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'localization_bloc_test.mocks.dart';

@GenerateMocks([SharedPreferencesAsync])
void main() {
  group('LocalizationBloc', () {
    late LocalizationBloc bloc;
    late MockSharedPreferencesAsync mockPrefs;

    setUp(() {
      mockPrefs = MockSharedPreferencesAsync();
      bloc = LocalizationBloc(mockPrefs);
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
      blocTest<LocalizationBloc, LocalizationState>(
        'emits [LocalizationState] when language is loaded successfully',
        build: () {
          when(
            mockPrefs.getString(LanguageConfig.languageKey),
          ).thenAnswer((_) async => 'en');
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadLanguage()),
        expect: () => [const LocalizationState(locale: Locale('en'))],
        verify: (_) {
          verify(mockPrefs.getString(LanguageConfig.languageKey)).called(1);
        },
      );

      blocTest<LocalizationBloc, LocalizationState>(
        'emits [LocalizationState] with default locale when no saved language',
        build: () {
          when(
            mockPrefs.getString(LanguageConfig.languageKey),
          ).thenAnswer((_) async => null);
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadLanguage()),
        expect: () => [
          LocalizationState(
            locale: Locale(LanguageConfig.getDefaultLanguageCode()),
          ),
        ],
        verify: (_) {
          verify(mockPrefs.getString(LanguageConfig.languageKey)).called(1);
        },
      );

      blocTest<LocalizationBloc, LocalizationState>(
        'emits [LocalizationState] with default locale when exception occurs',
        build: () {
          when(
            mockPrefs.getString(LanguageConfig.languageKey),
          ).thenThrow(Exception('Storage error'));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadLanguage()),
        expect: () => [
          LocalizationState(
            locale: Locale(LanguageConfig.getDefaultLanguageCode()),
          ),
        ],
        verify: (_) {
          verify(mockPrefs.getString(LanguageConfig.languageKey)).called(1);
        },
      );

      blocTest<LocalizationBloc, LocalizationState>(
        'emits [LocalizationState] with Arabic locale when Arabic is saved',
        build: () {
          when(
            mockPrefs.getString(LanguageConfig.languageKey),
          ).thenAnswer((_) async => 'ar');
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadLanguage()),
        expect: () => [const LocalizationState(locale: Locale('ar'))],
        verify: (_) {
          verify(mockPrefs.getString(LanguageConfig.languageKey)).called(1);
        },
      );

      blocTest<LocalizationBloc, LocalizationState>(
        'emits [LocalizationState] with English locale when English is saved',
        build: () {
          when(
            mockPrefs.getString(LanguageConfig.languageKey),
          ).thenAnswer((_) async => 'en');
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadLanguage()),
        expect: () => [const LocalizationState(locale: Locale('en'))],
        verify: (_) {
          verify(mockPrefs.getString(LanguageConfig.languageKey)).called(1);
        },
      );

      blocTest<LocalizationBloc, LocalizationState>(
        'emits [LocalizationState] with unsupported language when unsupported language is saved',
        build: () {
          when(
            mockPrefs.getString(LanguageConfig.languageKey),
          ).thenAnswer((_) async => 'fr'); // Unsupported language
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadLanguage()),
        expect: () => [const LocalizationState(locale: Locale('fr'))],
        verify: (_) {
          verify(mockPrefs.getString(LanguageConfig.languageKey)).called(1);
        },
      );
    });

    group('ChangeLanguage', () {
      blocTest<LocalizationBloc, LocalizationState>(
        'emits [LocalizationState] when language is changed successfully',
        build: () {
          when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);
          return bloc;
        },
        act: (bloc) => bloc.add(const ChangeLanguage(Locale('en'))),
        expect: () => [const LocalizationState(locale: Locale('en'))],
        verify: (_) {
          verify(
            mockPrefs.setString(LanguageConfig.languageKey, 'en'),
          ).called(1);
        },
      );

      blocTest<LocalizationBloc, LocalizationState>(
        'emits [LocalizationState] when saving fails but still updates state',
        build: () {
          when(
            mockPrefs.setString(any, any),
          ).thenThrow(Exception('Storage error'));
          return bloc;
        },
        act: (bloc) => bloc.add(const ChangeLanguage(Locale('ar'))),
        expect: () => [const LocalizationState(locale: Locale('ar'))],
        verify: (_) {
          verify(
            mockPrefs.setString(LanguageConfig.languageKey, 'ar'),
          ).called(1);
        },
      );

      blocTest<LocalizationBloc, LocalizationState>(
        'emits [LocalizationState] with Arabic locale when changing to Arabic',
        build: () {
          when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);
          return bloc;
        },
        act: (bloc) => bloc.add(const ChangeLanguage(Locale('ar'))),
        expect: () => [const LocalizationState(locale: Locale('ar'))],
        verify: (_) {
          verify(
            mockPrefs.setString(LanguageConfig.languageKey, 'ar'),
          ).called(1);
        },
      );

      blocTest<LocalizationBloc, LocalizationState>(
        'emits [LocalizationState] with English locale when changing to English',
        build: () {
          when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);
          return bloc;
        },
        act: (bloc) => bloc.add(const ChangeLanguage(Locale('en'))),
        expect: () => [const LocalizationState(locale: Locale('en'))],
        verify: (_) {
          verify(
            mockPrefs.setString(LanguageConfig.languageKey, 'en'),
          ).called(1);
        },
      );

      blocTest<LocalizationBloc, LocalizationState>(
        'emits [LocalizationState] with French locale when changing to French',
        build: () {
          when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);
          return bloc;
        },
        act: (bloc) => bloc.add(const ChangeLanguage(Locale('fr'))),
        expect: () => [const LocalizationState(locale: Locale('fr'))],
        verify: (_) {
          verify(
            mockPrefs.setString(LanguageConfig.languageKey, 'fr'),
          ).called(1);
        },
      );

      blocTest<LocalizationBloc, LocalizationState>(
        'emits [LocalizationState] with Chinese locale when changing to Chinese',
        build: () {
          when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);
          return bloc;
        },
        act: (bloc) => bloc.add(const ChangeLanguage(Locale('zh'))),
        expect: () => [const LocalizationState(locale: Locale('zh'))],
        verify: (_) {
          verify(
            mockPrefs.setString(LanguageConfig.languageKey, 'zh'),
          ).called(1);
        },
      );
    });

    group('Multiple Events', () {
      blocTest<LocalizationBloc, LocalizationState>(
        'handles multiple LoadLanguage events correctly',
        build: () {
          when(
            mockPrefs.getString(LanguageConfig.languageKey),
          ).thenAnswer((_) async => 'en');
          return bloc;
        },
        act: (bloc) {
          bloc.add(const LoadLanguage());
          bloc.add(const LoadLanguage());
        },
        expect: () => [const LocalizationState(locale: Locale('en'))],
        verify: (_) {
          verify(mockPrefs.getString(LanguageConfig.languageKey)).called(2);
        },
      );

      blocTest<LocalizationBloc, LocalizationState>(
        'handles multiple ChangeLanguage events correctly',
        build: () {
          when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);
          return bloc;
        },
        act: (bloc) {
          bloc.add(const ChangeLanguage(Locale('en')));
          bloc.add(const ChangeLanguage(Locale('ar')));
        },
        expect: () => [
          const LocalizationState(locale: Locale('en')),
          const LocalizationState(locale: Locale('ar')),
        ],
        verify: (_) {
          verify(
            mockPrefs.setString(LanguageConfig.languageKey, 'en'),
          ).called(1);
          verify(
            mockPrefs.setString(LanguageConfig.languageKey, 'ar'),
          ).called(1);
        },
      );

      blocTest<LocalizationBloc, LocalizationState>(
        'handles mixed LoadLanguage and ChangeLanguage events correctly',
        build: () {
          when(
            mockPrefs.getString(LanguageConfig.languageKey),
          ).thenAnswer((_) async => 'ar');
          when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);
          return bloc;
        },
        act: (bloc) {
          bloc.add(const LoadLanguage());
          bloc.add(const ChangeLanguage(Locale('en')));
          bloc.add(const LoadLanguage());
        },
        expect: () => [
          const LocalizationState(locale: Locale('ar')),
          const LocalizationState(locale: Locale('en')),
          const LocalizationState(locale: Locale('ar')),
        ],
        verify: (_) {
          verify(mockPrefs.getString(LanguageConfig.languageKey)).called(2);
          verify(
            mockPrefs.setString(LanguageConfig.languageKey, 'en'),
          ).called(1);
        },
      );
    });

    group('Edge Cases and Error Handling', () {
      blocTest<LocalizationBloc, LocalizationState>(
        'handles empty string language code gracefully',
        build: () {
          when(
            mockPrefs.getString(LanguageConfig.languageKey),
          ).thenAnswer((_) async => '');
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadLanguage()),
        expect: () => [
          LocalizationState(
            locale: Locale(LanguageConfig.getDefaultLanguageCode()),
          ),
        ],
        verify: (_) {
          verify(mockPrefs.getString(LanguageConfig.languageKey)).called(1);
        },
      );

      blocTest<LocalizationBloc, LocalizationState>(
        'handles whitespace-only language code gracefully',
        build: () {
          when(
            mockPrefs.getString(LanguageConfig.languageKey),
          ).thenAnswer((_) async => '   ');
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadLanguage()),
        expect: () => [const LocalizationState(locale: Locale('   '))],
        verify: (_) {
          verify(mockPrefs.getString(LanguageConfig.languageKey)).called(1);
        },
      );

      blocTest<LocalizationBloc, LocalizationState>(
        'handles rapid consecutive events correctly',
        build: () {
          when(
            mockPrefs.getString(LanguageConfig.languageKey),
          ).thenAnswer((_) async => 'en');
          when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);
          return bloc;
        },
        act: (bloc) {
          bloc.add(const LoadLanguage());
          bloc.add(const ChangeLanguage(Locale('ar')));
          bloc.add(const ChangeLanguage(Locale('en')));
          bloc.add(const LoadLanguage());
        },
        expect: () => [
          const LocalizationState(locale: Locale('en')),
          const LocalizationState(locale: Locale('ar')),
          const LocalizationState(locale: Locale('en')),
        ],
        verify: (_) {
          verify(mockPrefs.getString(LanguageConfig.languageKey)).called(2);
          verify(
            mockPrefs.setString(LanguageConfig.languageKey, 'ar'),
          ).called(1);
          verify(
            mockPrefs.setString(LanguageConfig.languageKey, 'en'),
          ).called(1);
        },
      );

      blocTest<LocalizationBloc, LocalizationState>(
        'handles final SharedPreferencesAsync _prefs returning false for setString',
        build: () {
          when(mockPrefs.setString(any, any)).thenAnswer((_) async => false);
          return bloc;
        },
        act: (bloc) => bloc.add(const ChangeLanguage(Locale('en'))),
        expect: () => [const LocalizationState(locale: Locale('en'))],
        verify: (_) {
          verify(
            mockPrefs.setString(LanguageConfig.languageKey, 'en'),
          ).called(1);
        },
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
        build: () {
          when(
            mockPrefs.getString(LanguageConfig.languageKey),
          ).thenAnswer((_) async => 'ar');
          when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);
          return bloc;
        },
        act: (bloc) async {
          // Load initial language
          bloc.add(const LoadLanguage());
          await Future.delayed(const Duration(milliseconds: 10));

          // Change to English
          bloc.add(const ChangeLanguage(Locale('en')));
          await Future.delayed(const Duration(milliseconds: 10));

          // Change back to Arabic
          bloc.add(const ChangeLanguage(Locale('ar')));
          await Future.delayed(const Duration(milliseconds: 10));

          // Load language again to verify persistence
          bloc.add(const LoadLanguage());
        },
        expect: () => [
          const LocalizationState(locale: Locale('ar')),
          const LocalizationState(locale: Locale('en')),
          const LocalizationState(locale: Locale('ar')),
        ],
        verify: (_) {
          verify(mockPrefs.getString(LanguageConfig.languageKey)).called(2);
          verify(
            mockPrefs.setString(LanguageConfig.languageKey, 'en'),
          ).called(1);
          verify(
            mockPrefs.setString(LanguageConfig.languageKey, 'ar'),
          ).called(1);
        },
      );
    });
  });
}
