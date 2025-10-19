import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:muzakri/core/errors/failures.dart';
import 'package:muzakri/features/downloads/domain/repositories/downloads_repository.dart';
import 'package:muzakri/features/downloads/domain/usecases/download_surah_use_case.dart';

import 'download_surah_use_case_test.mocks.dart';

@GenerateMocks([DownloadsRepository])
void main() {
  late DownloadSurahUseCase useCase;
  late MockDownloadsRepository mockRepository;

  setUp(() {
    mockRepository = MockDownloadsRepository();
    useCase = DownloadSurahUseCase(mockRepository);
  });

  group('DownloadSurahUseCase', () {
    const testSurahId = '001';
    const testSurahTitle = 'Al-Fatiha';
    const testReciterName = 'Abdul Rahman Al-Sudais';

    group('call', () {
      test('should return Right(null) when download is successful', () async {
        // Arrange
        when(
          mockRepository.startDownload(any, any, any),
        ).thenAnswer((_) async {});

        // Act
        final result = await useCase(
          surahId: testSurahId,
          surahTitle: testSurahTitle,
          reciterName: testReciterName,
        );

        // Assert
        expect(result, const Right(null));
        verify(
          mockRepository.startDownload(
            testSurahId,
            testSurahTitle,
            testReciterName,
          ),
        ).called(1);
        verifyNoMoreInteractions(mockRepository);
      });

      test(
        'should return Left(AudioFailure) when repository throws exception',
        () async {
          // Arrange
          const errorMessage = 'Network error';
          when(
            mockRepository.startDownload(any, any, any),
          ).thenThrow(Exception(errorMessage));

          // Act
          final result = await useCase(
            surahId: testSurahId,
            surahTitle: testSurahTitle,
            reciterName: testReciterName,
          );

          // Assert
          expect(result, Left(AudioFailure('Exception: $errorMessage')));
          verify(
            mockRepository.startDownload(
              testSurahId,
              testSurahTitle,
              testReciterName,
            ),
          ).called(1);
          verifyNoMoreInteractions(mockRepository);
        },
      );

      test(
        'should return Left(AudioFailure) when repository throws generic exception',
        () async {
          // Arrange
          when(
            mockRepository.startDownload(any, any, any),
          ).thenThrow('Generic error');

          // Act
          final result = await useCase(
            surahId: testSurahId,
            surahTitle: testSurahTitle,
            reciterName: testReciterName,
          );

          // Assert
          expect(result, const Left(AudioFailure('Generic error')));
          verify(
            mockRepository.startDownload(
              testSurahId,
              testSurahTitle,
              testReciterName,
            ),
          ).called(1);
          verifyNoMoreInteractions(mockRepository);
        },
      );

      test('should call repository with correct parameters', () async {
        // Arrange
        when(
          mockRepository.startDownload(any, any, any),
        ).thenAnswer((_) async {});

        // Act
        await useCase(
          surahId: testSurahId,
          surahTitle: testSurahTitle,
          reciterName: testReciterName,
        );

        // Assert
        verify(
          mockRepository.startDownload(
            testSurahId,
            testSurahTitle,
            testReciterName,
          ),
        ).called(1);
        verifyNoMoreInteractions(mockRepository);
      });

      test('should handle empty strings as parameters', () async {
        // Arrange
        when(
          mockRepository.startDownload(any, any, any),
        ).thenAnswer((_) async {});

        // Act
        final result = await useCase(
          surahId: '',
          surahTitle: '',
          reciterName: '',
        );

        // Assert
        expect(result, const Right(null));
        verify(mockRepository.startDownload('', '', '')).called(1);
        verifyNoMoreInteractions(mockRepository);
      });

      test('should handle special characters in parameters', () async {
        // Arrange
        const specialSurahId = '001-الفاتحة';
        const specialSurahTitle = 'Al-Fatiha (الفاتحة)';
        const specialReciterName = 'عبد الرحمن السديس';

        when(
          mockRepository.startDownload(any, any, any),
        ).thenAnswer((_) async {});

        // Act
        final result = await useCase(
          surahId: specialSurahId,
          surahTitle: specialSurahTitle,
          reciterName: specialReciterName,
        );

        // Assert
        expect(result, const Right(null));
        verify(
          mockRepository.startDownload(
            specialSurahId,
            specialSurahTitle,
            specialReciterName,
          ),
        ).called(1);
        verifyNoMoreInteractions(mockRepository);
      });
    });
  });
}
