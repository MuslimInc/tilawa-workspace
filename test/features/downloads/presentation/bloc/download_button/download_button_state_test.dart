import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/downloads/presentation/bloc/download_button/download_button_bloc.dart';

void main() {
  group('DownloadButtonState', () {
    test('initial supports value equality', () {
      expect(
        const DownloadButtonState.initial(),
        const DownloadButtonState.initial(),
      );
    });

    test('readyToDownload supports value equality', () {
      expect(
        const DownloadButtonState.readyToDownload(),
        const DownloadButtonState.readyToDownload(),
      );
    });

    test('pending supports value equality', () {
      expect(
        const DownloadButtonState.pending(),
        const DownloadButtonState.pending(),
      );
    });

    group('downloading', () {
      test('supports value equality', () {
        expect(
          const DownloadButtonState.downloading(
            progress: 0.5,
            downloadedBytes: 100,
            totalBytes: 200,
          ),
          const DownloadButtonState.downloading(
            progress: 0.5,
            downloadedBytes: 100,
            totalBytes: 200,
          ),
        );
      });

      test('is not equal when properties differ', () {
        expect(
          const DownloadButtonState.downloading(
            progress: 0.5,
            downloadedBytes: 100,
            totalBytes: 200,
          ),
          isNot(
            equals(
              const DownloadButtonState.downloading(
                progress: 0.6,
                downloadedBytes: 100,
                totalBytes: 200,
              ),
            ),
          ),
        );
      });

      test('props are correct', () {
        const state = DownloadButtonState.downloading(
          progress: 0.5,
          downloadedBytes: 100,
          totalBytes: 200,
        );
        state.map(
          initial: (_) => fail('Should be downloading'),
          readyToDownload: (_) => fail('Should be downloading'),
          pending: (_) => fail('Should be downloading'),
          downloading: (s) {
            expect(s.progress, 0.5);
            expect(s.downloadedBytes, 100);
            expect(s.totalBytes, 200);
          },
          completed: (_) => fail('Should be downloading'),
          failed: (_) => fail('Should be downloading'),
          cancelled: (_) => fail('Should be downloading'),
          networkError: (_) => fail('Should be downloading'),
          paused: (_) => fail('Should be downloading'),
        );
      });
    });

    test('completed supports value equality', () {
      expect(
        const DownloadButtonState.completed(),
        const DownloadButtonState.completed(),
      );
    });

    group('failed', () {
      test('supports value equality', () {
        expect(
          const DownloadButtonState.failed(errorMessage: 'Error'),
          const DownloadButtonState.failed(errorMessage: 'Error'),
        );
      });

      test('is not equal when message differs', () {
        expect(
          const DownloadButtonState.failed(errorMessage: 'Error'),
          isNot(
            equals(const DownloadButtonState.failed(errorMessage: 'Other')),
          ),
        );
      });
    });

    test('cancelled supports value equality', () {
      expect(
        const DownloadButtonState.cancelled(),
        const DownloadButtonState.cancelled(),
      );
    });

    group('networkError', () {
      test('supports value equality', () {
        expect(
          const DownloadButtonState.networkError(errorMessage: 'Error'),
          const DownloadButtonState.networkError(errorMessage: 'Error'),
        );
      });

      test('is not equal when message differs', () {
        expect(
          const DownloadButtonState.networkError(errorMessage: 'Error'),
          isNot(
            equals(
              const DownloadButtonState.networkError(errorMessage: 'Other'),
            ),
          ),
        );
      });
    });

    test('paused supports value equality', () {
      expect(
        const DownloadButtonState.paused(),
        const DownloadButtonState.paused(),
      );
    });
  });
}
