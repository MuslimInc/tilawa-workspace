import 'package:checks/checks.dart';
import 'package:test/test.dart';

import 'package:tilawa/core/bootstrap/app_launch_config.dart';

void main() {
  test('staging distribution enables Quran Sessions beta flags by default', () {
    check(quranSessionsStagingFlagsDefaultEnabled()).isTrue();
  });
}
