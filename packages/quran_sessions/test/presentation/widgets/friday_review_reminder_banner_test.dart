import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/src/presentation/widgets/friday_review_reminder_banner.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../helpers/widget_pump.dart';

void main() {
  group('FridayReviewReminderBanner', () {
    testWidgets('renders message with review and dismiss actions', (
      tester,
    ) async {
      await pumpInApp(
        tester,
        FridayReviewReminderBanner(onReview: () {}, onDismiss: () {}),
      );

      expect(find.text('Review'), findsOneWidget);
      expect(find.text('Dismiss'), findsOneWidget);
      expect(find.byType(TilawaCard), findsOneWidget);
    });

    testWidgets('tapping review and dismiss invokes the callbacks', (
      tester,
    ) async {
      var reviews = 0;
      var dismisses = 0;
      await pumpInApp(
        tester,
        FridayReviewReminderBanner(
          onReview: () => reviews++,
          onDismiss: () => dismisses++,
        ),
      );

      await tester.tap(find.text('Review'));
      await tester.pump();
      expect(reviews, 1);

      await tester.tap(find.text('Dismiss'));
      await tester.pump();
      expect(dismisses, 1);
    });
  });
}
