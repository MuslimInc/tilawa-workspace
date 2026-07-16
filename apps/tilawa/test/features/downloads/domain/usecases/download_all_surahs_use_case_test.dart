import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa_core/entities/audio.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa/features/downloads/domain/usecases/download_all_surahs_use_case.dart';
import 'package:tilawa/features/surah/domain/entities/surah_entity.dart';

import '../../helpers/mock_helper.mocks.dart';

void main() {
  late DownloadAllSurahsUseCase useCase;
  late MockDownloadsRepository mockDownloadsRepository;

  setUp(() {
    mockDownloadsRepository = MockDownloadsRepository();
    useCase = DownloadAllSurahsUseCase(mockDownloadsRepository);
  });

  const tReciterName = 'Mishary Rashid';
  const tReciterId = 1;

  const tSurah1 = SurahEntity(
    audio: AudioEntity(
      id: 'url1',
      title: 'Al-Fatiha',
      artist: tReciterName,
      url: 'url1',
      duration: Duration.zero,
    ),
  );

  const tSurah2 = SurahEntity(
    audio: AudioEntity(
      id: 'url2',
      title: 'Al-Baqarah',
      artist: tReciterName,
      url: 'url2',
      duration: Duration.zero,
    ),
  );

  final tSurahs = [tSurah1, tSurah2];

  test('should call startDownloadBatch for all surahs', () async {
    // Arrange
    when(
      mockDownloadsRepository.startDownloadBatch(any),
    ).thenAnswer((_) async {
      return;
    });

    // Act
    final Either<Failure, void> result = await useCase.call(
      surahs: tSurahs,
      reciterName: tReciterName,
      reciterId: tReciterId,
    );

    // Assert
    expect(result.isRight(), true);
    verify(mockDownloadsRepository.startDownloadBatch(any)).called(1);
    verifyNever(
      mockDownloadsRepository.startDownload(
        any,
        title: anyNamed('title'),
        surahTitle: anyNamed('surahTitle'),
        reciterName: anyNamed('reciterName'),
        reciterId: anyNamed('reciterId'),
      ),
    );
  });
}
