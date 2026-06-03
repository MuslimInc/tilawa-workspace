import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/audio_player/domain/playback_reconciliation_scheduler.dart';

void main() {
  test('single request fires leading only', () async {
    var leadingCount = 0;
    var trailingCount = 0;
    final PlaybackReconciliationScheduler scheduler =
        PlaybackReconciliationScheduler(
          onFire: ({required bool trailing}) {
            if (trailing) {
              trailingCount++;
            } else {
              leadingCount++;
            }
          },
          debounce: const Duration(milliseconds: 50),
        );

    scheduler.request();
    expect(leadingCount, 1);
    expect(trailingCount, 0);

    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(leadingCount, 1);
    expect(trailingCount, 0);

    scheduler.dispose();
  });

  test('burst fires leading then trailing after debounce', () async {
    var leadingCount = 0;
    var trailingCount = 0;
    final PlaybackReconciliationScheduler scheduler =
        PlaybackReconciliationScheduler(
          onFire: ({required bool trailing}) {
            if (trailing) {
              trailingCount++;
            } else {
              leadingCount++;
            }
          },
          debounce: const Duration(milliseconds: 50),
        );

    scheduler.request();
    scheduler.request();
    scheduler.request();
    expect(leadingCount, 1);
    expect(trailingCount, 0);

    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(leadingCount, 1);
    expect(trailingCount, 1);

    scheduler.dispose();
  });

  test('second burst after quiet period fires leading again', () async {
    var fireCount = 0;
    final PlaybackReconciliationScheduler scheduler =
        PlaybackReconciliationScheduler(
          onFire: ({required bool trailing}) => fireCount++,
          debounce: const Duration(milliseconds: 30),
        );

    scheduler.request();
    await Future<void>.delayed(const Duration(milliseconds: 50));

    scheduler.request();
    expect(fireCount, 2);

    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(fireCount, 2);

    scheduler.dispose();
  });

  test('dispose prevents pending trailing fire', () async {
    var fireCount = 0;
    final PlaybackReconciliationScheduler scheduler =
        PlaybackReconciliationScheduler(
          onFire: ({required bool trailing}) => fireCount++,
          debounce: const Duration(milliseconds: 30),
        );

    scheduler.request();
    scheduler.request();
    expect(fireCount, 1);

    scheduler.dispose();
    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(fireCount, 1);
  });

  test('dispose after single request does not add trailing fire', () async {
    var fireCount = 0;
    final PlaybackReconciliationScheduler scheduler =
        PlaybackReconciliationScheduler(
          onFire: ({required bool trailing}) => fireCount++,
          debounce: const Duration(milliseconds: 30),
        );

    scheduler.request();
    expect(fireCount, 1);

    scheduler.dispose();
    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(fireCount, 1);
  });
}
