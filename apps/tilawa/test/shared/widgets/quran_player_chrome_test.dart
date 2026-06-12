import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tilawa/shared/widgets/quran_player_chrome.dart';

void main() {
  group('AppShellRoutePolicy', () {
    test('shows bottom navigation only on main shell', () {
      expect(AppShellRoutePolicy.showsBottomNavigation('/'), isTrue);
      expect(AppShellRoutePolicy.showsBottomNavigation(''), isTrue);
      expect(AppShellRoutePolicy.showsBottomNavigation('/reciters/search'), isFalse);
      expect(AppShellRoutePolicy.showsBottomNavigation('/reciter/1'), isFalse);
      expect(AppShellRoutePolicy.showsBottomNavigation('/settings'), isFalse);
      expect(AppShellRoutePolicy.showsBottomNavigation('/history'), isFalse);
    });

    test('detects shell child routes without bottom navigation', () {
      expect(AppShellRoutePolicy.isInsideAppShell('/reciters/search'), isTrue);
      expect(AppShellRoutePolicy.isInsideAppShell('/settings'), isTrue);
      expect(AppShellRoutePolicy.isInsideAppShell('/athkar'), isFalse);
      expect(AppShellRoutePolicy.isInsideAppShell('/quran-reader/1'), isFalse);
      expect(
        AppShellRoutePolicy.isInsideAppShell('/prayer-alerts-permissions'),
        isFalse,
      );
    });

    test('shows phone bottom navigation only on main shell', () {
      expect(
        AppShellRoutePolicy.isPhoneBottomNavigationVisible('/'),
        isTrue,
      );
      expect(
        AppShellRoutePolicy.isPhoneBottomNavigationVisible(''),
        isTrue,
      );
      expect(
        AppShellRoutePolicy.isPhoneBottomNavigationVisible('/reciters/search'),
        isFalse,
      );
      expect(
        AppShellRoutePolicy.isPhoneBottomNavigationVisible('/reciter/1'),
        isFalse,
      );
      expect(
        AppShellRoutePolicy.isPhoneBottomNavigationVisible('/settings'),
        isFalse,
      );
      expect(
        AppShellRoutePolicy.isPhoneBottomNavigationVisible('/athkar/details'),
        isFalse,
      );
      expect(
        AppShellRoutePolicy.isPhoneBottomNavigationVisible(
          '/prayer-alerts-permissions',
        ),
        isFalse,
      );
    });

    test('prayer-alerts permissions is not the main tab shell', () {
      expect(QuranPlayerRoutePolicy.isMainShell('/'), isTrue);
      expect(
        QuranPlayerRoutePolicy.isMainShell('/prayer-alerts-permissions'),
        isFalse,
      );
    });
  });

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
