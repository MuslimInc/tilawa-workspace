import 'package:checks/checks.dart';
import 'package:test/test.dart';
import 'package:tilawa/features/forced_update/domain/entities/forced_update_decision.dart';
import 'package:tilawa/features/forced_update/domain/entities/forced_update_host_platform.dart';
import 'package:tilawa/features/forced_update/domain/entities/forced_update_policy.dart';
import 'package:tilawa/features/forced_update/domain/services/forced_update_evaluator.dart';

void main() {
  const ForcedUpdateEvaluator evaluator = ForcedUpdateEvaluator();

  group('ForcedUpdateEvaluator', () {
    test('returns none when platform min is missing', () {
      check(
        evaluator.evaluate(
          policy: const ForcedUpdatePolicy(iosMinBuildNumber: 80),
          installedBuildNumber: '70',
          platform: ForcedUpdateHostPlatform.android,
        ),
      ).equals(ForcedUpdateDecision.none);
    });

    test('returns none on non-mobile platforms', () {
      check(
        evaluator.evaluate(
          policy: const ForcedUpdatePolicy(
            androidMinBuildNumber: 80,
            iosMinBuildNumber: 80,
          ),
          installedBuildNumber: '70',
          platform: ForcedUpdateHostPlatform.other,
        ),
      ).equals(ForcedUpdateDecision.none);
    });

    test('returns none when install build is unparseable', () {
      check(
        evaluator.evaluate(
          policy: const ForcedUpdatePolicy(androidMinBuildNumber: 80),
          installedBuildNumber: 'not-a-number',
          platform: ForcedUpdateHostPlatform.android,
        ),
      ).equals(ForcedUpdateDecision.none);
    });

    test('returns none when install is equal to min', () {
      check(
        evaluator.evaluate(
          policy: const ForcedUpdatePolicy(androidMinBuildNumber: 78),
          installedBuildNumber: '78',
          platform: ForcedUpdateHostPlatform.android,
        ),
      ).equals(ForcedUpdateDecision.none);
    });

    test('returns none when install is above min', () {
      check(
        evaluator.evaluate(
          policy: const ForcedUpdatePolicy(iosMinBuildNumber: 78),
          installedBuildNumber: '79',
          platform: ForcedUpdateHostPlatform.ios,
        ),
      ).equals(ForcedUpdateDecision.none);
    });

    test('returns required when install is below android min', () {
      check(
        evaluator.evaluate(
          policy: const ForcedUpdatePolicy(androidMinBuildNumber: 80),
          installedBuildNumber: '79',
          platform: ForcedUpdateHostPlatform.android,
        ),
      ).equals(ForcedUpdateDecision.required);
    });

    test('returns required when install is below ios min', () {
      check(
        evaluator.evaluate(
          policy: const ForcedUpdatePolicy(iosMinBuildNumber: 90),
          installedBuildNumber: ' 88 ',
          platform: ForcedUpdateHostPlatform.ios,
        ),
      ).equals(ForcedUpdateDecision.required);
    });
  });
}
