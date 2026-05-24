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

    test('leaving prayer tab stops qibla and records signal', () {
      final List<ShellTabEffect> effects = coordinator.onTabChanged(
        previousIndex: 1,
        nextIndex: 2,
      );

      expect(effects, contains(const StopQiblaStreamEffect()));
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
        previousIndex: 1,
        nextIndex: 0,
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

    test('athkar to reciters may prompt review', () {
      final List<ShellTabEffect> effects = coordinator.onTabChanged(
        previousIndex: 2,
        nextIndex: 0,
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

    test('schedules prayer load only once when opening prayer tab', () {
      final List<ShellTabEffect> first = coordinator.onTabChanged(
        previousIndex: 0,
        nextIndex: 1,
      );
      final List<ShellTabEffect> second = coordinator.onTabChanged(
        previousIndex: 2,
        nextIndex: 1,
      );

      expect(first, contains(isA<SchedulePrayerTimesLoadEffect>()));
      expect(second, isNot(contains(isA<SchedulePrayerTimesLoadEffect>())));
    });
  });
}
