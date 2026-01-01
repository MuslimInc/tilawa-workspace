import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/core/errors/failures.dart';
import 'package:tilawa/features/downloads/domain/usecases/delete_reciter_downloads_use_case.dart';

import '../../helpers/mock_helper.mocks.dart';

void main() {
  late DeleteReciterDownloadsUseCase useCase;
  late MockDownloadsRepository mockRepository;

  setUp(() {
    mockRepository = MockDownloadsRepository();
    useCase = DeleteReciterDownloadsUseCase(mockRepository);
  });

  const testReciterName = 'Abdul Rahman Al-Sudais';

  group('DeleteReciterDownloadsUseCase', () {
    test(
      'should call repository.deleteReciterDownloads with reciter name',
      () async {
        // Arrange
        when(
          mockRepository.deleteReciterDownloads(any),
        ).thenAnswer((_) async => Future.value());

        // Act
        final Either<Failure, void> result = await useCase(testReciterName);

        // Assert
        expect(result, isA<Right>());
        verify(
          mockRepository.deleteReciterDownloads(testReciterName),
        ).called(1);
        verifyNoMoreInteractions(mockRepository);
      },
    );

    test(
      'should return AudioFailure when repository throws exception',
      () async {
        // Arrange
        const errorMessage = 'Delete failed';
        when(
          mockRepository.deleteReciterDownloads(any),
        ).thenThrow(Exception(errorMessage));

        // Act
        final Either<Failure, void> result = await useCase(testReciterName);

        // Assert
        expect(result, isA<Left>());
        result.fold((failure) {
          expect(failure, isA<AudioFailure>());
          expect(failure.message, contains(errorMessage));
        }, (_) => fail('Should return Left'));

        verify(
          mockRepository.deleteReciterDownloads(testReciterName),
        ).called(1);
      },
    );
  });
}
