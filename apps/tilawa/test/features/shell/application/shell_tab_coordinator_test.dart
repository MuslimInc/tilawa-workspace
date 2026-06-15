import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/app_review/domain/entities/app_review_prompt_moment.dart';
import 'package:tilawa/features/app_review/domain/entities/app_review_signal.dart';
import 'package:tilawa/features/shell/application/shell_tab_coordinator.dart';
import 'package:tilawa/features/shell/domain/shell_tab_effect.dart';

void main() {
  late ShellTabCoordinator coordinator;

  setUp(() {
    coordinator = ShellTabCoordinator();
  });

  group('onShellActivated', () {
    test('syncs tab and starts review session', () {
      final List<ShellTabEffect> effects = coordinator.onShellActivated(2);

      expect(effects, hasLength(2));
      expect(effects[0], isA<SyncMainShellTabEffect>());
      expect((effects[0] as SyncMainShellTabEffect).tabIndex, 2);
      expect(effects[1], isA<StartAppReviewSessionEffect>());
    });
  });

  group('onTabChanged', () {
    test('always syncs the new tab index', () {
      final List<ShellTabEffect> effects = coordinator.onTabChanged(
        previousIndex: 0,
        nextIndex: 2,
      );

      expect(effects.first, isA<SyncMainShellTabEffect>());
      expect((effects.first as SyncMainShellTabEffect).tabIndex, 2);
    });

    test('leaving prayer tab records signal', () {
      final List<ShellTabEffect> effects = coordinator.onTabChanged(
        previousIndex: 2,
        nextIndex: 3,
      );

      expect(
        effects,
        contains(
          const RecordAppReviewSignalEffect(
            AppReviewSignal.prayerTimesTabVisited,
          ),
        ),
      );
      expect(
        effects,
        isNot(
          contains(
            const TryAppReviewPromptEffect(
              AppReviewPromptMoment.leftPrayerTimesTab,
            ),
          ),
        ),
      );
    });

    test('leaving prayer tab for reciters may prompt review', () {
      final List<ShellTabEffect> effects = coordinator.onTabChanged(
        previousIndex: 2,
        nextIndex: 1,
      );

      expect(
        effects,
        contains(
          const TryAppReviewPromptEffect(
            AppReviewPromptMoment.leftPrayerTimesTab,
          ),
        ),
      );
    });

    test('leaving prayer tab for home does not prompt review', () {
      final List<ShellTabEffect> effects = coordinator.onTabChanged(
        previousIndex: 2,
        nextIndex: 0,
      );

      expect(
        effects,
        isNot(
          contains(
            const TryAppReviewPromptEffect(
              AppReviewPromptMoment.leftPrayerTimesTab,
            ),
          ),
        ),
      );
    });

    test('athkar to reciters may prompt review', () {
      final List<ShellTabEffect> effects = coordinator.onTabChanged(
        previousIndex: 3,
        nextIndex: 1,
      );

      expect(
        effects,
        contains(
          const TryAppReviewPromptEffect(
            AppReviewPromptMoment.returnedToRecitersTab,
          ),
        ),
      );
    });

    test('reciters to home does not prompt returnedToRecitersTab', () {
      final List<ShellTabEffect> effects = coordinator.onTabChanged(
        previousIndex: 1,
        nextIndex: 0,
      );

      expect(
        effects,
        isNot(
          contains(
            const TryAppReviewPromptEffect(
              AppReviewPromptMoment.returnedToRecitersTab,
            ),
          ),
        ),
      );
    });

    test('opening prayer tab does not schedule a deferred prayer load', () {
      final List<ShellTabEffect> effects = coordinator.onTabChanged(
        previousIndex: 0,
        nextIndex: 2,
      );

      expect(effects, contains(isA<SyncMainShellTabEffect>()));
      expect(effects, hasLength(1));
    });
  });
}
