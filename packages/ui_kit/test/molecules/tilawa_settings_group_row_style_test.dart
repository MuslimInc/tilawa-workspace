import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/src/molecules/tilawa_settings_group_row_style.dart';

void main() {
  group('tilawaSettingsGroupRowBorderRadius', () {
    test('single row uses full radius', () {
      expect(
        tilawaSettingsGroupRowBorderRadius(
          index: 0,
          rowCount: 1,
          radius: 20,
        ),
        BorderRadius.circular(20),
      );
    });

    test('first row uses top radius only', () {
      expect(
        tilawaSettingsGroupRowBorderRadius(
          index: 0,
          rowCount: 3,
          radius: 20,
        ),
        const BorderRadius.vertical(top: Radius.circular(20)),
      );
    });

    test('last row uses bottom radius only', () {
      expect(
        tilawaSettingsGroupRowBorderRadius(
          index: 2,
          rowCount: 3,
          radius: 20,
        ),
        const BorderRadius.vertical(bottom: Radius.circular(20)),
      );
    });

    test('middle row has no radius', () {
      expect(
        tilawaSettingsGroupRowBorderRadius(
          index: 1,
          rowCount: 3,
          radius: 20,
        ),
        BorderRadius.zero,
      );
    });
  });
}
