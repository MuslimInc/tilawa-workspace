import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/screens/main_screen.dart';

void main() {
  group('shouldHandleBottomNavTap', () {
    test('returns false when tapping the active tab', () {
      expect(
        shouldHandleBottomNavTap(currentIndex: 3, tappedIndex: 3),
        isFalse,
      );
    });

    test('returns true when tapping a different tab', () {
      expect(shouldHandleBottomNavTap(currentIndex: 2, tappedIndex: 3), isTrue);
    });
  });
}
