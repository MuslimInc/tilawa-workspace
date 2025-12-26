import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/features/onboarding/data/repositories/onboarding_repository_impl.dart';

import 'onboarding_repository_impl_test.mocks.dart';

@GenerateMocks([SharedPreferencesAsync])
void main() {
  late OnboardingRepositoryImpl repository;
  late MockSharedPreferencesAsync mockPrefs;

  setUp(() {
    mockPrefs = MockSharedPreferencesAsync();
    repository = OnboardingRepositoryImpl(mockPrefs);
  });

  group('isOnboardingCompleted', () {
    test(
      'should return true when value is set to true in shared preferences',
      () async {
        // Arrange
        when(
          mockPrefs.getBool('onboarding_completed'),
        ).thenAnswer((_) async => true);

        // Act
        final bool result = await repository.isOnboardingCompleted();

        // Assert
        expect(result, true);
        verify(mockPrefs.getBool('onboarding_completed')).called(1);
      },
    );

    test(
      'should return false when value is not set in shared preferences',
      () async {
        // Arrange
        when(
          mockPrefs.getBool('onboarding_completed'),
        ).thenAnswer((_) async => null);

        // Act
        final bool result = await repository.isOnboardingCompleted();

        // Assert
        expect(result, false);
        verify(mockPrefs.getBool('onboarding_completed')).called(1);
      },
    );
  });

  group('completeOnboarding', () {
    test(
      'should set onboarding_completed to true in shared preferences',
      () async {
        // Arrange
        when(
          mockPrefs.setBool('onboarding_completed', true),
        ).thenAnswer((_) async => {});

        // Act
        await repository.completeOnboarding();

        // Assert
        verify(mockPrefs.setBool('onboarding_completed', true)).called(1);
      },
    );
  });
}
