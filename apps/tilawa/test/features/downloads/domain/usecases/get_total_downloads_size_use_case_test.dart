import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/usecases/usecase.dart';
import 'package:tilawa/features/downloads/domain/usecases/get_total_downloads_size_use_case.dart';

import '../../helpers/mock_helper.mocks.dart';

void main() {
  late GetTotalDownloadsSizeUseCase useCase;
  late MockDownloadsRepository mockRepository;

  setUp(() {
    mockRepository = MockDownloadsRepository();
    useCase = GetTotalDownloadsSizeUseCase(mockRepository);
  });

  group('GetTotalDownloadsSizeUseCase', () {
    test('should get total downloads size successfully', () async {
      // Arrange
      const expectedSize = 1024000; // 1MB
      when(
        mockRepository.getTotalDownloadsSize(),
      ).thenAnswer((_) async => expectedSize);

      // Act
      final Either<Failure, int> result = await useCase(const NoParams());

      // Assert
      expect(result, isA<Right>());
      result.fold(
        (_) => fail('Should return Right'),
        (size) => expect(size, expectedSize),
      );
      verify(mockRepository.getTotalDownloadsSize()).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return 0 when no downloads exist', () async {
      // Arrange
      when(mockRepository.getTotalDownloadsSize()).thenAnswer((_) async => 0);

      // Act
      final Either<Failure, int> result = await useCase(const NoParams());

      // Assert
      expect(result, isA<Right>());
      result.fold(
        (_) => fail('Should return Right'),
        (size) => expect(size, 0),
      );
      verify(mockRepository.getTotalDownloadsSize()).called(1);
    });

    test('should return large size for many downloads', () async {
      // Arrange
      const largeSize = 1073741824; // 1GB
      when(
        mockRepository.getTotalDownloadsSize(),
      ).thenAnswer((_) async => largeSize);

      // Act
      final Either<Failure, int> result = await useCase(const NoParams());

      // Assert
      expect(result, isA<Right>());
      result.fold(
        (_) => fail('Should return Right'),
        (size) => expect(size, largeSize),
      );
      verify(mockRepository.getTotalDownloadsSize()).called(1);
    });

    test(
      'should return CacheFailure when repository throws exception',
      () async {
        // Arrange
        const errorMessage = 'Failed to calculate size';
        when(
          mockRepository.getTotalDownloadsSize(),
        ).thenThrow(Exception(errorMessage));

        // Act
        final Either<Failure, int> result = await useCase(const NoParams());

        // Assert
        expect(result, isA<Left>());
        result.fold((failure) {
          expect(failure, isA<CacheFailure>());
          expect(failure.message, contains(errorMessage));
        }, (_) => fail('Should return Left with CacheFailure'));
        verify(mockRepository.getTotalDownloadsSize()).called(1);
      },
    );
  });
}
