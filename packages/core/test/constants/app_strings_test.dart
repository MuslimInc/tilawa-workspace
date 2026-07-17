import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_core/constants/app_strings.dart';

void main() {
  group('AppStrings Google iOS client IDs', () {
    test('exposes non-empty OAuth client identifiers', () {
      expect(AppStrings.googleIosClientId, isNotEmpty);
      expect(
        AppStrings.googleIosReversedClientId,
        startsWith('com.googleusercontent.apps.'),
      );
      expect(
        AppStrings.googleClientId,
        contains('apps.googleusercontent.com'),
      );
    });
  });
}
