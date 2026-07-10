import 'package:checks/checks.dart';
import 'package:test/test.dart';

import 'package:tilawa/core/bootstrap/app_environment.dart';

void main() {
  test('default compile-time environment is development/local', () {
    check(AppEnvironment.current).equals(AppEnvironment.development);
    check(resolvedDistribution).equals('local');
  });
}
