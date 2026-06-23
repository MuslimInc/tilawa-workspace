import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/reciters/presentation/screens/reciters_screen.dart';

void main() {
  group('RecitersRootBackScope exit policy', () {
    // The app may only be exited from the Reciters tab (index 0). On every
    // other main tab, Back must switch to the Reciters tab instead of exiting,
    // so canExitApp must be false for those tabs.
    //
    // The index-0 "can exit" case depends on the live router location
    // (isMainShell(currentMatchedLocation())) and is covered by widget
    // behavior rather than this pure-logic test.
    test('non-Reciters tabs can never exit the app', () {
      for (final int tabIndex in <int>[1, 2]) {
        expect(
          RecitersRootBackScope.canExitApp(tabIndex),
          isFalse,
          reason: 'tab $tabIndex must not be allowed to exit the app',
        );
      }
    });
  });
}
