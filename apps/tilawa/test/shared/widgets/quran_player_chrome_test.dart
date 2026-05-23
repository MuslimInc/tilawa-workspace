import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tilawa/shared/widgets/quran_player_chrome.dart';

void main() {
  group('QuranPlayerChromeNotifier system nav override', () {
    test('does not notify listeners synchronously', () {
      TestWidgetsFlutterBinding.ensureInitialized();
      final QuranPlayerChromeNotifier notifier = QuranPlayerChromeNotifier();
      var notifyCount = 0;
      notifier.addListener(() => notifyCount++);

      notifier.setSystemNavigationBarColorOverride(Colors.black);
      expect(notifyCount, 0);
      expect(notifier.systemNavigationBarColorOverride, Colors.black);

      notifier.clearSystemNavigationBarColorOverride();
      expect(notifyCount, 0);
      expect(notifier.systemNavigationBarColorOverride, isNull);
    });

    testWidgets('is safe to call while a Provider descendant is building', (
      tester,
    ) async {
      final QuranPlayerChromeNotifier notifier = QuranPlayerChromeNotifier();

      await tester.pumpWidget(
        ChangeNotifierProvider<QuranPlayerChromeNotifier>.value(
          value: notifier,
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                context.watch<QuranPlayerChromeNotifier>();
                notifier.clearSystemNavigationBarColorOverride();
                notifier.setSystemNavigationBarColorOverride(
                  Colors.black,
                );
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      await tester.pump();
    });
  });
}
