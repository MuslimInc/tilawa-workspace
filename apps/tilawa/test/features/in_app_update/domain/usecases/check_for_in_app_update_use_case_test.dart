import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/in_app_update/domain/entities/in_app_update_availability.dart';
import 'package:tilawa/features/in_app_update/domain/entities/in_app_update_policy.dart';
import 'package:tilawa/features/in_app_update/domain/entities/in_app_update_presentation_event.dart';
import 'package:tilawa/features/in_app_update/domain/repositories/in_app_update_repository.dart';
import 'package:tilawa/features/in_app_update/domain/services/in_app_update_strategy_resolver.dart';
import 'package:tilawa/features/in_app_update/domain/usecases/check_for_in_app_update_use_case.dart';

void main() {
  late FakeInAppUpdateRepository repository;
  late CheckForInAppUpdateUseCase useCase;

  setUp(() {
    repository = FakeInAppUpdateRepository();
    useCase = CheckForInAppUpdateUseCase(
      repository,
      InAppUpdateStrategyResolver(),
    );
  });

  group('CheckForInAppUpdateUseCase', () {
    test('returns empty result when platform is unsupported', () async {
      repository.isSupportedResult = false;

      final result = await useCase();

      expect(result.hasPresentationEvent, isFalse);
      expect(repository.checkAvailabilityCalls, 0);
    });

    test('prompts for flexible restart after successful download', () async {
      repository.availability = const InAppUpdateAvailability(
        updateAvailable: true,
        immediateUpdateAllowed: true,
        flexibleUpdateAllowed: true,
      );
      repository.startFlexibleUpdateResult = true;

      final result = await useCase();

      expect(
        result.presentationEvent,
        InAppUpdatePresentationEvent.promptFlexibleRestart,
      );
      expect(repository.startFlexibleUpdateCalls, 1);
    });

    test('returns optional immediate prompt without starting update', () async {
      repository.availability = const InAppUpdateAvailability(
        updateAvailable: true,
        immediateUpdateAllowed: true,
        flexibleUpdateAllowed: false,
      );

      final result = await useCase();

      expect(
        result.presentationEvent,
        InAppUpdatePresentationEvent.promptOptionalImmediate,
      );
      expect(repository.performImmediateUpdateCalls, 0);
    });

    test('performs immediate update when force_update is enabled', () async {
      repository.policy = const InAppUpdatePolicy(forceUpdate: true);
      repository.availability = const InAppUpdateAvailability(
        updateAvailable: true,
        immediateUpdateAllowed: true,
        flexibleUpdateAllowed: true,
      );

      final result = await useCase();

      expect(result.hasPresentationEvent, isFalse);
      expect(repository.performImmediateUpdateCalls, 1);
    });
  });
}

class FakeInAppUpdateRepository implements InAppUpdateRepository {
  bool isSupportedResult = true;
  InAppUpdatePolicy policy = const InAppUpdatePolicy();
  InAppUpdateAvailability availability =
      const InAppUpdateAvailability.unavailable();
  bool startFlexibleUpdateResult = false;

  int checkAvailabilityCalls = 0;
  int performImmediateUpdateCalls = 0;
  int startFlexibleUpdateCalls = 0;
  int completeFlexibleUpdateCalls = 0;

  @override
  Future<InAppUpdateAvailability> checkAvailability() async {
    checkAvailabilityCalls++;
    return availability;
  }

  @override
  Future<void> completeFlexibleUpdate() async {
    completeFlexibleUpdateCalls++;
  }

  @override
  Future<InAppUpdatePolicy> getPolicy() async => policy;

  @override
  Future<bool> isSupported() async => isSupportedResult;

  @override
  Future<void> performImmediateUpdate() async {
    performImmediateUpdateCalls++;
  }

  @override
  Future<bool> startFlexibleUpdate() async {
    startFlexibleUpdateCalls++;
    return startFlexibleUpdateResult;
  }
}
