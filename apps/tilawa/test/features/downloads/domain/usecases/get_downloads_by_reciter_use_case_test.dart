import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa/features/downloads/domain/entities/download_item.dart';
import 'package:tilawa/features/downloads/domain/services/completed_download_file_validator.dart';
import 'package:tilawa/features/downloads/domain/usecases/get_downloads_by_reciter_use_case.dart';

import '../../helpers/mock_helper.mocks.dart';

void main() {
  late GetDownloadsByReciterUseCase useCase;
  late MockDownloadsRepository mockRepository;
  late MockRecitersRepository mockRecitersRepository;

  void provideDummies() {
    provideDummy<Either<Failure, List<ReciterEntity>>>(const Right([]));
  }

  setUp(() {
    provideDummies();
    mockRepository = MockDownloadsRepository();
    mockRecitersRepository = MockRecitersRepository();
    useCase = GetDownloadsByReciterUseCase(
      mockRepository,
      mockRecitersRepository,
      CompletedDownloadFileValidator(mockRepository),
    );
  });

  const testReciterId = 1;
  const testReciterName = 'Abdul Rahman Al-Sudais';

  const testReciter = ReciterEntity(
    id: testReciterId,
    name: testReciterName,
    letter: 'A',
    date: '2024-01-01',
    moshaf: [],
  );

  final downloadItem = DownloadItem(
    id: '1',
    reciterName: 'Old Name', // Should be overridden by ReciterEntity name
    reciterId: testReciterId,
    status: DownloadStatus.completed,
    title: 'Al-Fatiha',
    url: 'url1',
    filePath: "/downloads/$testReciterName/Rewayat Hafs A'n Assem/001.mp3",
    progress: 1.0,
    fileSize: 1024,
    downloadedSize: 1024,
    createdAt: DateTime.now(),
  );

  group('GetDownloadsByReciterUseCase', () {
    test('should group downloads by reciter and narrative', () async {
      // Arrange
      when(
        mockRepository.getAllDownloads(),
      ).thenAnswer((_) async => [downloadItem]);
      when(
        mockRepository.validateDownloadedFile(downloadItem),
      ).thenAnswer((_) async => true);
      when(
        mockRecitersRepository.getReciters(),
      ).thenAnswer((_) async => const Right([testReciter]));

      // Act
      final Either<Failure, Map<String, Map<String, List<DownloadItem>>>>
      result = await useCase();

      // Assert
      expect(result, isA<Right>());
      final Map<String, Map<String, List<DownloadItem>>> grouped = result
          .getOrElse(() => {});

      // key should be reciter name (from entity lookup)
      expect(grouped.containsKey(testReciterName), true);

      // inner key should be narrative (extracted from path)
      // Path: .../Rewayat Hafs A'n Assem/...
      expect(
        grouped[testReciterName]!.containsKey("Rewayat Hafs A'n Assem"),
        true,
      );

      // item should be in the list
      expect(
        grouped[testReciterName]!["Rewayat Hafs A'n Assem"]!.first,
        downloadItem,
      );

      verify(mockRepository.getAllDownloads()).called(1);
      verify(mockRepository.validateDownloadedFile(downloadItem)).called(1);
      verify(mockRecitersRepository.getReciters()).called(1);
    });

    test(
      'should omit completed downloads whose file is missing from the list',
      () async {
        when(
          mockRepository.getAllDownloads(),
        ).thenAnswer((_) async => [downloadItem]);
        when(
          mockRepository.validateDownloadedFile(downloadItem),
        ).thenAnswer((_) async => false);
        when(
          mockRecitersRepository.getReciters(),
        ).thenAnswer((_) async => const Right([testReciter]));

        final Either<Failure, Map<String, Map<String, List<DownloadItem>>>>
        result = await useCase();

        expect(result, isA<Right>());
        expect(result.getOrElse(() => {}), isEmpty);
        verify(mockRepository.validateDownloadedFile(downloadItem)).called(1);
      },
    );

    test('should fallback to stored reciter name if ID lookup fails', () async {
      // Arrange
      final DownloadItem itemNoId = downloadItem.copyWith(
        reciterName: 'Stored Name',
        reciterId: 999, // Use ID that won't be in the lookup
      );

      when(
        mockRepository.getAllDownloads(),
      ).thenAnswer((_) async => [itemNoId]);
      when(
        mockRepository.validateDownloadedFile(itemNoId),
      ).thenAnswer((_) async => true);
      when(
        mockRecitersRepository.getReciters(),
      ).thenAnswer((_) async => const Right([testReciter]));

      // Act
      final Either<Failure, Map<String, Map<String, List<DownloadItem>>>>
      result = await useCase();

      // Assert
      expect(result, isA<Right>());
      final Map<String, Map<String, List<DownloadItem>>> grouped = result
          .getOrElse(() => {});
      expect(grouped.containsKey('Stored Name'), true);
    });

    test('should omit non-completed downloads from the list', () async {
      final List<DownloadItem> mixedItems = [
        downloadItem.copyWith(id: 'pending', status: DownloadStatus.pending),
        downloadItem.copyWith(
          id: 'downloading',
          status: DownloadStatus.downloading,
          progress: 0.5,
        ),
        downloadItem.copyWith(id: 'failed', status: DownloadStatus.failed),
        downloadItem.copyWith(
          id: 'cancelled',
          status: DownloadStatus.cancelled,
        ),
        downloadItem.copyWith(id: 'paused', status: DownloadStatus.paused),
      ];

      when(
        mockRepository.getAllDownloads(),
      ).thenAnswer((_) async => mixedItems);
      when(
        mockRecitersRepository.getReciters(),
      ).thenAnswer((_) async => const Right([testReciter]));

      final Either<Failure, Map<String, Map<String, List<DownloadItem>>>>
      result = await useCase();

      expect(result, isA<Right>());
      expect(result.getOrElse(() => {}), isEmpty);
      verifyNever(mockRepository.validateDownloadedFile(any));
    });

    test('should keep only completed downloads with valid files', () async {
      final DownloadItem completedValid = downloadItem.copyWith(id: 'valid');
      final DownloadItem completedMissingFile = downloadItem.copyWith(
        id: 'ghost',
        title: 'Ghost Surah',
      );
      final DownloadItem pendingItem = downloadItem.copyWith(
        id: 'pending',
        status: DownloadStatus.pending,
      );

      when(mockRepository.getAllDownloads()).thenAnswer(
        (_) async => [completedValid, completedMissingFile, pendingItem],
      );
      when(
        mockRepository.validateDownloadedFile(completedValid),
      ).thenAnswer((_) async => true);
      when(
        mockRepository.validateDownloadedFile(completedMissingFile),
      ).thenAnswer((_) async => false);
      when(
        mockRecitersRepository.getReciters(),
      ).thenAnswer((_) async => const Right([testReciter]));

      final Either<Failure, Map<String, Map<String, List<DownloadItem>>>>
      result = await useCase();

      expect(result, isA<Right>());
      final Map<String, Map<String, List<DownloadItem>>> grouped = result
          .getOrElse(() => {});
      final List<DownloadItem> listed = grouped[testReciterName]!.values
          .expand((items) => items)
          .toList();
      expect(listed, [completedValid]);
      verify(mockRepository.validateDownloadedFile(completedValid)).called(1);
      verify(
        mockRepository.validateDownloadedFile(completedMissingFile),
      ).called(1);
      verifyNever(mockRepository.validateDownloadedFile(pendingItem));
    });

    test('should return AudioFailure when repository fails', () async {
      // Arrange
      when(mockRepository.getAllDownloads()).thenThrow(Exception('DB Error'));

      // Act
      final Either<Failure, Map<String, Map<String, List<DownloadItem>>>>
      result = await useCase();

      // Assert
      expect(result, isA<Left>());
      expect(result.fold((l) => l, (r) => null), isA<AudioFailure>());
    });

    test('should return failure when reciters lookup fails', () async {
      when(mockRepository.getAllDownloads()).thenAnswer((_) async => []);
      when(
        mockRecitersRepository.getReciters(),
      ).thenAnswer((_) async => const Left(ServerFailure('API error')));

      final Either<Failure, Map<String, Map<String, List<DownloadItem>>>>
      result = await useCase();

      expect(result, isA<Left>());
      expect(
        result.fold((failure) => failure.message, (_) => null),
        'API error',
      );
      verifyNever(mockRepository.validateDownloadedFile(any));
    });

    test('should group multiple narratives under the same reciter', () async {
      final DownloadItem narrativeOne = downloadItem.copyWith(
        id: '1',
        filePath: '/downloads/$testReciterName/Narrative One/001.mp3',
      );
      final DownloadItem narrativeTwo = downloadItem.copyWith(
        id: '2',
        title: 'Al-Baqarah',
        filePath: '/downloads/$testReciterName/Narrative Two/002.mp3',
      );

      when(
        mockRepository.getAllDownloads(),
      ).thenAnswer((_) async => [narrativeOne, narrativeTwo]);
      when(
        mockRepository.validateDownloadedFile(narrativeOne),
      ).thenAnswer((_) async => true);
      when(
        mockRepository.validateDownloadedFile(narrativeTwo),
      ).thenAnswer((_) async => true);
      when(
        mockRecitersRepository.getReciters(),
      ).thenAnswer((_) async => const Right([testReciter]));

      final Either<Failure, Map<String, Map<String, List<DownloadItem>>>>
      result = await useCase();

      expect(result, isA<Right>());
      final Map<String, Map<String, List<DownloadItem>>> grouped = result
          .getOrElse(() => {});
      expect(
        grouped[testReciterName]!.keys,
        containsAll(['Narrative One', 'Narrative Two']),
      );
      expect(grouped[testReciterName]!['Narrative One'], hasLength(1));
      expect(grouped[testReciterName]!['Narrative Two'], hasLength(1));
    });
  });
}
