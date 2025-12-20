import 'package:audio_service/audio_service.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:muzakri/core/errors/failures.dart';
import 'package:muzakri/features/downloads/domain/repositories/downloads_repository.dart';
import 'package:muzakri/features/downloads/domain/usecases/download_all_surahs_use_case.dart';
import 'package:muzakri/features/surah/domain/entities/surah_entity.dart';

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
    mediaItem: MediaItem(id: 'url1', title: 'Al-Fatiha', artist: tReciterName),
  );

  const tSurah2 = SurahEntity(
    mediaItem: MediaItem(id: 'url2', title: 'Al-Baqarah', artist: tReciterName),
  );

  final tSurahs = [tSurah1, tSurah2];

  test('should call startDownload for each surah', () async {
    // Arrange
    when(
      () => mockDownloadsRepository.startDownload(any(), any(), any(), any()),
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
      () => mockDownloadsRepository.startDownload(
        'url1',
        'Al-Fatiha',
        tReciterName,
        tReciterId,
      ),
    ).called(1);
    verify(
      () => mockDownloadsRepository.startDownload(
        'url2',
        'Al-Baqarah',
        tReciterName,
        tReciterId,
      ),
    ).called(1);
  });
}
