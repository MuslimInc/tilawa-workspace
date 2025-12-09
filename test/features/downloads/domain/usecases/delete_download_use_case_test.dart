import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:muzakri/core/errors/failures.dart';
import 'package:muzakri/features/downloads/domain/repositories/downloads_repository.dart';
import 'package:muzakri/features/downloads/domain/usecases/delete_download_use_case.dart';

import 'delete_download_use_case_test.mocks.dart';

@GenerateMocks([DownloadsRepository])
void main() {
  late DeleteDownloadUseCase useCase;
  late MockDownloadsRepository mockRepository;

  setUp(() {
    mockRepository = MockDownloadsRepository();
    useCase = DeleteDownloadUseCase(mockRepository);
  });

  group('DeleteDownloadUseCase', () {
    group('call', () {
      test('should return Right(null) when delete is successful', () async {
        // Arrange
        const testDownloadId = '001_Abdul_Rahman_Al-Sudais';
        when(mockRepository.deleteDownload(any)).thenAnswer((_) async {});

        // Act
        final Either<Failure, void> result = await useCase(testDownloadId);

        // Assert
        result.fold(
          (_) => fail('Expected Right but got Left'),
          (_) => expect(true, true), // Right with void
        );
        verify(mockRepository.deleteDownload(testDownloadId)).called(1);
        verifyNoMoreInteractions(mockRepository);
      });

      test(
        'should return Left(AudioFailure) when repository throws exception',
        () async {
          // Arrange
          const testDownloadId = '001_Abdul_Rahman_Al-Sudais';
          const errorMessage = 'File not found';
          when(
            mockRepository.deleteDownload(any),
          ).thenThrow(Exception(errorMessage));

          // Act
          final Either<Failure, void> result = await useCase(testDownloadId);

          // Assert
          result.fold((failure) {
            expect(failure, isA<AudioFailure>());
            expect(failure.message, 'Exception: $errorMessage');
          }, (_) => fail('Expected Left but got Right'));
          verify(mockRepository.deleteDownload(testDownloadId)).called(1);
          verifyNoMoreInteractions(mockRepository);
        },
      );

      test(
        'should return Left(AudioFailure) when repository throws generic exception',
        () async {
          // Arrange
          const testDownloadId = '001_Abdul_Rahman_Al-Sudais';
          when(mockRepository.deleteDownload(any)).thenThrow('Generic error');

          // Act
          final Either<Failure, void> result = await useCase(testDownloadId);

          // Assert
          result.fold((failure) {
            expect(failure, isA<AudioFailure>());
            expect(failure.message, 'Generic error');
          }, (_) => fail('Expected Left but got Right'));
          verify(mockRepository.deleteDownload(testDownloadId)).called(1);
          verifyNoMoreInteractions(mockRepository);
        },
      );

      test('should call repository with correct download ID', () async {
        // Arrange
        const testDownloadId = '002_Mishary_Rashid_Alafasy';
        when(mockRepository.deleteDownload(any)).thenAnswer((_) async {});

        // Act
        await useCase(testDownloadId);

        // Assert
        verify(mockRepository.deleteDownload(testDownloadId)).called(1);
        verifyNoMoreInteractions(mockRepository);
      });

      test('should handle empty download ID', () async {
        // Arrange
        const testDownloadId = '';
        when(mockRepository.deleteDownload(any)).thenAnswer((_) async {});

        // Act
        final Either<Failure, void> result = await useCase(testDownloadId);

        // Assert
        result.fold(
          (_) => fail('Expected Right but got Left'),
          (_) => expect(true, true), // Right with void
        );
        verify(mockRepository.deleteDownload(testDownloadId)).called(1);
        verifyNoMoreInteractions(mockRepository);
      });

      test('should handle special characters in download ID', () async {
        // Arrange
        const testDownloadId = '001-الفاتحة_عبد_الرحمن_السديس';
        when(mockRepository.deleteDownload(any)).thenAnswer((_) async {});

        // Act
        final Either<Failure, void> result = await useCase(testDownloadId);

        // Assert
        result.fold(
          (_) => fail('Expected Right but got Left'),
          (_) => expect(true, true), // Right with void
        );
        verify(mockRepository.deleteDownload(testDownloadId)).called(1);
        verifyNoMoreInteractions(mockRepository);
      });

      test('should handle very long download ID', () async {
        // Arrange
        final String testDownloadId = 'a' * 1000; // Very long ID
        when(mockRepository.deleteDownload(any)).thenAnswer((_) async {});

        // Act
        final Either<Failure, void> result = await useCase(testDownloadId);

        // Assert
        result.fold(
          (_) => fail('Expected Right but got Left'),
          (_) => expect(true, true), // Right with void
        );
        verify(mockRepository.deleteDownload(testDownloadId)).called(1);
        verifyNoMoreInteractions(mockRepository);
      });

      test('should handle database connection error', () async {
        // Arrange
        const testDownloadId = '001_Abdul_Rahman_Al-Sudais';
        const errorMessage = 'Database connection failed';
        when(
          mockRepository.deleteDownload(any),
        ).thenThrow(Exception(errorMessage));

        // Act
        final Either<Failure, void> result = await useCase(testDownloadId);

        // Assert
        result.fold((failure) {
          expect(failure, isA<AudioFailure>());
          expect(failure.message, 'Exception: $errorMessage');
        }, (_) => fail('Expected Left but got Right'));
        verify(mockRepository.deleteDownload(testDownloadId)).called(1);
        verifyNoMoreInteractions(mockRepository);
      });

      test('should handle file system error', () async {
        // Arrange
        const testDownloadId = '001_Abdul_Rahman_Al-Sudais';
        const errorMessage = 'Permission denied';
        when(
          mockRepository.deleteDownload(any),
        ).thenThrow(Exception(errorMessage));

        // Act
        final Either<Failure, void> result = await useCase(testDownloadId);

        // Assert
        result.fold((failure) {
          expect(failure, isA<AudioFailure>());
          expect(failure.message, 'Exception: $errorMessage');
        }, (_) => fail('Expected Left but got Right'));
        verify(mockRepository.deleteDownload(testDownloadId)).called(1);
        verifyNoMoreInteractions(mockRepository);
      });

      test('should handle network error during delete', () async {
        // Arrange
        const testDownloadId = '001_Abdul_Rahman_Al-Sudais';
        const errorMessage = 'Network timeout';
        when(
          mockRepository.deleteDownload(any),
        ).thenThrow(Exception(errorMessage));

        // Act
        final Either<Failure, void> result = await useCase(testDownloadId);

        // Assert
        result.fold((failure) {
          expect(failure, isA<AudioFailure>());
          expect(failure.message, 'Exception: $errorMessage');
        }, (_) => fail('Expected Left but got Right'));
        verify(mockRepository.deleteDownload(testDownloadId)).called(1);
        verifyNoMoreInteractions(mockRepository);
      });

      test('should handle multiple consecutive delete calls', () async {
        // Arrange
        const testDownloadId1 = '001_Abdul_Rahman_Al-Sudais';
        const testDownloadId2 = '002_Abdul_Rahman_Al-Sudais';
        const testDownloadId3 = '003_Abdul_Rahman_Al-Sudais';

        when(mockRepository.deleteDownload(any)).thenAnswer((_) async {});

        // Act
        final Either<Failure, void> result1 = await useCase(testDownloadId1);
        final Either<Failure, void> result2 = await useCase(testDownloadId2);
        final Either<Failure, void> result3 = await useCase(testDownloadId3);

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

        verify(mockRepository.deleteDownload(testDownloadId1)).called(1);
        verify(mockRepository.deleteDownload(testDownloadId2)).called(1);
        verify(mockRepository.deleteDownload(testDownloadId3)).called(1);
        verifyNoMoreInteractions(mockRepository);
      });
    });
  });
}
