import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/core/errors/failures.dart';
import 'package:tilawa/features/localization/data/datasources/localization_local_datasource.dart';
import 'package:tilawa/features/localization/data/repositories/localization_repository_impl.dart';

import 'localization_repository_impl_test.mocks.dart';

@GenerateMocks([LocalizationLocalDataSource])
void main() {
  provideDummy<Either<Failure, String>>(const Right(''));
  provideDummy<Either<Failure, void>>(const Right(null));
  provideDummy<Either<Failure, List<String>>>(const Right([]));

  late LocalizationRepositoryImpl repository;
  late MockLocalizationLocalDataSource mockLocalDataSource;

  setUp(() {
    mockLocalDataSource = MockLocalizationLocalDataSource();
    repository = LocalizationRepositoryImpl(mockLocalDataSource);
  });

  group('LocalizationRepositoryImpl', () {
    group('getCurrentLanguage', () {
      const tLanguageCode = 'en';

      test(
        'should return language code from data source when successful',
        () async {
          // Arrange
          when(
            mockLocalDataSource.getCurrentLanguage(),
          ).thenAnswer((_) async => tLanguageCode);

          // Act
          final Either<Failure, String> result = await repository
              .getCurrentLanguage();

          // Assert
          expect(result, const Right(tLanguageCode));
          verify(mockLocalDataSource.getCurrentLanguage()).called(1);
          verifyNoMoreInteractions(mockLocalDataSource);
        },
      );

      test(
        'should return CacheFailure when data source throws exception',
        () async {
          // Arrange
          const tErrorMessage = 'Failed to get language';
          when(
            mockLocalDataSource.getCurrentLanguage(),
          ).thenThrow(Exception(tErrorMessage));

          // Act
          final Either<Failure, String> result = await repository
              .getCurrentLanguage();

          // Assert
          result.fold((failure) {
            expect(failure, isA<CacheFailure>());
            expect(failure.message, contains(tErrorMessage));
          }, (_) => fail('Should return failure'));
          verify(mockLocalDataSource.getCurrentLanguage()).called(1);
          verifyNoMoreInteractions(mockLocalDataSource);
        },
      );
    });

    group('setLanguage', () {
      const tLanguageCode = 'ar';

      test('should successfully set language through data source', () async {
        // Arrange
        when(
          mockLocalDataSource.setLanguage(any),
        ).thenAnswer((_) async => Future.value());

        // Act
        final Either<Failure, void> result = await repository.setLanguage(
          tLanguageCode,
        );

        // Assert
        expect(result, const Right(null));
        verify(mockLocalDataSource.setLanguage(tLanguageCode)).called(1);
        verifyNoMoreInteractions(mockLocalDataSource);
      });

      test(
        'should return CacheFailure when data source throws exception',
        () async {
          // Arrange
          const tErrorMessage = 'Failed to set language';
          when(
            mockLocalDataSource.setLanguage(any),
          ).thenThrow(Exception(tErrorMessage));

          // Act
          final Either<Failure, void> result = await repository.setLanguage(
            tLanguageCode,
          );

          // Assert
          result.fold((failure) {
            expect(failure, isA<CacheFailure>());
            expect(failure.message, contains(tErrorMessage));
          }, (_) => fail('Should return failure'));
          verify(mockLocalDataSource.setLanguage(tLanguageCode)).called(1);
          verifyNoMoreInteractions(mockLocalDataSource);
        },
      );
    });

    group('getSupportedLanguages', () {
      const tSupportedLanguages = ['en', 'ar'];

      test(
        'should return supported languages from data source when successful',
        () async {
          // Arrange
          when(
            mockLocalDataSource.getSupportedLanguages(),
          ).thenAnswer((_) async => tSupportedLanguages);

          // Act
          final Either<Failure, List<String>> result = await repository
              .getSupportedLanguages();

          // Assert
          expect(result, const Right(tSupportedLanguages));
          verify(mockLocalDataSource.getSupportedLanguages()).called(1);
          verifyNoMoreInteractions(mockLocalDataSource);
        },
      );

      test(
        'should return CacheFailure when data source throws exception',
        () async {
          // Arrange
          const tErrorMessage = 'Failed to get supported languages';
          when(
            mockLocalDataSource.getSupportedLanguages(),
          ).thenThrow(Exception(tErrorMessage));

          // Act
          final Either<Failure, List<String>> result = await repository
              .getSupportedLanguages();

          // Assert
          result.fold((failure) {
            expect(failure, isA<CacheFailure>());
            expect(failure.message, contains(tErrorMessage));
          }, (_) => fail('Should return failure'));
          verify(mockLocalDataSource.getSupportedLanguages()).called(1);
          verifyNoMoreInteractions(mockLocalDataSource);
        },
      );
    });
  });
}
