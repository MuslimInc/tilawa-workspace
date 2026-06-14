import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/in_app_update/domain/entities/in_app_update_action.dart';
import 'package:tilawa/features/in_app_update/domain/entities/in_app_update_availability.dart';
import 'package:tilawa/features/in_app_update/domain/entities/in_app_update_policy.dart';
import 'package:tilawa/features/in_app_update/domain/services/in_app_update_strategy_resolver.dart';
import 'package:tilawa/features/in_app_update/domain/usecases/complete_flexible_in_app_update_use_case.dart';
import 'package:tilawa/features/in_app_update/domain/usecases/evaluate_in_app_update_use_case.dart';
import 'package:tilawa/features/in_app_update/domain/usecases/execute_in_app_update_action_use_case.dart';
import 'package:tilawa/features/in_app_update/domain/usecases/open_play_store_for_update_use_case.dart';
import 'package:tilawa_core/errors/failures.dart';

import '../../helpers/fake_in_app_update_repository.dart';

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

    test(
      'returns required store prompt when forced with no in-app modes',
      () async {
        repository.policy = const InAppUpdatePolicy(forceUpdate: true);
        repository.availability = const Right(
          InAppUpdateAvailability(
            updateAvailable: true,
            immediateUpdateAllowed: false,
            flexibleUpdateAllowed: false,
          ),
        );

        final Either<Failure, InAppUpdateAction> result =
            await evaluateUseCase();

        expect(
          result,
          const Right<Failure, InAppUpdateAction>(
            InAppUpdateAction.offerRequiredStoreUpdate,
          ),
        );
      },
    );

    test('propagates availability failures', () async {
      repository.availability = const Left(
        InAppUpdateFailure.checkFailed('network'),
      );

      final Either<Failure, InAppUpdateAction> result = await evaluateUseCase();

      expect(
        result,
        const Left<Failure, InAppUpdateAction>(
          InAppUpdateFailure.checkFailed('network'),
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

    test('propagates immediate update failures', () async {
      repository.performImmediateUpdateResult = const Left(
        InAppUpdateFailure.updateFailed(),
      );

      final Either<Failure, InAppUpdateAction> result = await executeUseCase(
        InAppUpdateAction.performImmediate,
      );

      expect(result.isLeft, isTrue);
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

    test('returns none when flexible update does not start', () async {
      repository.startFlexibleUpdateResult = const Right(false);

      final Either<Failure, InAppUpdateAction> result = await executeUseCase(
        InAppUpdateAction.startFlexible,
      );

      expect(
        result,
        const Right<Failure, InAppUpdateAction>(InAppUpdateAction.none),
      );
    });

    test('passes through prompt actions unchanged', () async {
      final Either<Failure, InAppUpdateAction> optionalResult =
          await executeUseCase(
            InAppUpdateAction.offerOptionalImmediate,
          );
      final Either<Failure, InAppUpdateAction> requiredResult =
          await executeUseCase(
            InAppUpdateAction.offerRequiredStoreUpdate,
          );

      expect(
        optionalResult,
        const Right<Failure, InAppUpdateAction>(
          InAppUpdateAction.offerOptionalImmediate,
        ),
      );
      expect(
        requiredResult,
        const Right<Failure, InAppUpdateAction>(
          InAppUpdateAction.offerRequiredStoreUpdate,
        ),
      );
    });

    test('returns none for none action', () async {
      final Either<Failure, InAppUpdateAction> result = await executeUseCase(
        InAppUpdateAction.none,
      );

      expect(
        result,
        const Right<Failure, InAppUpdateAction>(InAppUpdateAction.none),
      );
    });

    test('passes through flexible restart action', () async {
      final Either<Failure, InAppUpdateAction> result = await executeUseCase(
        InAppUpdateAction.promptFlexibleRestart,
      );

      expect(
        result,
        const Right<Failure, InAppUpdateAction>(
          InAppUpdateAction.promptFlexibleRestart,
        ),
      );
    });
  });

  group('OpenPlayStoreForUpdateUseCase', () {
    test('delegates to repository', () async {
      final OpenPlayStoreForUpdateUseCase useCase =
          OpenPlayStoreForUpdateUseCase(repository);

      final Either<Failure, void> result = await useCase();

      expect(result, const Right<Failure, void>(null));
      expect(repository.openAppStoreListingCalls, 1);
    });
  });

  group('CompleteFlexibleInAppUpdateUseCase', () {
    test('delegates to repository', () async {
      final CompleteFlexibleInAppUpdateUseCase useCase =
          CompleteFlexibleInAppUpdateUseCase(repository);

      final Either<Failure, void> result = await useCase();

      expect(result, const Right<Failure, void>(null));
      expect(repository.completeFlexibleUpdateCalls, 1);
    });
  });
}
