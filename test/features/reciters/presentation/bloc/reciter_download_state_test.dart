import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/reciters/presentation/bloc/reciter_download_bloc.dart';

void main() {
  group('ReciterDownloadState', () {
    test('supports value equality', () {
      expect(
        const ReciterDownloadState(),
        equals(const ReciterDownloadState()),
      );
    });

    test('props are correct', () {
      const state = ReciterDownloadState(
        progress: 0.5,
        isDownloadingAll: true,
        downloadedCount: 5,
        totalCount: 10,
        errorMessage: 'error',
      );

      expect(
        state.props,
        equals([
          0.5, // progress
          true, // isDownloadingAll
          false, // isPending
          5, // downloadedCount
          10, // totalCount
          'error', // errorMessage
        ]),
      );
    });

    test('copyWith returns the same object if no arguments are provided', () {
      const state = ReciterDownloadState();
      expect(state.copyWith(), equals(state));
    });

    test(
      'copyWith retains the old values for every parameter if null is provided',
      () {
        const state = ReciterDownloadState(
          progress: 0.5,
          isDownloadingAll: true,
          downloadedCount: 5,
          totalCount: 10,
        );

        expect(state.copyWith(), equals(state));
      },
    );

    test('copyWith replaces non-null parameters', () {
      const state = ReciterDownloadState();
      final ReciterDownloadState copy = state.copyWith(
        progress: 0.8,
        isDownloadingAll: true,
        downloadedCount: 8,
        totalCount: 12,
      );

      expect(
        copy,
        equals(
          const ReciterDownloadState(
            progress: 0.8,
            isDownloadingAll: true,
            downloadedCount: 8,
            totalCount: 12,
          ),
        ),
      );
    });

    group('isAllDownloaded', () {
      test('returns false when totalCount is 0', () {
        const state = ReciterDownloadState();
        expect(state.isAllDownloaded, isFalse);
      });

      test('returns false when downloadedCount != totalCount', () {
        const state = ReciterDownloadState(totalCount: 10, downloadedCount: 5);
        expect(state.isAllDownloaded, isFalse);
      });

      test(
        'returns true when totalCount > 0 and downloadedCount == totalCount',
        () {
          const state = ReciterDownloadState(
            totalCount: 10,
            downloadedCount: 10,
          );
          expect(state.isAllDownloaded, isTrue);
        },
      );
    });
  });
}
