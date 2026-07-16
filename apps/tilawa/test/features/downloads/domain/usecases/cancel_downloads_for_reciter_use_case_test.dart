import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/features/downloads/domain/entities/download_item.dart';
import 'package:tilawa/features/downloads/domain/usecases/cancel_downloads_for_reciter_use_case.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';
import 'package:tilawa_core/errors/failures.dart';

import '../../helpers/mock_helper.mocks.dart';

void main() {
  late CancelDownloadsForReciterUseCase useCase;
  late MockDownloadsRepository mockRepository;
  late MockRecitersRepository mockRecitersRepository;
  late MockBatchDownloadManager mockBatchDownloadManager;
  late MockDownloadQueueManager mockQueueManager;

  void provideDummies() {
    provideDummy<Either<Failure, List<ReciterEntity>>>(const Right([]));
  }

  const testReciterName = 'Abdul Rahman Al-Sudais';
  const otherReciterName = 'Other Reciter';
  const testReciterId = 1;
  const otherReciterId = 2;

  const testReciter = ReciterEntity(
    id: testReciterId,
    name: testReciterName,
    letter: 'A',
    date: '2024-01-01',
    moshaf: [],
  );

  DownloadItem makeItem({
    required String id,
    required DownloadStatus status,
    String reciterName = testReciterName,
    int reciterId = testReciterId,
    String? url,
  }) {
    return DownloadItem(
      id: id,
      reciterName: reciterName,
      reciterId: reciterId,
      status: status,
      title: 'Surah $id',
      url: url ?? 'https://example.com/$id.mp3',
      progress: status == DownloadStatus.completed ? 1.0 : 0.5,
      fileSize: 100,
      downloadedSize: status == DownloadStatus.completed ? 100 : 50,
      createdAt: DateTime(2024, 1, 1),
      filePath: '/downloads/$reciterName/$id.mp3',
    );
  }

  setUp(() {
    provideDummies();
    mockRepository = MockDownloadsRepository();
    mockRecitersRepository = MockRecitersRepository();
    mockBatchDownloadManager = MockBatchDownloadManager();
    mockQueueManager = MockDownloadQueueManager();

    when(
      mockBatchDownloadManager.cancelBatchesForReciter(any),
    ).thenAnswer((_) async {
      return;
    });
    when(mockRepository.cancelDownload(any)).thenAnswer((_) async {
      return;
    });
    when(
      mockRecitersRepository.getReciters(),
    ).thenAnswer((_) async => const Right([testReciter]));
    // dequeueForReciter is void — no stub needed; mockito no-ops void methods.

    useCase = CancelDownloadsForReciterUseCase(
      mockRepository,
      mockRecitersRepository,
      mockBatchDownloadManager,
      mockQueueManager,
    );
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Group 1: Call ordering — the queue must be drained BEFORE any async work
  // ─────────────────────────────────────────────────────────────────────────
  group('call ordering', () {
    test(
      'dequeueForReciter is called before cancelBatchesForReciter and getAllDownloads',
      () async {
        when(mockRepository.getAllDownloads()).thenAnswer((_) async => []);

        await useCase(testReciterName);

        verifyInOrder([
          // sync — must be first
          mockQueueManager.dequeueForReciter(testReciterName),
          // first async
          mockBatchDownloadManager.cancelBatchesForReciter(testReciterName),
          // second async
          mockRepository.getAllDownloads(),
        ]);
      },
    );

    test('dequeueForReciter is called exactly once per invocation', () async {
      when(mockRepository.getAllDownloads()).thenAnswer((_) async => []);

      await useCase(testReciterName);

      verify(mockQueueManager.dequeueForReciter(testReciterName)).called(1);
    });

    test(
      'dequeueForReciter is called with the exact reciter name passed in',
      () async {
        when(mockRepository.getAllDownloads()).thenAnswer((_) async => []);

        await useCase(otherReciterName);

        verify(mockQueueManager.dequeueForReciter(otherReciterName)).called(1);
        verifyNever(mockQueueManager.dequeueForReciter(testReciterName));
      },
    );

    test(
      'cancelBatchesForReciter is called even when getAllDownloads throws',
      () async {
        when(mockRepository.getAllDownloads()).thenThrow(Exception('DB error'));

        await useCase(testReciterName);

        // cancelBatchesForReciter runs before getAllDownloads, so it must have been called
        verify(
          mockBatchDownloadManager.cancelBatchesForReciter(testReciterName),
        ).called(1);
      },
    );

    test(
      'dequeueForReciter is called even when cancelBatchesForReciter throws',
      () async {
        when(
          mockBatchDownloadManager.cancelBatchesForReciter(any),
        ).thenThrow(Exception('notification error'));

        await useCase(testReciterName);

        // dequeueForReciter runs before cancelBatchesForReciter — must be called
        verify(mockQueueManager.dequeueForReciter(testReciterName)).called(1);
      },
    );
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Group 2: Status filtering — only active downloads should be cancelled
  // ─────────────────────────────────────────────────────────────────────────
  group('status filtering', () {
    test('cancels downloads with status downloading', () async {
      final item = makeItem(id: '1', status: DownloadStatus.downloading);
      when(mockRepository.getAllDownloads()).thenAnswer((_) async => [item]);

      await useCase(testReciterName);

      verify(mockRepository.cancelDownload('1')).called(1);
    });

    test('cancels downloads with status pending', () async {
      final item = makeItem(id: '1', status: DownloadStatus.pending);
      when(mockRepository.getAllDownloads()).thenAnswer((_) async => [item]);

      await useCase(testReciterName);

      verify(mockRepository.cancelDownload('1')).called(1);
    });

    test('cancels downloads with status paused', () async {
      final item = makeItem(id: '1', status: DownloadStatus.paused);
      when(mockRepository.getAllDownloads()).thenAnswer((_) async => [item]);

      await useCase(testReciterName);

      verify(mockRepository.cancelDownload('1')).called(1);
    });

    test('does NOT cancel downloads with status completed', () async {
      final item = makeItem(id: '1', status: DownloadStatus.completed);
      when(mockRepository.getAllDownloads()).thenAnswer((_) async => [item]);

      await useCase(testReciterName);

      verifyNever(mockRepository.cancelDownload(any));
    });

    test('does NOT cancel downloads with status cancelled', () async {
      final item = makeItem(id: '1', status: DownloadStatus.cancelled);
      when(mockRepository.getAllDownloads()).thenAnswer((_) async => [item]);

      await useCase(testReciterName);

      verifyNever(mockRepository.cancelDownload(any));
    });

    test('does NOT cancel downloads with status failed', () async {
      final item = makeItem(id: '1', status: DownloadStatus.failed);
      when(mockRepository.getAllDownloads()).thenAnswer((_) async => [item]);

      await useCase(testReciterName);

      verifyNever(mockRepository.cancelDownload(any));
    });

    test(
      'cancels only active downloads when list has mixed statuses',
      () async {
        final downloading = makeItem(
          id: '1',
          status: DownloadStatus.downloading,
        );
        final pending = makeItem(id: '2', status: DownloadStatus.pending);
        final paused = makeItem(id: '3', status: DownloadStatus.paused);
        final completed = makeItem(id: '4', status: DownloadStatus.completed);
        final cancelled = makeItem(id: '5', status: DownloadStatus.cancelled);
        final failed = makeItem(id: '6', status: DownloadStatus.failed);

        when(mockRepository.getAllDownloads()).thenAnswer(
          (_) async => [
            downloading,
            pending,
            paused,
            completed,
            cancelled,
            failed,
          ],
        );

        await useCase(testReciterName);

        verify(mockRepository.cancelDownload('1')).called(1);
        verify(mockRepository.cancelDownload('2')).called(1);
        verify(mockRepository.cancelDownload('3')).called(1);
        verifyNever(mockRepository.cancelDownload('4'));
        verifyNever(mockRepository.cancelDownload('5'));
        verifyNever(mockRepository.cancelDownload('6'));
      },
    );
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Group 3: Reciter matching — ID-based primary, name-based fallback
  // ─────────────────────────────────────────────────────────────────────────
  group('reciter matching', () {
    test('matches by reciter ID when reciters repository succeeds', () async {
      // Item has matching ID but different name — should still be cancelled
      final item = DownloadItem(
        id: '1',
        reciterName: 'Name Variant',
        reciterId: testReciterId,
        status: DownloadStatus.downloading,
        title: 'Surah 1',
        url: 'url1',
        progress: 0.5,
        fileSize: 100,
        downloadedSize: 50,
        createdAt: DateTime(2024),
        filePath: '/downloads/1.mp3',
      );
      when(mockRepository.getAllDownloads()).thenAnswer((_) async => [item]);

      await useCase(testReciterName);

      verify(mockRepository.cancelDownload('1')).called(1);
    });

    test(
      'falls back to name matching when reciters repository returns Left',
      () async {
        final item = makeItem(id: '1', status: DownloadStatus.downloading);
        when(mockRepository.getAllDownloads()).thenAnswer((_) async => [item]);
        when(
          mockRecitersRepository.getReciters(),
        ).thenAnswer((_) async => const Left(ServerFailure('Network error')));

        final result = await useCase(testReciterName);

        expect(result, isA<Right>());
        verify(mockRepository.cancelDownload('1')).called(1);
      },
    );

    test(
      'falls back to name matching when reciter not found in repository list',
      () async {
        final item = makeItem(id: '1', status: DownloadStatus.downloading);
        when(mockRepository.getAllDownloads()).thenAnswer((_) async => [item]);
        // Return a list that doesn't contain testReciterName
        when(mockRecitersRepository.getReciters()).thenAnswer(
          (_) async => const Right([
            ReciterEntity(
              id: 99,
              name: 'Someone Else',
              letter: 'S',
              date: '2024-01-01',
              moshaf: [],
            ),
          ]),
        );

        final result = await useCase(testReciterName);

        expect(result, isA<Right>());
        // Falls back to name match — item has testReciterName, so it is cancelled
        verify(mockRepository.cancelDownload('1')).called(1);
      },
    );

    test('does NOT cancel downloads belonging to other reciters', () async {
      final targetItem = makeItem(id: '1', status: DownloadStatus.downloading);
      final otherItem = makeItem(
        id: '2',
        status: DownloadStatus.downloading,
        reciterName: otherReciterName,
        reciterId: otherReciterId,
      );
      when(
        mockRepository.getAllDownloads(),
      ).thenAnswer((_) async => [targetItem, otherItem]);
      when(mockRecitersRepository.getReciters()).thenAnswer(
        (_) async => const Right([
          testReciter,
          ReciterEntity(
            id: otherReciterId,
            name: otherReciterName,
            letter: 'O',
            date: '2024-01-01',
            moshaf: [],
          ),
        ]),
      );

      await useCase(testReciterName);

      verify(mockRepository.cancelDownload('1')).called(1);
      verifyNever(mockRepository.cancelDownload('2'));
    });

    test('cancels multiple active downloads for the same reciter', () async {
      final item1 = makeItem(id: '1', status: DownloadStatus.downloading);
      final item2 = makeItem(id: '2', status: DownloadStatus.pending);
      final item3 = makeItem(id: '3', status: DownloadStatus.paused);
      when(
        mockRepository.getAllDownloads(),
      ).thenAnswer((_) async => [item1, item2, item3]);

      await useCase(testReciterName);

      verify(mockRepository.cancelDownload('1')).called(1);
      verify(mockRepository.cancelDownload('2')).called(1);
      verify(mockRepository.cancelDownload('3')).called(1);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Group 4: Edge cases
  // ─────────────────────────────────────────────────────────────────────────
  group('edge cases', () {
    test('returns Right(null) when download list is empty', () async {
      when(mockRepository.getAllDownloads()).thenAnswer((_) async => []);

      final result = await useCase(testReciterName);

      expect(result, isA<Right>());
      verifyNever(mockRepository.cancelDownload(any));
    });

    test(
      'returns Right(null) when all downloads for reciter are already completed',
      () async {
        final c1 = makeItem(id: '1', status: DownloadStatus.completed);
        final c2 = makeItem(id: '2', status: DownloadStatus.completed);
        when(
          mockRepository.getAllDownloads(),
        ).thenAnswer((_) async => [c1, c2]);

        final result = await useCase(testReciterName);

        expect(result, isA<Right>());
        verifyNever(mockRepository.cancelDownload(any));
      },
    );

    test(
      'still calls dequeueForReciter and cancelBatchesForReciter when there are no active downloads',
      () async {
        final completed = makeItem(id: '1', status: DownloadStatus.completed);
        when(
          mockRepository.getAllDownloads(),
        ).thenAnswer((_) async => [completed]);

        await useCase(testReciterName);

        verify(mockQueueManager.dequeueForReciter(testReciterName)).called(1);
        verify(
          mockBatchDownloadManager.cancelBatchesForReciter(testReciterName),
        ).called(1);
      },
    );

    test(
      'does not cancel items for other reciters even when target has none',
      () async {
        final otherItem = makeItem(
          id: '1',
          status: DownloadStatus.downloading,
          reciterName: otherReciterName,
          reciterId: otherReciterId,
        );
        when(
          mockRepository.getAllDownloads(),
        ).thenAnswer((_) async => [otherItem]);

        final result = await useCase(testReciterName);

        expect(result, isA<Right>());
        verifyNever(mockRepository.cancelDownload(any));
      },
    );
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Group 5: Error handling
  // ─────────────────────────────────────────────────────────────────────────
  group('error handling', () {
    test('returns Left(ServerFailure) when getAllDownloads throws', () async {
      when(
        mockRepository.getAllDownloads(),
      ).thenThrow(Exception('DB connection lost'));

      final result = await useCase(testReciterName);

      expect(result, isA<Left>());
      result.fold((failure) {
        expect(failure, isA<ServerFailure>());
        expect(failure.message, contains('DB connection lost'));
      }, (_) => fail('Expected Left'));
    });

    test('returns Left(ServerFailure) when cancelDownload throws', () async {
      final item = makeItem(id: '1', status: DownloadStatus.downloading);
      when(mockRepository.getAllDownloads()).thenAnswer((_) async => [item]);
      when(
        mockRepository.cancelDownload(any),
      ).thenThrow(Exception('Cancel failed'));

      final result = await useCase(testReciterName);

      expect(result, isA<Left>());
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('Expected Left'),
      );
    });

    test(
      'returns Left(ServerFailure) when cancelBatchesForReciter throws',
      () async {
        when(
          mockBatchDownloadManager.cancelBatchesForReciter(any),
        ).thenThrow(Exception('Notification error'));

        final result = await useCase(testReciterName);

        expect(result, isA<Left>());
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('Expected Left'),
        );
      },
    );

    test(
      'continues gracefully (returns Right) when getReciters returns Left',
      () async {
        final item = makeItem(id: '1', status: DownloadStatus.downloading);
        when(mockRepository.getAllDownloads()).thenAnswer((_) async => [item]);
        when(
          mockRecitersRepository.getReciters(),
        ).thenAnswer((_) async => const Left(ServerFailure('API error')));

        final result = await useCase(testReciterName);

        // A failure from getReciters should not propagate — use case falls
        // back to name-matching and returns Right.
        expect(result, isA<Right>());
      },
    );

    test('cancels downloads attempted before a mid-loop cancelDownload failure '
        'and stops on the throwing item', () async {
      final item1 = makeItem(id: '1', status: DownloadStatus.downloading);
      final item2 = makeItem(id: '2', status: DownloadStatus.downloading);
      when(
        mockRepository.getAllDownloads(),
      ).thenAnswer((_) async => [item1, item2]);
      // First cancel succeeds, second throws
      var callCount = 0;
      when(mockRepository.cancelDownload(any)).thenAnswer((_) async {
        callCount++;
        if (callCount == 2) throw Exception('Partial failure');
        return;
      });

      final result = await useCase(testReciterName);

      // The exception propagates → Left
      expect(result, isA<Left>());
      // First item was cancelled before the throw
      verify(mockRepository.cancelDownload('1')).called(1);
    });
  });
}
