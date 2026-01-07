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

    group('DownloadButtonStateX extension', () {
      group('shouldShowDownloadStarted', () {
        test('returns true when transitioning from readyToDownload', () {
          const previous = DownloadButtonState.readyToDownload();
          const current = DownloadButtonState.downloading(progress: 0.1);

          expect(current.shouldShowDownloadStarted(previous), isTrue);
        });

        test('returns true when transitioning from failed', () {
          const previous = DownloadButtonState.failed();
          const current = DownloadButtonState.downloading(progress: 0.1);

          expect(current.shouldShowDownloadStarted(previous), isTrue);
        });

        test('returns true when transitioning from cancelled', () {
          const previous = DownloadButtonState.cancelled();
          const current = DownloadButtonState.downloading(progress: 0.1);

          expect(current.shouldShowDownloadStarted(previous), isTrue);
        });

        test('returns true when transitioning from networkError', () {
          const previous = DownloadButtonState.networkError();
          const current = DownloadButtonState.downloading(progress: 0.1);

          expect(current.shouldShowDownloadStarted(previous), isTrue);
        });

        test('returns true when transitioning from paused', () {
          const previous = DownloadButtonState.paused();
          const current = DownloadButtonState.downloading(progress: 0.1);

          expect(current.shouldShowDownloadStarted(previous), isTrue);
        });

        test('returns false when transitioning from initial', () {
          const previous = DownloadButtonState.initial();
          const current = DownloadButtonState.downloading(progress: 0.1);

          expect(current.shouldShowDownloadStarted(previous), isFalse);
        });

        test(
          'returns true when transitioning from pending (user clicked download)',
          () {
            const previous = DownloadButtonState.pending();
            const current = DownloadButtonState.downloading(progress: 0.1);

            expect(current.shouldShowDownloadStarted(previous), isTrue);
          },
        );

        test('returns false when already downloading', () {
          const previous = DownloadButtonState.downloading(progress: 0.1);
          const current = DownloadButtonState.downloading(progress: 0.2);

          expect(current.shouldShowDownloadStarted(previous), isFalse);
        });

        test('returns false for non-downloading states', () {
          const previous = DownloadButtonState.readyToDownload();
          const current = DownloadButtonState.completed();

          expect(current.shouldShowDownloadStarted(previous), isFalse);
        });
      });

      group('shouldShowNetworkError', () {
        test('returns true when state is networkError', () {
          const state = DownloadButtonState.networkError();
          const previous = DownloadButtonState.readyToDownload();

          expect(state.shouldShowNetworkError(previous), isTrue);
        });

        test('returns false for other states', () {
          const states = [
            DownloadButtonState.initial(),
            DownloadButtonState.readyToDownload(),
            DownloadButtonState.pending(),
            DownloadButtonState.downloading(progress: 0.5),
            DownloadButtonState.completed(),
            DownloadButtonState.failed(),
            DownloadButtonState.cancelled(),
            DownloadButtonState.paused(),
          ];
          const previous = DownloadButtonState.initial();

          for (final state in states) {
            expect(state.shouldShowNetworkError(previous), isFalse);
          }
        });
      });

      group('shouldShowToast', () {
        test('returns true when shouldShowDownloadStarted is true', () {
          const previous = DownloadButtonState.readyToDownload();
          const current = DownloadButtonState.downloading(progress: 0.1);

          expect(current.shouldShowToast(previous), isTrue);
        });

        test('returns true when shouldShowNetworkError is true', () {
          const previous = DownloadButtonState.readyToDownload();
          const current = DownloadButtonState.networkError();

          expect(current.shouldShowToast(previous), isTrue);
        });

        test('returns false when neither condition is true', () {
          const previous = DownloadButtonState.initial();
          const current = DownloadButtonState.downloading(progress: 0.1);

          expect(current.shouldShowToast(previous), isFalse);
        });
      });

      group('hasSignificantProgressChange', () {
        test('returns true when progress changes by more than 2%', () {
          const previous = DownloadButtonState.downloading(progress: 0.1);
          const current = DownloadButtonState.downloading(progress: 0.13);

          expect(current.hasSignificantProgressChange(previous), isTrue);
        });

        test('returns false when progress changes by less than 2%', () {
          const previous = DownloadButtonState.downloading(progress: 0.1);
          const current = DownloadButtonState.downloading(progress: 0.11);

          expect(current.hasSignificantProgressChange(previous), isFalse);
        });

        test(
          'returns true when transitioning to downloading from other state',
          () {
            const previous = DownloadButtonState.pending();
            const current = DownloadButtonState.downloading(progress: 0.1);

            expect(current.hasSignificantProgressChange(previous), isTrue);
          },
        );

        test('returns true for non-downloading states', () {
          const previous = DownloadButtonState.downloading(progress: 0.5);
          const current = DownloadButtonState.completed();

          expect(current.hasSignificantProgressChange(previous), isTrue);
        });

        test('returns true when progress changes by exactly 2%', () {
          const previous = DownloadButtonState.downloading(progress: 0.1);
          const current = DownloadButtonState.downloading(progress: 0.12);

          expect(current.hasSignificantProgressChange(previous), isFalse);
        });

        test('returns true when progress decreases significantly', () {
          const previous = DownloadButtonState.downloading(progress: 0.5);
          const current = DownloadButtonState.downloading(progress: 0.47);

          expect(current.hasSignificantProgressChange(previous), isTrue);
        });
      });
    });
  });
}
