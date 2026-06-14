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
import 'package:tilawa/features/in_app_update/presentation/coordinators/in_app_update_coordinator.dart';
import 'package:tilawa_core/errors/failures.dart';

import '../../helpers/fake_in_app_update_prompt_presenter.dart';
import '../../helpers/fake_in_app_update_repository.dart';

void main() {
  late FakeInAppUpdateRepository repository;
  late FakeInAppUpdatePromptPresenter presenter;
  late InAppUpdateCoordinator coordinator;

  setUp(() {
    repository = FakeInAppUpdateRepository();
    presenter = FakeInAppUpdatePromptPresenter();
    coordinator = InAppUpdateCoordinator(
      EvaluateInAppUpdateUseCase(repository, InAppUpdateStrategyResolver()),
      ExecuteInAppUpdateActionUseCase(repository),
      OpenPlayStoreForUpdateUseCase(repository),
      CompleteFlexibleInAppUpdateUseCase(repository),
      presenter,
    );
  });

  group('InAppUpdateCoordinator', () {
    test('shows optional update prompt after evaluate and execute', () async {
      repository.availability = const Right(
        InAppUpdateAvailability(
          updateAvailable: true,
          immediateUpdateAllowed: true,
          flexibleUpdateAllowed: false,
        ),
      );

      await coordinator.checkForUpdate();

      expect(presenter.lastAction, InAppUpdateAction.offerOptionalImmediate);
    });

    test('throttles repeated checks within minCheckInterval', () async {
      repository.availability = const Right(
        InAppUpdateAvailability(
          updateAvailable: true,
          immediateUpdateAllowed: true,
          flexibleUpdateAllowed: false,
        ),
      );

      await coordinator.checkForUpdate();
      await coordinator.checkForUpdate();

      expect(repository.checkAvailabilityCalls, 1);
    });

    test('deduplicates in-flight checks', () async {
      repository.availability = const Right(
        InAppUpdateAvailability(
          updateAvailable: true,
          immediateUpdateAllowed: true,
          flexibleUpdateAllowed: false,
        ),
      );

      await Future.wait([
        coordinator.checkForUpdate(),
        coordinator.checkForUpdate(),
      ]);

      expect(repository.checkAvailabilityCalls, 1);
    });

    test('does not show prompt when evaluate fails', () async {
      repository.availability = const Left(InAppUpdateFailure.checkFailed());

      await coordinator.checkForUpdate();

      expect(presenter.lastAction, isNull);
    });

    test('does not show prompt for performImmediate action', () async {
      repository.policy = const InAppUpdatePolicy(forceUpdate: true);
      repository.availability = const Right(
        InAppUpdateAvailability(
          updateAvailable: true,
          immediateUpdateAllowed: true,
          flexibleUpdateAllowed: true,
        ),
      );

      await coordinator.checkForUpdate();

      expect(presenter.lastAction, isNull);
      expect(repository.performImmediateUpdateCalls, 1);
    });

    test('confirming optional prompt opens Play Store listing', () async {
      repository.availability = const Right(
        InAppUpdateAvailability(
          updateAvailable: true,
          immediateUpdateAllowed: true,
          flexibleUpdateAllowed: false,
        ),
      );

      await coordinator.checkForUpdate();
      await presenter.lastOnConfirm!();

      expect(repository.openAppStoreListingCalls, 1);
    });

    test('confirming flexible restart completes the update', () async {
      repository.availability = const Right(
        InAppUpdateAvailability(
          updateAvailable: true,
          immediateUpdateAllowed: true,
          flexibleUpdateAllowed: true,
          flexibleUpdateDownloaded: true,
        ),
      );

      await coordinator.checkForUpdate();
      await presenter.lastOnConfirm!();

      expect(repository.completeFlexibleUpdateCalls, 1);
    });
    test('logs execute failures without showing a prompt', () async {
      repository.performImmediateUpdateResult = const Left(
        InAppUpdateFailure.updateFailed(),
      );
      repository.policy = const InAppUpdatePolicy(forceUpdate: true);
      repository.availability = const Right(
        InAppUpdateAvailability(
          updateAvailable: true,
          immediateUpdateAllowed: true,
          flexibleUpdateAllowed: true,
        ),
      );

      await coordinator.checkForUpdate();

      expect(presenter.lastAction, isNull);
    });

    test('logs prompt confirmation failures', () async {
      repository.availability = const Right(
        InAppUpdateAvailability(
          updateAvailable: true,
          immediateUpdateAllowed: true,
          flexibleUpdateAllowed: false,
        ),
      );
      repository.openAppStoreListingResult = const Left(
        InAppUpdateFailure.platformError('store'),
      );

      await coordinator.checkForUpdate();
      await presenter.lastOnConfirm!();

      expect(repository.openAppStoreListingCalls, 1);
    });

    test('logs unexpected errors without showing a prompt', () async {
      repository.throwOnCheckAvailability = true;

      await coordinator.checkForUpdate();

      expect(presenter.lastAction, isNull);
    });
  });
}
