import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  group('TilawaDensity', () {
    test('has correct enum values', () {
      expect(TilawaDensity.values, [
        TilawaDensity.comfortable,
        TilawaDensity.compact,
      ]);
    });

    test('comfortable is first value (default)', () {
      expect(TilawaDensity.values.first, TilawaDensity.comfortable);
    });

    test('compact is second value', () {
      expect(TilawaDensity.values[1], TilawaDensity.compact);
    });

    test('enum values can be compared', () {
      expect(TilawaDensity.comfortable != TilawaDensity.compact, isTrue);
      expect(TilawaDensity.comfortable == TilawaDensity.comfortable, isTrue);
      expect(TilawaDensity.compact == TilawaDensity.compact, isTrue);
    });
  });
}
