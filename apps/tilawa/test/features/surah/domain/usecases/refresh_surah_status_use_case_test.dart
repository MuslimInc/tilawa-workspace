import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa_core/entities/audio.dart';
import 'package:tilawa/features/downloads/domain/repositories/downloads_repository.dart';
import 'package:tilawa/features/surah/domain/entities/surah_entity.dart';
import 'package:tilawa/features/surah/domain/repositories/surah_repository.dart';
import 'package:tilawa/features/surah/domain/usecases/refresh_surah_status_use_case.dart';

import 'refresh_surah_status_use_case_test.mocks.dart';

@GenerateMocks([SurahRepository, DownloadsRepository])
void main() {
  late RefreshSurahStatusUseCase useCase;
  late MockSurahRepository mockSurahRepo;
  late MockDownloadsRepository mockDownloadsRepo;

  setUp(() {
    mockSurahRepo = MockSurahRepository();
    mockDownloadsRepo = MockDownloadsRepository();
    useCase = RefreshSurahStatusUseCase(mockSurahRepo, mockDownloadsRepo);
  });

  const tSurahId = 'audio/001.mp3';
  const tReciter = 'Abdul Basit';

  group('RefreshSurahStatusUseCase', () {
    test('updates existing surah with new isDownloaded value', () async {
      const existing = SurahEntity(
        audio: AudioEntity(
          id: tSurahId,
          title: 'Al-Fatiha',
          artist: tReciter,
          url: 'https://example.com/001.mp3',
          duration: Duration(seconds: 95),
        ),
        isDownloading: true,
      );
      when(
        mockDownloadsRepo.isSurahDownloaded(any, any),
      ).thenAnswer((_) async => true);
      when(
        mockSurahRepo.getSurah(any, any),
      ).thenAnswer((_) async => existing);
      when(
        mockSurahRepo.updateSurah(any),
      ).thenAnswer((_) => Future<void>.value());

      final result = await useCase(
        surahId: tSurahId,
        reciterName: tReciter,
      );

      expect(result, isNotNull);
      expect(result!.isDownloaded, isTrue);
      // isDownloading flag is preserved (only isDownloaded is refreshed here).
      expect(result.isDownloading, isTrue);

      final captured =
          verify(mockSurahRepo.updateSurah(captureAny)).captured.single
              as SurahEntity;
      expect(captured.isDownloaded, isTrue);
      expect(captured.audio.id, tSurahId);
    });

    test('synthesises a placeholder surah when repository has none', () async {
      when(
        mockDownloadsRepo.isSurahDownloaded(any, any),
      ).thenAnswer((_) async => false);
      when(
        mockSurahRepo.getSurah(any, any),
      ).thenAnswer((_) async => null);
      when(
        mockSurahRepo.updateSurah(any),
      ).thenAnswer((_) => Future<void>.value());

      final result = await useCase(
        surahId: tSurahId,
        reciterName: tReciter,
      );

      expect(result, isNotNull);
      expect(result!.audio.id, tSurahId);
      expect(result.audio.artist, tReciter);
      // Title/url come from the data source, not this use case.
      expect(result.audio.title, isEmpty);
      expect(result.audio.url, isEmpty);
      expect(result.audio.duration, Duration.zero);
      expect(result.isDownloaded, isFalse);

      verify(mockSurahRepo.updateSurah(any)).called(1);
    });
  });
}
