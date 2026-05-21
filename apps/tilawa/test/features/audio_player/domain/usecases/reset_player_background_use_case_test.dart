import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa/features/audio_player/domain/repositories/player_background_repository.dart';
import 'package:tilawa/features/audio_player/domain/usecases/reset_player_background_use_case.dart';

import 'reset_player_background_use_case_test.mocks.dart';

@GenerateMocks([PlayerBackgroundRepository])
void main() {
  late ResetPlayerBackgroundUseCase useCase;
  late MockPlayerBackgroundRepository mockRepository;

  setUp(() {
    mockRepository = MockPlayerBackgroundRepository();
    useCase = ResetPlayerBackgroundUseCase(mockRepository);
  });

  group('ResetPlayerBackgroundUseCase', () {
    test('deletes the existing image when path is provided', () async {
      when(
        mockRepository.deleteImage(any),
      ).thenAnswer((_) => Future<void>.value());

      final result = await useCase('/app/storage/bg.png');

      expect(result, const Right<Failure, void>(null));
      verify(mockRepository.deleteImage('/app/storage/bg.png')).called(1);
    });

    test('returns success without deleting when path is null', () async {
      final result = await useCase(null);

      expect(result, const Right<Failure, void>(null));
      verifyNever(mockRepository.deleteImage(any));
    });

    test('wraps repository exceptions in CacheFailure', () async {
      when(mockRepository.deleteImage(any)).thenThrow(Exception('io error'));

      final result = await useCase('/app/storage/bg.png');

      result.fold(
        (f) {
          expect(f, isA<CacheFailure>());
          expect(f.message, contains('io error'));
        },
        (_) => fail('Expected Left result'),
      );
    });
  });
}
