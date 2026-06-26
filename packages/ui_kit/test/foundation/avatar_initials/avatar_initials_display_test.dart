import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  group('AvatarInitialsDisplay', () {
    testWidgets('formats Arabic pair with hair or thin space', (tester) async {
      const style = TextStyle(fontSize: 16, fontWeight: FontWeight.w700);

      await tester.pumpWidget(const SizedBox.shrink());

      final formatted = AvatarInitialsDisplay.formatForTextStyle('ما', style);
      expect(formatted, isNot('ما'));
      expect(formatted, anyOf('م\u200Aا', 'م\u2009ا'));
    });

    testWidgets('leaves Latin initials unchanged', (tester) async {
      const style = TextStyle(fontSize: 16, fontWeight: FontWeight.w700);

      await tester.pumpWidget(const SizedBox.shrink());

      check(
        AvatarInitialsDisplay.formatForTextStyle('MK', style),
      ).equals('MK');
    });
  });
}
