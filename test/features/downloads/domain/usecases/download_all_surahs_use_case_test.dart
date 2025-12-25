import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/core/entities/audio.dart';
import 'package:tilawa/core/errors/failures.dart';
import 'package:tilawa/features/downloads/domain/repositories/downloads_repository.dart';
import 'package:tilawa/features/downloads/domain/usecases/download_all_surahs_use_case.dart';
import 'package:tilawa/features/surah/domain/entities/surah_entity.dart';

class MockDownloadsRepository extends Mock implements DownloadsRepository {}

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
      () => mockDownloadsRepository.startDownloadBatch(any()),
    ).thenAnswer((_) async {});

    // Act
    final Either<Failure, void> result = await useCase.call(
      surahs: tSurahs,
      reciterName: tReciterName,
      reciterId: tReciterId,
    );

    // Assert
    expect(result.isRight, true);
    verify(
      () => mockDownloadsRepository.startDownloadBatch(
        any(
          that:
              isA<
                    List<
                      ({
                        int reciterId,
                        String reciterName,
                        String surahTitle,
                        String url,
                      })
                    >
                  >()
                  .having((l) => l.length, 'length', 2)
                  .having((l) => l[0].url, 'url1', 'url1')
                  .having((l) => l[1].url, 'url2', 'url2'),
        ),
      ),
    ).called(1);
    verifyNever(
      () => mockDownloadsRepository.startDownload(
        any(),
        title: any(named: 'title'),
        surahTitle: any(named: 'surahTitle'),
        reciterName: any(named: 'reciterName'),
        reciterId: any(named: 'reciterId'),
      ),
    );
  });
}
