import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/core/errors/failures.dart';
import 'package:tilawa/features/downloads/domain/repositories/downloads_repository.dart';
import 'package:tilawa/features/downloads/domain/usecases/cancel_downloads_for_reciter_use_case.dart';

import 'cancel_downloads_for_reciter_use_case_test.mocks.dart';

@GenerateMocks([DownloadsRepository])
void main() {
  late CancelDownloadsForReciterUseCase useCase;
  late MockDownloadsRepository mockRepository;

  setUp(() {
    mockRepository = MockDownloadsRepository();
    useCase = CancelDownloadsForReciterUseCase(mockRepository);
  });

  const testReciterName = 'Abdul Rahman Al-Sudais';

  group('CancelDownloadsForReciterUseCase', () {
    test('should cancel downloads for reciter successfully', () async {
      // Arrange
      when(
        mockRepository.cancelDownloadsForReciter(any),
      ).thenAnswer((_) async => Future.value());

      // Act
      final Either<Failure, void> result = await useCase(testReciterName);

      // Assert
      expect(result, isA<Right>());
      verify(
        mockRepository.cancelDownloadsForReciter(testReciterName),
      ).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test(
      'should return ServerFailure when repository throws exception',
      () async {
        // Arrange
        const errorMessage = 'Failed to cancel downloads';
        when(
          mockRepository.cancelDownloadsForReciter(any),
        ).thenThrow(Exception(errorMessage));

        // Act
        final Either<Failure, void> result = await useCase(testReciterName);

        // Assert
        expect(result, isA<Left>());
        result.fold((failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, contains(errorMessage));
        }, (_) => fail('Should return Left with ServerFailure'));
        verify(
          mockRepository.cancelDownloadsForReciter(testReciterName),
        ).called(1);
      },
    );

    test('should handle empty reciter name', () async {
      // Arrange
      when(
        mockRepository.cancelDownloadsForReciter(any),
      ).thenAnswer((_) async => Future.value());

      // Act
      final Either<Failure, void> result = await useCase('');

      // Assert
      expect(result, isA<Right>());
      verify(mockRepository.cancelDownloadsForReciter('')).called(1);
    });
  });
}
