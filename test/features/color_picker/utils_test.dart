import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/color_picker/utils.dart';

void main() {
  group('Test useWhiteForeground:', () {
    test('It should return true for dark colors', () {
      expect(useWhiteForeground(const Color(0xff000000)), true);
      expect(useWhiteForeground(const Color(0xff550000)), true);
    });

    test('It should return false for light colors', () {
      expect(useWhiteForeground(const Color(0xffffffff)), false);
      expect(useWhiteForeground(const Color(0xffffaaaa)), false);
    });

    test('It should respect bias', () {
      // Gray area check
      const gray = Color(0xff808080);
      // Default behavior
      expect(useWhiteForeground(gray), true);
      // With bias
      expect(useWhiteForeground(gray, bias: 100.0), true);
      expect(useWhiteForeground(gray, bias: -100.0), false);
    });
  });

  group('Test HSV/HSL conversions:', () {
    test('hsvToHsl and hslToHsv should be reversible', () {
      const hsv = HSVColor.fromAHSV(1.0, 180.0, 0.5, 0.5);
      final HSLColor hsl = hsvToHsl(hsv);
      final HSVColor hsvBack = hslToHsv(hsl);

      expect(hsvBack.alpha, closeTo(hsv.alpha, 0.001));
      expect(hsvBack.hue, closeTo(hsv.hue, 0.001));
      expect(hsvBack.saturation, closeTo(hsv.saturation, 0.001));
      expect(hsvBack.value, closeTo(hsv.value, 0.001));
    });

    test('hsvToHsl edge cases', () {
      // Black
      const hsvBlack = HSVColor.fromAHSV(1.0, 0.0, 0.0, 0.0);
      final HSLColor hslBlack = hsvToHsl(hsvBlack);
      expect(hslBlack.lightness, 0.0);

      // White
      const hsvWhite = HSVColor.fromAHSV(1.0, 0.0, 0.0, 1.0);
      final HSLColor hslWhite = hsvToHsl(hsvWhite);
      expect(hslWhite.lightness, 1.0);
    });
  });

  group('Test ColorExtension1 (String extensions):', () {
    test('toColor should resolve hex strings', () {
      expect('#ff0000'.toColor(), const Color(0xffff0000));
      expect('ff0000'.toColor(), const Color(0xffff0000));
    });

    test('toColor should resolve named colors', () {
      expect('red'.toColor(), const Color(0xffff0000));
      expect('blue'.toColor(), const Color(0xff0000ff));
      // Case insensitive and trimming
      expect(' Red '.toColor(), const Color(0xffff0000));
    });

    test('toColor should return null for invalid inputs', () {
      expect('notacolor'.toColor(), null);
    });
  });

  group('Test colorFromHex:', () {
    group('Valid formats test:', () {
      const valid6digits = <String>{'aBc', '#aBc', 'aaBBcc', '#aaBBcc'},
          valid8digits = {'00aaBBcc', '#00aaBBcc'};

      const expectedColor = Color(0xffaabbcc),
          expectedColorTransparent = Color(0x00aabbcc);

      for (final format in valid6digits) {
        test(
          'It should accept text input with a format: $format, with disabled alpha',
          () => expect(colorFromHex(format, enableAlpha: false), expectedColor),
        );
      }

      for (final format in valid6digits) {
        final String upperCaseFormat = format.toUpperCase();
        test(
          'It should accept text input with a format: $upperCaseFormat, with disabled alpha',
          () => expect(
            colorFromHex(upperCaseFormat, enableAlpha: false),
            expectedColor,
          ),
        );
      }

      for (final format in valid6digits) {
        final String lowerCaseFormat = format.toLowerCase();
        test(
          'It should accept text input with a format: $lowerCaseFormat, with disabled alpha',
          () => expect(
            colorFromHex(lowerCaseFormat, enableAlpha: false),
            expectedColor,
          ),
        );
      }

      for (final format in valid6digits) {
        test(
          'It should accept text input with a format: $format',
          () => expect(colorFromHex(format), expectedColor),
        );
      }

      for (final format in valid6digits) {
        final String upperCaseFormat = format.toUpperCase();
        test(
          'It should accept text input with a format: $upperCaseFormat',
          () => expect(colorFromHex(upperCaseFormat), expectedColor),
        );
      }

      for (final format in valid6digits) {
        final String lowerCaseFormat = format.toLowerCase();
        test(
          'It should accept text input with a format: $lowerCaseFormat',
          () => expect(colorFromHex(lowerCaseFormat), expectedColor),
        );
      }

      for (final format in valid8digits) {
        test(
          'It should accept text input with a format: $format, with disabled alpha',
          () => expect(colorFromHex(format, enableAlpha: false), expectedColor),
        );
      }

      for (final format in valid8digits) {
        final String upperCaseFormat = format.toUpperCase();
        test(
          'It should accept text input with a format: $upperCaseFormat, with disabled alpha',
          () => expect(
            colorFromHex(upperCaseFormat, enableAlpha: false),
            expectedColor,
          ),
        );
      }

      for (final format in valid8digits) {
        final String lowerCaseFormat = format.toLowerCase();
        test(
          'It should accept text input with a format: $lowerCaseFormat, with disabled alpha',
          () => expect(
            colorFromHex(lowerCaseFormat, enableAlpha: false),
            expectedColor,
          ),
        );
      }

      for (final format in valid8digits) {
        test(
          'It should accept text input with a format: $format',
          () => expect(colorFromHex(format), expectedColorTransparent),
        );
      }

      for (final format in valid8digits) {
        final String upperCaseFormat = format.toUpperCase();
        test(
          'It should accept text input with a format: $upperCaseFormat',
          () => expect(colorFromHex(upperCaseFormat), expectedColorTransparent),
        );
      }

      for (final format in valid8digits) {
        final String lowerCaseFormat = format.toLowerCase();
        test(
          'It should accept text input with a format: $lowerCaseFormat',
          () => expect(colorFromHex(lowerCaseFormat), expectedColorTransparent),
        );
      }
    });

    group('Invalid formats test:', () {
      const invalidFormats = <String>{
        // x char.
        'aaBBcx',
        '#aaBBcx',
        '00aaBBcx',
        '#00aaBBcx',
        // á char.
        'áaBBcc',
        '#áaBBcc',
        '00áaBBcc',
        '#00áaBBcc',
        // cyrillic а char.
        'аaBBcc',
        '#аaBBcc',
        '00аaBBcc',
        '#00аaBBcc',
      };
      test('It should return null if text length is not 3, 6 or 8', () {
        final buffer = StringBuffer();
        for (var i = 0; i <= 9; i++) {
          buffer.write(i.toString());
          expect(
            colorFromHex(buffer.toString()),
            (i == 7 || i == 5 || i == 2) ? isNot(null) : null,
          );
        }
      });

      test(
        'It should return null if text length is not 3, 6 or 8, with alpha disabled',
        () {
          final buffer = StringBuffer();
          for (var i = 0; i <= 9; i++) {
            buffer.write(i.toString());
            expect(
              colorFromHex(buffer.toString(), enableAlpha: false),
              (i == 7 || i == 5 || i == 2) ? isNot(null) : null,
            );
          }
        },
      );

      for (final format in invalidFormats) {
        final String lowerCaseFormat = format.toLowerCase();
        test(
          'It should return null if format is: $lowerCaseFormat',
          () => expect(colorFromHex(lowerCaseFormat), null),
        );
      }

      for (final format in invalidFormats) {
        final String upperCaseFormat = format.toUpperCase();
        test(
          'It should return null if format is: $upperCaseFormat',
          () => expect(colorFromHex(upperCaseFormat), null),
        );
      }

      for (final format in invalidFormats) {
        test(
          'It should return null if format is: $format',
          () => expect(colorFromHex(format), null),
        );
      }

      for (final format in invalidFormats) {
        final String lowerCaseFormat = format.toLowerCase();
        test(
          'It should return null if format is: $lowerCaseFormat, with alpha disabled',
          () => expect(colorFromHex(lowerCaseFormat, enableAlpha: false), null),
        );
      }

      for (final format in invalidFormats) {
        final String upperCaseFormat = format.toUpperCase();
        test(
          'It should return null if format is: $upperCaseFormat, with alpha disabled',
          () => expect(colorFromHex(upperCaseFormat, enableAlpha: false), null),
        );
      }

      for (final format in invalidFormats) {
        test(
          'It should return null if format is: $format, with alpha disabled',
          () => expect(colorFromHex(format, enableAlpha: false), null),
        );
      }
    });
  });

  group('Test colorToHex:', () {
    final colorsMap = <Color, String>{
      const Color(0xffffffff): 'FFFFFF',
      const Color(0x00000000): '000000',
      const Color(0xF0F0F0F0): 'F0F0F0',
    };

    colorsMap.forEach((color, string) {
      final String transparency = string.substring(4);
      test(
        'It should convert $color: to ${transparency + string}',
        () => expect(colorToHex(color), transparency + string),
      );
    });

    colorsMap.forEach((color, string) {
      final String transparency = string.substring(4);
      test(
        'It should convert $color: to #${transparency + string} with hash',
        () => expect(
          colorToHex(color, includeHashSign: true),
          '#$transparency$string',
        ),
      );
    });

    colorsMap.forEach((color, string) {
      final String transparency = string.substring(4).toLowerCase();
      test(
        'It should convert $color: to #${transparency + string.toLowerCase()}, with hash, to lower case',
        () => expect(
          colorToHex(color, includeHashSign: true, toUpperCase: false),
          '#$transparency${string.toLowerCase()}',
        ),
      );
    });

    colorsMap.forEach((color, string) {
      final String transparency = string.substring(4).toLowerCase();
      test(
        'It should convert $color to ${transparency + string.toLowerCase()}, with lower case',
        () => expect(
          colorToHex(color, toUpperCase: false),
          transparency + string.toLowerCase(),
        ),
      );
    });

    colorsMap.forEach(
      (color, string) => test(
        'It should convert $color: to $string, with alpha disabled',
        () => expect(colorToHex(color, enableAlpha: false), string),
      ),
    );

    colorsMap.forEach(
      (color, string) => test(
        'It should convert $color: to #$string, with alpha disabled and hash',
        () => expect(
          colorToHex(color, enableAlpha: false, includeHashSign: true),
          '#$string',
        ),
      ),
    );

    colorsMap.forEach(
      (color, string) => test(
        'It should convert $color: to #${string.toLowerCase()}, with alpha disabled and hash, to lower case',
        () => expect(
          colorToHex(
            color,
            enableAlpha: false,
            includeHashSign: true,
            toUpperCase: false,
          ),
          '#$string'.toLowerCase(),
        ),
      ),
    );

    colorsMap.forEach(
      (color, string) => test(
        'It should convert $color to ${string.toLowerCase()}, with alpha disabled, to lower case',
        () => expect(
          colorToHex(color, enableAlpha: false, toUpperCase: false),
          string.toLowerCase(),
        ),
      ),
    );
  });

  group('Test ColorExtension2.toHexString:', () {
    final colorsMap = <Color, String>{
      const Color(0xffffffff): 'FFFFFF',
      const Color(0x00000000): '000000',
      const Color(0xF0F0F0F0): 'F0F0F0',
    };

    colorsMap.forEach((color, string) {
      final String transparency = string.substring(4);
      test(
        'It should convert $color: to ${transparency + string}',
        () => expect(color.toHexString(), transparency + string),
      );
    });

    colorsMap.forEach((color, string) {
      final String transparency = string.substring(4);
      test(
        'It should convert $color: to #${transparency + string} with hash',
        () => expect(
          color.toHexString(includeHashSign: true),
          '#$transparency$string',
        ),
      );
    });

    colorsMap.forEach((color, string) {
      final String transparency = string.substring(4).toLowerCase();
      test(
        'It should convert $color: to #${transparency + string.toLowerCase()}, with hash, to lower case',
        () => expect(
          color.toHexString(includeHashSign: true, toUpperCase: false),
          '#$transparency${string.toLowerCase()}',
        ),
      );
    });

    colorsMap.forEach((color, string) {
      final String transparency = string.substring(4).toLowerCase();
      test(
        'It should convert $color to ${transparency + string.toLowerCase()}, with lower case',
        () => expect(
          color.toHexString(toUpperCase: false),
          transparency + string.toLowerCase(),
        ),
      );
    });

    colorsMap.forEach(
      (color, string) => test(
        'It should convert $color: to $string, with alpha disabled',
        () => expect(color.toHexString(enableAlpha: false), string),
      ),
    );

    colorsMap.forEach(
      (color, string) => test(
        'It should convert $color: to #$string, with alpha disabled and hash',
        () => expect(
          color.toHexString(enableAlpha: false, includeHashSign: true),
          '#$string',
        ),
      ),
    );

    colorsMap.forEach(
      (color, string) => test(
        'It should convert $color: to #${string.toLowerCase()}, with alpha disabled and hash, to lower case',
        () => expect(
          color.toHexString(
            enableAlpha: false,
            includeHashSign: true,
            toUpperCase: false,
          ),
          '#$string'.toLowerCase(),
        ),
      ),
    );

    colorsMap.forEach(
      (color, string) => test(
        'It should convert $color to ${string.toLowerCase()}, with alpha disabled, to lower case',
        () => expect(
          color.toHexString(enableAlpha: false, toUpperCase: false),
          string.toLowerCase(),
        ),
      ),
    );
  });
}
