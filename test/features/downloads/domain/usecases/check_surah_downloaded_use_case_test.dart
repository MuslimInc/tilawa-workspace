import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:muzakri/core/errors/failures.dart';
import 'package:muzakri/features/downloads/domain/repositories/downloads_repository.dart';
import 'package:muzakri/features/downloads/domain/usecases/check_surah_downloaded_use_case.dart';

import 'check_surah_downloaded_use_case_test.mocks.dart';

@GenerateMocks([DownloadsRepository])
void main() {
  late CheckSurahDownloadedUseCase useCase;
  late MockDownloadsRepository mockRepository;

  setUp(() {
    mockRepository = MockDownloadsRepository();
    useCase = CheckSurahDownloadedUseCase(mockRepository);
  });

  group('CheckSurahDownloadedUseCase', () {
    group('call', () {
      test('should return Right(true) when surah is downloaded', () async {
        // Arrange
        const testSurahId = '001';
        const testReciterName = 'Abdul Rahman Al-Sudais';
        when(
          mockRepository.isSurahDownloaded(any, any),
        ).thenAnswer((_) async => true);

        // Act
        final result = await useCase(
          surahId: testSurahId,
          reciterName: testReciterName,
        );

        // Assert
        expect(result, const Right(true));
        verify(
          mockRepository.isSurahDownloaded(testSurahId, testReciterName),
        ).called(1);
        verifyNoMoreInteractions(mockRepository);
      });

      test('should return Right(false) when surah is not downloaded', () async {
        // Arrange
        const testSurahId = '001';
        const testReciterName = 'Abdul Rahman Al-Sudais';
        when(
          mockRepository.isSurahDownloaded(any, any),
        ).thenAnswer((_) async => false);

        // Act
        final result = await useCase(
          surahId: testSurahId,
          reciterName: testReciterName,
        );

        // Assert
        expect(result, const Right(false));
        verify(
          mockRepository.isSurahDownloaded(testSurahId, testReciterName),
        ).called(1);
        verifyNoMoreInteractions(mockRepository);
      });

      test(
        'should return Left(AudioFailure) when repository throws exception',
        () async {
          // Arrange
          const testSurahId = '001';
          const testReciterName = 'Abdul Rahman Al-Sudais';
          const errorMessage = 'Database error';
          when(
            mockRepository.isSurahDownloaded(any, any),
          ).thenThrow(Exception(errorMessage));

          // Act
          final result = await useCase(
            surahId: testSurahId,
            reciterName: testReciterName,
          );

          // Assert
          expect(result, Left(AudioFailure('Exception: $errorMessage')));
          verify(
            mockRepository.isSurahDownloaded(testSurahId, testReciterName),
          ).called(1);
          verifyNoMoreInteractions(mockRepository);
        },
      );

      test(
        'should return Left(AudioFailure) when repository throws generic exception',
        () async {
          // Arrange
          const testSurahId = '001';
          const testReciterName = 'Abdul Rahman Al-Sudais';
          when(
            mockRepository.isSurahDownloaded(any, any),
          ).thenThrow('Generic error');

          // Act
          final result = await useCase(
            surahId: testSurahId,
            reciterName: testReciterName,
          );

          // Assert
          expect(result, const Left(AudioFailure('Generic error')));
          verify(
            mockRepository.isSurahDownloaded(testSurahId, testReciterName),
          ).called(1);
          verifyNoMoreInteractions(mockRepository);
        },
      );

      test('should call repository with correct parameters', () async {
        // Arrange
        const testSurahId = '002';
        const testReciterName = 'Mishary Rashid Alafasy';
        when(
          mockRepository.isSurahDownloaded(any, any),
        ).thenAnswer((_) async => true);

        // Act
        await useCase(surahId: testSurahId, reciterName: testReciterName);

        // Assert
        verify(
          mockRepository.isSurahDownloaded(testSurahId, testReciterName),
        ).called(1);
        verifyNoMoreInteractions(mockRepository);
      });

      test('should handle empty surah ID', () async {
        // Arrange
        const testSurahId = '';
        const testReciterName = 'Abdul Rahman Al-Sudais';
        when(
          mockRepository.isSurahDownloaded(any, any),
        ).thenAnswer((_) async => false);

        // Act
        final result = await useCase(
          surahId: testSurahId,
          reciterName: testReciterName,
        );

        // Assert
        expect(result, const Right(false));
        verify(
          mockRepository.isSurahDownloaded(testSurahId, testReciterName),
        ).called(1);
        verifyNoMoreInteractions(mockRepository);
      });

      test('should handle empty reciter name', () async {
        // Arrange
        const testSurahId = '001';
        const testReciterName = '';
        when(
          mockRepository.isSurahDownloaded(any, any),
        ).thenAnswer((_) async => false);

        // Act
        final result = await useCase(
          surahId: testSurahId,
          reciterName: testReciterName,
        );

        // Assert
        expect(result, const Right(false));
        verify(
          mockRepository.isSurahDownloaded(testSurahId, testReciterName),
        ).called(1);
        verifyNoMoreInteractions(mockRepository);
      });

      test('should handle special characters in surah ID', () async {
        // Arrange
        const testSurahId = '001-الفاتحة';
        const testReciterName = 'Abdul Rahman Al-Sudais';
        when(
          mockRepository.isSurahDownloaded(any, any),
        ).thenAnswer((_) async => true);

        // Act
        final result = await useCase(
          surahId: testSurahId,
          reciterName: testReciterName,
        );

        // Assert
        expect(result, const Right(true));
        verify(
          mockRepository.isSurahDownloaded(testSurahId, testReciterName),
        ).called(1);
        verifyNoMoreInteractions(mockRepository);
      });

      test('should handle special characters in reciter name', () async {
        // Arrange
        const testSurahId = '001';
        const testReciterName = 'عبد الرحمن السديس';
        when(
          mockRepository.isSurahDownloaded(any, any),
        ).thenAnswer((_) async => true);

        // Act
        final result = await useCase(
          surahId: testSurahId,
          reciterName: testReciterName,
        );

        // Assert
        expect(result, const Right(true));
        verify(
          mockRepository.isSurahDownloaded(testSurahId, testReciterName),
        ).called(1);
        verifyNoMoreInteractions(mockRepository);
      });

      test('should handle very long surah ID', () async {
        // Arrange
        final testSurahId = 'a' * 1000; // Very long ID
        const testReciterName = 'Abdul Rahman Al-Sudais';
        when(
          mockRepository.isSurahDownloaded(any, any),
        ).thenAnswer((_) async => false);

        // Act
        final result = await useCase(
          surahId: testSurahId,
          reciterName: testReciterName,
        );

        // Assert
        expect(result, const Right(false));
        verify(
          mockRepository.isSurahDownloaded(testSurahId, testReciterName),
        ).called(1);
        verifyNoMoreInteractions(mockRepository);
      });

      test('should handle very long reciter name', () async {
        // Arrange
        const testSurahId = '001';
        final testReciterName = 'A' * 1000; // Very long name
        when(
          mockRepository.isSurahDownloaded(any, any),
        ).thenAnswer((_) async => false);

        // Act
        final result = await useCase(
          surahId: testSurahId,
          reciterName: testReciterName,
        );

        // Assert
        expect(result, const Right(false));
        verify(
          mockRepository.isSurahDownloaded(testSurahId, testReciterName),
        ).called(1);
        verifyNoMoreInteractions(mockRepository);
      });

      test('should handle database connection error', () async {
        // Arrange
        const testSurahId = '001';
        const testReciterName = 'Abdul Rahman Al-Sudais';
        const errorMessage = 'Database connection failed';
        when(
          mockRepository.isSurahDownloaded(any, any),
        ).thenThrow(Exception(errorMessage));

        // Act
        final result = await useCase(
          surahId: testSurahId,
          reciterName: testReciterName,
        );

        // Assert
        expect(result, Left(AudioFailure('Exception: $errorMessage')));
        verify(
          mockRepository.isSurahDownloaded(testSurahId, testReciterName),
        ).called(1);
        verifyNoMoreInteractions(mockRepository);
      });

      test('should handle file system error', () async {
        // Arrange
        const testSurahId = '001';
        const testReciterName = 'Abdul Rahman Al-Sudais';
        const errorMessage = 'File system error';
        when(
          mockRepository.isSurahDownloaded(any, any),
        ).thenThrow(Exception(errorMessage));

        // Act
        final result = await useCase(
          surahId: testSurahId,
          reciterName: testReciterName,
        );

        // Assert
        expect(result, Left(AudioFailure('Exception: $errorMessage')));
        verify(
          mockRepository.isSurahDownloaded(testSurahId, testReciterName),
        ).called(1);
        verifyNoMoreInteractions(mockRepository);
      });

      test('should handle network error', () async {
        // Arrange
        const testSurahId = '001';
        const testReciterName = 'Abdul Rahman Al-Sudais';
        const errorMessage = 'Network timeout';
        when(
          mockRepository.isSurahDownloaded(any, any),
        ).thenThrow(Exception(errorMessage));

        // Act
        final result = await useCase(
          surahId: testSurahId,
          reciterName: testReciterName,
        );

        // Assert
        expect(result, Left(AudioFailure('Exception: $errorMessage')));
        verify(
          mockRepository.isSurahDownloaded(testSurahId, testReciterName),
        ).called(1);
        verifyNoMoreInteractions(mockRepository);
      });

      test(
        'should handle multiple consecutive calls with different parameters',
        () async {
          // Arrange
          when(
            mockRepository.isSurahDownloaded(any, any),
          ).thenAnswer((_) async => true);

          // Act
          final result1 = await useCase(
            surahId: '001',
            reciterName: 'Abdul Rahman Al-Sudais',
          );
          final result2 = await useCase(
            surahId: '002',
            reciterName: 'Mishary Rashid Alafasy',
          );
          final result3 = await useCase(
            surahId: '003',
            reciterName: 'Saad Al-Ghamdi',
          );

          // Assert
          expect(result1, const Right(true));
          expect(result2, const Right(true));
          expect(result3, const Right(true));

          verify(
            mockRepository.isSurahDownloaded('001', 'Abdul Rahman Al-Sudais'),
          ).called(1);
          verify(
            mockRepository.isSurahDownloaded('002', 'Mishary Rashid Alafasy'),
          ).called(1);
          verify(
            mockRepository.isSurahDownloaded('003', 'Saad Al-Ghamdi'),
          ).called(1);
          verifyNoMoreInteractions(mockRepository);
        },
      );

      test('should handle null pointer exception', () async {
        // Arrange
        const testSurahId = '001';
        const testReciterName = 'Abdul Rahman Al-Sudais';
        const errorMessage = 'Null pointer exception';
        when(
          mockRepository.isSurahDownloaded(any, any),
        ).thenThrow(Exception(errorMessage));

        // Act
        final result = await useCase(
          surahId: testSurahId,
          reciterName: testReciterName,
        );

        // Assert
        expect(result, Left(AudioFailure('Exception: $errorMessage')));
        verify(
          mockRepository.isSurahDownloaded(testSurahId, testReciterName),
        ).called(1);
        verifyNoMoreInteractions(mockRepository);
      });

      test('should handle unknown error type', () async {
        // Arrange
        const testSurahId = '001';
        const testReciterName = 'Abdul Rahman Al-Sudais';
        when(
          mockRepository.isSurahDownloaded(any, any),
        ).thenThrow(123); // Non-Exception error

        // Act
        final result = await useCase(
          surahId: testSurahId,
          reciterName: testReciterName,
        );

        // Assert
        expect(result, const Left(AudioFailure('123')));
        verify(
          mockRepository.isSurahDownloaded(testSurahId, testReciterName),
        ).called(1);
        verifyNoMoreInteractions(mockRepository);
      });
    });
  });
}
