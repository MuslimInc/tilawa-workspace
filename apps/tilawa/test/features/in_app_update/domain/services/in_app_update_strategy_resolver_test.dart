import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/in_app_update/domain/entities/in_app_update_action.dart';
import 'package:tilawa/features/in_app_update/domain/entities/in_app_update_availability.dart';
import 'package:tilawa/features/in_app_update/domain/entities/in_app_update_policy.dart';
import 'package:tilawa/features/in_app_update/domain/services/in_app_update_strategy_resolver.dart';

void main() {
  late InAppUpdateStrategyResolver resolver;

  setUp(() {
    resolver = InAppUpdateStrategyResolver();
  });

  group('InAppUpdateStrategyResolver', () {
    test('returns none when no update is available', () {
      expect(
        resolver.resolve(
          policy: const InAppUpdatePolicy(forceUpdate: true),
          availability: const InAppUpdateAvailability(
            updateAvailable: false,
            immediateUpdateAllowed: true,
            flexibleUpdateAllowed: true,
          ),
        ),
        InAppUpdateAction.none,
      );
    });

    test('uses immediate update when force_update is true', () {
      expect(
        resolver.resolve(
          policy: const InAppUpdatePolicy(forceUpdate: true),
          availability: const InAppUpdateAvailability(
            updateAvailable: true,
            immediateUpdateAllowed: true,
            flexibleUpdateAllowed: true,
          ),
        ),
        InAppUpdateAction.performImmediate,
      );
    });

    test('prefers flexible update when force_update is false', () {
      expect(
        resolver.resolve(
          policy: const InAppUpdatePolicy(),
          availability: const InAppUpdateAvailability(
            updateAvailable: true,
            immediateUpdateAllowed: true,
            flexibleUpdateAllowed: true,
          ),
        ),
        InAppUpdateAction.startFlexible,
      );
    });

    test('prompts for optional immediate update when only immediate allowed',
        () {
      expect(
        resolver.resolve(
          policy: const InAppUpdatePolicy(),
          availability: const InAppUpdateAvailability(
            updateAvailable: true,
            immediateUpdateAllowed: true,
            flexibleUpdateAllowed: false,
          ),
        ),
        InAppUpdateAction.offerOptionalImmediate,
      );
    });

    test('falls back to flexible when forced but immediate is unavailable', () {
      expect(
        resolver.resolve(
          policy: const InAppUpdatePolicy(forceUpdate: true),
          availability: const InAppUpdateAvailability(
            updateAvailable: true,
            immediateUpdateAllowed: false,
            flexibleUpdateAllowed: true,
          ),
        ),
        InAppUpdateAction.startFlexible,
      );
    });
  });
}
