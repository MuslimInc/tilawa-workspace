import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/features/quran_sessions/presentation/quran_sessions_user.dart';
import 'package:tilawa/features/quran_sessions/quran_sessions_feature_flags.dart';

/// Whether Settings / profile should show the teaching section.
abstract final class SettingsTeachingVisibility {
  /// Approved or former teachers only — no in-app apply entry.
  static bool shouldShowSection({
    required bool capabilityLoaded,
    required TeacherCapability? capability,
  }) {
    if (!capabilityLoaded || capability == null) {
      return false;
    }
    return capability.hasTeacherMarketplaceRole;
  }

  static bool isLoading({required bool capabilityLoaded}) {
    return !capabilityLoaded;
  }
}

class TeacherApplicationAccessState extends Equatable {
  const TeacherApplicationAccessState({
    this.canApplyAsTeacher = false,
    this.isLoading = true,
    this.hasResolved = false,
  });

  final bool canApplyAsTeacher;
  final bool isLoading;
  final bool hasResolved;

  TeacherApplicationAccessState copyWith({
    bool? canApplyAsTeacher,
    bool? isLoading,
    bool? hasResolved,
  }) {
    return TeacherApplicationAccessState(
      canApplyAsTeacher: canApplyAsTeacher ?? this.canApplyAsTeacher,
      isLoading: isLoading ?? this.isLoading,
      hasResolved: hasResolved ?? this.hasResolved,
    );
  }

  @override
  List<Object?> get props => [canApplyAsTeacher, isLoading, hasResolved];
}

/// Loads remote [canApplyAsTeacher] for Settings teaching entry gating.
class TeacherApplicationAccessCubit
    extends Cubit<TeacherApplicationAccessState> {
  TeacherApplicationAccessCubit({
    ResolveTeacherApplicationAccessUseCase? useCase,
  }) : _useCase = useCase ?? getIt<ResolveTeacherApplicationAccessUseCase>(),
       super(const TeacherApplicationAccessState());

  final ResolveTeacherApplicationAccessUseCase _useCase;
  int _loadGeneration = 0;

  void load() => _load(silent: false);

  void refresh() => _load(silent: state.hasResolved);

  Future<void> _load({required bool silent}) async {
    final generation = ++_loadGeneration;

    final config = quranSessionsFeatureConfig();
    if (!config.teacherApplicationEnabled &&
        !config.teacherApplicationEntryEnabled) {
      if (isClosed || generation != _loadGeneration) return;
      emit(
        const TeacherApplicationAccessState(
          canApplyAsTeacher: false,
          isLoading: false,
          hasResolved: true,
        ),
      );
      return;
    }

    final userId = quranSessionsCurrentUserId(getIt);
    if (userId == null) {
      if (isClosed || generation != _loadGeneration) return;
      emit(
        const TeacherApplicationAccessState(
          canApplyAsTeacher: false,
          isLoading: false,
          hasResolved: true,
        ),
      );
      return;
    }

    if (!silent) {
      if (!isClosed) {
        emit(state.copyWith(isLoading: true));
      }
    }

    final result = await _useCase(userId);
    if (isClosed || generation != _loadGeneration) return;

    emit(
      TeacherApplicationAccessState(
        canApplyAsTeacher: result.fold(
          (_) => false,
          (access) => access.canApplyAsTeacher,
        ),
        isLoading: false,
        hasResolved: true,
      ),
    );
  }
}
