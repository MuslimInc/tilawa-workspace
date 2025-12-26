import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/core/errors/failures.dart';
import 'package:tilawa/features/downloads/domain/repositories/downloads_repository.dart';
import 'package:tilawa/features/downloads/domain/usecases/download_surah_use_case.dart';

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
    const testReciterId = 1;

    group('call', () {
      test('should return Right(null) when download is successful', () async {
        // Arrange
        when(
          mockRepository.startDownload(
            any,
            title: anyNamed('title'),
            surahTitle: anyNamed('surahTitle'),
            reciterName: anyNamed('reciterName'),
            reciterId: anyNamed('reciterId'),
          ),
        ).thenAnswer((_) async {});

        // Act
        final Either<Failure, void> result = await useCase(
          surahId: testSurahId,
          surahTitle: testSurahTitle,
          reciterName: testReciterName,
          reciterId: testReciterId,
        );

        // Assert
        result.fold(
          (_) => fail('Expected Right but got Left'),
          (_) => expect(true, true), // Right with void
        );
        verify(
          mockRepository.startDownload(
            testSurahId,
            title: testSurahTitle,
            surahTitle: testSurahTitle,
            reciterName: testReciterName,
            reciterId: testReciterId,
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
            mockRepository.startDownload(
              any,
              title: anyNamed('title'),
              surahTitle: anyNamed('surahTitle'),
              reciterName: anyNamed('reciterName'),
              reciterId: anyNamed('reciterId'),
            ),
          ).thenThrow(Exception(errorMessage));

          // Act
          final Either<Failure, void> result = await useCase(
            surahId: testSurahId,
            surahTitle: testSurahTitle,
            reciterName: testReciterName,
            reciterId: testReciterId,
          );

          // Assert
          result.fold((failure) {
            expect(failure, isA<AudioFailure>());
            expect(failure.message, 'Exception: $errorMessage');
          }, (_) => fail('Expected Left but got Right'));
          verify(
            mockRepository.startDownload(
              testSurahId,
              title: testSurahTitle,
              surahTitle: testSurahTitle,
              reciterName: testReciterName,
              reciterId: testReciterId,
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
            mockRepository.startDownload(
              any,
              title: anyNamed('title'),
              surahTitle: anyNamed('surahTitle'),
              reciterName: anyNamed('reciterName'),
              reciterId: anyNamed('reciterId'),
            ),
          ).thenThrow('Generic error');

          // Act
          final Either<Failure, void> result = await useCase(
            surahId: testSurahId,
            surahTitle: testSurahTitle,
            reciterName: testReciterName,
            reciterId: testReciterId,
          );

          // Assert
          result.fold((failure) {
            expect(failure, isA<AudioFailure>());
            expect(failure.message, 'Generic error');
          }, (_) => fail('Expected Left but got Right'));
          verify(
            mockRepository.startDownload(
              testSurahId,
              title: testSurahTitle,
              surahTitle: testSurahTitle,
              reciterName: testReciterName,
              reciterId: testReciterId,
            ),
          ).called(1);
          verifyNoMoreInteractions(mockRepository);
        },
      );

      test('should call repository with correct parameters', () async {
        // Arrange
        when(
          mockRepository.startDownload(
            any,
            title: anyNamed('title'),
            surahTitle: anyNamed('surahTitle'),
            reciterName: anyNamed('reciterName'),
            reciterId: anyNamed('reciterId'),
          ),
        ).thenAnswer((_) async {});

        // Act
        await useCase(
          surahId: testSurahId,
          surahTitle: testSurahTitle,
          reciterName: testReciterName,
          reciterId: testReciterId,
        );

        // Assert
        verify(
          mockRepository.startDownload(
            testSurahId,
            title: testSurahTitle,
            surahTitle: testSurahTitle,
            reciterName: testReciterName,
            reciterId: testReciterId,
          ),
        ).called(1);
        verifyNoMoreInteractions(mockRepository);
      });

      test('should handle empty strings as parameters', () async {
        // Arrange
        when(
          mockRepository.startDownload(
            any,
            title: anyNamed('title'),
            surahTitle: anyNamed('surahTitle'),
            reciterName: anyNamed('reciterName'),
            reciterId: anyNamed('reciterId'),
          ),
        ).thenAnswer((_) async {});

        // Act
        final Either<Failure, void> result = await useCase(
          surahId: '',
          surahTitle: '',
          reciterName: '',
          reciterId: 0,
        );

        // Assert
        result.fold(
          (_) => fail('Expected Right but got Left'),
          (_) => expect(true, true), // Right with void
        );
        verify(
          mockRepository.startDownload(
            any,
            title: '',
            surahTitle: '',
            reciterName: '',
            reciterId: 0,
          ),
        ).called(1);
        verifyNoMoreInteractions(mockRepository);
      });

      test('should handle special characters in parameters', () async {
        // Arrange
        const specialSurahId = '001-الفاتحة';
        const specialSurahTitle = 'Al-Fatiha (الفاتحة)';
        const specialReciterName = 'عبد الرحمن السديس';

        when(
          mockRepository.startDownload(
            any,
            title: anyNamed('title'),
            surahTitle: anyNamed('surahTitle'),
            reciterName: anyNamed('reciterName'),
            reciterId: anyNamed('reciterId'),
          ),
        ).thenAnswer((_) async {});

        // Act
        final Either<Failure, void> result = await useCase(
          surahId: specialSurahId,
          surahTitle: specialSurahTitle,
          reciterName: specialReciterName,
          reciterId: testReciterId,
        );

        // Assert
        result.fold(
          (_) => fail('Expected Right but got Left'),
          (_) => expect(true, true), // Right with void
        );
        verify(
          mockRepository.startDownload(
            specialSurahId,
            title: specialSurahTitle,
            surahTitle: specialSurahTitle,
            reciterName: specialReciterName,
            reciterId: testReciterId,
          ),
        ).called(1);
        verifyNoMoreInteractions(mockRepository);
      });
    });
  });
}
