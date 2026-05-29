import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/usecases/usecase.dart';

import '../../domain/constants/tasbeeh_constants.dart';
import '../../domain/entities/tasbeeh_dhikr.dart';
import '../../domain/policies/tasbeeh_target_reached_policy.dart';
import '../../domain/services/tasbeeh_target_feedback_service.dart';
import '../../domain/usecases/delete_tasbeeh_dhikr_use_case.dart';
import '../../domain/usecases/get_saved_tasbeeh_use_case.dart';
import '../../domain/usecases/increment_tasbeeh_count_use_case.dart';
import '../../domain/usecases/reset_tasbeeh_count_use_case.dart';
import '../../domain/usecases/save_custom_tasbeeh_use_case.dart';
import '../../domain/usecases/set_tasbeeh_target_count_use_case.dart';
import 'tasbeeh_state.dart';

@injectable
class TasbeehCubit extends Cubit<TasbeehState> {
  TasbeehCubit(
    this._getSavedTasbeeh,
    this._saveCustomTasbeeh,
    this._incrementTasbeehCount,
    this._resetTasbeehCount,
    this._setTasbeehTargetCount,
    this._deleteTasbeehDhikr,
    this._feedbackService, {
    TasbeehTargetReachedPolicy? targetReachedPolicy,
  }) : _targetReachedPolicy =
           targetReachedPolicy ?? const TasbeehTargetReachedPolicy(),
       super(const TasbeehState());

  final GetSavedTasbeehUseCase _getSavedTasbeeh;
  final SaveCustomTasbeehUseCase _saveCustomTasbeeh;
  final IncrementTasbeehCountUseCase _incrementTasbeehCount;
  final ResetTasbeehCountUseCase _resetTasbeehCount;
  final SetTasbeehTargetCountUseCase _setTasbeehTargetCount;
  final DeleteTasbeehDhikrUseCase _deleteTasbeehDhikr;
  final TasbeehTargetFeedbackService _feedbackService;
  final TasbeehTargetReachedPolicy _targetReachedPolicy;

  // ── Navigation ───────────────────────────────────────────────────────────

  void showCreateView() {
    emit(
      state.copyWith(
        viewMode: TasbeehViewMode.create,
        draftText: '',
        draftTargetText: '',
        failure: null,
        errorMessage: null,
      ),
    );
  }

  void showHistoryView() {
    emit(
      state.copyWith(
        viewMode: TasbeehViewMode.history,
        failure: null,
        errorMessage: null,
      ),
    );
  }

  void startEphemeralCounting() {
    emit(
      state.copyWith(
        viewMode: TasbeehViewMode.counting,
        activeSavedDhikrId: null,
        savedTargetFeedbackPulse: 0,
        failure: null,
        errorMessage: null,
      ),
    );
  }

  void startSavedDhikrCounting(String dhikrId) {
    final TasbeehDhikr? dhikr = _findDhikr(dhikrId);
    if (dhikr == null) return;

    emit(
      state.copyWith(
        viewMode: TasbeehViewMode.selectedCounting,
        activeSavedDhikrId: dhikrId,
        savedTargetFeedbackPulse: 0,
        draftTargetText: dhikr.targetCount.toString(),
        failure: null,
        errorMessage: null,
      ),
    );
  }

  /// Back from create/history sub-views.
  void startCounting() => startEphemeralCounting();

  void selectDhikrAndStartCounting(String dhikrId) =>
      startSavedDhikrCounting(dhikrId);

  // ── Ephemeral counting ─────────────────────────────────────────────────────

  void incrementEphemeralCount() {
    if (state.viewMode != TasbeehViewMode.counting) return;
    emit(state.copyWith(ephemeralCount: state.ephemeralCount + 1));
  }

  void resetEphemeralCount() {
    if (state.viewMode != TasbeehViewMode.counting) return;
    emit(state.copyWith(ephemeralCount: 0));
  }

  // ── Saved dhikr catalog ────────────────────────────────────────────────────

  Future<void> loadSavedDhikr() async {
    emit(
      state.copyWith(
        status: TasbeehStatus.loading,
        failure: null,
        errorMessage: null,
      ),
    );

    final result = await _getSavedTasbeeh(const NoParams());
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: TasbeehStatus.error,
          failure: failure,
          errorMessage: failure.message,
        ),
      ),
      (items) {
        String? activeId = state.activeSavedDhikrId;
        TasbeehDhikr? active;
        if (activeId != null) {
          active = _findDhikr(activeId, items);
          if (active == null) activeId = null;
        }
        emit(
          state.copyWith(
            status: TasbeehStatus.loaded,
            savedDhikr: items,
            activeSavedDhikrId: activeId,
            draftTargetText:
                active?.targetCount.toString() ??
                TasbeehConstants.defaultTargetCount.toString(),
            failure: null,
            errorMessage: null,
          ),
        );
      },
    );
  }

  void updateDraftText(String value) {
    emit(state.copyWith(draftText: value, failure: null, errorMessage: null));
  }

  void updateDraftTargetText(String value) {
    emit(
      state.copyWith(draftTargetText: value, failure: null, errorMessage: null),
    );
  }

  Future<void> saveDraftDhikr() async {
    final String draft = state.draftText.trim();
    if (draft.isEmpty) return;

    final int? target = _parseRequiredTargetCount(state.draftTargetText);
    if (target == null) {
      emit(
        state.copyWith(
          status: TasbeehStatus.error,
          failure: const ValidationFailure(),
          errorMessage: null,
        ),
      );
      return;
    }

    final result = await _saveCustomTasbeeh(
      SaveCustomTasbeehParams(text: draft, targetCount: target),
    );
    await result.fold(
      (failure) async {
        emit(
          state.copyWith(
            status: TasbeehStatus.error,
            failure: failure,
            errorMessage: failure.message,
          ),
        );
      },
      (saved) async {
        final List<TasbeehDhikr> updated = List<TasbeehDhikr>.from(
          state.savedDhikr,
        );
        final int index = updated.indexWhere((item) => item.id == saved.id);
        if (index >= 0) {
          updated[index] = saved;
        } else {
          updated.add(saved);
        }
        updated.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

        emit(
          state.copyWith(
            status: TasbeehStatus.loaded,
            viewMode: TasbeehViewMode.selectedCounting,
            savedDhikr: updated,
            activeSavedDhikrId: saved.id,
            savedTargetFeedbackPulse: 0,
            draftText: '',
            draftTargetText: saved.targetCount.toString(),
            failure: null,
            errorMessage: null,
          ),
        );
      },
    );
  }

  Future<void> setTargetForActiveSavedDhikr() async {
    final TasbeehDhikr? active = state.activeSavedDhikr;
    if (active == null) return;

    final int? target = _parseRequiredTargetCount(state.draftTargetText);
    if (target == null) {
      emit(
        state.copyWith(
          status: TasbeehStatus.error,
          failure: const ValidationFailure(),
          errorMessage: null,
        ),
      );
      return;
    }

    final result = await _setTasbeehTargetCount(
      SetTasbeehTargetCountParams(dhikrId: active.id, targetCount: target),
    );
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: TasbeehStatus.error,
          failure: failure,
          errorMessage: failure.message,
        ),
      ),
      (updated) => _upsertSavedDhikr(updated),
    );
  }

  // ── Saved dhikr counting ─────────────────────────────────────────────────────

  Future<void> incrementActiveSavedDhikr() async {
    if (state.viewMode != TasbeehViewMode.selectedCounting) return;

    final TasbeehDhikr? active = state.activeSavedDhikr;
    if (active == null) return;
    final String activeId = active.id;

    _upsertSavedDhikr(
      active.copyWith(count: active.count + 1, updatedAt: DateTime.now()),
    );

    final result = await _incrementTasbeehCount(activeId);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: TasbeehStatus.error,
          failure: failure,
          errorMessage: failure.message,
        ),
      ),
      (updated) async {
        if (state.activeSavedDhikrId != activeId) return;

        final bool shouldNotify = _targetReachedPolicy.shouldNotify(updated);
        _upsertSavedDhikr(
          updated,
          feedbackPulse: shouldNotify
              ? state.savedTargetFeedbackPulse + 1
              : state.savedTargetFeedbackPulse,
        );
        if (shouldNotify) {
          await _feedbackService.onTargetReached();
        }
      },
    );
  }

  Future<void> resetActiveSavedDhikr() async {
    if (state.viewMode != TasbeehViewMode.selectedCounting) return;

    final TasbeehDhikr? active = state.activeSavedDhikr;
    if (active == null) return;

    _upsertSavedDhikr(
      active.copyWith(count: 0, updatedAt: DateTime.now()),
    );

    final result = await _resetTasbeehCount(active.id);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: TasbeehStatus.error,
          failure: failure,
          errorMessage: failure.message,
        ),
      ),
      _upsertSavedDhikr,
    );
  }

  Future<void> removeDhikr(String dhikrId) async {
    final result = await _deleteTasbeehDhikr(dhikrId);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: TasbeehStatus.error,
          failure: failure,
          errorMessage: failure.message,
        ),
      ),
      (_) {
        final updated = state.savedDhikr
            .where((item) => item.id != dhikrId)
            .toList();
        final bool removedActive = state.activeSavedDhikrId == dhikrId;
        emit(
          state.copyWith(
            status: TasbeehStatus.loaded,
            savedDhikr: updated,
            activeSavedDhikrId: removedActive ? null : state.activeSavedDhikrId,
            draftTargetText: updated.isEmpty
                ? TasbeehConstants.defaultTargetCount.toString()
                : state.draftTargetText,
            failure: null,
            errorMessage: null,
          ),
        );
      },
    );
  }

  Future<void> removeActiveSavedDhikr() async {
    final String? id = state.activeSavedDhikrId;
    if (id == null) return;
    await removeDhikr(id);
  }

  // ── Legacy aliases (tests / gradual migration) ─────────────────────────────

  void incrementFreeCount() => incrementEphemeralCount();

  void resetFreeCount() => resetEphemeralCount();

  Future<void> incrementSelected() => incrementActiveSavedDhikr();

  Future<void> resetSelected() => resetActiveSavedDhikr();

  Future<void> setTargetForSelected() => setTargetForActiveSavedDhikr();

  Future<void> removeSelected() => removeActiveSavedDhikr();

  void selectDhikr(String dhikrId) {
    final TasbeehDhikr? dhikr = _findDhikr(dhikrId);
    if (dhikr == null) return;
    emit(
      state.copyWith(
        activeSavedDhikrId: dhikrId,
        draftTargetText: dhikr.targetCount.toString(),
        failure: null,
        errorMessage: null,
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  TasbeehDhikr? _findDhikr(String id, [List<TasbeehDhikr>? source]) {
    final list = source ?? state.savedDhikr;
    for (final item in list) {
      if (item.id == id) return item;
    }
    return null;
  }

  void _upsertSavedDhikr(TasbeehDhikr item, {int? feedbackPulse}) {
    final List<TasbeehDhikr> updated = List<TasbeehDhikr>.from(
      state.savedDhikr,
    );
    final index = updated.indexWhere((e) => e.id == item.id);
    if (index >= 0) {
      updated[index] = item;
    } else {
      updated.add(item);
    }
    updated.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    emit(
      state.copyWith(
        status: TasbeehStatus.loaded,
        savedDhikr: updated,
        activeSavedDhikrId: state.activeSavedDhikrId == item.id
            ? item.id
            : state.activeSavedDhikrId,
        savedTargetFeedbackPulse:
            feedbackPulse ?? state.savedTargetFeedbackPulse,
        draftTargetText: state.activeSavedDhikrId == item.id
            ? item.targetCount.toString()
            : state.draftTargetText,
        failure: null,
        errorMessage: null,
      ),
    );
  }

  int? _parseRequiredTargetCount(String rawValue) {
    final value = rawValue.trim();
    if (value.isEmpty) return null;

    final int? parsed = int.tryParse(value);
    if (parsed == null) return null;
    if (parsed < TasbeehConstants.minTargetCount ||
        parsed > TasbeehConstants.maxTargetCount) {
      return null;
    }
    return parsed;
  }
}
