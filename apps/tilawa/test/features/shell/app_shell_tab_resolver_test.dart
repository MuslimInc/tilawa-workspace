import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/screens/app_shell_nav_destinations.dart';
import 'package:tilawa/shared/widgets/quran_player_chrome.dart';

void main() {
  group('AppShellRoutePolicy.tabIndexForLocation', () {
    test('maps teacher dashboard routes to profile tab', () {
      expect(
        AppShellRoutePolicy.tabIndexForLocation('/sessions/dashboard'),
        kAppShellSettingsTabIndex,
      );
      expect(
        AppShellRoutePolicy.tabIndexForLocation('/sessions/teacher/status'),
        kAppShellSettingsTabIndex,
      );
      expect(
        AppShellRoutePolicy.tabIndexForLocation('/teacher/dashboard'),
        kAppShellSettingsTabIndex,
      );
    });

    test('maps settings and account routes to profile tab', () {
      expect(
        AppShellRoutePolicy.tabIndexForLocation('/settings'),
        kAppShellSettingsTabIndex,
      );
      expect(
        AppShellRoutePolicy.tabIndexForLocation('/profile'),
        kAppShellSettingsTabIndex,
      );
      expect(
        AppShellRoutePolicy.tabIndexForLocation('/account/details'),
        kAppShellSettingsTabIndex,
      );
    });

    test('navIndexForLocation delegates to tabIndexForLocation', () {
      expect(
        AppShellRoutePolicy.navIndexForLocation('/sessions/dashboard'),
        AppShellRoutePolicy.tabIndexForLocation('/sessions/dashboard'),
      );
    });
  });
}
