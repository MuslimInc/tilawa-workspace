import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/app_review/domain/entities/app_review_prompt_moment.dart';
import 'package:tilawa/features/app_review/domain/entities/app_review_signal.dart';
import 'package:tilawa/features/shell/application/shell_tab_coordinator.dart';
import 'package:tilawa/features/shell/domain/shell_tab_effect.dart';
import 'package:tilawa/screens/app_shell_nav_destinations.dart';

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

    test('leaving qibla tab does not record prayer visit signal', () {
      final List<ShellTabEffect> effects = coordinator.onTabChanged(
        previousIndex: 2,
        nextIndex: 3,
      );

      expect(
        effects,
        isNot(
          contains(
            const RecordAppReviewSignalEffect(
              AppReviewSignal.prayerTimesTabVisited,
            ),
          ),
        ),
      );
    });

    test('leaving qibla tab for reciters does not prompt review', () {
      final List<ShellTabEffect> effects = coordinator.onTabChanged(
        previousIndex: 2,
        nextIndex: 1,
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

    test('leaving qibla tab for home does not prompt review', () {
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

    test('athkar tab removal no longer prompts returnedToRecitersTab', () {
      final List<ShellTabEffect> effects = coordinator.onTabChanged(
        previousIndex: 0,
        nextIndex: kAppShellRecitersTabIndex,
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
      expect(
        effects,
        contains(const MaybeTryLeftPrayerRecitersPromptEffect()),
      );
    });

    test('reciters navigation may try post-prayer review', () {
      final List<ShellTabEffect> effects = coordinator.onTabChanged(
        previousIndex: 0,
        nextIndex: kAppShellRecitersTabIndex,
      );

      expect(
        effects,
        contains(const MaybeTryLeftPrayerRecitersPromptEffect()),
      );
    });

    test('leaving home for qibla cancels post-prayer review arm', () {
      final List<ShellTabEffect> effects = coordinator.onTabChanged(
        previousIndex: 0,
        nextIndex: 2,
      );

      expect(
        effects,
        contains(const CancelLeftPrayerRecitersPromptEffect()),
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

    test('opening qibla tab cancels a pending post-prayer review arm', () {
      final List<ShellTabEffect> effects = coordinator.onTabChanged(
        previousIndex: 0,
        nextIndex: 2,
      );

      expect(effects, contains(isA<SyncMainShellTabEffect>()));
      expect(
        effects,
        contains(const CancelLeftPrayerRecitersPromptEffect()),
      );
      expect(effects, hasLength(2));
    });
  });
}
