import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa/features/audio_player/domain/repositories/player_background_repository.dart';
import 'package:tilawa/features/audio_player/domain/usecases/delete_player_background_use_case.dart';

import 'delete_player_background_use_case_test.mocks.dart';

@GenerateMocks([PlayerBackgroundRepository])
void main() {
  late DeletePlayerBackgroundUseCase useCase;
  late MockPlayerBackgroundRepository mockRepository;

  setUp(() {
    mockRepository = MockPlayerBackgroundRepository();
    useCase = DeletePlayerBackgroundUseCase(mockRepository);
  });

  group('DeletePlayerBackgroundUseCase', () {
    test('forwards the path to repository.deleteImage', () async {
      when(
        mockRepository.deleteImage(any),
      ).thenAnswer((_) => Future<void>.value());

      final result = await useCase('/app/storage/bg.png');

      expect(result, const Right<Failure, void>(null));
      verify(mockRepository.deleteImage('/app/storage/bg.png')).called(1);
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
