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
    const testUrl = 'https://example.com/audio.mp3';

    test(
      'should return Right(null) when download starts successfully',
      () async {
        // Arrange
        when(
          mockRepository.startDownload(any, any, any, any),
        ).thenAnswer((_) async {});

        // Act
        final result = await useCase(
          surahId: testSurahId,
          surahTitle: testSurahTitle,
          reciterName: testReciterName,
          url: testUrl,
        );

        // Assert
        expect(result, const Right(null));
        verify(
          mockRepository.startDownload(
            testSurahId,
            testSurahTitle,
            testReciterName,
            testUrl,
          ),
        ).called(1);
      },
    );

    test(
      'should return Left(AudioFailure) when repository throws exception',
      () async {
        // Arrange
        const errorMessage = 'Network error';
        when(
          mockRepository.startDownload(any, any, any, any),
        ).thenThrow(Exception(errorMessage));

        // Act
        final result = await useCase(
          surahId: testSurahId,
          surahTitle: testSurahTitle,
          reciterName: testReciterName,
          url: testUrl,
        );

        // Assert
        expect(result, isA<Left<Failure, void>>());
        result.fold((failure) {
          expect(failure, isA<AudioFailure>());
          expect(failure.message, contains(errorMessage));
        }, (_) => fail('Should return failure'));
        verify(
          mockRepository.startDownload(
            testSurahId,
            testSurahTitle,
            testReciterName,
            testUrl,
          ),
        ).called(1);
      },
    );

    test('should handle empty surah ID', () async {
      // Arrange
      when(
        mockRepository.startDownload(any, any, any, any),
      ).thenThrow(Exception('Invalid surah ID'));

      // Act
      final result = await useCase(
        surahId: '',
        surahTitle: testSurahTitle,
        reciterName: testReciterName,
        url: testUrl,
      );

      // Assert
      expect(result, isA<Left<Failure, void>>());
      result.fold((failure) {
        expect(failure, isA<AudioFailure>());
        expect(failure.message, contains('Invalid surah ID'));
      }, (_) => fail('Should return failure'));
    });

    test('should handle invalid URL', () async {
      // Arrange
      const invalidUrl = 'not-a-valid-url';
      when(
        mockRepository.startDownload(any, any, any, any),
      ).thenThrow(Exception('Invalid URL format'));

      // Act
      final result = await useCase(
        surahId: testSurahId,
        surahTitle: testSurahTitle,
        reciterName: testReciterName,
        url: invalidUrl,
      );

      // Assert
      expect(result, isA<Left<Failure, void>>());
      result.fold((failure) {
        expect(failure, isA<AudioFailure>());
        expect(failure.message, contains('Invalid URL format'));
      }, (_) => fail('Should return failure'));
    });

    test('should handle network timeout', () async {
      // Arrange
      when(
        mockRepository.startDownload(any, any, any, any),
      ).thenThrow(Exception('Connection timeout'));

      // Act
      final result = await useCase(
        surahId: testSurahId,
        surahTitle: testSurahTitle,
        reciterName: testReciterName,
        url: testUrl,
      );

      // Assert
      expect(result, isA<Left<Failure, void>>());
      result.fold((failure) {
        expect(failure, isA<AudioFailure>());
        expect(failure.message, contains('Connection timeout'));
      }, (_) => fail('Should return failure'));
    });

    test('should handle file system errors', () async {
      // Arrange
      when(
        mockRepository.startDownload(any, any, any, any),
      ).thenThrow(Exception('Permission denied'));

      // Act
      final result = await useCase(
        surahId: testSurahId,
        surahTitle: testSurahTitle,
        reciterName: testReciterName,
        url: testUrl,
      );

      // Assert
      expect(result, isA<Left<Failure, void>>());
      result.fold((failure) {
        expect(failure, isA<AudioFailure>());
        expect(failure.message, contains('Permission denied'));
      }, (_) => fail('Should return failure'));
    });
  });
}
