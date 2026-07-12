import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/create_khatma_plan_use_case.dart';
import '../../domain/usecases/extend_khatma_plan_use_case.dart';
import '../../domain/usecases/get_active_khatma_plan_use_case.dart';
import '../../domain/usecases/get_khatma_today_target_use_case.dart';
import '../../domain/usecases/reset_khatma_plan_use_case.dart';
import '../../domain/usecases/select_khatma_catch_up_use_case.dart';
import 'khatma_plan_event.dart';
import 'khatma_plan_state.dart';

final class KhatmaPlanBloc extends Bloc<KhatmaPlanEvent, KhatmaPlanState> {
  KhatmaPlanBloc(
    this._getActivePlan,
    this._getTodayTarget,
    this._createPlan,
    this._selectCatchUp,
    this._extendPlan,
    this._resetPlan,
    this._onPlanChanged,
  ) : super(const KhatmaPlanInitial()) {
    on<KhatmaPlanStarted>(_onStarted);
    on<KhatmaPlanQuickStartRequested>(_onQuickStartRequested);
    on<KhatmaPlanCatchUpSelected>(_onCatchUpSelected);
    on<KhatmaPlanExtendSelected>(_onExtendSelected);
    on<KhatmaPlanResetRequested>(_onResetRequested);
  }

  final GetActiveKhatmaPlanUseCase _getActivePlan;
  final GetKhatmaTodayTargetUseCase _getTodayTarget;
  final CreateKhatmaPlanUseCase _createPlan;
  final SelectKhatmaCatchUpUseCase _selectCatchUp;
  final ExtendKhatmaPlanUseCase _extendPlan;
  final ResetKhatmaPlanUseCase _resetPlan;
  final Future<void> Function() _onPlanChanged;

  Future<void> _onStarted(
    KhatmaPlanStarted event,
    Emitter<KhatmaPlanState> emit,
  ) async {
    await _load(emit, showLoading: true);
  }

  Future<void> _onQuickStartRequested(
    KhatmaPlanQuickStartRequested event,
    Emitter<KhatmaPlanState> emit,
  ) async {
    emit(const KhatmaPlanLoading());
    final result = await _createPlan(durationDays: event.durationDays);
    await result.fold(
      (failure) async =>
          emit(KhatmaPlanFailure(failure.message ?? 'Khatma unavailable')),
      (_) async {
        await _onPlanChanged();
        await _load(emit, showLoading: false);
      },
    );
  }

  Future<void> _onCatchUpSelected(
    KhatmaPlanCatchUpSelected event,
    Emitter<KhatmaPlanState> emit,
  ) async {
    final result = await _selectCatchUp();
    await result.fold(
      (failure) async =>
          emit(KhatmaPlanFailure(failure.message ?? 'Khatma unavailable')),
      (_) async {
        await _onPlanChanged();
        await _load(emit, showLoading: false);
      },
    );
  }

  Future<void> _onExtendSelected(
    KhatmaPlanExtendSelected event,
    Emitter<KhatmaPlanState> emit,
  ) async {
    final result = await _extendPlan();
    await result.fold(
      (failure) async =>
          emit(KhatmaPlanFailure(failure.message ?? 'Khatma unavailable')),
      (_) async {
        await _onPlanChanged();
        await _load(emit, showLoading: false);
      },
    );
  }

  Future<void> _onResetRequested(
    KhatmaPlanResetRequested event,
    Emitter<KhatmaPlanState> emit,
  ) async {
    final result = await _resetPlan();
    await result.fold(
      (failure) async =>
          emit(KhatmaPlanFailure(failure.message ?? 'Khatma unavailable')),
      (_) async {
        await _onPlanChanged();
        await _load(emit, showLoading: false);
      },
    );
  }

  Future<void> _load(
    Emitter<KhatmaPlanState> emit, {
    required bool showLoading,
  }) async {
    if (showLoading) {
      emit(const KhatmaPlanLoading());
    }
    final planResult = await _getActivePlan();
    await planResult.fold(
      (failure) async =>
          emit(KhatmaPlanFailure(failure.message ?? 'Khatma unavailable')),
      (plan) async {
        final targetResult = await _getTodayTarget();
        targetResult.fold(
          (failure) =>
              emit(KhatmaPlanFailure(failure.message ?? 'Khatma unavailable')),
          (target) => emit(KhatmaPlanLoaded(plan: plan, todayTarget: target)),
        );
      },
    );
  }
}
