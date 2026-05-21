import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/features/surah/domain/repositories/surah_repository.dart';
import 'package:tilawa/features/surah/domain/usecases/update_surah_download_progress_use_case.dart';

import 'update_surah_download_progress_use_case_test.mocks.dart';

@GenerateMocks([SurahRepository])
void main() {
  late UpdateSurahDownloadProgressUseCase useCase;
  late MockSurahRepository mockRepository;

  setUp(() {
    mockRepository = MockSurahRepository();
    useCase = UpdateSurahDownloadProgressUseCase(mockRepository);
  });

  group('UpdateSurahDownloadProgressUseCase', () {
    const tSurahId = 'audio/001.mp3';
    const tReciter = 'Abdul Basit';

    test('forwards all progress fields to repository', () async {
      when(
        mockRepository.updateSurahDownloadProgress(any, any, any, any, any),
      ).thenAnswer((_) => Future<void>.value());

      await useCase(
        surahId: tSurahId,
        reciterName: tReciter,
        isDownloading: true,
        progress: 0.42,
        downloadId: 'd-1',
      );

      verify(
        mockRepository.updateSurahDownloadProgress(
          tSurahId,
          tReciter,
          true,
          0.42,
          'd-1',
        ),
      ).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('passes a null downloadId through unchanged', () async {
      when(
        mockRepository.updateSurahDownloadProgress(any, any, any, any, any),
      ).thenAnswer((_) => Future<void>.value());

      await useCase(
        surahId: tSurahId,
        reciterName: tReciter,
        isDownloading: false,
        progress: 0.0,
      );

      verify(
        mockRepository.updateSurahDownloadProgress(
          tSurahId,
          tReciter,
          false,
          0.0,
          null,
        ),
      ).called(1);
    });
  });
}
