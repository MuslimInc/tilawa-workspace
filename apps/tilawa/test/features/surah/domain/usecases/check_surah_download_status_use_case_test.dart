import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa_core/entities/audio.dart';
import 'package:tilawa/features/downloads/domain/repositories/downloads_repository.dart';
import 'package:tilawa/features/surah/domain/entities/surah_entity.dart';
import 'package:tilawa/features/surah/domain/repositories/surah_repository.dart';
import 'package:tilawa/features/surah/domain/usecases/check_surah_download_status_use_case.dart';

import 'check_surah_download_status_use_case_test.mocks.dart';

@GenerateMocks([SurahRepository, DownloadsRepository])
void main() {
  late CheckSurahDownloadStatusUseCase useCase;
  late MockSurahRepository mockSurahRepo;
  late MockDownloadsRepository mockDownloadsRepo;

  setUp(() {
    mockSurahRepo = MockSurahRepository();
    mockDownloadsRepo = MockDownloadsRepository();
    useCase = CheckSurahDownloadStatusUseCase(mockSurahRepo, mockDownloadsRepo);
  });

  const tSurahId = 'audio/001.mp3';
  const tReciter = 'Abdul Basit';
  const tAudio = AudioEntity(
    id: tSurahId,
    title: 'Al-Fatiha',
    artist: tReciter,
    url: 'https://example.com/001.mp3',
    duration: Duration(seconds: 95),
  );
  const tSurah = SurahEntity(audio: tAudio);

  group('CheckSurahDownloadStatusUseCase', () {
    test(
      'updates surah with downloads.isSurahDownloaded result and persists it',
      () async {
        when(
          mockDownloadsRepo.isSurahDownloaded(any, any),
        ).thenAnswer((_) async => true);
        when(
          mockSurahRepo.getSurah(any, any),
        ).thenAnswer((_) async => tSurah);
        when(
          mockSurahRepo.updateSurah(any),
        ).thenAnswer((_) => Future<void>.value());

        final result = await useCase(
          surahId: tSurahId,
          reciterName: tReciter,
        );

        expect(result, isNotNull);
        expect(result!.isDownloaded, isTrue);

        verify(mockDownloadsRepo.isSurahDownloaded(tSurahId, tReciter))
            .called(1);
        verify(mockSurahRepo.getSurah(tSurahId, tReciter)).called(1);
        final captured = verify(mockSurahRepo.updateSurah(captureAny))
            .captured
            .single as SurahEntity;
        expect(captured.isDownloaded, isTrue);
        expect(captured.audio, tAudio);
      },
    );

    test('returns null and does not update when surah is not in repository', () async {
      when(
        mockDownloadsRepo.isSurahDownloaded(any, any),
      ).thenAnswer((_) async => false);
      when(
        mockSurahRepo.getSurah(any, any),
      ).thenAnswer((_) async => null);

      final result = await useCase(
        surahId: tSurahId,
        reciterName: tReciter,
      );

      expect(result, isNull);
      verifyNever(mockSurahRepo.updateSurah(any));
    });

    test('preserves other fields on the surah when toggling isDownloaded', () async {
      const surahWithProgress = SurahEntity(
        audio: tAudio,
        isDownloading: true,
        downloadProgress: 0.5,
        downloadId: 'd-1',
      );
      when(
        mockDownloadsRepo.isSurahDownloaded(any, any),
      ).thenAnswer((_) async => true);
      when(
        mockSurahRepo.getSurah(any, any),
      ).thenAnswer((_) async => surahWithProgress);
      when(
        mockSurahRepo.updateSurah(any),
      ).thenAnswer((_) => Future<void>.value());

      final result = await useCase(
        surahId: tSurahId,
        reciterName: tReciter,
      );

      expect(result!.isDownloaded, isTrue);
      expect(result.isDownloading, isTrue);
      expect(result.downloadProgress, 0.5);
      expect(result.downloadId, 'd-1');
    });
  });
}
