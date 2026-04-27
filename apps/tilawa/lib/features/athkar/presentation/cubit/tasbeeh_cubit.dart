import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/usecases/usecase.dart';

import '../../domain/constants/tasbeeh_constants.dart';
import '../../domain/entities/tasbeeh_dhikr.dart';
import '../../domain/services/tasbeeh_target_feedback_service.dart';
import '../../domain/usecases/delete_tasbeeh_dhikr_use_case.dart';
import '../../domain/usecases/get_saved_tasbeeh_use_case.dart';
import '../../domain/usecases/increment_tasbeeh_count_use_case.dart';
import '../../domain/usecases/reset_tasbeeh_count_use_case.dart';
import '../../domain/usecases/save_custom_tasbeeh_use_case.dart';
import '../../domain/usecases/set_tasbeeh_target_count_use_case.dart';
import 'tasbeeh_state.dart';

class TasbeehCubit extends Cubit<TasbeehState> {
  TasbeehCubit({
    required GetSavedTasbeehUseCase getSavedTasbeeh,
    required SaveCustomTasbeehUseCase saveCustomTasbeeh,
    required IncrementTasbeehCountUseCase incrementTasbeehCount,
    required ResetTasbeehCountUseCase resetTasbeehCount,
    required SetTasbeehTargetCountUseCase setTasbeehTargetCount,
    required DeleteTasbeehDhikrUseCase deleteTasbeehDhikr,
    required TasbeehTargetFeedbackService feedbackService,
  }) : _getSavedTasbeeh = getSavedTasbeeh,
       _saveCustomTasbeeh = saveCustomTasbeeh,
       _incrementTasbeehCount = incrementTasbeehCount,
       _resetTasbeehCount = resetTasbeehCount,
       _setTasbeehTargetCount = setTasbeehTargetCount,
       _deleteTasbeehDhikr = deleteTasbeehDhikr,
       _feedbackService = feedbackService,
       super(const TasbeehState());

  final GetSavedTasbeehUseCase _getSavedTasbeeh;
  final SaveCustomTasbeehUseCase _saveCustomTasbeeh;
  final IncrementTasbeehCountUseCase _incrementTasbeehCount;
  final ResetTasbeehCountUseCase _resetTasbeehCount;
  final SetTasbeehTargetCountUseCase _setTasbeehTargetCount;
  final DeleteTasbeehDhikrUseCase _deleteTasbeehDhikr;
  final TasbeehTargetFeedbackService _feedbackService;

  void showOptionsView() {
    emit(
      state.copyWith(
        viewMode: TasbeehViewMode.options,
        failure: null,
        errorMessage: null,
      ),
    );
  }

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

  void startCounting() {
    emit(
      state.copyWith(
        viewMode: TasbeehViewMode.counting,
        failure: null,
        errorMessage: null,
      ),
    );
  }

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
        final String? selectedId = items.isEmpty
            ? null
            : state.selectedDhikrId ?? items.first.id;
        TasbeehDhikr? selected;
        if (selectedId != null) {
          for (final item in items) {
            if (item.id == selectedId) {
              selected = item;
              break;
            }
          }
        }
        emit(
          state.copyWith(
            status: TasbeehStatus.loaded,
            savedDhikr: items,
            selectedDhikrId: selectedId,
            draftTargetText:
                selected?.targetCount.toString() ??
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

  void selectDhikr(String dhikrId) {
    TasbeehDhikr? selected;
    for (final item in state.savedDhikr) {
      if (item.id == dhikrId) {
        selected = item;
        break;
      }
    }
    emit(
      state.copyWith(
        selectedDhikrId: dhikrId,
        draftTargetText:
            selected?.targetCount.toString() ?? state.draftTargetText,
        failure: null,
        errorMessage: null,
      ),
    );
  }

  void selectDhikrAndStartCounting(String dhikrId) {
    selectDhikr(dhikrId);
    startCounting();
  }

  Future<void> saveDraftDhikr() async {
    final String draft = state.draftText.trim();
    if (draft.isEmpty) {
      return;
    }

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
            viewMode: TasbeehViewMode.counting,
            savedDhikr: updated,
            selectedDhikrId: saved.id,
            draftText: '',
            draftTargetText: saved.targetCount.toString(),
            failure: null,
            errorMessage: null,
          ),
        );
      },
    );
  }

  Future<void> setTargetForSelected() async {
    final selected = state.selectedDhikr;
    if (selected == null) {
      return;
    }

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
      SetTasbeehTargetCountParams(dhikrId: selected.id, targetCount: target),
    );
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: TasbeehStatus.error,
          failure: failure,
          errorMessage: failure.message,
        ),
      ),
      (updated) => _replaceInState(updated),
    );
  }

  Future<void> incrementSelected() async {
    final selected = state.selectedDhikr;
    if (selected == null) return;
    final selectedId = selected.id;

    final TasbeehDhikr optimistic = selected.copyWith(
      count: selected.count + 1,
      updatedAt: DateTime.now(),
    );
    _replaceInState(optimistic);

    final result = await _incrementTasbeehCount(selected.id);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: TasbeehStatus.error,
          failure: failure,
          errorMessage: failure.message,
        ),
      ),
      (updated) async {
        final bool stillSelected = state.selectedDhikrId == selectedId;
        final bool shouldVibrate =
            stillSelected && updated.count >= updated.targetCount;
        _replaceInState(
          updated,
          selectItem: stillSelected,
          triggerShake: shouldVibrate,
        );
        if (shouldVibrate) {
          await _feedbackService.onTargetReached();
        }
      },
    );
  }

  Future<void> resetSelected() async {
    final selected = state.selectedDhikr;
    if (selected == null) return;

    final TasbeehDhikr optimistic = selected.copyWith(
      count: 0,
      updatedAt: DateTime.now(),
    );
    _replaceInState(optimistic);

    final result = await _resetTasbeehCount(selected.id);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: TasbeehStatus.error,
          failure: failure,
          errorMessage: failure.message,
        ),
      ),
      _replaceInState,
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
        final selectedId = updated.isEmpty ? null : updated.first.id;
        emit(
          state.copyWith(
            status: TasbeehStatus.loaded,
            savedDhikr: updated,
            selectedDhikrId: selectedId,
            draftTargetText: updated.isEmpty
                ? TasbeehConstants.defaultTargetCount.toString()
                : updated.first.targetCount.toString(),
            failure: null,
            errorMessage: null,
          ),
        );
      },
    );
  }

  Future<void> removeSelected() async {
    final selected = state.selectedDhikr;
    if (selected == null) return;
    await removeDhikr(selected.id);
  }

  void _replaceInState(
    TasbeehDhikr item, {
    bool selectItem = true,
    bool triggerShake = false,
  }) {
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

    String? nextSelectedId = state.selectedDhikrId;
    if (selectItem) {
      nextSelectedId = item.id;
    } else if (nextSelectedId != null &&
        !updated.any((element) => element.id == nextSelectedId)) {
      nextSelectedId = updated.isEmpty ? null : updated.first.id;
    }

    TasbeehDhikr? selected;
    if (nextSelectedId != null) {
      for (final entry in updated) {
        if (entry.id == nextSelectedId) {
          selected = entry;
          break;
        }
      }
    }

    emit(
      state.copyWith(
        status: TasbeehStatus.loaded,
        savedDhikr: updated,
        selectedDhikrId: nextSelectedId,
        draftTargetText:
            selected?.targetCount.toString() ??
            TasbeehConstants.defaultTargetCount.toString(),
        vibrationEventCount: triggerShake
            ? state.vibrationEventCount + 1
            : state.vibrationEventCount,
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
