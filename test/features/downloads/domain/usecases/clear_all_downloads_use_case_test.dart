import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:muzakri/core/errors/failures.dart';
import 'package:muzakri/features/downloads/domain/repositories/downloads_repository.dart';
import 'package:muzakri/features/downloads/domain/usecases/clear_all_downloads_use_case.dart';

import 'clear_all_downloads_use_case_test.mocks.dart';

@GenerateMocks([DownloadsRepository])
void main() {
  late ClearAllDownloadsUseCase useCase;
  late MockDownloadsRepository mockRepository;

  setUp(() {
    mockRepository = MockDownloadsRepository();
    useCase = ClearAllDownloadsUseCase(mockRepository);
  });

  group('ClearAllDownloadsUseCase', () {
    group('call', () {
      test('should return Right(null) when clear is successful', () async {
        // Arrange
        when(mockRepository.clearAllDownloads()).thenAnswer((_) async {});

        // Act
        final result = await useCase();

        // Assert
        expect(result, const Right(null));
        verify(mockRepository.clearAllDownloads()).called(1);
        verifyNoMoreInteractions(mockRepository);
      });

      test(
        'should return Left(AudioFailure) when repository throws exception',
        () async {
          // Arrange
          const errorMessage = 'Database error';
          when(
            mockRepository.clearAllDownloads(),
          ).thenThrow(Exception(errorMessage));

          // Act
          final result = await useCase();

          // Assert
          expect(result, Left(AudioFailure('Exception: $errorMessage')));
          verify(mockRepository.clearAllDownloads()).called(1);
          verifyNoMoreInteractions(mockRepository);
        },
      );

      test(
        'should return Left(AudioFailure) when repository throws generic exception',
        () async {
          // Arrange
          when(mockRepository.clearAllDownloads()).thenThrow('Generic error');

          // Act
          final result = await useCase();

          // Assert
          expect(result, const Left(AudioFailure('Generic error')));
          verify(mockRepository.clearAllDownloads()).called(1);
          verifyNoMoreInteractions(mockRepository);
        },
      );

      test('should call repository clearAllDownloads method', () async {
        // Arrange
        when(mockRepository.clearAllDownloads()).thenAnswer((_) async {});

        // Act
        await useCase();

        // Assert
        verify(mockRepository.clearAllDownloads()).called(1);
        verifyNoMoreInteractions(mockRepository);
      });

      test('should handle database connection error', () async {
        // Arrange
        const errorMessage = 'Database connection failed';
        when(
          mockRepository.clearAllDownloads(),
        ).thenThrow(Exception(errorMessage));

        // Act
        final result = await useCase();

        // Assert
        expect(result, Left(AudioFailure('Exception: $errorMessage')));
        verify(mockRepository.clearAllDownloads()).called(1);
        verifyNoMoreInteractions(mockRepository);
      });

      test('should handle file system error', () async {
        // Arrange
        const errorMessage = 'Permission denied';
        when(
          mockRepository.clearAllDownloads(),
        ).thenThrow(Exception(errorMessage));

        // Act
        final result = await useCase();

        // Assert
        expect(result, Left(AudioFailure('Exception: $errorMessage')));
        verify(mockRepository.clearAllDownloads()).called(1);
        verifyNoMoreInteractions(mockRepository);
      });

      test('should handle network error during clear', () async {
        // Arrange
        const errorMessage = 'Network timeout';
        when(
          mockRepository.clearAllDownloads(),
        ).thenThrow(Exception(errorMessage));

        // Act
        final result = await useCase();

        // Assert
        expect(result, Left(AudioFailure('Exception: $errorMessage')));
        verify(mockRepository.clearAllDownloads()).called(1);
        verifyNoMoreInteractions(mockRepository);
      });

      test('should handle storage full error', () async {
        // Arrange
        const errorMessage = 'Storage full';
        when(
          mockRepository.clearAllDownloads(),
        ).thenThrow(Exception(errorMessage));

        // Act
        final result = await useCase();

        // Assert
        expect(result, Left(AudioFailure('Exception: $errorMessage')));
        verify(mockRepository.clearAllDownloads()).called(1);
        verifyNoMoreInteractions(mockRepository);
      });

      test('should handle concurrent access error', () async {
        // Arrange
        const errorMessage = 'Concurrent access denied';
        when(
          mockRepository.clearAllDownloads(),
        ).thenThrow(Exception(errorMessage));

        // Act
        final result = await useCase();

        // Assert
        expect(result, Left(AudioFailure('Exception: $errorMessage')));
        verify(mockRepository.clearAllDownloads()).called(1);
        verifyNoMoreInteractions(mockRepository);
      });

      test('should handle multiple consecutive clear calls', () async {
        // Arrange
        when(mockRepository.clearAllDownloads()).thenAnswer((_) async {});

        // Act
        final result1 = await useCase();
        final result2 = await useCase();
        final result3 = await useCase();

        // Assert
        expect(result1, const Right(null));
        expect(result2, const Right(null));
        expect(result3, const Right(null));

        verify(mockRepository.clearAllDownloads()).called(3);
        verifyNoMoreInteractions(mockRepository);
      });

      test('should handle clear when no downloads exist', () async {
        // Arrange
        when(mockRepository.clearAllDownloads()).thenAnswer((_) async {});

        // Act
        final result = await useCase();

        // Assert
        expect(result, const Right(null));
        verify(mockRepository.clearAllDownloads()).called(1);
        verifyNoMoreInteractions(mockRepository);
      });

      test('should handle clear with large number of downloads', () async {
        // Arrange
        when(mockRepository.clearAllDownloads()).thenAnswer((_) async {});

        // Act
        final result = await useCase();

        // Assert
        expect(result, const Right(null));
        verify(mockRepository.clearAllDownloads()).called(1);
        verifyNoMoreInteractions(mockRepository);
      });

      test('should handle timeout error', () async {
        // Arrange
        const errorMessage = 'Operation timeout';
        when(
          mockRepository.clearAllDownloads(),
        ).thenThrow(Exception(errorMessage));

        // Act
        final result = await useCase();

        // Assert
        expect(result, Left(AudioFailure('Exception: $errorMessage')));
        verify(mockRepository.clearAllDownloads()).called(1);
        verifyNoMoreInteractions(mockRepository);
      });

      test('should handle memory error', () async {
        // Arrange
        const errorMessage = 'Out of memory';
        when(
          mockRepository.clearAllDownloads(),
        ).thenThrow(Exception(errorMessage));

        // Act
        final result = await useCase();

        // Assert
        expect(result, Left(AudioFailure('Exception: $errorMessage')));
        verify(mockRepository.clearAllDownloads()).called(1);
        verifyNoMoreInteractions(mockRepository);
      });

      test('should handle null pointer exception', () async {
        // Arrange
        const errorMessage = 'Null pointer exception';
        when(
          mockRepository.clearAllDownloads(),
        ).thenThrow(Exception(errorMessage));

        // Act
        final result = await useCase();

        // Assert
        expect(result, Left(AudioFailure('Exception: $errorMessage')));
        verify(mockRepository.clearAllDownloads()).called(1);
        verifyNoMoreInteractions(mockRepository);
      });

      test('should handle unknown error type', () async {
        // Arrange
        when(
          mockRepository.clearAllDownloads(),
        ).thenThrow(123); // Non-Exception error

        // Act
        final result = await useCase();

        // Assert
        expect(result, const Left(AudioFailure('123')));
        verify(mockRepository.clearAllDownloads()).called(1);
        verifyNoMoreInteractions(mockRepository);
      });
    });
  });
}
