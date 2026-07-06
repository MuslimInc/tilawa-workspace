import 'dart:io';

import 'package:checks/checks.dart';
import 'package:test/test.dart';

void main() {
  const productFlags = <String>[
    'TILAWA_LAUNCH_QURAN_SESSIONS_ENABLED',
    'TILAWA_LAUNCH_QURAN_SESSIONS_BOOKING_ENABLED',
    'TILAWA_LAUNCH_LEARN_QURAN_STUDENT_FEATURE_ENABLED',
    'TILAWA_LAUNCH_QURAN_SESSIONS_PAID_BOOKING_SANDBOX_ENABLED',
    'TILAWA_LAUNCH_ENABLED_CALL_PROVIDERS',
  ];

  test('.vscode launch config does not force Quran Sessions product flags', () {
    final text = File('../../.vscode/launch.json').readAsStringSync();

    for (final flag in productFlags) {
      check(text.contains(flag), because: flag).isFalse();
    }
  });

  test('staging env files do not force Quran Sessions product flags', () {
    const paths = <String>[
      'env/staging.json',
      'env/staging.video.local.json',
      'env/staging.video.local.json.example',
    ];

    for (final path in paths) {
      final text = File(path).readAsStringSync();
      for (final flag in productFlags) {
        check(text.contains(flag), because: '$path $flag').isFalse();
      }
    }
  });
}
