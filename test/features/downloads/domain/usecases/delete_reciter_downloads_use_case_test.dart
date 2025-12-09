import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:muzakri/core/errors/failures.dart';
import 'package:muzakri/features/downloads/domain/repositories/downloads_repository.dart';
import 'package:muzakri/features/downloads/domain/usecases/delete_reciter_downloads_use_case.dart';

import 'delete_reciter_downloads_use_case_test.mocks.dart';

@GenerateMocks([DownloadsRepository])
void main() {
  late DeleteReciterDownloadsUseCase useCase;
  late MockDownloadsRepository mockRepository;

  setUp(() {
    mockRepository = MockDownloadsRepository();
    useCase = DeleteReciterDownloadsUseCase(mockRepository);
  });

  group('DeleteReciterDownloadsUseCase', () {
    group('call', () {
      test('should return Right(null) when delete is successful', () async {
        // Arrange
        const testReciterName = 'Abdul Rahman Al-Sudais';
        when(
          mockRepository.deleteDownloadsForReciter(any),
        ).thenAnswer((_) async {});

        // Act
        final Either<Failure, void> result = await useCase(testReciterName);

        // Assert
        result.fold(
          (_) => fail('Expected Right but got Left'),
          (_) => expect(true, true), // Right with void
        );
        verify(
          mockRepository.deleteDownloadsForReciter(testReciterName),
        ).called(1);
        verifyNoMoreInteractions(mockRepository);
      });

      test(
        'should return Left(AudioFailure) when repository throws exception',
        () async {
          // Arrange
          const testReciterName = 'Abdul Rahman Al-Sudais';
          const errorMessage = 'Reciter not found';
          when(
            mockRepository.deleteDownloadsForReciter(any),
          ).thenThrow(Exception(errorMessage));

          // Act
          final Either<Failure, void> result = await useCase(testReciterName);

          // Assert
          result.fold((failure) {
            expect(failure, isA<AudioFailure>());
            expect(failure.message, 'Exception: $errorMessage');
          }, (_) => fail('Expected Left but got Right'));
          verify(
            mockRepository.deleteDownloadsForReciter(testReciterName),
          ).called(1);
          verifyNoMoreInteractions(mockRepository);
        },
      );

      test(
        'should return Left(AudioFailure) when repository throws generic exception',
        () async {
          // Arrange
          const testReciterName = 'Abdul Rahman Al-Sudais';
          when(
            mockRepository.deleteDownloadsForReciter(any),
          ).thenThrow('Generic error');

          // Act
          final Either<Failure, void> result = await useCase(testReciterName);

          // Assert
          result.fold((failure) {
            expect(failure, isA<AudioFailure>());
            expect(failure.message, 'Generic error');
          }, (_) => fail('Expected Left but got Right'));
          verify(
            mockRepository.deleteDownloadsForReciter(testReciterName),
          ).called(1);
          verifyNoMoreInteractions(mockRepository);
        },
      );

      test('should call repository with correct reciter name', () async {
        // Arrange
        const testReciterName = 'Mishary Rashid Alafasy';
        when(
          mockRepository.deleteDownloadsForReciter(any),
        ).thenAnswer((_) async {});

        // Act
        await useCase(testReciterName);

        // Assert
        verify(
          mockRepository.deleteDownloadsForReciter(testReciterName),
        ).called(1);
        verifyNoMoreInteractions(mockRepository);
      });

      test('should handle empty reciter name', () async {
        // Arrange
        const testReciterName = '';
        when(
          mockRepository.deleteDownloadsForReciter(any),
        ).thenAnswer((_) async {});

        // Act
        final Either<Failure, void> result = await useCase(testReciterName);

        // Assert
        result.fold(
          (_) => fail('Expected Right but got Left'),
          (_) => expect(true, true), // Right with void
        );
        verify(
          mockRepository.deleteDownloadsForReciter(testReciterName),
        ).called(1);
        verifyNoMoreInteractions(mockRepository);
      });

      test('should handle special characters in reciter name', () async {
        // Arrange
        const testReciterName = 'عبد الرحمن السديس';
        when(
          mockRepository.deleteDownloadsForReciter(any),
        ).thenAnswer((_) async {});

        // Act
        final Either<Failure, void> result = await useCase(testReciterName);

        // Assert
        result.fold(
          (_) => fail('Expected Right but got Left'),
          (_) => expect(true, true), // Right with void
        );
        verify(
          mockRepository.deleteDownloadsForReciter(testReciterName),
        ).called(1);
        verifyNoMoreInteractions(mockRepository);
      });

      test('should handle very long reciter name', () async {
        // Arrange
        final String testReciterName = 'A' * 1000; // Very long name
        when(
          mockRepository.deleteDownloadsForReciter(any),
        ).thenAnswer((_) async {});

        // Act
        final Either<Failure, void> result = await useCase(testReciterName);

        // Assert
        result.fold(
          (_) => fail('Expected Right but got Left'),
          (_) => expect(true, true), // Right with void
        );
        verify(
          mockRepository.deleteDownloadsForReciter(testReciterName),
        ).called(1);
        verifyNoMoreInteractions(mockRepository);
      });

      test('should handle database connection error', () async {
        // Arrange
        const testReciterName = 'Abdul Rahman Al-Sudais';
        const errorMessage = 'Database connection failed';
        when(
          mockRepository.deleteDownloadsForReciter(any),
        ).thenThrow(Exception(errorMessage));

        // Act
        final Either<Failure, void> result = await useCase(testReciterName);

        // Assert
        result.fold((failure) {
          expect(failure, isA<AudioFailure>());
          expect(failure.message, 'Exception: $errorMessage');
        }, (_) => fail('Expected Left but got Right'));
        verify(
          mockRepository.deleteDownloadsForReciter(testReciterName),
        ).called(1);
        verifyNoMoreInteractions(mockRepository);
      });

      test('should handle file system error', () async {
        // Arrange
        const testReciterName = 'Abdul Rahman Al-Sudais';
        const errorMessage = 'Permission denied';
        when(
          mockRepository.deleteDownloadsForReciter(any),
        ).thenThrow(Exception(errorMessage));

        // Act
        final Either<Failure, void> result = await useCase(testReciterName);

        // Assert
        result.fold((failure) {
          expect(failure, isA<AudioFailure>());
          expect(failure.message, 'Exception: $errorMessage');
        }, (_) => fail('Expected Left but got Right'));
        verify(
          mockRepository.deleteDownloadsForReciter(testReciterName),
        ).called(1);
        verifyNoMoreInteractions(mockRepository);
      });

      test('should handle network error during delete', () async {
        // Arrange
        const testReciterName = 'Abdul Rahman Al-Sudais';
        const errorMessage = 'Network timeout';
        when(
          mockRepository.deleteDownloadsForReciter(any),
        ).thenThrow(Exception(errorMessage));

        // Act
        final Either<Failure, void> result = await useCase(testReciterName);

        // Assert
        result.fold((failure) {
          expect(failure, isA<AudioFailure>());
          expect(failure.message, 'Exception: $errorMessage');
        }, (_) => fail('Expected Left but got Right'));
        verify(
          mockRepository.deleteDownloadsForReciter(testReciterName),
        ).called(1);
        verifyNoMoreInteractions(mockRepository);
      });

      test('should handle reciter with no downloads', () async {
        // Arrange
        const testReciterName = 'Non-existent Reciter';
        when(
          mockRepository.deleteDownloadsForReciter(any),
        ).thenAnswer((_) async {});

        // Act
        final Either<Failure, void> result = await useCase(testReciterName);

        // Assert
        result.fold(
          (_) => fail('Expected Right but got Left'),
          (_) => expect(true, true), // Right with void
        );
        verify(
          mockRepository.deleteDownloadsForReciter(testReciterName),
        ).called(1);
        verifyNoMoreInteractions(mockRepository);
      });

      test(
        'should handle multiple consecutive delete calls for different reciters',
        () async {
          // Arrange
          const testReciterName1 = 'Abdul Rahman Al-Sudais';
          const testReciterName2 = 'Mishary Rashid Alafasy';
          const testReciterName3 = 'Saad Al-Ghamdi';

          when(
            mockRepository.deleteDownloadsForReciter(any),
          ).thenAnswer((_) async {});

          // Act
          final Either<Failure, void> result1 = await useCase(testReciterName1);
          final Either<Failure, void> result2 = await useCase(testReciterName2);
          final Either<Failure, void> result3 = await useCase(testReciterName3);

          // Assert
          result1.fold(
            (_) => fail('Expected Right but got Left'),
            (_) => expect(true, true), // Right with void
          );
          result2.fold(
            (_) => fail('Expected Right but got Left'),
            (_) => expect(true, true), // Right with void
          );
          result3.fold(
            (_) => fail('Expected Right but got Left'),
            (_) => expect(true, true), // Right with void
          );

          verify(
            mockRepository.deleteDownloadsForReciter(testReciterName1),
          ).called(1);
          verify(
            mockRepository.deleteDownloadsForReciter(testReciterName2),
          ).called(1);
          verify(
            mockRepository.deleteDownloadsForReciter(testReciterName3),
          ).called(1);
          verifyNoMoreInteractions(mockRepository);
        },
      );

      test(
        'should handle reciter name with spaces and special characters',
        () async {
          // Arrange
          const testReciterName = 'Abdul Rahman Al-Sudais (عبد الرحمن السديس)';
          when(
            mockRepository.deleteDownloadsForReciter(any),
          ).thenAnswer((_) async {});

          // Act
          final Either<Failure, void> result = await useCase(testReciterName);

          // Assert
          result.fold(
            (_) => fail('Expected Right but got Left'),
            (_) => expect(true, true), // Right with void
          );
          verify(
            mockRepository.deleteDownloadsForReciter(testReciterName),
          ).called(1);
          verifyNoMoreInteractions(mockRepository);
        },
      );

      test('should handle reciter name with numbers', () async {
        // Arrange
        const testReciterName = 'Reciter 123';
        when(
          mockRepository.deleteDownloadsForReciter(any),
        ).thenAnswer((_) async {});

        // Act
        final Either<Failure, void> result = await useCase(testReciterName);

        // Assert
        result.fold(
          (_) => fail('Expected Right but got Left'),
          (_) => expect(true, true), // Right with void
        );
        verify(
          mockRepository.deleteDownloadsForReciter(testReciterName),
        ).called(1);
        verifyNoMoreInteractions(mockRepository);
      });
    });
  });
}
