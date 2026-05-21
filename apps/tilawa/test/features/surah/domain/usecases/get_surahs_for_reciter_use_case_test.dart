import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa_core/entities/audio.dart';
import 'package:tilawa/features/surah/domain/entities/surah_entity.dart';
import 'package:tilawa/features/surah/domain/repositories/surah_repository.dart';
import 'package:tilawa/features/surah/domain/usecases/get_surahs_for_reciter_use_case.dart';

import 'get_surahs_for_reciter_use_case_test.mocks.dart';

@GenerateMocks([SurahRepository])
void main() {
  late GetSurahsForReciterUseCase useCase;
  late MockSurahRepository mockRepository;

  setUp(() {
    mockRepository = MockSurahRepository();
    useCase = GetSurahsForReciterUseCase(mockRepository);
  });

  group('GetSurahsForReciterUseCase', () {
    const tReciter = 'Abdul Basit';
    const tSurahs = [
      SurahEntity(
        audio: AudioEntity(
          id: 'audio/001.mp3',
          title: 'Al-Fatiha',
          artist: tReciter,
          url: 'https://example.com/001.mp3',
          duration: Duration(seconds: 95),
        ),
      ),
    ];

    test('delegates to repository and returns surahs', () async {
      when(
        mockRepository.getSurahsForReciter(any),
      ).thenAnswer((_) async => tSurahs);

      final result = await useCase(tReciter);

      expect(result, tSurahs);
      verify(mockRepository.getSurahsForReciter(tReciter)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('returns empty list when repository has no surahs', () async {
      when(
        mockRepository.getSurahsForReciter(any),
      ).thenAnswer((_) async => <SurahEntity>[]);

      final result = await useCase(tReciter);

      expect(result, isEmpty);
      verify(mockRepository.getSurahsForReciter(tReciter)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('propagates repository errors', () async {
      when(
        mockRepository.getSurahsForReciter(any),
      ).thenThrow(Exception('db error'));

      await expectLater(useCase(tReciter), throwsException);
    });
  });
}
