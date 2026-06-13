import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa_core/entities/audio.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa/features/downloads/domain/entities/download_item.dart';
import 'package:tilawa/features/downloads/domain/repositories/downloads_repository.dart';
import 'package:tilawa/features/reciters/domain/repositories/reciters_repository.dart';
import 'package:tilawa/features/surah/domain/repositories/surah_repository.dart';
import 'package:tilawa/features/surah/domain/usecases/convert_audio_entities_to_surahs_use_case.dart';

import 'convert_audio_entities_to_surahs_use_case_test.mocks.dart';

@GenerateMocks([SurahRepository, DownloadsRepository, RecitersRepository])
void main() {
  provideDummy<Either<Failure, List<ReciterEntity>>>(const Right([]));

  late ConvertAudioEntitiesToSurahsUseCase useCase;
  late MockSurahRepository mockSurahRepo;
  late MockDownloadsRepository mockDownloadsRepo;
  late MockRecitersRepository mockRecitersRepo;

  setUp(() {
    mockSurahRepo = MockSurahRepository();
    mockDownloadsRepo = MockDownloadsRepository();
    mockRecitersRepo = MockRecitersRepository();
    useCase = ConvertAudioEntitiesToSurahsUseCase(
      mockSurahRepo,
      mockDownloadsRepo,
      mockRecitersRepo,
    );
    when(
      mockSurahRepo.updateSurah(any),
    ).thenAnswer((_) => Future<void>.value());
  });

  const tReciter = 'Abdul Basit';
  const tReciterEntity = ReciterEntity(
    id: 7,
    name: tReciter,
    letter: 'ع',
    date: '2020-01-01',
    moshaf: [],
  );

  AudioEntity audio(String url, {String? artist}) => AudioEntity(
    id: url,
    title: url,
    artist: artist ?? tReciter,
    url: url,
    duration: const Duration(seconds: 30),
  );

  DownloadItem downloadItem({
    required String url,
    required DownloadStatus status,
    double progress = 0.0,
    int? reciterId,
    String? reciterName,
    String id = 'd-1',
  }) {
    return DownloadItem(
      id: id,
      title: url,
      url: url,
      filePath: '/tmp/$id',
      reciterName: reciterName ?? tReciter,
      reciterId: reciterId,
      status: status,
      progress: progress,
      fileSize: 1000,
      downloadedSize: (1000 * progress).toInt(),
      createdAt: DateTime(2026),
    );
  }

  group('ConvertAudioEntitiesToSurahsUseCase', () {
    test('returns an empty list when given no audio entities', () async {
      final result = await useCase([]);

      expect(result, isEmpty);
      verifyNever(mockDownloadsRepo.getAllDownloads());
      verifyNever(mockRecitersRepo.getReciters());
      verifyNever(mockSurahRepo.updateSurah(any));
    });

    test(
      'matches completed downloads by reciterId and marks isDownloaded',
      () async {
        final a1 = audio('https://example.com/001.mp3');
        when(
          mockDownloadsRepo.getAllDownloads(),
        ).thenAnswer(
          (_) async => [
            downloadItem(
              url: a1.url,
              status: DownloadStatus.completed,
              reciterId: tReciterEntity.id,
              reciterName: 'someone-else',
            ),
          ],
        );
        when(
          mockRecitersRepo.getReciters(),
        ).thenAnswer((_) async => const Right([tReciterEntity]));

        final result = await useCase([a1]);

        expect(result, hasLength(1));
        expect(result.single.isDownloaded, isTrue);
        expect(result.single.isDownloading, isFalse);
        expect(result.single.downloadId, 'd-1');
      },
    );

    test(
      'matches in-flight downloads by reciter name when id lookup fails',
      () async {
        final a1 = audio('https://example.com/001.mp3');
        when(
          mockDownloadsRepo.getAllDownloads(),
        ).thenAnswer(
          (_) async => [
            downloadItem(
              url: a1.url,
              status: DownloadStatus.downloading,
              progress: 0.4,
            ),
          ],
        );
        when(
          mockRecitersRepo.getReciters(),
        ).thenAnswer((_) async => const Left(ServerFailure('boom')));

        final result = await useCase([a1]);

        expect(result.single.isDownloaded, isFalse);
        expect(result.single.isDownloading, isTrue);
        expect(result.single.downloadProgress, 0.4);
      },
    );

    test('treats pending downloads the same as downloading', () async {
      final a1 = audio('https://example.com/001.mp3');
      when(
        mockDownloadsRepo.getAllDownloads(),
      ).thenAnswer(
        (_) async => [
          downloadItem(
            url: a1.url,
            status: DownloadStatus.pending,
            progress: 0.1,
          ),
        ],
      );
      when(
        mockRecitersRepo.getReciters(),
      ).thenAnswer((_) async => const Right([tReciterEntity]));

      final result = await useCase([a1]);

      expect(result.single.isDownloading, isTrue);
      expect(result.single.downloadProgress, 0.1);
    });

    test(
      'skips download lookup entirely when first audio has no artist',
      () async {
        final a1 = audio('https://example.com/001.mp3', artist: '');

        final result = await useCase([a1]);

        expect(result, hasLength(1));
        expect(result.single.isDownloaded, isFalse);
        expect(result.single.isDownloading, isFalse);
        verifyNever(mockDownloadsRepo.getAllDownloads());
        verifyNever(mockRecitersRepo.getReciters());
      },
    );

    test(
      'ignores downloads that match neither reciterId nor reciterName',
      () async {
        final a1 = audio('https://example.com/001.mp3');
        when(
          mockDownloadsRepo.getAllDownloads(),
        ).thenAnswer(
          (_) async => [
            downloadItem(
              url: a1.url,
              status: DownloadStatus.completed,
              reciterId: 999,
              reciterName: 'someone-else',
            ),
          ],
        );
        when(
          mockRecitersRepo.getReciters(),
        ).thenAnswer((_) async => const Right([tReciterEntity]));

        final result = await useCase([a1]);

        expect(result.single.isDownloaded, isFalse);
      },
    );

    test('persists each generated surah to the surah repository', () async {
      final a1 = audio('https://example.com/001.mp3');
      final a2 = audio('https://example.com/002.mp3');
      when(
        mockDownloadsRepo.getAllDownloads(),
      ).thenAnswer((_) async => <DownloadItem>[]);
      when(
        mockRecitersRepo.getReciters(),
      ).thenAnswer((_) async => const Right([tReciterEntity]));

      final result = await useCase([a1, a2]);

      expect(result.map((s) => s.id), [a1.id, a2.id]);
      verify(mockSurahRepo.updateSurah(any)).called(2);
    });
  });
}
