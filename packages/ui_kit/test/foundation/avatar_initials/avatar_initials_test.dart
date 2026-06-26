import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  group('AvatarInitialsScript', () {
    test('isArabicScriptCharacter recognizes Arabic graphemes', () {
      check(AvatarInitialsScript.isArabicScriptCharacter('م')).isTrue();
      check(AvatarInitialsScript.isArabicScriptCharacter('أ')).isTrue();
      check(AvatarInitialsScript.isArabicScriptCharacter('M')).isFalse();
    });

    test('insertSeparator adds hair space between Arabic pair', () {
      check(
        AvatarInitialsScript.insertSeparator('ما'),
      ).equals('م\u200Aا');
    });

    test('insertSeparator leaves Latin initials unchanged', () {
      check(AvatarInitialsScript.insertSeparator('MK')).equals('MK');
    });

    test('insertSeparator leaves single grapheme unchanged', () {
      check(AvatarInitialsScript.insertSeparator('أ')).equals('أ');
    });

    test('insertSeparator accepts custom separator', () {
      check(
        AvatarInitialsScript.insertSeparator(
          'ما',
          separator: AvatarInitialsSeparators.thinSpace,
        ),
      ).equals('م\u2009ا');
    });
  });

  group('AvatarInitialsFromName', () {
    test('two-word Latin name yields two graphemes', () {
      check(AvatarInitialsFromName.extract('Sheikh Ahmed')).equals('SA');
    });

    test('skips Arabic honorific prefix', () {
      check(
        AvatarInitialsFromName.extract('الشيخ أحمد محمد'),
      ).equals('أم');
    });

    test('Arabic two-word name yields first grapheme of each word', () {
      check(AvatarInitialsFromName.extract('محمد المعلم')).equals('ما');
    });

    test('empty name yields empty string', () {
      check(AvatarInitialsFromName.extract('')).equals('');
    });
  });
}
