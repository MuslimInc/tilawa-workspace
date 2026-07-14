import 'package:checks/checks.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:test/test.dart';
import 'package:tilawa/features/app_review/domain/usecases/open_app_store_listing_use_case.dart';
import 'package:tilawa/features/forced_update/domain/entities/forced_update_decision.dart';
import 'package:tilawa/features/forced_update/domain/usecases/evaluate_forced_update_use_case.dart';
import 'package:tilawa/features/forced_update/presentation/coordinators/forced_update_coordinator.dart';
import 'package:tilawa/features/forced_update/presentation/services/forced_update_gate_presenter.dart';
import 'package:tilawa_core/errors/failures.dart';

class _FakeEvaluateForcedUpdateUseCase implements EvaluateForcedUpdateUseCase {
  _FakeEvaluateForcedUpdateUseCase(this.decision);

  ForcedUpdateDecision decision;
  int callCount = 0;

  @override
  Future<ForcedUpdateDecision> call() async {
    callCount += 1;
    return decision;
  }
}

class _FakeOpenAppStoreListingUseCase implements OpenAppStoreListingUseCase {
  int callCount = 0;

  @override
  Future<Either<Failure, void>> call() async {
    callCount += 1;
    return const Right(null);
  }
}

class _FakeGatePresenter implements ForcedUpdateGatePresenter {
  bool showing = false;
  int showCount = 0;
  int dismissCount = 0;
  Future<void> Function()? lastOnUpdate;

  @override
  bool get isShowing => showing;

  @override
  void showGate({required Future<void> Function() onUpdate}) {
    showCount += 1;
    showing = true;
    lastOnUpdate = onUpdate;
  }

  @override
  void dismissGate() {
    dismissCount += 1;
    showing = false;
  }
}

void main() {
  late _FakeEvaluateForcedUpdateUseCase evaluate;
  late _FakeOpenAppStoreListingUseCase openStore;
  late _FakeGatePresenter presenter;
  late ForcedUpdateCoordinator coordinator;

  setUp(() {
    evaluate = _FakeEvaluateForcedUpdateUseCase(ForcedUpdateDecision.none);
    openStore = _FakeOpenAppStoreListingUseCase();
    presenter = _FakeGatePresenter();
    coordinator = ForcedUpdateCoordinator(evaluate, openStore, presenter);
  });

  group('ForcedUpdateCoordinator', () {
    test('shows gate when update is required', () async {
      evaluate.decision = ForcedUpdateDecision.required;

      await coordinator.checkForUpdate();

      check(presenter.showCount).equals(1);
      check(presenter.showing).isTrue();
      check(presenter.dismissCount).equals(0);
    });

    test('dismisses gate when update is not required', () async {
      presenter.showing = true;
      evaluate.decision = ForcedUpdateDecision.none;

      await coordinator.checkForUpdate();

      check(presenter.dismissCount).equals(1);
      check(presenter.showCount).equals(0);
    });

    test('opens store when gate confirm runs', () async {
      evaluate.decision = ForcedUpdateDecision.required;

      await coordinator.checkForUpdate();
      await presenter.lastOnUpdate!();

      check(openStore.callCount).equals(1);
    });

    test('deduplicates in-flight checks', () async {
      evaluate.decision = ForcedUpdateDecision.required;

      await Future.wait(<Future<void>>[
        coordinator.checkForUpdate(),
        coordinator.checkForUpdate(),
      ]);

      check(evaluate.callCount).equals(1);
      check(presenter.showCount).equals(1);
    });
  });
}
