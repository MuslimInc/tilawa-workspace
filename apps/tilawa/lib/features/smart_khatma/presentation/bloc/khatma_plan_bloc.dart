import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa_core/core.dart';

import '../../domain/usecases/create_khatma_plan_use_case.dart';
import '../../domain/entities/khatma_plan.dart';
import '../../domain/usecases/extend_khatma_plan_use_case.dart';
import '../../domain/usecases/get_active_khatma_plan_use_case.dart';
import '../../domain/usecases/get_khatma_today_target_use_case.dart';
import '../../domain/usecases/reset_khatma_plan_use_case.dart';
import '../../domain/usecases/update_khatma_progress_use_case.dart';
import 'khatma_plan_event.dart';
import 'khatma_plan_state.dart';

final class KhatmaPlanBloc extends Bloc<KhatmaPlanEvent, KhatmaPlanState> {
  KhatmaPlanBloc(
    this._getActivePlan,
    this._getTodayTarget,
    this._createPlan,
    this._confirmProgress,
    this._extendPlan,
    this._resetPlan,
    this._onPlanChanged,
  ) : super(const KhatmaPlanInitial()) {
    on<KhatmaPlanStarted>(_onStarted);
    on<KhatmaPlanPreviewRequested>(_onPreviewRequested);
    on<KhatmaPlanCreationConfirmed>(_onCreationConfirmed);
    on<KhatmaProgressConfirmed>(_onProgressConfirmed);
    on<KhatmaPlanExtendSelected>(_onExtendSelected);
    on<KhatmaPlanResetRequested>(_onResetRequested);
  }

  final GetActiveKhatmaPlanUseCase _getActivePlan;
  final GetKhatmaTodayTargetUseCase _getTodayTarget;
  final CreateKhatmaPlanUseCase _createPlan;
  final UpdateKhatmaProgressUseCase _confirmProgress;
  final ExtendKhatmaPlanUseCase _extendPlan;
  final ResetKhatmaPlanUseCase _resetPlan;
  final Future<void> Function() _onPlanChanged;

  Future<void> _onStarted(
    KhatmaPlanStarted event,
    Emitter<KhatmaPlanState> emit,
  ) => _load(emit, showLoading: true);

  Future<void> _onPreviewRequested(
    KhatmaPlanPreviewRequested event,
    Emitter<KhatmaPlanState> emit,
  ) async {
    emit(const KhatmaPlanLoading());
    final result = await _createPlan.preview(
      durationDays: event.durationDays,
      startPage: event.startPage,
      targetPage: event.targetPage,
    );
    result.fold(
      (failure) =>
          emit(KhatmaPlanFailure(failure.message ?? 'Khatma unavailable')),
      (plan) => emit(KhatmaPlanCreationReview(plan)),
    );
  }

  Future<void> _onCreationConfirmed(
    KhatmaPlanCreationConfirmed event,
    Emitter<KhatmaPlanState> emit,
  ) async {
    emit(const KhatmaPlanLoading());
    await _completeMutation<KhatmaPlan>(_createPlan.confirm(event.plan), emit);
  }

  Future<void> _onProgressConfirmed(
    KhatmaProgressConfirmed event,
    Emitter<KhatmaPlanState> emit,
  ) async {
    await _completeMutation<KhatmaPlan?>(
      _confirmProgress(confirmedThroughPage: event.page),
      emit,
    );
  }

  Future<void> _onExtendSelected(
    KhatmaPlanExtendSelected event,
    Emitter<KhatmaPlanState> emit,
  ) async => _completeMutation<KhatmaPlan?>(_extendPlan(), emit);

  Future<void> _onResetRequested(
    KhatmaPlanResetRequested event,
    Emitter<KhatmaPlanState> emit,
  ) async => _completeMutation<void>(_resetPlan(), emit);

  Future<void> _completeMutation<T>(
    Future<Either<Failure, T>> operation,
    Emitter<KhatmaPlanState> emit,
  ) async {
    final result = await operation;
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
    if (showLoading) emit(const KhatmaPlanLoading());
    final planResult = await _getActivePlan();
    await planResult.fold(
      (failure) async =>
          emit(KhatmaPlanFailure(failure.message ?? 'Khatma unavailable')),
      (plan) async {
        if (plan == null || plan.isCompleted) {
          emit(KhatmaPlanLoaded(plan: plan, todayTarget: null));
          return;
        }
        final targetResult = await _getTodayTarget();
        targetResult.fold(
          (failure) =>
              emit(KhatmaPlanFailure(failure.message ?? 'Khatma unavailable')),
          (target) =>
              emit(KhatmaPlanLoaded(plan: target?.plan, todayTarget: target)),
        );
      },
    );
  }
}
