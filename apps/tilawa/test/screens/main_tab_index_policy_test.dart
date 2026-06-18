import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/screens/app_shell_nav_destinations.dart';

void main() {
  group('Main tab viewport indices', () {
    test('reciters tab exists off bottom bar', () {
      expect(kAppShellRecitersTabIndex, 1);
      expect(kPhoneShellNavTabIndices, isNot(contains(1)));
    });

    test('settings tab exists off bottom bar', () {
      expect(kAppShellSettingsTabIndex, 4);
      expect(kPhoneShellNavTabIndices, isNot(contains(4)));
    });

    test('phone nav tab indices align with shell tabs', () {
      expect(kPhoneShellNavTabIndices, {0, 2, 3});
    });
  });
}
