import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa/features/downloads/domain/entities/download_item.dart';
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
      verify(mockRecitersRepository.getReciters()).called(1);
    });

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
  });
}
