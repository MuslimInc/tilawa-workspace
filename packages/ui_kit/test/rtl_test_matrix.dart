import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Runs a test callback in both LTR and RTL directions, registering two
/// separate `testWidgets` cases so failures report the offending direction.
void testInBothDirections(
  String description,
  Future<void> Function(WidgetTester tester, TextDirection direction) body,
) {
  testWidgets('$description (LTR)', (tester) async {
    await body(tester, TextDirection.ltr);
  });
  testWidgets('$description (RTL)', (tester) async {
    await body(tester, TextDirection.rtl);
  });
}

/// Pumps [widget] under a [Directionality] of the given [direction].
Future<void> pumpWithDirection(
  WidgetTester tester,
  Widget widget,
  TextDirection direction,
) {
  return tester.pumpWidget(
    Directionality(textDirection: direction, child: widget),
  );
}
