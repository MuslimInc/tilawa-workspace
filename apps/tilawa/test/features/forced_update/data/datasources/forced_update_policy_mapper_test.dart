import 'package:checks/checks.dart';
import 'package:test/test.dart';
import 'package:tilawa/features/forced_update/data/datasources/forced_update_policy_mapper.dart';
import 'package:tilawa/features/forced_update/domain/entities/forced_update_policy.dart';

void main() {
  group('mapForcedUpdatePolicy', () {
    test('maps platform min build numbers', () {
      final ForcedUpdatePolicy policy = mapForcedUpdatePolicy(<String, dynamic>{
        'android_min_build_number': 80,
        'ios_min_build_number': 81,
      });

      check(policy.androidMinBuildNumber).equals(80);
      check(policy.iosMinBuildNumber).equals(81);
    });

    test('parses numeric strings as ints', () {
      final ForcedUpdatePolicy policy = mapForcedUpdatePolicy(<String, dynamic>{
        'android_min_build_number': '82',
        'ios_min_build_number': '83',
      });

      check(policy.androidMinBuildNumber).equals(82);
      check(policy.iosMinBuildNumber).equals(83);
    });

    test('ignores invalid field values fail-open', () {
      final ForcedUpdatePolicy policy = mapForcedUpdatePolicy(<String, dynamic>{
        'android_min_build_number': true,
        'ios_min_build_number': <String>['bad'],
      });

      check(policy.androidMinBuildNumber).isNull();
      check(policy.iosMinBuildNumber).isNull();
    });

    test('returns empty policy for empty map', () {
      final ForcedUpdatePolicy policy = mapForcedUpdatePolicy(
        <String, dynamic>{},
      );

      check(policy.androidMinBuildNumber).isNull();
      check(policy.iosMinBuildNumber).isNull();
    });
  });
}
