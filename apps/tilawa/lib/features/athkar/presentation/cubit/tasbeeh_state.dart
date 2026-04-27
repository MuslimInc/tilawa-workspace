import 'package:equatable/equatable.dart';
import 'package:tilawa_core/errors/failures.dart';

import '../../domain/entities/tasbeeh_dhikr.dart';

enum TasbeehStatus { initial, loading, loaded, error }

enum TasbeehViewMode { options, create, history, counting }

class TasbeehState extends Equatable {
  const TasbeehState({
    this.status = TasbeehStatus.initial,
    this.viewMode = TasbeehViewMode.options,
    this.savedDhikr = const [],
    this.draftText = '',
    this.draftTargetText = '',
    this.vibrationEventCount = 0,
    this.selectedDhikrId,
    this.failure,
    this.errorMessage,
  });

  final TasbeehStatus status;
  final TasbeehViewMode viewMode;
  final List<TasbeehDhikr> savedDhikr;
  final String draftText;
  final String draftTargetText;
  final int vibrationEventCount;
  final String? selectedDhikrId;
  final Failure? failure;
  final String? errorMessage;

  TasbeehDhikr? get selectedDhikr {
    if (selectedDhikrId == null) return null;

    for (final item in savedDhikr) {
      if (item.id == selectedDhikrId) {
        return item;
      }
    }
    return null;
  }

  int get selectedCount => selectedDhikr?.count ?? 0;

  TasbeehState copyWith({
    TasbeehStatus? status,
    TasbeehViewMode? viewMode,
    List<TasbeehDhikr>? savedDhikr,
    String? draftText,
    String? draftTargetText,
    int? vibrationEventCount,
    Object? selectedDhikrId = _sentinel,
    Object? failure = _sentinel,
    Object? errorMessage = _sentinel,
  }) {
    return TasbeehState(
      status: status ?? this.status,
      viewMode: viewMode ?? this.viewMode,
      savedDhikr: savedDhikr ?? this.savedDhikr,
      draftText: draftText ?? this.draftText,
      draftTargetText: draftTargetText ?? this.draftTargetText,
      vibrationEventCount: vibrationEventCount ?? this.vibrationEventCount,
      selectedDhikrId: selectedDhikrId == _sentinel
          ? this.selectedDhikrId
          : selectedDhikrId as String?,
      failure: failure == _sentinel ? this.failure : failure as Failure?,
      errorMessage: errorMessage == _sentinel
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  @override
  List<Object?> get props => [
    status,
    viewMode,
    savedDhikr,
    draftText,
    draftTargetText,
    vibrationEventCount,
    selectedDhikrId,
    failure,
    errorMessage,
  ];
}

const Object _sentinel = Object();
