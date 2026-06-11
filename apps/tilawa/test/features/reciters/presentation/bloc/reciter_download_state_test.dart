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

    group('shouldShowError', () {
      test('returns true when error message changes from null to value', () {
        const previous = ReciterDownloadState();
        const current = ReciterDownloadState(errorMessage: 'Network error');

        expect(current.shouldShowError(previous), isTrue);
      });

      test('returns false when error message is null', () {
        const previous = ReciterDownloadState();
        const current = ReciterDownloadState();

        expect(current.shouldShowError(previous), isFalse);
      });

      test('returns false when error message remains the same', () {
        const previous = ReciterDownloadState(errorMessage: 'Error');
        const current = ReciterDownloadState(errorMessage: 'Error');

        expect(current.shouldShowError(previous), isFalse);
      });

      test('returns true when error message changes to different value', () {
        const previous = ReciterDownloadState(errorMessage: 'Error 1');
        const current = ReciterDownloadState(errorMessage: 'Error 2');

        expect(current.shouldShowError(previous), isTrue);
      });
    });

    group('shouldShowDownloadStarted', () {
      test('returns true when transitioning from pending to downloading', () {
        const previous = ReciterDownloadState(isPending: true);
        const current = ReciterDownloadState(isDownloadingAll: true);

        expect(current.shouldShowDownloadStarted(previous), isTrue);
      });

      test('returns false when discovering ongoing download on navigation', () {
        const previous = ReciterDownloadState();
        const current = ReciterDownloadState(isDownloadingAll: true);

        expect(current.shouldShowDownloadStarted(previous), isFalse);
      });

      test('returns false when already downloading', () {
        const previous = ReciterDownloadState(isDownloadingAll: true);
        const current = ReciterDownloadState(isDownloadingAll: true);

        expect(current.shouldShowDownloadStarted(previous), isFalse);
      });

      test('returns false when pending but not downloading', () {
        const previous = ReciterDownloadState(isPending: true);
        const current = ReciterDownloadState(isPending: true);

        expect(current.shouldShowDownloadStarted(previous), isFalse);
      });
    });

    group('isInsufficientStorage', () {
      test('returns true for storage error token', () {
        const state = ReciterDownloadState(
          errorMessage: kInsufficientStorageError,
        );

        expect(state.isInsufficientStorage, isTrue);
      });

      test('returns false for other errors', () {
        const state = ReciterDownloadState(errorMessage: 'No internet');

        expect(state.isInsufficientStorage, isFalse);
      });
    });

    group('isNetworkError', () {
      test('returns true when error contains "No internet"', () {
        const state = ReciterDownloadState(
          errorMessage: 'No internet connection',
        );

        expect(state.isNetworkError, isTrue);
      });

      test('returns true when error contains "internet"', () {
        const state = ReciterDownloadState(errorMessage: 'Check your internet');

        expect(state.isNetworkError, isTrue);
      });

      test('returns false when error message is null', () {
        const state = ReciterDownloadState();

        expect(state.isNetworkError, isFalse);
      });

      test('returns false when error does not contain internet keywords', () {
        const state = ReciterDownloadState(errorMessage: 'Server error');

        expect(state.isNetworkError, isFalse);
      });
    });
  });
}
