import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa/features/audio_player/domain/repositories/player_background_repository.dart';
import 'package:tilawa/features/audio_player/domain/usecases/pick_player_background_use_case.dart';

import 'pick_player_background_use_case_test.mocks.dart';

@GenerateMocks([PlayerBackgroundRepository])
void main() {
  late PickPlayerBackgroundUseCase useCase;
  late MockPlayerBackgroundRepository mockRepository;

  setUp(() {
    mockRepository = MockPlayerBackgroundRepository();
    useCase = PickPlayerBackgroundUseCase(mockRepository);
  });

  group('PickPlayerBackgroundUseCase', () {
    test('persists picked image and returns the persistent path', () async {
      when(
        mockRepository.pickImage(any),
      ).thenAnswer((_) async => '/cache/tmp.png');
      when(
        mockRepository.persistImage(any),
      ).thenAnswer((_) async => '/app/storage/bg.png');

      final result = await useCase(ImageSource.gallery);

      result.fold(
        (_) => fail('Expected Right result'),
        (path) => expect(path, '/app/storage/bg.png'),
      );
      verify(mockRepository.pickImage(ImageSource.gallery)).called(1);
      verify(mockRepository.persistImage('/cache/tmp.png')).called(1);
    });

    test('returns UserCancelledFailure when picker yields null', () async {
      when(mockRepository.pickImage(any)).thenAnswer((_) async => null);

      final result = await useCase(ImageSource.camera);

      result.fold(
        (f) => expect(f, isA<UserCancelledFailure>()),
        (_) => fail('Expected Left result'),
      );
      // Should not attempt to persist a non-existent image.
      verifyNever(mockRepository.persistImage(any));
    });

    test('wraps picker exceptions in CacheFailure', () async {
      when(
        mockRepository.pickImage(any),
      ).thenThrow(Exception('permission denied'));

      final result = await useCase(ImageSource.gallery);

      result.fold(
        (f) {
          expect(f, isA<CacheFailure>());
          expect(f.message, contains('permission denied'));
        },
        (_) => fail('Expected Left result'),
      );
    });

    test('wraps persistImage exceptions in CacheFailure', () async {
      when(
        mockRepository.pickImage(any),
      ).thenAnswer((_) async => '/cache/tmp.png');
      when(
        mockRepository.persistImage(any),
      ).thenThrow(Exception('disk full'));

      final result = await useCase(ImageSource.gallery);

      result.fold(
        (f) {
          expect(f, isA<CacheFailure>());
          expect(f.message, contains('disk full'));
        },
        (_) => fail('Expected Left result'),
      );
    });
  });
}
