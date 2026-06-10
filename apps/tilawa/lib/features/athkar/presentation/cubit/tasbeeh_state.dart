import 'package:equatable/equatable.dart';
import 'package:tilawa_core/errors/failures.dart';

import '../../domain/entities/tasbeeh_dhikr.dart';
import '../../domain/entities/tasbeeh_layout_mode.dart';
import '../models/tasbeeh_counting_session.dart';

enum TasbeehStatus { initial, loading, loaded, error }

enum TasbeehViewMode {
  /// Entry hub: saved dhikr list, quick count, and create.
  home,

  /// In-memory tap-to-count (no persistence, no target feedback).
  quickCount,
  create,

  /// Counting a saved dhikr from the hub or after create.
  selectedCounting,
}

class TasbeehState extends Equatable {
  const TasbeehState({
    this.status = TasbeehStatus.initial,
    this.viewMode = TasbeehViewMode.home,
    this.savedDhikr = const [],
    this.draftText = '',
    this.draftTargetText = '',
    this.ephemeralCount = 0,
    this.activeSavedDhikrId,
    this.savedTargetFeedbackPulse = 0,
    this.layoutMode = TasbeehLayoutMode.list,
    this.failure,
    this.errorMessage,
  });

  final TasbeehStatus status;
  final TasbeehViewMode viewMode;
  final List<TasbeehDhikr> savedDhikr;
  final String draftText;
  final String draftTargetText;

  /// In-memory counter for [TasbeehViewMode.quickCount] only.
  final int ephemeralCount;

  /// Saved dhikr being counted in [TasbeehViewMode.selectedCounting].
  final String? activeSavedDhikrId;

  /// Bumps on target-reached feedback for saved-dhikr counting only.
  final int savedTargetFeedbackPulse;

  final TasbeehLayoutMode layoutMode;

  final Failure? failure;
  final String? errorMessage;

  TasbeehDhikr? get activeSavedDhikr {
    final id = activeSavedDhikrId;
    if (id == null) return null;
    for (final item in savedDhikr) {
      if (item.id == id) return item;
    }
    return null;
  }

  TasbeehCountingSession? get countingSession => switch (viewMode) {
    TasbeehViewMode.quickCount => TasbeehEphemeralCountingSession(
      count: ephemeralCount,
    ),
    TasbeehViewMode.selectedCounting => () {
      final dhikr = activeSavedDhikr;
      if (dhikr == null) return null;
      return TasbeehSavedDhikrCountingSession(
        dhikr: dhikr,
        targetFeedbackPulse: savedTargetFeedbackPulse,
      );
    }(),
    _ => null,
  };

  TasbeehState copyWith({
    TasbeehStatus? status,
    TasbeehViewMode? viewMode,
    List<TasbeehDhikr>? savedDhikr,
    String? draftText,
    String? draftTargetText,
    int? ephemeralCount,
    int? savedTargetFeedbackPulse,
    TasbeehLayoutMode? layoutMode,
    Object? activeSavedDhikrId = _sentinel,
    Object? failure = _sentinel,
    Object? errorMessage = _sentinel,
  }) {
    return TasbeehState(
      status: status ?? this.status,
      viewMode: viewMode ?? this.viewMode,
      savedDhikr: savedDhikr ?? this.savedDhikr,
      draftText: draftText ?? this.draftText,
      draftTargetText: draftTargetText ?? this.draftTargetText,
      ephemeralCount: ephemeralCount ?? this.ephemeralCount,
      activeSavedDhikrId: activeSavedDhikrId == _sentinel
          ? this.activeSavedDhikrId
          : activeSavedDhikrId as String?,
      savedTargetFeedbackPulse:
          savedTargetFeedbackPulse ?? this.savedTargetFeedbackPulse,
      layoutMode: layoutMode ?? this.layoutMode,
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
    ephemeralCount,
    activeSavedDhikrId,
    savedTargetFeedbackPulse,
    layoutMode,
    failure,
    errorMessage,
  ];
}

const Object _sentinel = Object();
