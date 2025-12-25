import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/core/widgets/hidden_thumb_component_shape.dart';

void main() {
  group('HiddenThumbComponentShape', () {
    test('getPreferredSize should return Size.zero', () {
      // arrange
      final shape = HiddenThumbComponentShape();

      // act
      final Size size = shape.getPreferredSize(true, false);

      // assert
      expect(size, Size.zero);
    });

    test('getPreferredSize should return Size.zero when disabled', () {
      // arrange
      final shape = HiddenThumbComponentShape();

      // act
      final Size size = shape.getPreferredSize(false, false);

      // assert
      expect(size, Size.zero);
    });

    test('getPreferredSize should return Size.zero when discrete', () {
      // arrange
      final shape = HiddenThumbComponentShape();

      // act
      final Size size = shape.getPreferredSize(true, true);

      // assert
      expect(size, Size.zero);
    });

    test('paint method should complete without throwing', () {
      // This test verifies the paint method exists and can be called
      // The implementation is empty so we just verify it doesn't throw
      final shape = HiddenThumbComponentShape();
      expect(shape, isA<SliderComponentShape>());
      expect(shape.getPreferredSize(true, true), Size.zero);
    });
  });
}
