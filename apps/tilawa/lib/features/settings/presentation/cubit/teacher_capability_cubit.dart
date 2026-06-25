import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_sessions/quran_sessions.dart' as quran_sessions;
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/features/quran_sessions/presentation/quran_sessions_user.dart';
import 'package:tilawa/features/quran_sessions/quran_sessions_feature_flags.dart';
import 'package:tilawa/features/settings/domain/services/teacher_capability_refresh_notifier.dart';

class SettingsTeacherCapabilityLoadState extends Equatable {
  const SettingsTeacherCapabilityLoadState({
    this.capability,
    this.isLoading = true,
    this.hasLoaded = false,
  });

  final quran_sessions.TeacherCapability? capability;
  final bool isLoading;
  final bool hasLoaded;

  SettingsTeacherCapabilityLoadState copyWith({
    quran_sessions.TeacherCapability? capability,
    bool? isLoading,
    bool? hasLoaded,
  }) {
    return SettingsTeacherCapabilityLoadState(
      capability: capability ?? this.capability,
      isLoading: isLoading ?? this.isLoading,
      hasLoaded: hasLoaded ?? this.hasLoaded,
    );
  }

  @override
  List<Object?> get props => [capability, isLoading, hasLoaded];
}

/// Loads [TeacherCapability] for Settings profile + teaching section.
class TeacherCapabilityCubit extends Cubit<SettingsTeacherCapabilityLoadState> {
  TeacherCapabilityCubit({
    quran_sessions.GetCurrentUserTeacherCapabilityUseCase? useCase,
    TeacherCapabilityRefreshNotifier? refreshNotifier,
  }) : _useCase =
           useCase ??
           getIt<quran_sessions.GetCurrentUserTeacherCapabilityUseCase>(),
       _refreshNotifier =
           refreshNotifier ?? getIt<TeacherCapabilityRefreshNotifier>(),
       super(const SettingsTeacherCapabilityLoadState()) {
    _reviewSubscription = _refreshNotifier.onApplicationReviewed.listen(
      _onApplicationReviewed,
    );
  }

  final quran_sessions.GetCurrentUserTeacherCapabilityUseCase _useCase;
  final TeacherCapabilityRefreshNotifier _refreshNotifier;
  late final StreamSubscription<String> _reviewSubscription;
  int _loadGeneration = 0;

  void load() => _load(silent: false);

  void refresh() => _load(silent: state.hasLoaded);

  @override
  Future<void> close() {
    _reviewSubscription.cancel();
    return super.close();
  }

  Future<void> _load({bool silent = false}) async {
    final generation = ++_loadGeneration;

    if (!silent) {
      if (!isClosed) {
        emit(state.copyWith(isLoading: true));
      }
    }

    final config = quranSessionsFeatureConfig();
    if (!config.showProfileTeacherEntry) {
      if (isClosed || generation != _loadGeneration) return;
      emit(state.copyWith(isLoading: false, hasLoaded: true));
      return;
    }

    final userId = quranSessionsCurrentUserId(getIt);
    if (userId == null) {
      if (isClosed || generation != _loadGeneration) return;
      emit(state.copyWith(isLoading: false, hasLoaded: true));
      return;
    }

    final result = await _useCase(userId);
    if (isClosed || generation != _loadGeneration) return;

    emit(
      state.copyWith(
        isLoading: false,
        hasLoaded: true,
        capability: result.fold(
          (_) => const quran_sessions.TeacherCapability(
            state: quran_sessions.TeacherCapabilityState.none,
          ),
          (capability) => capability,
        ),
      ),
    );
  }

  void _onApplicationReviewed(String status) {
    if (!state.hasLoaded) {
      return;
    }
    if (status.isEmpty) {
      return;
    }
    refresh();
  }
}
