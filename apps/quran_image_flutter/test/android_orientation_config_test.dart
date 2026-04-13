import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android activity uses sensor orientation without reverse portrait', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();

    expect(manifest, contains('android:screenOrientation="sensor"'));
  });
}
