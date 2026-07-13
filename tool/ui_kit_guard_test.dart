import 'dart:io';

import 'package:checks/checks.dart';
import 'package:test/test.dart';

void main() {
  test('self-test handles comments and strings without crashing', () async {
    final result = await Process.run(
      Platform.resolvedExecutable,
      <String>['run', 'tool/ui_kit_guard.dart', '--self-test'],
    );

    check(result.exitCode).equals(0);
    check(result.stdout as String).contains('UI Kit guard self-test passed.');
    check(result.stderr as String).isEmpty();
  });
}
