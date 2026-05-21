import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa_core/entities/audio.dart';
import 'package:tilawa/features/downloads/domain/repositories/downloads_repository.dart';
import 'package:tilawa/features/surah/domain/entities/surah_entity.dart';
import 'package:tilawa/features/surah/domain/repositories/surah_repository.dart';
import 'package:tilawa/features/surah/domain/usecases/refresh_surah_download_status_use_case.dart';

import 'refresh_surah_download_status_use_case_test.mocks.dart';

@GenerateMocks([SurahRepository, DownloadsRepository])
void main() {
  late RefreshSurahDownloadStatusUseCase useCase;
  late MockSurahRepository mockSurahRepo;
  late MockDownloadsRepository mockDownloadsRepo;

  setUp(() {
    mockSurahRepo = MockSurahRepository();
    mockDownloadsRepo = MockDownloadsRepository();
    useCase = RefreshSurahDownloadStatusUseCase(
      mockSurahRepo,
      mockDownloadsRepo,
    );
  });

  const tReciter = 'Abdul Basit';
  const tTargetId = 'audio/001.mp3';
  const tOtherId = 'audio/002.mp3';

  AudioEntity makeAudio(String id) => AudioEntity(
    id: id,
    title: id,
    artist: tReciter,
    url: 'https://example.com/$id',
    duration: const Duration(seconds: 30),
  );

  group('RefreshSurahDownloadStatusUseCase', () {
    test(
      'updates only the matching surah in the list and refreshes the cache',
      () async {
        final target = SurahEntity(audio: makeAudio(tTargetId));
        final other = SurahEntity(audio: makeAudio(tOtherId));

        when(
          mockDownloadsRepo.isSurahDownloaded(any, any),
        ).thenAnswer((_) async => true);
        when(
          mockDownloadsRepo.isSurahDownloading(any, any),
        ).thenAnswer((_) async => false);
        when(
          mockSurahRepo.getSurah(any, any),
        ).thenAnswer((_) async => target);
        when(
          mockSurahRepo.updateSurah(any),
        ).thenAnswer((_) => Future<void>.value());

        final result = await useCase(
          currentSurahs: [target, other],
          surahId: tTargetId,
          reciterName: tReciter,
        );

        expect(result, hasLength(2));
        expect(result[0].id, tTargetId);
        expect(result[0].isDownloaded, isTrue);
        expect(result[0].isDownloading, isFalse);
        // Other surah passes through unchanged
        expect(result[1].id, tOtherId);
        expect(result[1].isDownloaded, isFalse);

        verify(mockDownloadsRepo.isSurahDownloaded(tTargetId, tReciter))
            .called(1);
        verify(mockDownloadsRepo.isSurahDownloading(tTargetId, tReciter))
            .called(1);

        final captured = verify(mockSurahRepo.updateSurah(captureAny))
            .captured
            .single as SurahEntity;
        expect(captured.id, tTargetId);
        expect(captured.isDownloaded, isTrue);
      },
    );

    test(
      'skips repository cache update when surah is not in repository',
      () async {
        final target = SurahEntity(audio: makeAudio(tTargetId));

        when(
          mockDownloadsRepo.isSurahDownloaded(any, any),
        ).thenAnswer((_) async => true);
        when(
          mockDownloadsRepo.isSurahDownloading(any, any),
        ).thenAnswer((_) async => true);
        when(
          mockSurahRepo.getSurah(any, any),
        ).thenAnswer((_) async => null);

        final result = await useCase(
          currentSurahs: [target],
          surahId: tTargetId,
          reciterName: tReciter,
        );

        // List is still updated for the UI.
        expect(result.single.isDownloaded, isTrue);
        expect(result.single.isDownloading, isTrue);

        // But the repository write is skipped because there's nothing to update.
        verifyNever(mockSurahRepo.updateSurah(any));
      },
    );
  });
}
