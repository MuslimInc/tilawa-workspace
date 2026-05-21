import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/features/surah/domain/repositories/surah_repository.dart';
import 'package:tilawa/features/surah/domain/usecases/update_surah_download_status_use_case.dart';

import 'update_surah_download_status_use_case_test.mocks.dart';

@GenerateMocks([SurahRepository])
void main() {
  late UpdateSurahDownloadStatusUseCase useCase;
  late MockSurahRepository mockRepository;

  setUp(() {
    mockRepository = MockSurahRepository();
    useCase = UpdateSurahDownloadStatusUseCase(mockRepository);
  });

  group('UpdateSurahDownloadStatusUseCase', () {
    const tSurahId = 'audio/001.mp3';
    const tReciter = 'Abdul Basit';

    test('forwards isDownloaded=true to repository', () async {
      when(
        mockRepository.updateSurahDownloadStatus(any, any, any),
      ).thenAnswer((_) => Future<void>.value());

      await useCase(
        surahId: tSurahId,
        reciterName: tReciter,
        isDownloaded: true,
      );

      verify(
        mockRepository.updateSurahDownloadStatus(tSurahId, tReciter, true),
      ).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('forwards isDownloaded=false to repository', () async {
      when(
        mockRepository.updateSurahDownloadStatus(any, any, any),
      ).thenAnswer((_) => Future<void>.value());

      await useCase(
        surahId: tSurahId,
        reciterName: tReciter,
        isDownloaded: false,
      );

      verify(
        mockRepository.updateSurahDownloadStatus(tSurahId, tReciter, false),
      ).called(1);
    });
  });
}
