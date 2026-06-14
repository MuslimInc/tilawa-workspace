import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/in_app_update/domain/entities/in_app_update_action.dart';
import 'package:tilawa/features/in_app_update/domain/entities/in_app_update_availability.dart';
import 'package:tilawa/features/in_app_update/domain/entities/in_app_update_policy.dart';
import 'package:tilawa/features/in_app_update/domain/repositories/in_app_update_repository.dart';
import 'package:tilawa/features/in_app_update/domain/services/in_app_update_strategy_resolver.dart';
import 'package:tilawa/features/in_app_update/domain/usecases/evaluate_in_app_update_use_case.dart';
import 'package:tilawa/features/in_app_update/domain/usecases/execute_in_app_update_action_use_case.dart';
import 'package:tilawa_core/errors/failures.dart';

void main() {
  late FakeInAppUpdateRepository repository;
  late EvaluateInAppUpdateUseCase evaluateUseCase;
  late ExecuteInAppUpdateActionUseCase executeUseCase;

  setUp(() {
    repository = FakeInAppUpdateRepository();
    evaluateUseCase = EvaluateInAppUpdateUseCase(
      repository,
      InAppUpdateStrategyResolver(),
    );
    executeUseCase = ExecuteInAppUpdateActionUseCase(repository);
  });

  group('EvaluateInAppUpdateUseCase', () {
    test('returns none when platform is unsupported', () async {
      repository.isSupportedResult = false;

      final Either<Failure, InAppUpdateAction> result = await evaluateUseCase();

      expect(
        result,
        const Right<Failure, InAppUpdateAction>(InAppUpdateAction.none),
      );
      expect(repository.checkAvailabilityCalls, 0);
    });

    test('returns optional immediate prompt without side effects', () async {
      repository.availability = const Right(
        InAppUpdateAvailability(
          updateAvailable: true,
          immediateUpdateAllowed: true,
          flexibleUpdateAllowed: false,
        ),
      );

      final Either<Failure, InAppUpdateAction> result = await evaluateUseCase();

      expect(
        result,
        const Right<Failure, InAppUpdateAction>(
          InAppUpdateAction.offerOptionalImmediate,
        ),
      );
      expect(repository.performImmediateUpdateCalls, 0);
    });

    test('returns performImmediate when force_update is enabled', () async {
      repository.policy = const InAppUpdatePolicy(forceUpdate: true);
      repository.availability = const Right(
        InAppUpdateAvailability(
          updateAvailable: true,
          immediateUpdateAllowed: true,
          flexibleUpdateAllowed: true,
        ),
      );

      final Either<Failure, InAppUpdateAction> result = await evaluateUseCase();

      expect(
        result,
        const Right<Failure, InAppUpdateAction>(
          InAppUpdateAction.performImmediate,
        ),
      );
    });
  });

  group('ExecuteInAppUpdateActionUseCase', () {
    test('performs immediate update and returns none', () async {
      final Either<Failure, InAppUpdateAction> result = await executeUseCase(
        InAppUpdateAction.performImmediate,
      );

      expect(
        result,
        const Right<Failure, InAppUpdateAction>(InAppUpdateAction.none),
      );
      expect(repository.performImmediateUpdateCalls, 1);
    });

    test('prompts for flexible restart after successful download', () async {
      repository.startFlexibleUpdateResult = const Right(true);

      final Either<Failure, InAppUpdateAction> result = await executeUseCase(
        InAppUpdateAction.startFlexible,
      );

      expect(
        result,
        const Right<Failure, InAppUpdateAction>(
          InAppUpdateAction.promptFlexibleRestart,
        ),
      );
      expect(repository.startFlexibleUpdateCalls, 1);
    });

    test('passes through prompt actions unchanged', () async {
      final Either<Failure, InAppUpdateAction> result = await executeUseCase(
        InAppUpdateAction.offerOptionalImmediate,
      );

      expect(
        result,
        const Right<Failure, InAppUpdateAction>(
          InAppUpdateAction.offerOptionalImmediate,
        ),
      );
    });
  });
}

class FakeInAppUpdateRepository implements InAppUpdateRepository {
  bool isSupportedResult = true;
  InAppUpdatePolicy policy = const InAppUpdatePolicy();
  Either<Failure, InAppUpdateAvailability> availability = const Right(
    InAppUpdateAvailability.unavailable(),
  );
  Either<Failure, bool> startFlexibleUpdateResult = const Right(false);

  int checkAvailabilityCalls = 0;
  int performImmediateUpdateCalls = 0;
  int openAppStoreListingCalls = 0;
  int startFlexibleUpdateCalls = 0;
  int completeFlexibleUpdateCalls = 0;

  @override
  Future<Either<Failure, InAppUpdateAvailability>> checkAvailability() async {
    checkAvailabilityCalls++;
    return availability;
  }

  @override
  Future<Either<Failure, void>> completeFlexibleUpdate() async {
    completeFlexibleUpdateCalls++;
    return const Right(null);
  }

  @override
  Future<InAppUpdatePolicy> getPolicy() async => policy;

  @override
  Future<bool> isSupported() async => isSupportedResult;

  @override
  Future<Either<Failure, void>> performImmediateUpdate() async {
    performImmediateUpdateCalls++;
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> openAppStoreListing() async {
    openAppStoreListingCalls++;
    return const Right(null);
  }

  @override
  Future<Either<Failure, bool>> startFlexibleUpdate() async {
    startFlexibleUpdateCalls++;
    return startFlexibleUpdateResult;
  }
}
